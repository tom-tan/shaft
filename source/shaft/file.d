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
 * A subset of File object for canonicalized internal File representation.
 * It can be:
 * - a file literal, or
 * - a File object that has only `location` to show an absolute URI, `basename`,
 *   `secondaryFiles` (optional) and `format`.
 */
alias URIFile = File;

/**
 * A subset of File object for already staged local file.
 * It is a File object that provides all the fields (except optional fields) and
 * `path` and `location` have the same local path.
 */
alias StagedFile = File;

/**
 * Params:
 *   path = is a path to the staged file to complete `path`, `location`, `basename`,
            `dirname`, `nameroot`, and `namext`
 *   node = represnts URIFile to complete `format` and extension fields
 *   seccondaryFils = Files and Directories for stageed `secondaryFiles`
 */
auto toStagedFile(string path, Node node, Either!(File, Directory)[] secondaryFiles = [])
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
