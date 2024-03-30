/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.command_line_tool;

import cwl.v1_0;

import dyaml : Node;

import salad.type : Either, Optional, orElse;

import shaft.evaluator : Evaluator;
import shaft.runtime : Runtime;
import shaft.type.argstr : EscapedString, NonEscapedString;
import shaft.type.common : DeterminedType, TypedParameters;

import std.logger : stdThreadLocalLog;
import std.typecons : Tuple;

/**
 * See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Generic_execution_process
 * This function provides 6 and 7 for CommandLineTool
 */
int execute(CommandLineTool clt, TypedParameters params, Runtime runtime, Evaluator evaluator)
{
    import salad.type : match;
    import salad.util : dig;
    import shaft.exception : SystemException;
    import shaft.requirement : getRequirement;
    import shaft.runtime : availableCores, availableDirSize, availableRam;
    import std.array : join;
    import std.exception : enforce, ifThrown;
    import std.path : buildPath;
    import std.process : Config, environment, ProcessException, spawnProcess, wait;
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
                              clt.getRequirement!InitialWorkDirRequirement(params.parameters),
                              evaluator);
        // path mapping
        Node mappedInputs;
        Runtime mappedRuntime;
    }

    auto useShell = clt.getRequirement!ShellCommandRequirement(params.parameters) !is null;

    auto args = buildCommandLine(clt, params, runtime, evaluator, useShell);

    version(none)
    {
        // add container args
    }

    auto env = [
        "HOME": runtime.outdir,
        "TMPDIR": runtime.tmpdir,
        "PATH": environment["PATH"],
    ];

    if (auto e = clt.getRequirement!EnvVarRequirement(params.parameters))
    {
        foreach(def; e.envDef_)
        {
            env[def.envName_] = evaluator.eval!string(def.envValue_, params.parameters, runtime);
        }
    }

    long[string] limits;
        
    if (runtime.cores < availableCores)
    {
        limits["cores"] = runtime.cores;
    }

    if (runtime.ram < availableRam)
    {
        limits["ram"] = runtime.ram;
    }

    if (runtime.tmpdirSize < availableDirSize(runtime.tmpdir))
    {
        limits["tmpdirSize"] = runtime.tmpdirSize;
    }

    if (runtime.outdirSize < availableDirSize(runtime.outdir))
    {
        limits["outdirSize"] = runtime.outdirSize;
    }

    if (false /**/)
    {
        // user hooks such as container
    }
    else
    {
        // TODO: embedded limit fun
    }

    // 7. Execute the process.
    auto pid = spawnProcess(args, stdin, stdout, stderr, env, Config.newEnv, runtime.outdir)
        .ifThrown!ProcessException((e) {
            import std.process : Pid;
            enforce!SystemException(false, e.msg);
            return Pid.init;
        });
    stdThreadLocalLog.info(() {
        import std : JSONValue, escapeShellCommand;
        return JSONValue([
            "message": JSONValue("Start execution"),
            "command": JSONValue(escapeShellCommand(args)),
            "args": JSONValue(args),
            "env": JSONValue(env),
            "stdin": JSONValue(stdin.name),
            "stdout": JSONValue(stdout.name),
            "stderr": JSONValue(stderr.name),
            "outdir": JSONValue(runtime.outdir),
            "pid": JSONValue(pid.processID),
        ]);
    }());
    scope(failure)
    {
        import std.process : kill;
        kill(pid);
        wait(pid);
    }

    version(none)
    {
        // TODO: restore resource limit for embedded limit fun
    }

    auto code = wait(pid);

    stdThreadLocalLog.info(() {
        import std : JSONValue;
        return JSONValue([
            "message": JSONValue("Success execution"),
            "code": JSONValue(code),
            "outdir": JSONValue(runtime.outdir),
            "stdout": JSONValue(stdout.name),
            "stderr": JSONValue(stderr.name),
        ]);
    }());

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
auto buildCommandLine(CommandLineTool cmd, TypedParameters params, Runtime runtime, Evaluator evaluator, bool useShell)
{
    import salad.type : match, None, orElse;

    import shaft.type.common : guessedType;

    import std.algorithm : map, multiSort;
    import std.array : array, join;
    import std.conv : to;
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
    auto inp = cmd.inputs_.map!(i => 
        collectParams(
            i.id_, params.parameters[i.id_], params.types[i.id_], i.inputBinding_,
            params.parameters, runtime, evaluator,
        )
    ).join;

    // 4. Sort elements using the assigned sorting keys. Numeric entries sort before strings.
    // 5. In the sorted order, apply the rules defined in `CommandLineBinding` to convert bindings to actual command line elements.
    auto cmdElems = processParameters(args~inp, params.parameters, runtime, evaluator, useShell).map!(to!string).array;
    
    // 6. Insert elements from `baseCommand` at the beginning of the command line.
    auto base = cmd.baseCommand_.match!(
        (string s) => [s],
        (string[] ss) => ss,
        _ => (string[]).init,
    );

    auto retArgs = base~cmdElems;
    return useShell ? ["sh", "-c", retArgs.join(" ")] : retArgs;
}

