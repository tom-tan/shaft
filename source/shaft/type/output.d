/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.type.output;

import dyaml : Node;

import cwl.v1_0.schema;
import salad.context : LoadingContext;
import salad.type : Either, None, Optional, This;

import shaft.evaluator : Evaluator;
import shaft.exception : CaptureFailed, NotYetImplemented;
import shaft.type.common : DeterminedType, guessedType, TypedParameters, TypeException, TypedValue;
import shaft.type.common : TC_ = TypeConflicts;
import shaft.runtime : Runtime;

import std.experimental.logger : sharedLog;

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

string toStr(DeclaredType dt) pure @safe
{
    import salad.type : match, orElse;

    import std.algorithm : map;
    import std.array : array;
    import std.format : format;
    import std.meta : AliasSeq;

    alias funs = AliasSeq!(
        (CWLType t) => cast(string)t.value_,
        (CommandOutputRecordSchema s) => 
            s.name_.orElse(format!"Record(%-(%s, %))"(s.fields_
                                                      .orElse([])
                                                      .map!(f => f.name_~": "~toStr(f.type_)).array)),
        (CommandOutputEnumSchema s) => "enum",
        (CommandOutputArraySchema s) => "array",
        (string s) => s,
    );

    return dt.match!(
        funs,
        (Either!(
            CWLType,
            CommandOutputRecordSchema,
            CommandOutputEnumSchema,
            CommandOutputArraySchema,
            string
        )[] un) => format!"(%-(%s|%))"(un.map!(e => e.match!funs).array),
    );
}

alias TypeConflicts = TC_!(DeclaredType, toStr);

/**
 * See_Also: https://www.commonwl.org/v1.0/CommandLineTool.html#Output_binding
 * Note: have to consider SchemaDefRequirement?
 */
