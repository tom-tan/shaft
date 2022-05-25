/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.command_line_tool;

import cwl.v1_0.schema;

import dyaml : Node;

import salad.type : Either, orElse;

import shaft.evaluator : Evaluator;
import shaft.runtime : Runtime;
import shaft.type.common : DeterminedType, TypedParameters;

import std.typecons : Tuple;

/**
 * See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Generic_execution_process
 * This function provides 6 and 7 for CommandLineTool
 */
int execute(CommandLineTool clt, TypedParameters params, Runtime runtime, Evaluator evaluator)
{
    import salad.type : match;
    import std.array : join;
    import std.exception : enforce;
    import std.path : buildPath;
    import std.process : Config, environment, Pid, spawnProcess, wait;
    import std.stdio : File;
    // 6. Perform any further setup required by the specific process type.

    auto stdin = runtime.internal.stdin.match!(
        (string file) => File(file),
        _ => File("/dev/null"),
    );

    auto stdout = runtime.internal.stdout.match!(
        (string basename) => File(buildPath(runtime.outdir, basename), "w"),
        _ => File(buildPath(runtime.internal.logdir, "stdout.txt"), "w"),
    );

    auto stderr = runtime.internal.stderr.match!(
        (string basename) => File(buildPath(runtime.outdir, basename), "w"),
        _ => File(buildPath(runtime.internal.logdir, "stderr.txt"), "w"),
    );

    version(none) // TODO
    {
        // stage in (all process types)
        auto staged = stageIn(params, runtime,
                              clt.dig!(["requirements", "InitialWorkDirRequirement"], InitialWorkDirRequirement),
                              evaluator);
        // path mapping
        Node mappedInputs;
        Runtime mappedRuntime;
        // TODO
        string mappedStdin;
    }

    auto args = buildCommandLine(clt, params, runtime, evaluator);

    version(none)
    {
        // add container args
    }

    auto env = [
        "HOME": runtime.outdir,
        "TMPDIR": runtime.tmpdir,
        "PATH": environment["PATH"],
    ];

    import salad.util : dig;
    if (auto e = clt.dig!(["requirements", "EnvVarRequirement"], EnvVarRequirement))
    {
        foreach(def; e.envDef_)
        {
            env[def.envName_] = evaluator.eval!string(def.envValue_, params.parameters, runtime);
        }
    }
    else if (auto e = clt.dig!(["hints", "EnvVarRequirement"], EnvVarRequirement))
    {
        foreach(def; e.envDef_)
        {
            env[def.envName_] = evaluator.eval!string(def.envValue_, params.parameters, runtime);
        }
    }

    Pid pid;
    // 7. Execute the process.
    if (clt.dig!(["requirements", "ShellCommandRequirement"], ShellCommandRequirement))
    {
        pid = spawnProcess(args.join(" "), stdin, stdout, stderr, env, Config.newEnv, runtime.outdir);
    }
    else
    {
        // execute in the shell?
        pid = spawnProcess(args, stdin, stdout, stderr, env, Config.newEnv, runtime.outdir);
    }
    scope(failure)
    {
        import std.process : kill;
        kill(pid);
        wait(pid);
    }

    auto code = wait(pid);

    return code;
}

///
alias Param = Tuple!(
    Tuple!(int, TieBreaker), "key",
    CommandLineBinding, "binding",
    Node, "self",
    DeterminedType, "type",
);

/**
 * See_Also: 3 in https://www.commonwl.org/v1.1/CommandLineTool.html#CommandLineBinding
 */
alias TieBreaker = Either!(size_t, string);

/**
 * See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Input_binding
 */
