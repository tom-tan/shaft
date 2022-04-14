/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.main;

import dyaml : Node;

///
static immutable suppertedVersions = ["v1.0"];

///
enum LeaveTmpdir
{
    always,
    onErrors,
    never,
}

/// See_Also: https://github.com/common-workflow-language/common-workflow-language/issues/915
int shaftMain(string[] args)
{
    import dyaml : Loader, Node;

    import std.file : getcwd;
    import std.exception : enforce;
    import std.format : format;
    import std.getopt : getopt, GetOptException;
	import std.range : empty;
    import std.typecons : Flag, No, Yes;

    import cwl : CommandInputParameter, CommandLineTool, DocumentRootType, importFromURI, SchemaDefRequirement;
    import salad.exception : DocumentException;
    import salad.fetcher : Fetcher;
    import salad.type : MatchException, tryMatch;
    import salad.util : dig, edig;

	string baseTmpdir;
	string outdir = getcwd;
	LeaveTmpdir ltopt = LeaveTmpdir.onErrors;
	bool verbose;
	bool computeChecksum = true;
    Flag!"overwrite" forceOverwrite = No.overwrite;

    try
    {
    	bool showVersion;
        bool showSupportedVersions;

	    auto opts = args.getopt(
    		"base-tmpdir", "directory for temporary files", &baseTmpdir,
	    	"outdir", "directory for output objects", &outdir,
    		"leave-tmpdir", "always leave temporary directory", () { ltopt = LeaveTmpdir.always; },
	    	"leave-tmpdir-on-errors", "leave temporary directory on errors (default)", () { ltopt = LeaveTmpdir.onErrors; },
    		"remove-tmpdir", "always remove temporary directory", () { ltopt = LeaveTmpdir.never; },
	    	"quiet", "only print warnings and errors", &verbose,
    		"verbose", "verbose output", &verbose,
	    	"veryverbose", "more verbose output", &verbose,
    		"compute-checksum", "compute checksum of contents (default)", () { computeChecksum = true; },
	    	"no-compute-checksum", "do not compute checksum of contents", () { computeChecksum = false; },
            "force-overwrite", "overwrite existing files and directories with output object",
            () { forceOverwrite = Yes.overwrite; },
    		"print-supported-versions", "print supported CWL specs", &showSupportedVersions,
		    "version", "show version information", &showVersion,
    	);

        if (showVersion)
        {
            import std.stdio : write;
            write(import("version"));
            return 0;
        }
        else if (showSupportedVersions)
        {
            import std.stdio : writefln;
            writefln("%-(%s\n%)", suppertedVersions);
            return 0;
        }
        else if (opts.helpWanted || args.length <= 1 || args.length > 3)
        {
            import std.getopt : defaultGetoptFormatter;
            import std.path : baseName;
            import std.string : outdent;
            import std.stdio : stdout;

            immutable baseMessage = format!(q"EOS
                Shaft: A workflow engine for CommandLineTool in local machine
                Usage: %s [options] cwl [jobfile]
EOS".outdent[0 .. $ - 1])(args[0].baseName);

            defaultGetoptFormatter(
                stdout.lockingTextWriter, baseMessage,
                opts.options, "%-*s %-*s%*s%s\x0a",
            );
            return 0;
        }
    }
    catch(GetOptException e)
    {
        import std.stdio : writeln;

        writeln(e.msg);
        return 1;
    }

    Fetcher.instance.removeSchemeFetcher("http");
    Fetcher.instance.removeSchemeFetcher("https");

    import std.path : buildPath;
    import std.path : absolutePath;
    if (baseTmpdir.empty)
    {
        import std.file : tempDir;
        import std.uuid : randomUUID;
        baseTmpdir = buildPath(tempDir, "shaft-"~randomUUID().toString()).absolutePath;
    }
    else
    {
        baseTmpdir = baseTmpdir.absolutePath;
    }
    import std.file : exists;
    import std.file : mkdirRecurse;

    enforce(!baseTmpdir.exists, format!"%s already exists"(baseTmpdir));

    auto rstagedir = buildPath(baseTmpdir, "stagein");
    mkdirRecurse(rstagedir);
    auto routdir = buildPath(baseTmpdir, "output");
    mkdirRecurse(routdir);
    auto rtmpdir = buildPath(baseTmpdir, "temporary");
    mkdirRecurse(rtmpdir);
    auto rlogdir = buildPath(baseTmpdir, "log");
    mkdirRecurse(rlogdir);
    scope(success)
    {
        if (ltopt != LeaveTmpdir.always)
        {
            import std.file : rmdirRecurse;
            rmdirRecurse(baseTmpdir);    
        }
    }
    scope(failure)
    {
        if (ltopt == LeaveTmpdir.never)
        {
            import std.file : rmdirRecurse;
            rmdirRecurse(baseTmpdir);
        }
    }

    // See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Generic_execution_process
    // 1. Load input object.
    auto loader = args.length == 3 ? Loader.fromFile(args[2].absolutePath)
                                   : Loader.fromString("{}");
    auto inp = loader.load;
    import dyaml : NodeType;
    enforce(inp.type == NodeType.mapping, "Input should be a mapping but it is not");

    // TODO: handle `cwl:tool` (input object must start with shebang and marked as executable)
    // - load as YAMl
    //   - check shebang and executable
    //   - check cwl:tool
    //     - yes -> input object
    //     - no
    // TODO: handle `cwl:requirements`

    // 2. Load, process and validate a CWL document, yielding one or more process objects. The $namespaces present in the CWL document are also used when validating and processing the input object.
    auto path = args[1];
    auto cwlfile = discoverDocumentURI(path);
    CommandLineTool cmd;
    try
    {
        // TODO: ExpressionTool
        cmd = importFromURI(cwlfile, "main").tryMatch!(
            (DocumentRootType doc) => doc.tryMatch!((CommandLineTool com) => com)
        );
    }
    catch(DocumentException e)
    {
        import std;
        stderr.writeln(e.msg);
        return 251;
    }
    catch(MatchException e)
    {
        // TODO: msg
        return 33;
    }

    // 3. If there are multiple process objects (due to $graph) and which process object to start with is not specified in the input object (via a cwl:tool entry)
    // or by any other means (like a URL fragment) then choose the process with the id of "#main" or "main".
    // -> done by `importFromURI`

    // store current version of CWL for parameter references
    import cwl : CWLVersion;
    auto cwlVersion = cmd.cwlVersion_.tryMatch!((CWLVersion ver) => ver.value_);
    enforce(cwlVersion == "v1.0");
    // TODO: upgrade document to the latest version

    import cwl.v1_0.schema : InlineJavascriptRequirement;
    import shaft.evaluator : Evaluator;

    auto evaluator = Evaluator(
        cmd.dig!(["requirements", "InlineJavascriptRequirement"], InlineJavascriptRequirement),
        cwlVersion
    );

    // 4. Validate the input object against the inputs schema for the process.
    import shaft.type.input : annotateInputParameters;

    // TODO: pass evaluator (CommandInputRecordField may have an Expression)
    auto typedParams = annotateInputParameters(inp, cmd.inputs_,
                                               cmd.dig!(["requirements", "SchemaDefRequirement"],
                                                        SchemaDefRequirement));

    import shaft.staging : fetch;
    auto fetched = typedParams.fetch(rstagedir);

    // 5. Validate process requirements are met.
    // DockerRequirement, SoftwareRequirement, ResourceRequirement can be hints
    // others -> should be requirements (warning if exists in reqs)
    import std.meta : AliasSeq;
    import cwl.v1_0.schema : DockerRequirement, SoftwareRequirement, InitialWorkDirRequirement,
                             ShellCommandRequirement, ResourceRequirement;

    alias UnsupportedRequirements = AliasSeq!(
        InlineJavascriptRequirement,
        DockerRequirement,
        SoftwareRequirement,
        InitialWorkDirRequirement,
        ShellCommandRequirement,
        ResourceRequirement,
    );
    static foreach(req; UnsupportedRequirements)
    {
        if (cmd.dig!(["requirements", req.stringof], req))
        {
            import std.stdio : stderr;
            stderr.writeln(req.stringof, " is not supported yet");
            return 33;
        }
    }

    import cwl.v1_0.schema : ResourceRequirement;
    import shaft.runtime : Runtime;

    auto runtime = Runtime(fetched.parameters, routdir, rtmpdir, rlogdir,
                           cmd.dig!(["requirements", "ResourceRequirement"], ResourceRequirement),
                           cmd.dig!(["hints", "ResourceRequirement"], ResourceRequirement),
                           evaluator);

    // 6. Perform any further setup required by the specific process type.
    // 7. Execute the process.
    import shaft.command_line_tool : execute;

    auto ret = execute(cmd, fetched, runtime, evaluator);

    // runtime.exitCode = ret; // v1.1 and later

    // 8. Capture results of process execution into the output object.
    import shaft.type.output : captureOutputs;
    auto outs = captureOutputs(cmd, fetched.parameters, runtime, evaluator);

    import shaft.staging : stageOut;
    mkdirRecurse(outdir);
    auto staged = stageOut(outs, outdir, forceOverwrite);

    // 9. Validate the output object against the outputs schema for the process.

    // 10. Report the output object to the process caller.
    import shaft.type.common : dumpJSON;
    import std.stdio : stdout;
    dumpJSON(staged.parameters, stdout.lockingTextWriter);

    return 0;
}


/// See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Discovering_CWL_documents_on_a_local_filesystem
auto discoverDocumentURI(string path) @safe
{
    import std.algorithm : canFind, startsWith;
    import std.exception : enforce;
    import std.file : exists, getcwd, isFile;

    // absolute URI
    if (path.canFind("://"))
    {
        return path;
    }

    // relative path
    import salad.resolver : absoluteURI, fragment, withoutFragment;
    import std.algorithm : find, map, splitter;
    import std.path : absolutePath, buildPath;
    import std.process : environment;
    import std.range : chain, empty;

    auto xdg_data_dirs = environment.get("XDG_DATA_DIRS", "");
    if (xdg_data_dirs.empty)
    {
        xdg_data_dirs = "/usr/local/share/:/usr/share/";
    }
    auto dirs = xdg_data_dirs.splitter(":")
                             .map!(p => p.buildPath("commonwl"));

    auto data_home = environment.get("XDG_DATA_HOME",
                                     buildPath(environment["HOME"], ".local/share"))
                                .buildPath("commonwl");

    auto frag = path.fragment;
    auto pathWithoutFrag = path.withoutFragment;
    auto fs = chain([getcwd], dirs, [data_home]).map!(d => pathWithoutFrag.absolutePath(d))
                                             .find!(p => p.exists && p.isFile);
    enforce(!fs.empty);
    return fs.front.absoluteURI~(frag.empty ? "" : "#"~frag);
}
