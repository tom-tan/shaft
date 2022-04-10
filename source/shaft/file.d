/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.file;

import cwl.v1_0.schema : Directory, File;

import dyaml : Node, NodeType;

import salad.type : Either, None;

import std.digest : isDigest;
import std.file : exists;

/**
 * A subset of File that represents canonicalized internal File representation.
 * It can be:
 * - a file literal, or
 * - a File object that has only `location` with an absolute URI, `basename`,
 *   `secondaryFiles` (optional) and `format`.
 *
 * Note: It is introduced for documentation rather than type-based validation.
 */
alias URIFile = File;

/**
 * A subset of File that represents already staged local file.
 * It is a File object that provides all the fields (except optional fields) and
 * `path` and `location` have the same local path.
 *
 * Note: It is introduced for documentation rather than type-based validation.
 */
alias StagedFile = File;



/**
 * Params:
 *   file = is a File object. It can be any valid File object
 *   baseURI = is a URI to resolve a relative URI to an absolute URI
 */
URIFile toURIFile(File file, string baseURI)
{
    import salad.resolver : absoluteURI;
    import salad.type : match, None, Optional, tryMatch;
    import std.algorithm : map;
    import std.array : array;
    import std.path : baseName, dirName, extension, stripExtension;

    alias OStr = Optional!string;

    auto ret = new File;
    ret.location_ = match!(
        (None _1, None _2) => OStr.init,
        (None _, string loc) => OStr(loc.absoluteURI(baseURI)),
        (string path, None _) => OStr(path.absoluteURI(baseURI)), // TODO
        (string path, string loc) => OStr(loc.absoluteURI(baseURI)),
    )(file.path_, file.location_);

    ret.basename_ = file.basename_.match!(
        (string name) => OStr(name),
        _ => ret.location_.match!((string s) => OStr(s.baseName), none => OStr.init),
    );

    // ret.dirname_ = file.dirname_.match!(
    //     (string name) => name,
    //     _ => ret.location_.tryMatch!((string s) => s.dirName),
    // );
    // ret.nameroot_ = file.nameroot_.match!(
    //     (string root) => root,
    //     _ => ret.basename_.tryMatch!((string s) => s.stripExtension),
    // );
    // ret.nameext_ = file.nameext_.match!(
    //     (string ext) => ext,
    //     _ => ret.basename_.tryMatch!((string s) => s.extension),
    // );

    // ret.checksum_ = file.checksum_; // TODO
    // ret.size_ = file.size_; // TODO

    ret.secondaryFiles_ = file.secondaryFiles_.match!(
        (Either!(File, Directory)[] ff) => typeof(ret.secondaryFiles_)(ff.map!(f => f.match!(
            (File f) => Either!(File, Directory)(f.toURIFile(baseURI)),
            (Directory dir) => Either!(File, Directory)(dir.toURIDirectory(baseURI)),
        )).array),
        _ => typeof(ret.secondaryFiles_).init,
    );
    
    ret.format_ = file.format_;
    ret.contents_ = file.contents_;

    return ret;
}

/// TODO
Directory toURIDirectory(Directory dir, string baseURI)
{
    return dir;
}

/**
 * Params:
 *   path = is a path to the staged file to complete `path`, `location`, `basename`,
 *          `dirname`, `nameroot`, and `namext`
 *   node = represnts URIFile to complete `format` (TODO: complete extension fields)
 *   seccondaryFils = Files and Directories for stageed `secondaryFiles`
 */
StagedFile toStagedFile(string path, Node node, Either!(StagedFile, Directory)[] secondaryFiles = [])
in(path.exists)
in(node.type == NodeType.mapping)
in(node["class"] == "File")
{
    import std.conv : to;
    import std.digest.sha : SHA1;
    import std.file : getSize;
    import std.path : baseName, dirName, extension, stripExtension;
    import std.range : empty;

    auto ret = new File;

    ret.location_ = path;
    ret.path_ = path;
    ret.basename_ = path.baseName;
    ret.dirname_ = path.dirName;
    ret.nameroot_ = path.stripExtension;
    ret.nameext_ = path.extension;

    ret.checksum_ = path.digestFile!SHA1;
    ret.size_ = path.getSize.to!long;

    alias SFType = typeof(ret.secondaryFiles_);
    ret.secondaryFiles_ = secondaryFiles.empty ? SFType.init : SFType(secondaryFiles);

    if (auto f = "format" in node)
    {
        ret.format_ = f.as!string;
    }

    // ret.contents_ = "";

    return ret;
}

auto digestFile(Hash)(string filename)
if (isDigest!Hash)
{
    import std.digest : digest, LetterCase, toHexString;
    import std.stdio : StdFile = File;

    auto file = StdFile(filename);
    return digest!Hash(file.byChunk(4096 * 1024)).toHexString!(LetterCase.lower);
}

/**
 * Throws: Exception if some fields are not valid
 */
void enforceValid(File file) pure @safe
{
    import salad.type : match, None, tryMatch;
    import std.ascii : isHexDigit;
    import std.algorithm : all, canFind, each, endsWith, startsWith;
    import std.exception : enforce;

    match!(
        (None _1, None _2) => file.contents_.match!(
            (string s) => enforce(s.length <= 64*2^^10, "too large `contents` field"),
            none => enforce(false),
        ),
        (None _, string loc) => enforce(file.contents_.tryMatch!((None _) => true),
                                        "`location` and `contents` fields are exclusive"),
        (string path, None _) => enforce(file.contents_.tryMatch!((None _) => true),
                                         "`path` and `contents` fields are exclusive"),
        (string path, string loc) => enforce(loc.endsWith(path),
                                             "`path` and `location` have inconsistent values"), // TODO
    )(file.path_, file.location_);

    file.basename_.match!(
        (string s) => enforce(!s.canFind("/"), "basename must not include `/`"),
        _ => true,
    );

    // file.checksum_.match!(
    //     (string checksum) => enforce(checksum.startsWith("sha1$") && checksum[5..$].all!isHexDigit,
    //                                  "Invalid checksum: "~checksum),
    //     _ => true,
    // );

    // file.size_.match!(
    //     (long s) => enforce(s >= 0, "file size must be zero or positive"),
    //     _ => true,
    // );

    file.secondaryFiles_.match!(
        (Either!(File, Directory)[] files) => files.each!(
            ff => ff.match!(
                (File f) => f.enforceValid,
                (Directory d) => d.enforceValid,
            )
        ),
        _ => true,
    );
    // TODO: how to deal with dirname, nameroot, nameext, and format
}

/**
 * Throws: Exception if some fields are not valid
 */
void enforceValid(Directory dir) pure @safe
{
}
