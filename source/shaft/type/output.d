/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.type.output;

import dyaml : Node;

import cwl.v1_0.schema;
import salad.type : Either, None, Optional, This;

import shaft.evaluator : Evaluator;
import shaft.type.common : DeterminedType, TypedParameters, TypedValue;
import shaft.runtime : Runtime;

import std.stdio : serr = stderr;
import shaft.type.common : dumpJSON;


///
alias DeclaredType = Either!(
    CWLType,
    CommandOutputRecordSchema,
    CommandOutputEnumSchema,
    CommandOutputArraySchema,
    string,
    Either!(
        CWLType,
        CommandOutputRecordSchema,
        CommandOutputEnumSchema,
        CommandOutputArraySchema,
        string
    )[],
);

// TODO stdout and stderr -> File


/**
 * See_Also: https://www.commonwl.org/v1.0/CommandLineTool.html#Output_binding
 */
auto captureOutputs(CommandLineTool clt, Node inputs, Runtime runtime, Evaluator evaluator)
{
    import dyaml : Loader, NodeType;
    import shaft.type.common : toJSONNode;
    import std.algorithm : each, filter, map;
    import std.array : array;
    import std.exception : enforce;
    import std.file : exists;
    import std.format : format;
    import std.path : buildPath;

    auto outJSON = runtime.outdir.buildPath("cwl.output.json");
    auto ret = Node((Node[string]).init).toJSONNode;
    if (outJSON.exists)
    {
        import std.container.rbtree : redBlackTree;

        ret = Loader.fromFile(outJSON).load;
        enforce(ret.type == NodeType.mapping);

        auto rest = redBlackTree(ret.mappingKeys.map!(a => a.as!string));

        clt.outputs_.each!((o) {
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
            rest.removeKey(id);
        });
        enforce(rest.empty,
                format!"cwl.output.json contains undeclared output parameters: %-(%s, %)"(rest.array));
    }
    else
    {
        import salad.type : orElse;

        clt.outputs_
           .map!((o) {
               import salad.type : match, None, tryMatch;
               import std.typecons : tuple;

               CommandOutputBinding binding;
               auto streamable = o.streamable_.orElse(false);

               auto type = o.type_.match!(
                   (None _) {
                       // TODO: should be handled?
                       binding = o.outputBinding_.orElse(null);
                       return DeclaredType("Any");
                   },
                   (stdout _) {
                       // Only valid as a `type` for a `CommandLineTool` output with no `outputBinding` set.
                       enforce(o.outputBinding_.orElse(null) is null,
                               "`outputBinding` must be null for `stdout` type");
                       binding = new CommandOutputBinding;
                       binding.glob_ = clt.stdout_.tryMatch!((string s) => s); // TODO
                       streamable = true;
                       return DeclaredType(new CWLType("File"));
                   },
                   (stderr _) {
                       // Only valid as a `type` for a `CommandLineTool` output with no `outputBinding` set.
                       enforce(o.outputBinding_.orElse(null) is null,
                               "`outputBinding` must be null for `stderr` type");
                       binding = new CommandOutputBinding;
                       binding.glob_ = clt.stderr_.tryMatch!((string s) => s); // TODO
                       streamable = true;
                       return DeclaredType(new CWLType("File"));
                   },
                   (other) {
                       binding = o.outputBinding_.orElse(null);
                       return DeclaredType(other);
                   },
               );

               auto secondaryFiles = o.secondaryFiles_.match!(
                   (string s) => [s],
                   (string[] ss) => ss,
                   none => (string[]).init,
               );

               auto n = collectOutputParameter(
                   binding, type, inputs, runtime, evaluator, streamable, o.format_, secondaryFiles);
               return tuple(o.id_.toJSONNode, n);
           })
           .filter!(kv => kv[1].type != NodeType.null_)
           .each!(kv => ret.add(kv[0], kv[1]));
    }
    return ret;
}

//
auto collectOutputParameter(CommandOutputBinding binding, DeclaredType type, Node inputs, Runtime runtime, Evaluator evaluator,
                            bool streamable = false, Optional!string format = None(), string[] secondaryFiles = [])
in(binding !is null)
{
    import dyaml : YAMLNull;
    import salad.type : match;
    import shaft.type.common : toJSONNode;
    import std.algorithm : joiner, map;
    import std.array : array;

    auto files = binding
        .glob_
        .match!(
            (string g) {
                //  If an expression is provided, the expression must return a string or an array of strings, which will then be evaluated as one or more glob patterns.
                import dyaml : NodeType;
                import std.exception : enforce;

                auto ret = evaluator.eval(g, inputs, runtime);
                if (ret.type == NodeType.string)
                {
                    return [ret.as!string];
                }
                else
                {
                    enforce(ret.type == NodeType.sequence);
                    return ret.sequence.map!(a => a.as!string).array;
                }
            },
            (string[] gs) => gs,
            none => (string[]).init,
        )
        .map!((pat) {
            //  If an array is provided, find files that match any pattern in the array.
            import std.file : dirEntries, SpanMode;
            return dirEntries(runtime.outdir, pat, SpanMode.shallow);
        })
        .joiner
        .map!((path) {
            import salad.type : orElse;
            import shaft.file : toStagedFile;
            import std.file : read;

            auto file = path.toStagedFile;
            if (binding.loadContents_.orElse(false))
            {
                file.contents_ = cast(string)path.read(64*2^^10);
            }
            return file.toJSONNode;
        })
        .array
        .toJSONNode;
    auto evaled = binding.outputEval_.match!(
        (None _) => binding.glob_.match!((None _) => Node(YAMLNull()), others => files),
        (string exp) => evaluator.eval(exp, inputs, runtime, files),
    );
    // TODO: validate type
    // TODO: secondaryFiles
    return evaled;
}

//
auto validateOutputParameter(Node node, CommandOutputParameter cop)
{
    //
}
