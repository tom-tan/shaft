/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.file;

import cwl.v1_0.schema : Directory, File;

import dyaml : Node, NodeType, YAMLNull;

import salad.type : Either, None;

import std.digest : isDigest;
import std.exception : assertNotThrown;
import std.file : isFile, isDir;
import std.path : isAbsolute;

/**
 * A subset of File that represents canonicalized internal File representation.
 * It can be:
 * - a file literal, or
 * - a File object that has only `location` with an absolute URI, `basename`,
 *   `secondaryFiles` (optional) and `format` (optional).
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
 * A subset of Directory that represents canonicalized internal Directory representation.
 * It can be:
 * - a directory literal, or
 * - a Directory object that has only `location` with an absolute URI, `basename`, and
 *   `listing` (optional).
 *
 * Note: It is introduced for documentation rather than type-based validation.
 */
alias URIDirectory = Directory;

/**
 * A subset of Directory that represents already staged local directory.
 * It is a Directory object that provides all the fields (except optional fields) and
 * `path` and `location` have the same local path.
 *
 * Note: It is introduced for documentation rather than type-based validation.
 */
alias StagedDirectory = Directory;

/**
 * Params:
 *   file = is a File object. It can be any valid File object
 *   baseURI = is a URI to resolve a relative URI to an absolute URI
 */
URIFile toURIFile(File file)
in
{
    file.enforceValid.assertNotThrown;
}
do
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
        (None _, string loc) => OStr(loc),
        (string path, None _) => OStr(path.absoluteURI),
        (string _, string loc) => OStr(loc),
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
            (File f) => Either!(File, Directory)(f.toURIFile),
            (Directory dir) => Either!(File, Directory)(dir.toURIDirectory),
        )).array),
        _ => typeof(ret.secondaryFiles_).init,
    );
    
    ret.format_ = file.format_;
    ret.contents_ = file.contents_;

    return ret;
}

/**
 * Params:
 *   path = is a path to the staged file to complete `path`, `location`, `basename`,
 *          `dirname`, `nameroot`, and `namext`
 *   node = represnts URIFile to complete `format` (TODO: complete extension fields)
 *   seccondaryFils = Files and Directories for stageed `secondaryFiles`
 */
StagedFile toStagedFile(string path, Node node = YAMLNull(), Node secondaryFiles = YAMLNull())
in(path.isFile)
in(path.isAbsolute)
in(node.type == NodeType.mapping || node.type == NodeType.null_)
in(node.type == NodeType.null_ || node["class"] == "File")
{
    import salad.resolver : absoluteURI;
    import std.conv : to;
    import std.digest.sha : SHA1;
    import std.file : getSize;
    import std.path : baseName, dirName, extension, stripExtension;
    import std.range : empty;

    auto ret = new File;

    ret.location_ = path.absoluteURI;
    ret.path_ = path;
    ret.basename_ = path.baseName;
    ret.dirname_ = path.dirName;
    ret.nameroot_ = path.baseName.stripExtension;
    if (auto ext = path.extension)
    {
        ret.nameext_ = path.extension;
    }
    else
    {
        // workaround for https://github.com/dlang-community/D-YAML/issues/286
        ret.nameext_ = "";
    }

    ret.checksum_ = path.digestFile!SHA1;
    ret.size_ = path.getSize.to!long;

    // alias SFType = typeof(ret.secondaryFiles_);
    // ret.secondaryFiles_ = secondaryFiles.empty ? SFType.init : SFType(secondaryFiles);

    if (node.type == NodeType.mapping)
    {
        if (auto f = "format" in node)
        {
            ret.format_ = f.as!string;
        }
    }
    return ret;
}

auto digestFile(Hash)(string filename)
if (isDigest!Hash)
{
    import std.digest : digest, LetterCase, toHexString;
    import std.format : format;
    import std.stdio : StdFile = File;

    auto file = StdFile(filename);
    return format!"sha1$%s"(digest!Hash(file.byChunk(4096 * 1024)).toHexString!(LetterCase.lower));
}