// 2. Collect `CommandLineBinding` objects from the `inputs` schema and associate them with values from the input object. Where the input type is a record, array, or map, recursively walk the schema and input object, collecting nested `CommandLineBinding` objects and associating them with values from the input object.
// 3. Create a sorting key by taking the value of the `position` field at each level leading to each leaf binding object. If `position` is not specified, it is not added to the sorting key. For bindings on arrays and maps, the sorting key must include the array index or map key following the position. If and only if two bindings have the same sort key, the tie must be broken using the ordering of the field or parameter name immediately containing the leaf binding.
Param[] collectParams(
    string id, Node node, DeterminedType type, Optional!CommandLineBinding binding,
    Node inputs, Runtime runtime, Evaluator evaluator
)
{
    import salad.type : match, None;
    import shaft.type.common : ArrayType, EnumType, RecordType;
    import std.algorithm : map;
    import std.array : byPair, join;
    import std.typecons : tuple;

    return binding.match!(
        // If none, search in leaves
        // See_Also: record_output_binding
        (None _) =>
            type.match!(
                (EnumType et) =>
                    et.inputBinding.match!(
                        (None _) => (Param[]).init,
                        (binding_) {
                            auto pos = binding_.position_.orElse(0);
                            auto type_ = DeterminedType(EnumType(et.name, Optional!CommandLineBinding.init));
                            return [Param(tuple(pos, TieBreaker(id)), binding_, node, type_)];
                        },
                    ),
                (ArrayType at) =>
                    at.inputBinding.match!(
                        (None _) => (Param[]).init,
                        (binding_) {
                            auto pos = binding_.position_.orElse(0);
                            // TODO: inputBinding for each element
                            auto type_ = DeterminedType(ArrayType(at.types, Optional!CommandLineBinding.init));
                            return [Param(tuple(pos, TieBreaker(id)), binding_, node, type_)];
                        },
                    ),
                (RecordType rt) =>
                    rt.fields.byPair.map!(fs =>
                        collectParams(fs.key, node[fs.key], *fs.value[0], fs.value[1], inputs, runtime, evaluator)
                    ).join,
                other => (Param[]).init,
            ),
        clb =>
            clb.valueFrom_.match!(
                (None _) => [Param(tuple(clb.position_.orElse(0), TieBreaker(id)), clb, node, type)],
                (str) {
                    import dyaml : NodeType;

                    Node val;
                    DeterminedType type_;
                    if (node.type == NodeType.null_)
                    {
                        // See_Also: `valueFrom` in https://www.commonwl.org/v1.1/CommandLineTool.html#CommandLineBinding
                        // If the value of the associated input parameter is `null`, `valueFrom` is not evaluated ...
                        val = node;
                        type_ = type;
                    }
                    else
                    {
                        import shaft.type.common : guessedType;
                        val = evaluator.eval(str, inputs, runtime, node);
                        type_ = val.guessedType;
                    }
                    return [Param(tuple(clb.position_.orElse(0), TieBreaker(id)), clb, val, type_)];
                },
            )
    );
}

///
auto processParameters(Param[] params, Node inputs, Runtime runtime, Evaluator evaluator, bool useShell)
{
    import salad.type : match;
    import shaft.exception : InvalidDocument;
    import std.algorithm : filter, joiner, map, multiSort;
    import std.array : array;
    import std.conv : to;
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
            applyRules(p.tupleof[1..$], inputs, runtime, evaluator, useShell)
                .ifThrown!InvalidDocument((e) {
                    enforce(false, new InvalidDocument(format!"%s in `%s`"(e.msg, p.key[1]), e.mark));
                    return CmdElemType.init;
                })
                .match!(
                    (Str s) => [s],
                    ss => ss,
                )
        )
        .joiner
        .filter!(a => !a.match!(to!string).empty)
        .array;
}

//
unittest
{
    import dyaml : Loader, Node;
    import shaft.type.common : PrimitiveType;
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
        ["inp1": DeterminedType(PrimitiveType(new CWLType("int")))],
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
        Runtime(params.parameters, outdir, tmpdir, null, evaluator),
        evaluator,
        false,
    );

    assert(args == ["echo", "10"]);
}

alias Str = Either!(NonEscapedString, EscapedString);
alias CmdElemType = Either!(Str, Str[]);