TypedParameters captureOutputs(CommandLineTool clt, Node inputs, Runtime runtime, Evaluator evaluator)
{
    import dyaml : Loader, NodeType;
    import std.algorithm : filter, fold, map;
    import std.array : array;
    import std.range : tee;
    import std.exception : enforce;
    import std.file : exists;
    import std.format : format;
    import std.path : buildPath;
    import std.typecons : Tuple;

    import shaft.type.common : toJSON;

    auto outJSON = runtime.outdir.buildPath("cwl.output.json");
    Tuple!(Node, DeterminedType[string]) ret;
    if (outJSON.exists)
    {
        import std.container.rbtree : redBlackTree;

        auto loaded = Loader.fromFile(outJSON).load;
        enforce!CaptureFailed(loaded.type == NodeType.mapping);

        auto rest = redBlackTree(loaded.mappingKeys.map!(a => a.as!string));

        ret = clt
            .outputs_
            .map!((o) {
                import salad.type : tryMatch;
                import std.typecons : tuple;

                auto id = o.id_;
                rest.removeKey(id);
                sharedLog.trace("Capture: "~id);

                if (auto n = id in loaded)
                {
                    return tuple(
                        id,
                        collectOutputParameter(
                            Either!(Node, CommandOutputBinding)(*n),
                            o.type_.tryMatch!(t => DeclaredType(t)),
                            inputs, runtime, clt.context, evaluator
                        )
                    );
                }
                else
                {
                    import dyaml : YAMLNull;
                    return tuple(
                        id,
                        collectOutputParameter(
                            Either!(Node, CommandOutputBinding)(Node(YAMLNull())),
                            o.type_.tryMatch!(t => DeclaredType(t)),
                            inputs, runtime, clt.context, evaluator
                        )
                    );
                }
            })
            .tee!(kv => sharedLog.tracef("%s: %s", kv[0], kv[1].value.toJSON))
            .array
            .filter!(kv => kv[1].value.type != NodeType.null_)
            .fold!(
                (acc, e) { acc.add(e[0], e[1].value); return acc; },
                (acc, e) { acc[e[0]] = e[1].type; return acc; },
            )(Node((Node[string]).init), (DeterminedType[string]).init);
        enforce!CaptureFailed(rest.empty,
            format!"cwl.output.json contains undeclared output parameters: %-(%s, %)"(rest.array));
    }
    else
    {
        import salad.type : orElse;

        ret = clt
            .outputs_
            .map!((o) {
                import salad.type : match, None, tryMatch;
                import std.typecons : tuple;

                CommandOutputBinding binding;
                bool streamable = o.streamable_.orElse(false);

                auto type = o.type_.tryMatch!(
                    (None _) { // v1.0 only
                        // See_Also: https://www.commonwl.org/v1.1/CommandLineTool.html#Changelog
                        // > Fixed schema error where the `type` field inside the `inputs` and `outputs` field was incorrectly listed as optional.
                        enforce!CaptureFailed(false, format!"`type` field is missing in `%s` output parameter"(o.id_));
                        return DeclaredType("Any");
                    },
                    (stdout _) {
                        // Only valid as a `type` for a `CommandLineTool` output with no `outputBinding` set.
                        enforce!CaptureFailed(o.outputBinding_.orElse(null) is null,
                            "`outputBinding` must be null for `stdout` type");
                        binding = new CommandOutputBinding;
                        binding.glob_ = runtime.internal.stdout.tryMatch!((string path) => path);
                        streamable = true;
                        return DeclaredType(new CWLType("File"));
                    },
                    (stderr _) {
                        // Only valid as a `type` for a `CommandLineTool` output with no `outputBinding` set.
                        enforce!CaptureFailed(o.outputBinding_.orElse(null) is null,
                            "`outputBinding` must be null for `stderr` type");
                        binding = new CommandOutputBinding;
                        binding.glob_ = runtime.internal.stderr.tryMatch!((string path) => path);
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

                try
                {
                    sharedLog.trace("Capture: "~o.id_);
                    return tuple(
                        o.id_,
                        collectOutputParameter(
                            Either!(Node, CommandOutputBinding)(binding), type,
                            inputs, runtime, clt.context, evaluator, streamable, o.format_, secondaryFiles
                        )
                    );
                }
                catch(TypeConflicts e)
                {
                    throw new TypeConflicts(e.expected_, e.actual_, o.id_);
                }
            })
            .tee!(kv => sharedLog.tracef("%s: %s", kv[0], kv[1].value.toJSON))
            .array
            .filter!(kv => kv[1].value.type != NodeType.null_)
            .fold!(
                (acc, e) {
                    sharedLog.tracef("acc value: %s = %s", e[0], e[1].value.toJSON);
                    scope(success) sharedLog.tracef("acc value: %s = %s -> done", e[0], e[1].value.toJSON);
                    scope(failure) sharedLog.tracef("acc value: %s = %s -> fail", e[0], e[1].value.toJSON);
                    acc.add(e[0], e[1].value); return acc;
                                    },
                (acc, e) {
                    import shaft.type.common : toS = toStr;
                    sharedLog.tracef("acc type: %s = %s", e[0], e[1].type.toS);
                    scope(success) sharedLog.tracef("acc value: %s = %s -> done", e[0], e[1].type.toS);
                    scope(failure) sharedLog.tracef("acc value: %s = %s -> fail", e[0], e[1].type.toS);
                    acc[e[0]] = e[1].type; return acc;
                },
            )(Node((Node[string]).init), (DeterminedType[string]).init);
    }
    sharedLog.trace("done!");
    return typeof(return)(ret[0], ret[1]);
}

/**
 * Collect the results of `outputBinding` without validating its type
 *
 * Note: It assumes that the parent `outputBinding` takes precedence over children's `outputBinding`s
 */
TypedValue collectOutputParameter(Either!(Node, CommandOutputBinding) nodeOrBinding, DeclaredType type,
                            Node inputs, Runtime runtime, LoadingContext context, Evaluator evaluator,
                            bool streamable = false, Optional!string format = None(), string[] secondaryFiles = [])
{
    import dyaml : NodeType;
    import salad.type : match;
    import std.exception : enforce;

    return type.match!(
        (CWLType t) {
            auto node = nodeOrBinding.match!(
                (Node n) => n,
                (CommandOutputBinding binding) {
                    if (binding is null)
                    {
                        import dyaml : YAMLNull;
                        return Node(YAMLNull());
                    }
                    else
                    {
                        return processBinding(binding, inputs, runtime, evaluator);
                    }
                }
            );
            sharedLog.trace("type: ", cast(string)t.value_);
            final switch(t.value_)
            {
            case "null": {
                if (node.type == NodeType.null_)
                {
                    return TypedValue(node, t);
                }
                else if (node.type == NodeType.sequence)
                {
                    import dyaml : YAMLNull;
                    // hidden spec in v1.0
                    enforce(node.length == 0, new TypeConflicts(type, node.guessedType));
                    return TypedValue(Node(YAMLNull()), t);
                }
                else
                {
                    throw new TypeConflicts(type, node.guessedType);
                }
            }
            case "boolean": {
                enforce(node.type == NodeType.boolean, new TypeConflicts(type, node.guessedType));
                return TypedValue(node, t);
            }
            case "int", "long": {
                enforce(node.type == NodeType.integer, new TypeConflicts(type, node.guessedType));
                return TypedValue(node, t);
            }
            case "float", "double": {
                enforce(node.type == NodeType.decimal, new TypeConflicts(type, node.guessedType));
                return TypedValue(node, t);
            }
            case "string": {
                enforce(node.type == NodeType.string, new TypeConflicts(type, node.guessedType));
                return TypedValue(node, t);
            }
            case "File": {
                import salad.meta.impl : as_;
                import shaft.file : enforceValid, toURIFile;

                File file;
                if (node.type == NodeType.mapping)
                {
                    file = node.as_!File(context);
                }
                else if (node.type == NodeType.sequence)
                {
                    import std.array : array;
                    enforce(node.sequence.array.length == 1,
                            new TypeConflicts(type, node.guessedType));
                    node = node[0];
                    file = node.as_!File(context);
                }
                else
                {
                    throw new TypeConflicts(type, node.guessedType);
                }
                file.format_ = format.match!(
                    (string exp) => Optional!string(evaluator.eval!string(exp, inputs, runtime)),
                    none => Optional!string(none),
                );
                // TODO: secondaryFiles
                file.enforceValid;
                return TypedValue(Node(file.toURIFile), t);
            }
            case "Directory": {
                import salad.meta.impl : as_;
                import shaft.file : enforceValid, toURIDirectory;

                Directory dir;
                if (node.type == NodeType.mapping)
                {
                    dir = node.as_!Directory(context);
                }
                else if (node.type == NodeType.sequence)
                {
                    auto listingSchema = new CommandOutputArraySchema;
                    alias ItemType = Either!(
                        CWLType,
                        CommandOutputRecordSchema,
                        CommandOutputEnumSchema,
                        CommandOutputArraySchema,
                        string,
                    );
                    listingSchema.items_ = [ItemType(new CWLType("File")), ItemType(new CWLType("Directory"))];

                    auto listing = collectOutputParameter(
                        Either!(Node, CommandOutputBinding)(node), DeclaredType(listingSchema),
                        inputs, runtime, context, evaluator
                    );
                    dir = new Directory;
                    dir.listing_ = listing.value.as_!(Optional!(
                        Either!(File, Directory)[]
                    ))(context);
                }
                else
                {
                    throw new TypeConflicts(type, node.guessedType);
                }
                dir.enforceValid; // TODO: more strict validation
                return TypedValue(Node(dir.toURIDirectory), t);
            }
            }
        },
        (CommandOutputRecordSchema s) {
            import salad.type : orElse;
            import shaft.type.common : RecordType;
            import std.algorithm : fold, map;
            import std.typecons : tuple, Tuple;

            alias FieldTypes = typeof(RecordType.init[1]);

            sharedLog.trace("type: record");

            return nodeOrBinding.match!(
                (Node node) {
                    enforce(node.type == NodeType.mapping, new TypeConflicts(type, node.guessedType));

                    auto tv = s
                        .fields_
                        .orElse([])
                        .map!((f) {
                            // validate types for each fields with a given node element
                            auto fnode = *enforce(f.name_ in node);
                            auto collected = collectOutputParameter(
                                Either!(Node, CommandOutputBinding)(fnode), f.type_,
                                inputs, runtime, context, evaluator
                            );
                            return tuple(f.name_, collected.type, collected.value);
                        })
                        .fold!(
                            (acc, e) { acc.add(e[0], e[2]); return acc; },
                            (acc, e) {
                               acc[e[0]] = tuple(&e[1], Optional!CommandLineBinding.init);
                               return acc;
                            },
                        )(Node((Node[string]).init), FieldTypes.init);
                    return TypedValue(tv[0], RecordType(s.name_.orElse(""), tv[1]));
                },
                (CommandOutputBinding binding) {
                    if (binding is null)
                    {
                        auto tv = s
                            .fields_
                            .orElse([])
                            .map!((f) {
                                // collect and validate for each fields with f.outputBinding_
                                auto collected = collectOutputParameter(
                                    Either!(Node, CommandOutputBinding)(f.outputBinding_.orElse(null)), f.type_,
                                    inputs, runtime, context, evaluator
                                );
                                return tuple(f.name_, collected.type, collected.value);
                            })
                            .fold!(
                                (acc, e) { acc.add(e[0], e[2]); return acc; },
                                (acc, e) {
                                    acc[e[0]] = tuple(&e[1], Optional!CommandLineBinding.init);
                                    return acc;
                                },
                            )(Node((Node[string]).init), FieldTypes.init);
                        return TypedValue(tv[0], RecordType(s.name_.orElse(""), tv[1]));
                    }
                    else
                    {
                        return collectOutputParameter(
                            Either!(Node, CommandOutputBinding)(processBinding(binding, inputs, runtime, evaluator)),
                            type, inputs, runtime, context, evaluator
                        );
                    }
                },
            );
        },
        (CommandOutputEnumSchema s) {
            sharedLog.trace("type: enum");
            return nodeOrBinding.match!(
                (Node node) {
                    import shaft.type.common : EnumType;
                    import std.algorithm : canFind;

                    enforce(node.type == NodeType.string, new TypeConflicts(type, node.guessedType));
                    enforce(s.symbols_.canFind(node.as!string), new TypeConflicts(type, node.guessedType));
                    return TypedValue(node, EnumType("", Optional!CommandLineBinding.init));
                },
                (CommandOutputBinding binding) {
                    if (binding is null)
                    {
                        import salad.type : tryMatch;
                        binding = s.outputBinding_.tryMatch!((CommandOutputBinding b) => b);
                    }
                    return collectOutputParameter(
                        Either!(Node, CommandOutputBinding)(processBinding(binding, inputs, runtime, evaluator)),
                        type, inputs, runtime, context, evaluator
                    );
                },
            );
        },
        (CommandOutputArraySchema s) {
            sharedLog.trace("type: array");
            return nodeOrBinding.match!(
                (Node node) {
                    import shaft.type.common : ArrayType;
                    import std.algorithm : fold, map;

                    enforce(node.type == NodeType.sequence, new TypeConflicts(type, node.guessedType));
                    
                    auto tvals = node
                        .sequence
                        .map!(e => collectOutputParameter(
                            Either!(Node, CommandOutputBinding)(e), s.items_, inputs, runtime, context, evaluator)
                        )
                        .fold!(
                            (acc, e) { acc.add(e.value); return acc; },
                            (acc, e) @trusted {
                                  import std.algorithm : moveEmplace;
                                  auto dt = new DeterminedType;
                                  moveEmplace(e.type, *dt);
                                  return acc ~ dt;
                            },
                        )(Node((Node[]).init), (DeterminedType*[]).init);
                    // TODO: secondaryFiles when File[]
                    return TypedValue(tvals[0], ArrayType(tvals[1], Optional!CommandLineBinding.init));
                },
                (CommandOutputBinding binding) {
                    if (binding is null)
                    {
                        import salad.type : tryMatch;
                        binding = s.outputBinding_.tryMatch!((CommandOutputBinding b) => b);
                    }
                    return collectOutputParameter(
                        Either!(Node, CommandOutputBinding)(processBinding(binding, inputs, runtime, evaluator)),
                        type, inputs, runtime, context, evaluator
                    );
                },
            );
        },
        (string s) {
            import shaft.type.common : guessedType;
            import std.format : format;

            enforce(s == "Any", new TypeException(format!"Unknown output type: `%s`"(s)));
            sharedLog.trace("type: Any");

            auto node = nodeOrBinding.match!(
                (Node n) => n,
                (CommandOutputBinding binding) {
                    enforce!TypeException(binding !is null, "Any must not be null");
                    return processBinding(binding, inputs, runtime, evaluator);
                }
            );
            enforce(node.type != NodeType.null_, new TypeConflicts(type, node.guessedType));
            return TypedValue(node, node.guessedType);
        },
        (Either!(
            CWLType,
            CommandOutputRecordSchema,
            CommandOutputEnumSchema,
            CommandOutputArraySchema,
            string
         )[] union_) {
            sharedLog.trace("type: union");
            foreach(t; union_)
            {
                try
                {
                    return collectOutputParameter(
                        nodeOrBinding, t.match!(tt => DeclaredType(tt)),
                        inputs, runtime, context, evaluator
                    );
                }
                catch(TypeException e)
                {
                    continue;
                }
            }
            throw new TypeException("No matched type");
        },
    );
}

/**
 * It processes the `glob`, `loadContents`, and `outputEval` fields in a given `CommandOutputBinding`.
 * Returns: processed `CommandOutputBinding` object
 *
 * See_Also: https://www.commonwl.org/v1.0/CommandLineTool.html#CommandOutputBinding
 */
auto processBinding(CommandOutputBinding binding, Node inputs, Runtime runtime, Evaluator evaluator)
{
    import dyaml : YAMLNull;
    import salad.type : match;
    import std.algorithm : all, joiner, map, sort;
    import std.array : array;
    import std.path : isAbsolute;

    sharedLog.trace("process binding");

    if (binding is null)
    {
        return Node(YAMLNull());
    }

    auto paths = binding
        .glob_
        .match!(
            (string g) {
                // If an expression is provided, the expression must return a string or an array of strings, which will then be evaluated as one or more glob patterns.
                import dyaml : NodeType;
                import std.exception : enforce;

                auto ret = evaluator.eval(g, inputs, runtime);
                if (ret.type == NodeType.string)
                {
                    return [ret.as!string];
                }
                else
                {
                    enforce!CaptureFailed(ret.type == NodeType.sequence);
                    return ret.sequence.map!(a => a.as!string).array;
                }
            },
            (string[] gs) => gs,
            none => (string[]).init,
        )
        .map!((pat_) {
            //  If an array is provided, find files that match any pattern in the array.
            import std.file : dirEntries, exists, isDir, SpanMode;
            import std.path : buildNormalizedPath;

            auto built = buildNormalizedPath(runtime.outdir, pat_);

            auto isDirectory = built.exists && built.isDir;

            auto dirBase = isDirectory ? built : runtime.outdir;
            auto pat = isDirectory ? "*" : pat_;

            return dirEntries(dirBase, pat, SpanMode.shallow);
        })
        .joiner
        .array;

    // Paths must be sorted as specified by POSIX glob (3)
    // See_Also: outputbinding_glob_sorted in conformance tests
    paths.sort;
    assert(paths.all!isAbsolute);
    sharedLog.tracef("paths: %s", paths);

    auto files = paths
        .map!((path) {
            import salad.type : orElse;
            import shaft.file : toStagedFile;
            import std.file : read, isFile;

            if (path.isFile)
            {
                auto file = path.toStagedFile;
                if (binding.loadContents_.orElse(false))
                {
                    file.contents_ = cast(string)path.read(64*2^^10);
                }
                return Node(file);
            }
            else
            {
                import dyaml : YAMLNull;
                import std.exception : enforce;
                import std.file : isDir;
                assert(path.isDir);
                enforce!NotYetImplemented(false, "Glob for Directory types is not yet supported");
                return Node(YAMLNull());
            }
        })
        .array;

    return binding.outputEval_.match!(
        (None _) => binding.glob_.match!((None _) => Node(YAMLNull()), others => Node(files)),
        (string exp) => evaluator.eval(exp, inputs, runtime, Node(files)),
    );
}