auto buildCommandLine(CommandLineTool cmd, TypedParameters params, Runtime runtime, Evaluator evaluator)
{
    import salad.type : match, None, orElse;

    import shaft.type.common : guessedType;

    import std.algorithm : map, multiSort;
    import std.array : array, join;
    import std.range : chain, enumerate;
    import std.typecons : tuple;

    // 1. Collect `CommandLineBinding` objects from `arguments``. Assign a sorting key `[position, i]` where `position` is `CommandLineBinding.position` and `i` is the index in the `arguments` list.
    auto args = cmd.arguments_.match!(
        (None _) => (Param[]).init,
        args => args.enumerate.map!(a => 
            a.value.match!(
                (string s) {
                    auto val = evaluator.eval(s, params.parameters, runtime);
                    return Param(tuple(0, TieBreaker(a.index)), new CommandLineBinding, val, val.guessedType);
                },
                (CommandLineBinding clb) {
                    import salad.type : tryMatch;
                    auto pos = clb.position_.match!(
                        (int i) => i,
                        // (string exp) => evaluator.eval!int(exp, params.parameters, runtime),  // TODO for v1.1 and later
                        none => 0,
                    );
                    auto val = evaluator.eval(clb.valueFrom_.tryMatch!((string s) => s), params.parameters, runtime);
                    return Param(tuple(pos, TieBreaker(a.index)), clb, val, val.guessedType);
                },
            )
        ).array,
    );

    // 2. Collect `CommandLineBinding` objects from the `inputs` schema and associate them with values from the input object. Where the input type is a record, array, or map, recursively walk the schema and input object, collecting nested `CommandLineBinding` objects and associating them with values from the input object.
    // 3. Create a sorting key by taking the value of the `position` field at each level leading to each leaf binding object. If `position` is not specified, it is not added to the sorting key. For bindings on arrays and maps, the sorting key must include the array index or map key following the position. If and only if two bindings have the same sort key, the tie must be broken using the ordering of the field or parameter name immediately containing the leaf binding.
    auto inp = cmd.inputs_.map!((i) {
        import salad.util : dig;

        auto id = i.id_;
        auto pos = i.dig!(["inputBinding", "position"])(0); // TODO for v1.2: Expression
        Node val;
        DeterminedType type;
        CommandLineBinding clb;

        i.inputBinding_.match!(
            (None _) {
                val = params.parameters[id];
                type = params.types[id];
                clb = null;
            },
            (clb_) {
                clb = clb_;
                clb_.valueFrom_.match!(
                    (None _) {
                        val = params.parameters[id];
                        type = params.types[id];
                    },
                    (str) {
                        import dyaml : NodeType;

                        if (params.parameters[id].type == NodeType.null_)
                        {
                            // See_Also: `valueFrom` in https://www.commonwl.org/v1.1/CommandLineTool.html#CommandLineBinding
                            // If the value of the associated input parameter is `null`, `valueFrom` is not evaluated ...
                            val = params.parameters[id];
                            type = params.types[id];
                        }
                        else
                        {
                            val = evaluator.eval(str, params.parameters, runtime, params.parameters[id]);
                            type = val.guessedType;
                        }
                    },
                );
            },
        );
        return Param(tuple(pos, TieBreaker(id)), clb, val, type);
    }).array;

    // 4. Sort elements using the assigned sorting keys. Numeric entries sort before strings.
    // 5. In the sorted order, apply the rules defined in `CommandLineBinding` to convert bindings to actual command line elements.
    // TODO: pass ShellCommandRequirement?
    auto cmdElems = processParameters(args~inp);
    
    // 6. Insert elements from `baseCommand` at the beginning of the command line.
    auto base = cmd.baseCommand_.match!(
        (string s) => [s],
        (string[] ss) => ss,
        _ => (string[]).init,
    );

    return base~cmdElems;
}

///
auto processParameters(Param[] params)
{
    import salad.type : match;
    import shaft.exception : InvalidDocument;
    import std.algorithm : filter, joiner, map, multiSort;
    import std.array : array;
    import std.exception : enforce, ifThrown;
    import std.format : format;
    import std.range : empty;

    // 4. Sort elements using the assigned sorting keys. Numeric entries sort before strings.
    params.multiSort!(
        "a.key[0] < b.key[0]",
        (a, b) => match!(
            (size_t lhs, string rhs) => true,
            (string lhs, size_t rhs) => false,
            (lhs, rhs) => lhs < rhs,
        )(a.key[1], b.key[1]),
    );

    // 5. In the sorted order, apply the rules defined in `CommandLineBinding` to convert bindings to actual command line elements.
    return params
        .map!(p => 
            applyRules(p.tupleof[1..$])
                .ifThrown!InvalidDocument((e) {
                    enforce(false, new InvalidDocument(format!"%s in `%s`"(e.msg, p.key[1]), e.mark));
                    return CmdElemType.init;
                })
                .match!(
                    (string s) => [s],
                    ss => ss,
                )
        )
        .joiner
        .filter!(a => !a.empty)
        .array;
}

//
unittest
{
    import dyaml : Loader, Node;
    import std.file : mkdir, rmdir;

    enum inpDoc = q"EOS
        inp1: 10
EOS";

    enum cwlDoc = q"EOS
        cwlVersion: v1.0
        class: CommandLineTool
        baseCommand: echo
        inputs:
            - id: inp1
              type: int
              inputBinding: {}
        outputs:
            - id: out
              type: stdout
EOS";

    auto params = TypedParameters(
        Loader.fromString(inpDoc).load,
        ["inp1": DeterminedType(new CWLType("int"))],
    );

    auto clt = Loader.fromString(cwlDoc).load.as!CommandLineTool;

    auto evaluator = Evaluator(null, "v1.0", false);

    auto outdir = "test-outdir";
    mkdir(outdir);
    scope(exit) rmdir(outdir);

    auto tmpdir = "test-tmpdir";
    mkdir(tmpdir);
    scope(exit) rmdir(tmpdir);

    auto args = buildCommandLine(
        clt,
        params,
        Runtime(params.parameters, outdir, tmpdir, null, null, evaluator),
        evaluator
    );

    assert(args == ["echo", "10"]);
}

