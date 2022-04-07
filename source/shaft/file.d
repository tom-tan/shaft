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

///
auto toStagedFile(Node node, string stagedPath, Either!(File, Directory)[] secondaryFiles = [])
in(stagedPath.exists)
in(node.type == NodeType.mapping)
in(node["class"] == "File")
{
    import std.conv : to;
    import std.digest.sha : SHA1;
    import std.file : getSize;
    import std.path : baseName, dirName, extension, stripExtension;
    import std.range : empty;

    auto ret = new File;

    ret.location_ = stagedPath;
    ret.path_ = stagedPath;
    ret.basename_ = stagedPath.baseName;
    ret.dirname_ = stagedPath.dirName;
    ret.nameroot_ = stagedPath.stripExtension;
    ret.nameext_ = stagedPath.extension;

    ret.checksum_ = stagedPath.digestFile!SHA1;
    ret.size_ = stagedPath.getSize.to!int; // TODO: Fix the scheme in schema-salad-d!

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
