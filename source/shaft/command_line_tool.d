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
import shaft.type : DeterminedType, TypedParameters;

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

    // TODO: consider the following cases:
    // - params.parameters refer `stdin` with `type: stdin`
    // - `stdin` field refers inut parameter
    auto stdin = clt.stdin_.match!(
        (string exp) => File(evaluator.eval!string(exp, params.parameters, runtime)),
        none => File("/dev/null"),
    );

    auto stdout = clt.stdout_.match!(
        (string exp) {
            import dyaml : NodeType;
            auto path = evaluator.eval(exp, params.parameters, runtime);
            enforce(path.type == NodeType.string);
            // TODO:  If ..., or the resulting path contains illegal characters (such as the path separator /) it is an error.
            return File(buildPath(runtime.outdir, path.as!string), "w");
        },
        none => File(buildPath(runtime.logdir, "stdout.txt"), "w"),
    );

    auto stderr = clt.stderr_.match!(
        (string exp) {
            import dyaml : NodeType;
            auto path = evaluator.eval(exp, params.parameters, runtime);
            enforce(path.type == NodeType.string);
            // TODO:  If ..., or the resulting path contains illegal characters (such as the path separator /) it is an error.
            return File(buildPath(runtime.outdir, path.as!string), "w");
        },
        none => File(buildPath(runtime.logdir, "stderr.txt"), "w"),
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
    if (auto e = clt.dig!(["requirements", "EnvVarRequirement"])(EnvVarRequirement.init))
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

    import shaft.type : guessedType;

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
    auto collectedParams = args~inp;
    collectedParams.multiSort!(
        "a.key[0] < b.key[0]",
        (a, b) => match!(
            (size_t lhs, string rhs) => true,
            (string lhs, size_t rhs) => false,
            (lhs, rhs) => lhs < rhs,
        )(a.key[1], b.key[1]),
    );

    // 5. In the sorted order, apply the rules defined in `CommandLineBinding` to convert bindings to actual command line elements.
    // 6. Insert elements from `baseCommand` at the beginning of the command line.
    // TODO: pass ShellCommandRequirement?
    auto cmdElems = collectedParams.map!(p => applyRules(p.tupleof[1..$])).join;
    
    auto base = cmd.baseCommand_.match!(
        (string s) => [s],
        (string[] ss) => ss,
        _ => (string[]).init,
    );

    return base~cmdElems;
}

//
unittest
{
    import dyaml : Loader, Node;

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
        ["inp1": DeterminedType(new CWLType(Node("int")))],
    );

    auto clt = Loader.fromString(cwlDoc).load.as!CommandLineTool;

    auto evaluator = Evaluator(null, "v1.0");

    auto args = buildCommandLine(
        clt,
        params,
        Runtime(params.parameters, "outDir", "tmpDir", "logDir", null, null, evaluator),
        evaluator
    );

    assert(args == ["echo", "10"]);
}

/**
 * See_Also: https://www.commonwl.org/v1.1/CommandLineTool.html#CommandLineBinding
 */
string[] applyRules(CommandLineBinding binding, Node self, DeterminedType type)
{
    import salad.type : match;
    import shaft.type : ArrayType, EnumType, RecordType;
    import std.exception : enforce;

    alias toCmdElems = (string[] val, CommandLineBinding clb) {
        import std.array : join;

        if (clb is null)
        {
            return (string[]).init;
        }

        auto sep = clb.separate_.orElse(true);
        // TODO: handle ShellCommandRequirement?
        return clb.prefix_.match!(
            // TODO: how to join an array of elems for arrays?
            (string pr) => sep ? pr~val : [pr~val.join],
            none => val,
        );
    };

    return type.match!(
        (CWLType t) {
            final switch(t.value_)
            {
            case "null":
                // Add nothing.
                return (string[]).init;
            case "boolean":
                // If true, add `prefix` to the command line. If false, add nothing.
                if (self.as!bool)
                {
                    if (binding is null)
                    {
                        return (string[]).init;
                    }
                    return binding.prefix_.match!(
                        (string pre) => [pre],
                        none => (string[]).init,
                    );
                }
                else
                {
                    return (string[]).init;
                }
            case "int", "long", "float", "double", "string":
                // Add `prefix` and the string (or decimal representation for numbers) to command line.
                return toCmdElems([self.as!string], binding);
            case "File", "Directory":
                assert("path" in self);
                // Add `prefix` and the value of `File.path` (or `Directory.path`) to the command line.
                return toCmdElems([self["path"].as!string], binding);
            }
        },
        (RecordType rtype) {
            // Add `prefix` only, and recursively add object fields for which `inputBinding` is specified.
            enforce(false, "Record type is not supported yet");
            return (string[]).init;
        },
        (EnumType etype) {
            return toCmdElems(toCmdElems([self.as!string], etype.inputBinding.orElse(CommandLineBinding.init)),
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
                return (string[]).init;
            }
            else
            {
                import salad.type : orElse;
                import std.algorithm : map;
                import std.array : join;
                import std.range : zip;

                auto strs = zip(atype.types, self.sequence)
                                .map!((tpl) {
                                    auto clb = atype.inputBinding.match!(
                                        (CommandLineBinding clb) => clb,
                                        none => new CommandLineBinding
                                    );
                                    return applyRules(clb, tpl[1], *tpl[0]);
                                })
                                .join;

                return binding.itemSeparator_.match!(
                    // If `itemSeparator` is specified, add `prefix` and the join the array into a single string with `itemSeparator` separating the items.
                    (string isep) => toCmdElems([strs.join(isep)], binding),
                    // Otherwise first add `prefix`, then recursively process individual elements.
                    none => toCmdElems(strs, binding),
                );
            }
        },
    );
}