///
auto toCmdElems(CmdElemType val, CommandLineBinding clb, bool useShell)
{
    import dyaml : Mark;
    import salad.type : match, MatchException, None, tryMatch;
    import shaft.exception : InvalidDocument;
    import std.algorithm : map;
    import std.array : array;
    import std.exception : enforce, ifThrown;
    import std.range : empty;

    auto join(Str[] ss, string sep)
    {
        import std.algorithm : reduce;

        if (ss.empty)
        {
            return Str.init;
        }
        return ss[0].reduce!((Str a, Str b) {
            return match!((a_, b_) => Str(a_~sep~b_))(a, b);
        })(ss[1..$]);
    }

    if (clb is null)
    {
        return CmdElemType((Str[]).init);
    }

    auto arg = val.match!(
        (Str _) {
            clb.itemSeparator_
               .tryMatch!((None _) => true)
               .ifThrown!MatchException((e) {
                   enforce(false, new InvalidDocument(
                       "`itemSeparator` is supported only for array types",
                       clb.mark,
                   ));
                   return true;
               });
            return val;
        },
        (Str[] vs) => clb.itemSeparator_.match!(
            (string sep) => vs.empty ? val : CmdElemType(join(vs, sep)),
            none => val,
        ),
    );

    auto ret = clb
        .prefix_
        .match!(
            (string pr) {
                return arg.match!(
                    (Str s) {
                        auto sep = clb.separate_.orElse(true);
                        return sep ? CmdElemType([Str(pr), s]) : CmdElemType(s.match!(ss => Str(pr~ss)));
                    },
                    (Str[] ss) {
                        clb.separate_.match!(
                            (bool sep_) {
                                enforce(sep_, new InvalidDocument(
                                    "`separate: false` is supported only for scalar types",
                                    clb.mark,
                                ));
                                return true;
                            },
                            none => true,
                        );
                        return CmdElemType(Str(pr)~ss);
                    },
                );
            },
            none => arg,
        );

    // strings are not quoted when !useShell because it can be done by `buildCommandLine`
    auto shouldQuote = useShell && clb.shellQuote_.orElse(true);
    alias escapeIfUseShell = s => s.match!(s_ =>
        shouldQuote ? Str(EscapedString(s_))
                    : Str(s_)
    );
    return ret.match!(
        (Str s) => CmdElemType(escapeIfUseShell(s)),
        (Str[] ss) => CmdElemType(ss.map!escapeIfUseShell.array),
    );
}

/**
 * See_Also: https://www.commonwl.org/v1.1/CommandLineTool.html#CommandLineBinding
 */
CmdElemType applyRules(
    CommandLineBinding binding, Node self, DeterminedType type,
    Node inputs, Runtime runtime, Evaluator evaluator, bool useShell
)
{
    import salad.type : match;
    import shaft.type.common : ArrayType, EnumType, PrimitiveType, RecordType;

    return type.match!(
        (PrimitiveType t) {
            final switch(t.type.value)
            {
            case "null":
                // Add nothing.
                return CmdElemType((Str[]).init);
            case "boolean":
                // If true, add `prefix` to the command line. If false, add nothing.
                if (self.as!bool)
                {
                    if (binding is null)
                    {
                        return CmdElemType((Str[]).init);
                    }
                    return binding.prefix_.match!(
                        (string pre) => CmdElemType(Str(pre)),
                        none => CmdElemType((Str[]).init),
                    );
                }
                else
                {
                    return CmdElemType((Str[]).init);
                }
            case "int", "long", "float", "double", "string":
                // Add `prefix` and the string (or decimal representation for numbers) to command line.
                return toCmdElems(CmdElemType(Str(self.as!string)), binding, useShell);
            case "File", "Directory":
                assert("path" in self);
                // Add `prefix` and the value of `File.path` (or `Directory.path`) to the command line.
                auto path = useShell ? Str(EscapedString(self["path"].as!string))
                                     : Str(self["path"].as!string);
                return toCmdElems(CmdElemType(path), binding, useShell);
            }
        },
        (RecordType rtype) {
            // Add `prefix` only, and recursively add object fields for which `inputBinding` is specified.
            import std.algorithm : map;
            import std.array : byPair, join;

            auto cmdElems = rtype
                .fields
                .byPair
                .map!(pair =>
                    collectParams(pair.key, self[pair.key], *pair.value[0], pair.value[1], inputs, runtime, evaluator)
                )
                .join
                .processParameters(inputs, runtime, evaluator, useShell);
            return toCmdElems(CmdElemType(cmdElems), binding, useShell);
        },
        (EnumType etype) {
            return toCmdElems(toCmdElems(CmdElemType(Str(self.as!string)),
                                         etype.inputBinding.orElse(new CommandLineBinding),
                                         useShell),
                              binding,
                              useShell);
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
                return CmdElemType((Str[]).init);
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
                        return applyRules(clb, tpl[1], *tpl[0], inputs, runtime, evaluator, useShell).match!(
                            (Str s) => [s],
                            ss => ss,
                        );
                    })
                    .join;
                return toCmdElems(CmdElemType(strs), binding, useShell);
            }
        },
    );
}
