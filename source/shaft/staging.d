/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.staging;

import cwl.v1_0.schema : Directory, File;

import dyaml : Node, NodeType;

import salad.resolver : scheme;
import shaft.type.common : TypedParameters, TypedValue;

import std.file : exists, isDir;
import std.path : baseName, buildPath, isAbsolute;
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
    auto ret = Node((Node[string]).init);
    foreach(string k, Node v; params.parameters)
    {

        auto p = stagingParam(
            TypedValue(v, params.types[k]), destURI, keepStructure,
            forceStaging, overwrite,
        );
        ret.add(k, p);
    }
    return TypedParameters(ret, params.types);
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
            auto randomDir(string baseDir)
            {
                import std.file : mkdirRecurse;
                import std.path : buildPath;
                import std.uuid : randomUUID;

                auto base = buildPath(baseDir, randomUUID.toString);
                mkdirRecurse(base);
                return base;
            }

            switch(t.value) {
            case "File": {
                import shaft.file : toStagedFile;
                import std.path : buildPath;

                auto node = tv.value;
                assert("class" in node);
                assert(node["class"] == "File");

                // TODO: validate format?
                // TODO: contents (need `loadContents`)

                auto shouldBeStaged_ = node.shouldBeStaged;

                string stagedPath;
                Flag!"forceStaging" forceStaging_ = forceStaging;
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

                    auto dir = (keepStructure || !shouldBeStaged_) ? dest : randomDir(dest);
                    stagedPath = buildPath(dir, bname);
                    stagedPath.write(con.as!string);
                    forceStaging_ |= Yes.forceStaging;
                }
                else
                {
                    import salad.resolver : path;
                    import std.path : baseName;

                    auto bname = node["basename"].as!string;
                    auto loc = node["location"].as!string.path;
                    if (loc.baseName != bname || shouldBeStaged_ || forceStaging)
                    {
                        import std.exception : enforce;
                        import std.file : copy, exists;
                        import std.format : format;

                        auto dir = (keepStructure || !shouldBeStaged_) ? dest : randomDir(dest);
                        stagedPath = buildPath(dir, bname);
                        // TODO: it may happen with duplicated secondaryFile entries
                        // it must be detected before staging to throw InvalidDocument
                        enforce(overwrite || !stagedPath.exists,
                            format!"File already exists: %s"(stagedPath));
                        loc.copy(stagedPath);
                        forceStaging_ |= Yes.forceStaging;
                    }
                    else
                    {
                        stagedPath = loc;
                        forceStaging_ |= No.forceStaging;
                    }
                }

                Node sec;
                if (auto sec_ = "secondaryFiles" in node)
                {
                    import std.algorithm : map;
                    import std.array : array;

                    sec = Node(
                        sec_.sequence.map!((e) {
                            import shaft.type.common : DeterminedType;
                            import std.path : dirName;

                            assert("class" in e);
                            switch(e["class"].as!string)
                            {
                            case "File":
                                return stagingParam(
                                    TypedValue(e, DeterminedType(new CWLType("File"))),
                                    stagedPath.dirName, Yes.keepStructure, forceStaging_, No.overwrite,
                                );
                            case "Directory":
                                return stagingParam(
                                    TypedValue(e, DeterminedType(new CWLType("Directory"))),
                                    stagedPath.dirName, Yes.keepStructure, forceStaging_, No.overwrite,
                                );
                            default: assert(false);
                            }
                        }).array
                    );
                }
                else
                {
                    import dyaml : YAMLNull;
                    sec = Node(YAMLNull());
                }
                return Node(stagedPath.toStagedFile(node, sec));
            }
            case "Directory": {
                import shaft.file : toStagedDirectory;
                import std.path : buildPath;

                auto node = tv.value;
                assert("class" in node);
                assert(node["class"] == "Directory");

                auto shouldBeStaged_ = node.shouldBeStaged;

                string stagedPath;
                if (auto location = "location" in node)
                {
                    import salad.resolver : path;
                    import std.path : baseName;

                    auto bname = node["basename"].as!string;
                    auto loc = location.as!string.path;
                    if (loc.baseName != bname || shouldBeStaged_ || forceStaging)
                    {
                        import std.exception : enforce;
                        import std.file : exists, mkdir;
                        import std.format : format;

                        auto dir = (keepStructure || !shouldBeStaged_) ? dest : randomDir(dest);

                        stagedPath = buildPath(dir, bname);
                        // TODO: it may happen with duplicated secondaryFile entries
                        // they must be merged when duplicated entries are directories
                        enforce(overwrite || !stagedPath.exists,
                            format!"Dirctory already exists: %s"(stagedPath));
                    }
                    else
                    {
                        stagedPath = loc;
                    }
                }
                else
                {
                    // directory literal
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
                    auto dir = (keepStructure || !shouldBeStaged_) ? dest : randomDir(dest);
                    stagedPath = buildPath(dir, bname);
                }

                Node listing;
                if (shouldBeStaged_)
                {
                    import dyaml : YAMLNull;
                    import std.file : mkdir;
                    if (auto lst_ = "listing" in node)
                    {
                        import shaft.type.common : DeterminedType;
                        import std.algorithm : map;
                        import std.array : array;
                        import std.path : dirName;
                        import std.range : empty;

                        mkdir(stagedPath);
                        auto lst = lst_
                            .sequence
                            .map!(l => stagingParam(TypedValue(l, DeterminedType(new CWLType(l["class"]))),
                                                    stagedPath, Yes.keepStructure, forceStaging, No.overwrite))
                            .array;
                        // set listing if LoadListingReq
                        listing = lst.empty ? Node(YAMLNull()) : Node(lst);
                    }
                    else if (auto loc = "location" in node)
                    {
                        import salad.resolver : path;
                        import shaft.file : collectListing;

                        auto src = loc.as!string;
                        cpdirRecurse(src.path, stagedPath);
                        // collectListing if LoadListing
                        listing = collectListing(stagedPath);
                    }
                    else
                    {
                        import dyaml : YAMLNull;
                        listing = Node(YAMLNull());
                    }
                }
                else
                {
                    import salad.resolver : path;
                    import shaft.file : collectListing;

                    assert(stagedPath.isDir);
                    assert("location" in node);
                    auto src = node["location"].as!string;
                    if (src.path != stagedPath)
                    {
                        cpdirRecurse(src.path, stagedPath);
                    }
                    // collectListing if LoadListing
                    listing = collectListing(stagedPath);
                }
                return Node(stagedPath.toStagedDirectory(node, listing));
            }
            default:
                return tv.value;
            }
        },
        (EnumType _) => tv.value,
        (ArrayType at) {
            import dyaml : NodeType;
            import std.algorithm : map;
            import std.range : array, StoppingPolicy, zip;

            auto node = tv.value;
            assert(node.type == NodeType.sequence);

            auto staged = zip(StoppingPolicy.requireSameLength, at.types, node.sequence).map!((tpl) {
                return stagingParam(TypedValue(tpl[1], *tpl[0]), dest, keepStructure);
            }).array;
            return Node(staged);
        },
        (RecordType rt) {
            import dyaml : NodeType;
            import std.algorithm : map;
            import std.array : assocArray, byPair;
            import std.typecons : tuple;

            auto node = tv.value;
            assert(node.type == NodeType.mapping);

            auto types = rt.fields.byPair.map!((tpl) {
                return tuple(tpl.key, *tpl.value[0]);
            }).assocArray;

            auto staged = staging(
                TypedParameters(node, types), dest,
                keepStructure, forceStaging, overwrite,
            );

            return staged.parameters;
        },
    );
}