/**
 * See_Also: https://www.commonwl.org/v1.0/CommandLineTool.html#Output_binding
 */
auto captureOutputs(CommandLineTool clt, Runtime runtime, Evaluator evaluator)
{
    import dyaml : Loader, NodeType;
    import shaft.type : toJSONNode;
    import std.algorithm : each, filter, map;
    import std.array : array, assocArray;
    import std.file : exists;
    import std.path : buildPath;

    auto outJSON = runtime.outdir.buildPath("cwl.output.json");
    Node ret;
    if (outJSON.exists)
    {
        ret = Loader.fromFile(outJSON).load;
        clt.outputs_.each!((o) {
            import shaft.type : bindType, DeclaredType;
            auto id = o.id_;
            if (auto n = id in ret)
            {
                //bindType(*n, o.type_, (DeclaredType[string]).init);
            }
            else
            {
                import dyaml : YAMLNull;
                auto null_ = Node(YAMLNull());
                //bindType(null_, o.type_, (DeclaredType[string]).init);
            }
        });
    }
    else
    {
        clt.outputs_
           .map!((o) {
               import salad.type : match, None, orElse;
               import std.typecons : tuple;

               auto binding = o.outputBinding_.match!(
                   (CommandOutputBinding cob) => cob,
                   none => CommandOutputBinding.init,
               );
               auto secondaryFiles = o.secondaryFiles_.match!(
                   (string[] ss) => ss,
                   (string s) => [s],
                   none => (string[]).init,
               );
               auto streamable = o.streamable_.orElse(false);
               auto n = collectOutputParameter(
                   binding, DeterminedType.init, runtime, evaluator, streamable, o.format_, secondaryFiles);
               return tuple(o.id_.toJSONNode, n);
           })
           .filter!(n => n[1].type != NodeType.null_)
           .each!((k, v) => ret.add(k, v));
    }
    return ret;
}

import salad.type : None, Optional;

//
auto collectOutputParameter(CommandOutputBinding binding, DeterminedType type, Runtime runtime, Evaluator evaluator,
                            bool streamable = false, Optional!string format = None.init, string[] secondaryFiles = [])
{
    import shaft.type : toJSONNode;
    import std.typecons : tuple;/+

    auto n = cop.type_.match!(
        (None _) => Node.init, // TODO
        (CWLType t) {
            final switch(t.value_)
            {
            case "null":
                enforce(n.type == NodeType.null_, new TypeConflicts("TODO: guess type", type, n.guessedType));
                return TypedValue(n, t);
            case "boolean":
                enforce(n.type == NodeType.boolean, new TypeConflicts("TODO: guess type", type, n.guessedType));
                return TypedValue(n, t);
            case "int", "long":
                enforce(n.type == NodeType.integer, new TypeConflicts("TODO: guess type", type, n.guessedType));
                return TypedValue(n, t);
            case "float", "double":
                enforce(n.type == NodeType.decimal, new TypeConflicts("TODO: guess type", type, n.guessedType));
                return TypedValue(n, t);
            case "File":
                enforce(n.type == NodeType.mapping, new TypeConflicts("TODO: guess type", type, n.guessedType));
                n.enforceValidFile;
                return TypedValue(n, t);
            case "Directory":
                enforce(n.type == NodeType.mapping, new TypeConflicts("TODO: guess type", type, n.guessedType));
                n.enforceValidDirectory;
                return TypedValue(n, t);
            }
        },
        (stdout o) {
            //
        },
        (stderr e) {
            //
        },
        (CommandOutputRecordSchema s) {},
        (CommandOutputEnumSchema s) {},
        (CommandOutputArraySchema s) {},
        (string s) => Node.init, // TODO
        (Either!(
            CWLType,
            CommandOutputRecordSchema,
            CommandOutputEnumSchema,
            CommandOutputArraySchema,
            string
        )[] union_) {},
    );
    auto type = cop.type_.match!(
        (None _) => "Any",
        (string s) => "",
        others => "",
    );+/


    return Node.init;
}

//
auto validateOutputParameter(Node node, CommandOutputParameter cop)
{
    //
}