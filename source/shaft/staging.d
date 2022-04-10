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
import std.typecons : Flag, Yes;

/**
 * 
 */
auto staging(TypedParameters params, string destURI, Flag!"keepStructure" keepStructure)
in(params.parameters.type == NodeType.mapping)
in(destURI.scheme.empty || destURI.isDir)
{
    import shaft.type.common : toJSONNode;

    auto ret = Node((Node[string]).init);
    foreach(string k, Node v; params.parameters)
    {

        auto p = stagingParam(TypedValue(v, params.types[k]), destURI, keepStructure);
        ret.add(k.toJSONNode, p);
    }
    return TypedParameters(ret.toJSONNode, params.types);
}

///
Node stagingParam(TypedValue tv, string dest, Flag!"keepStructure" keepStructure)
in(dest.isDir)
{
    import cwl.v1_0.schema : CWLType;
    import salad.type : match;
    import shaft.type.common : ArrayType, EnumType, RecordType;

    return tv.type.match!(
        (CWLType t) {
            switch(t.value_) {
            case "File" : {
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
                    if (loc.baseName != bname)
                    {
                        import std.file : copy;

                        auto dir = mkdirIfNeeded(dest);
                        stagedPath = buildPath(dir, bname);
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

///
auto fetch(TypedParameters params, string dest)
{
    import std.typecons : No;
    return staging(params, dest, No.keepStructure);
}