///
bool shouldBeStaged(Node node)
in("class" in node)
{
    switch(node["class"].as!string)
    {
    case "File": return node.as!File.shouldBeStaged;
    case "Directory": return node.as!Directory.shouldBeStaged;
    default: assert(false);
    }
}

///
bool shouldBeStaged(File file)
{
    import salad.resolver : path;
    import salad.type : match, orElse;
    import salad.util : edig;
    import std.algorithm : any;
    import std.path : baseName;

    return
        // file literal
        file.contents_.match!((string _) => true, none => false) ||
        // remote resource
        file.edig!("location", string).scheme != "file" ||
        // must be renamed
        file.edig!("location", string).path.baseName != file.edig!("basename", string) ||
        // any secondaryFiles must be staged
        file.secondaryFiles_.orElse([]).any!(sec => sec.match!(f => f.shouldBeStaged));
}

///
bool shouldBeStaged(Directory dir)
{
    import salad.resolver : path, scheme;
    import salad.type : match, orElse;
    import salad.util : edig;
    import std.algorithm : any;
    import std.path : baseName;

    return
        // directory literal
        dir.location_.match!((string _) => false, none => true) ||
        // remote resource
        dir.edig!("location", string).scheme != "file" ||
        // must be renamed
        dir.edig!("location", string).path.baseName != dir.edig!("basename", string) ||
        // any listing must be staged
        dir.listing_.orElse([]).any!(lst => lst.match!(f => f.shouldBeStaged));
}

/**
 * Copy `src` directory to `dst` recursively.
 * It makes `dst/src.baseName`.
 *
 * TODO: how to do with symlinks?
 */
void cpdirRecurse(string src, string dst)
in(src.isAbsolute, src)
in(dst.isAbsolute && !dst.exists, dst)
{
    import std.file : dirEntries, mkdirRecurse, SpanMode;

    mkdirRecurse(dst);
    foreach(string name; dirEntries(src, SpanMode.depth, false))
    {
        import std.file : isDir, isFile;
        import std.path : buildPath, dirName, relativePath;

        auto rel = name.relativePath(src);
        if (name.isFile)
        {
            import std.file : copy;
            auto file = buildPath(dst, rel);
            mkdirRecurse(file.dirName);
            copy(name, file);
        }
        else if (name.isDir)
        {
            auto dir = buildPath(dst, rel);
            mkdirRecurse(dir);
        }
        else
        {
            assert(false);
        }
    }
}