/// TODO: LoadListingRequirement (v1.1 and later)
URIDirectory toURIDirectory(Directory dir)
in
{
    dir.enforceValid.assertNotThrown;
}
do
{
    import salad.resolver : absoluteURI;
    import salad.type : match, Optional;
    import std.algorithm : map;
    import std.array : array;
    import std.path : baseName;

    alias OStr = Optional!string;

    auto ret = new Directory;
    ret.location_ = match!(
        (None _1, None _2) => OStr.init,
        (None _, string loc) => OStr(loc),
        (string path, None _) => OStr(path.absoluteURI),
        (string _, string loc) => OStr(loc),
    )(dir.path_, dir.location_);

    ret.basename_ = dir.basename_.match!(
        (string name) => OStr(name),
        _ => ret.location_.match!((string s) => OStr(s.baseName), none => OStr.init),
    );

    ret.listing_ = dir.listing_.match!(
        (Either!(File, Directory)[] ff) => typeof(ret.listing_)(ff.map!(f => f.match!(
            (File f) => Either!(File, Directory)(f.toURIFile),
            (Directory d) => Either!(File, Directory)(d.toURIDirectory),
        )).array),
        _ => typeof(ret.listing_).init,
    );
    return ret;
}

///
StagedDirectory toStagedDirectory(string path, Node node = YAMLNull(), Node listing = YAMLNull())
in(path.isDir)
in(path.isAbsolute)
in(node.type == NodeType.mapping || node.type == NodeType.null_)
in(node.type == NodeType.null_ || node["class"] == "Directory")
{
    import salad.resolver : absoluteURI;
    import std.path : baseName;
    import std.range : empty;

    auto ret = new Directory;
    ret.location_ = path.absoluteURI;
    ret.path_ = path;
    ret.basename_ = path.baseName;

    alias ListingType = typeof(ret.listing_);
    if (listing.type == NodeType.null_)
    {
        ret.listing_ = ListingType.init;
    }
    else
    {
        import salad.context : LoadingContext;
        import salad.meta.impl : as_;
        ret.listing_ = listing.as_!(typeof(ret.listing_))(LoadingContext.init);
    }

    return ret;
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
        (None _, string loc) {
            import std.format : format;
            import salad.resolver : isAbsoluteURI;

            assert(loc.isAbsoluteURI, format!"`location` (%s) must be an absolute URI"(loc));
            enforce(file.contents_.tryMatch!((None _) => true), "`location` and `contents` fields are exclusive");
            return true;
        },
        (string path, None _) {
            import salad.resolver : isAbsoluteURI;
            import std.format : format;
            import std.path : isAbsolute;

            assert(path.isAbsolute || path.isAbsoluteURI, format!"`path` (%s) must be absolute"(path));
            enforce(file.contents_.tryMatch!((None _) => true), "`path` and `contents` fields are exclusive");
            return true;
        },
        (string path, string loc) {
            import salad.resolver : isAbsoluteURI;
            import std.format : format;
            import std.path : isAbsolute;

            assert(path.isAbsolute || path.isAbsoluteURI, format!"`path` (%s) must be absolute"(path));
            assert(loc.isAbsoluteURI, format!"`location` (%s) must be an absolute URI"(loc));
            enforce(loc.endsWith(path), "`path` and `location` have inconsistent values");
            return true;
        },
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
    import salad.type : match;
    import std.algorithm : canFind, each, endsWith;
    import std.exception : enforce;

    match!(
        (None _1, None _2) => dir.listing_.match!(
            (Either!(File, Directory)[] ls) => true,
            none => enforce(false),
        ),
        (None _, string loc) {
            import salad.resolver : isAbsoluteURI;
            import std.format : format;

            assert(loc.isAbsoluteURI, format!"`location` (%s) must be an absolute URI"(loc));
            return true;
        },
        (string path, None _) {
            import salad.resolver : isAbsoluteURI;
            import std.format : format;
            import std.path : isAbsolute;

            assert(path.isAbsolute || path.isAbsoluteURI, format!"`path` (%s) must be absolute"(path));
            return true;
        },
        (string path, string loc) {
            import salad.resolver : isAbsoluteURI;
            import std.format : format;
            import std.path : isAbsolute;

            assert(path.isAbsolute || path.isAbsoluteURI, format!"`path` (%s) must be absolute"(path));
            assert(loc.isAbsoluteURI, format!"`location` (%s) must be an absolute URI"(loc));
            enforce(loc.endsWith(path), "`path` and `location` have inconsistent values");
            return true;
        },
    )(dir.path_, dir.location_);

    dir.basename_.match!(
        (string s) => enforce(!s.canFind("/"), "basename must not include `/`"),
        _ => true,
    );

    dir.listing_.match!(
        (Either!(File, Directory)[] listing) => listing.each!(
            ff => ff.match!(
                (File f) => f.enforceValid, // TODO: validate location
                (Directory d) => d.enforceValid, // TODO: validate location
            )
        ),
        _ => true
    );
}