alias CmdElemType = Either!(string, string[]);

///
auto toCmdElems(CmdElemType val, CommandLineBinding clb)
{
    import dyaml : Mark;
    import salad.type : match, MatchException, None, tryMatch;
    import shaft.exception : InvalidDocument;
    import std.array : join;
    import std.exception : enforce, ifThrown;
    import std.range : empty;

    if (clb is null)
    {
        return CmdElemType((string[]).init);
    }

    auto arg = val.match!(
        (string _) {
            clb.itemSeparator_
               .tryMatch!((None _) => true)
               .ifThrown!MatchException((e) {
                   enforce(false, new InvalidDocument(
                       "`itemSeparator` is supported only for array types: "~_,
                       Mark.init,
                   ));
                   return true;
               });
            return val;
        },
        (string[] vs) => clb.itemSeparator_.match!(
            (string sep) => vs.empty ? val : CmdElemType(vs.join(sep)),
            none => val,
        ),
    );

    auto ret = clb
        .prefix_
        .match!(
            (string pr) {
                return arg.match!(
                    (string s) {
                        auto sep = clb.separate_.orElse(true);
                        return sep ? CmdElemType([pr, s]) : CmdElemType(pr~s);
                    },
                    (string[] ss) {
                        clb.separate_.match!(
                            (bool sep_) {
                                enforce(sep_, new InvalidDocument(
                                    "`separate: false` is supported only for scalar types",
                                    Mark.init,
                                ));
                                return true;
                            },
                            none => true,
                        );
                        return CmdElemType(pr~ss);
                    },
                );
            },
            none => arg,
        );

    // process shellQuote: false
    return ret.match!(
        (string s) => ret,
        (string[] ss) => ret,
    );
}

/**
 * See_Also: https://www.commonwl.org/v1.1/CommandLineTool.html#CommandLineBinding
 */
CmdElemType applyRules(CommandLineBinding binding, Node self, DeterminedType type)
{
    import salad.type : match;
    import shaft.type.common : ArrayType, EnumType, RecordType;
    import std.exception : enforce;

    return type.match!(
        (CWLType t) {
            final switch(t.value_)
            {
            case "null":
                // Add nothing.
                return CmdElemType((string[]).init);
            case "boolean":
                // If true, add `prefix` to the command line. If false, add nothing.
                if (self.as!bool)
                {
                    if (binding is null)
                    {
                        return CmdElemType((string[]).init);
                    }
                    return binding.prefix_.match!(
                        (string pre) => CmdElemType([pre]),
                        none => CmdElemType((string[]).init),
                    );
                }
                else
                {
                    return CmdElemType((string[]).init);
                }
            case "int", "long", "float", "double", "string":
                // Add `prefix` and the string (or decimal representation for numbers) to command line.
                return toCmdElems(CmdElemType(self.as!string), binding);
            case "File", "Directory":
                assert("path" in self);
                // Add `prefix` and the value of `File.path` (or `Directory.path`) to the command line.
                return toCmdElems(CmdElemType(self["path"].as!string), binding);
            }
        },
        (RecordType rtype) {
            // Add `prefix` only, and recursively add object fields for which `inputBinding` is specified.
            import salad.type : orElse;
            import salad.util : dig;
            import std.algorithm : filter, map;
            import std.array : array, byPair;
            import std.typecons : tuple;

            auto cmdElems = rtype
                .fields
                .byPair
                .filter!(pair => pair.value[1].orElse(null))
                .map!(pair => 
                    Param(
                        tuple(pair.value[1].dig!"position"(0), TieBreaker(pair.key)),
                        pair.value[1].orElse(null),
                        self[pair.key],
                        *pair.value[0],
                    )
                )
                .array
                .processParameters;
            return toCmdElems(CmdElemType(cmdElems), binding);
        },
        (EnumType etype) {
            return toCmdElems(toCmdElems(CmdElemType(self.as!string), etype.inputBinding.orElse(new CommandLineBinding)),
                              binding);
        },
        (ArrayType atype) {
            import dyaml : NodeType;
            import std.array : array;
            import std.range : empty;

            assert(self.type == NodeType.sequence);
            auto arr = self.sequence.array;
            if (arr.empty)
            {
                // If the array is empty, it does not add anything to command line.
                return CmdElemType((string[]).init);
            }
            else
            {
                import salad.type : orElse;
                import std.algorithm : map;
                import std.array : join;
                import std.range : zip;

                auto strs = zip(atype.types, self.sequence)
                    .map!((tpl) {
                        auto clb = atype.inputBinding.orElse(new CommandLineBinding);
                        return applyRules(clb, tpl[1], *tpl[0]).match!(
                            (string s) => [s],
                            ss => ss,
                        );
                    })
                    .join;
                return toCmdElems(CmdElemType(strs), binding);
            }
        },
    );
}
