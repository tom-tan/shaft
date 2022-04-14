/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.staging;

import dyaml : Node, NodeType;

import salad.resolver : scheme;
import shaft.type.common : TypedParameters, TypedValue;

import std.file : isDir;
import std.range : empty;
import std.typecons : Flag, No, Yes;


///
auto fetch(TypedParameters params, string dest)
{
    return staging(params, dest, No.keepStructure);
}

///
auto stageOut(TypedParameters params, string dest, Flag!"overwrite" overwrite = No.overwrite)
{
    return staging(params, dest, Yes.keepStructure, Yes.forceStaging, overwrite);
}

/**
 * Params:
 *   destURI = is a destination directory path.
 *
 * TODO: `dest` will be extended to URI in the future release.
 */
auto staging(
    TypedParameters params, string destURI, Flag!"keepStructure" keepStructure,
    Flag!"forceStaging" forceStaging = No.forceStaging, Flag!"overwrite" overwrite = No.overwrite,
)
in(params.parameters.type == NodeType.mapping)
in(destURI.scheme.empty || destURI.isDir)
{
    import shaft.type.common : toJSONNode;

    auto ret = Node((Node[string]).init);
    foreach(string k, Node v; params.parameters)
    {

        auto p = stagingParam(
            TypedValue(v, params.types[k]), destURI, keepStructure,
            forceStaging, overwrite,
        );
        ret.add(k.toJSONNode, p);
    }
    return TypedParameters(ret.toJSONNode, params.types);
}

/**
 * Params:
 *   dest = is a destination directory path.
 *
 * TODO: `dest` will be extended to URI in the future release.
 */
Node stagingParam(
    TypedValue tv, string dest, Flag!"keepStructure" keepStructure,
    Flag!"forceStaging" forceStaging = No.forceStaging, Flag!"overwrite" overwrite = No.overwrite,
)
in(dest.isDir)
{
    import cwl.v1_0.schema : CWLType;
    import salad.type : match;
    import shaft.type.common : ArrayType, EnumType, RecordType;

    return tv.type.match!(
        (CWLType t) {
            switch(t.value_) {
            case "File": {
                import shaft.file : toStagedFile;
                import shaft.type.common : toJSONNode;
                import std.path : buildPath;

                auto node = tv.value;

                auto mkdirIfNeeded(string dst)
                {
                    if (keepStructure == Yes.keepStructure)
                    {
                        return dst;
                    }
                    else
                    {
                        import std.file : mkdirRecurse;
                        import std.path : buildPath;
                        import std.uuid : randomUUID;

                        auto base = buildPath(dst, randomUUID.toString);
                        mkdirRecurse(base);
                        return base;
                    }
                }

                string stagedPath;

                if (auto con = "contents" in node)
                {
                    // file literal
                    import std.file : write;

                    string bname;
                    if (auto bn_ = "basename" in node)
                    {
                        bname = bn_.as!string;
                    }
                    else
                    {
                        import std.uuid : randomUUID;
                        bname = randomUUID.toString;
                    }
                    auto dir = mkdirIfNeeded(dest);
                    stagedPath = buildPath(dir, bname);
                    stagedPath.write(con.as!string);
                }
                else
                {
                    import salad.resolver : path;
                    import std.path : baseName;

                    auto bname = node["basename"].as!string;
                    auto loc = node["location"].as!string.path;
                    if (loc.baseName != bname || forceStaging == Yes.forceStaging)
                    {
                        import std.exception : enforce;
                        import std.file : copy, exists;
                        import std.format : format;

                        auto dir = mkdirIfNeeded(dest);
                        stagedPath = buildPath(dir, bname);
                        enforce(overwrite == Yes.overwrite || !stagedPath.exists,
                            format!"File already exists: %s"(stagedPath));
                        loc.copy(stagedPath);
                    }
                    else
                    {
                        stagedPath = loc;
                    }
                }
                // TODO: secondaryFiles
                // TODO: validate format?
                // TODO: contents (need `loadContents`)
                return stagedPath.toStagedFile(node).toJSONNode;
            }
            case "Directory": {
                return tv.value; // TODO
            }
            default:
                return tv.value;
            }
        },
        (EnumType _) => tv.value,
        (ArrayType at) {
            import dyaml : NodeType;
            import shaft.type.common : toJSONNode;
            import std.algorithm : map;
            import std.range : array, StoppingPolicy, zip;

            auto node = tv.value;
            assert(node.type == NodeType.sequence);

            auto staged = zip(StoppingPolicy.requireSameLength, at.types, node.sequence).map!((tpl) {
                return stagingParam(TypedValue(tpl[1], *tpl[0]), dest, keepStructure);
            }).array;
            return staged.toJSONNode;
        },
        (RecordType rt) => tv.value, // TODO
    );
}

