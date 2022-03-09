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
int execute(CommandLineTool cmd, TypedParameters params, Runtime runtime, Evaluator evaluator)
{
    // 6. Perform any further setup required by the specific process type.

    version(none) // 後回し
    {
        // stage in (all process types)
        auto staged = stageIn(params, runtime,
                              cmd.dig!(["requirements", "InitialWorkDirRequirement"], InitialWorkDirRequirement),
                              evaluator);
        // path mapping
        Node mapped_inputs;
        Runtime mapped_runtime;
    }

    auto args = buildCommandLine(cmd, params, runtime, evaluator);

    version(none)
    {
        // add container args
    }

    // 7. Execute the process.

    return 0; // TODO
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
string[] buildCommandLine(CommandLineTool cmd, TypedParameters params, Runtime runtime, Evaluator evaluator)
{
    import salad.type : match, None, orElse;

    import shaft.type : guessedType;

    import std.algorithm : map;
    import std.array : array;
    import std.range : enumerate;
    import std.typecons : tuple;

    // 1. Collect `CommandLineBinding` objects from `arguments``. Assign a sorting key `[position, i]` where `position` is `CommandLineBinding.position` and `i` is the index in the `arguments` list.
    auto args = cmd.arguments_.match!(
        (None _) => (Param[]).init,
        args => args.enumerate.map!(a => 
            a.value.match!(
                (string s) {
                    auto val = evaluator.eval(s, params.parameters, runtime);
                    return Param(tuple(0, TieBreaker(a.index)), null, val, val.guessedType);
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

    // 3. Create a sorting key by taking the value of the `position` field at each level leading to each leaf binding object. If `position` is not specified, it is not added to the sorting key. For bindings on arrays and maps, the sorting key must include the array index or map key following the position. If and only if two bindings have the same sort key, the tie must be broken using the ordering of the field or parameter name immediately containing the leaf binding.

    // 4. Sort elements using the assigned sorting keys. Numeric entries sort before strings.

    // 5. In the sorted order, apply the rules defined in `CommandLineBinding` to convert bindings to actual command line elements.

    // 6. Insert elements from `baseCommand` at the beginning of the command line.

    return [];
}
