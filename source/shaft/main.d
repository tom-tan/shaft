/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.main;

import dyaml : Node;

///
auto toURI(string pathOrURI) pure @safe
{
    import salad.resolver : scheme;
    import std.range : empty;

    if (pathOrURI.scheme.empty)
    {
        import std.algorithm : startsWith;

        if (pathOrURI.startsWith("/"))
        {
            return "file://"~pathOrURI;
        }
        else
        {
            import std.path : absolutePath;
            return "file://"~pathOrURI.absolutePath;
        }
    }
    else
    {
        return pathOrURI;
    }
}

/// See_Also: https://github.com/common-workflow-language/common-workflow-language/issues/915
int shaftMain(string[] args)
{
    import dyaml : Loader, Node;

    import std.file : getcwd;
    import std.exception : enforce;
    import std.format : format;
    import std.getopt : getopt;
	import std.range : empty;

    import cwl : CommandInputParameter, CommandLineTool, DocumentRootType, importFromURI, SchemaDefRequirement;
    import salad.exception : DocumentException;
    import salad.fetcher : Fetcher;
    import salad.type : MatchException, tryMatch;
    import salad.util : dig, edig;

	string tmpdir;
	string outdir = getcwd;
	bool b;
	bool verbose;
	bool showversion;
	bool computeChecksum = true;
	auto opts = args.getopt(
		"tmpdir", "directory for temporary files", &tmpdir,
		"outdir", "directory for output objects", &outdir,
		"leave-tmpdir", "always leave temporary directory", &b,
		"leave-tmpdir-on-errors", "leave temporary directory on errors (default)", &b,
		"remove-tmpdir", "always remove temporary directory", &b,
		"quiet", "only print warnings and errors", &verbose,
		"verbose", "verbose output", &verbose,
		"veryverbose", "more verbose output", &verbose,
		"compute-checksum", "compute checksum of contents (default)", () { computeChecksum = true; },
		"no-compute-checksum", "do not compute checksum of contents", () { computeChecksum = false; },
		"version", "show version information", &showversion,
	);

	if (opts.helpWanted || args.empty || args.length > 3)
	{
		import std.getopt : defaultGetoptPrinter;
        import std.path : baseName;
        import std.string : outdent;

		immutable baseMessage = format!(q"EOS
			Shaft: A workflow engine for CommandLineTool in local machine
			Usage: %s [options] cwl [jobfile]
EOS".outdent[0..$-1])(args[0].baseName);
		defaultGetoptPrinter(baseMessage, opts.options);
		return 0;
	}

    Fetcher.instance.removeSchemeFetcher("http");
    Fetcher.instance.removeSchemeFetcher("https");

    // See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Generic_execution_process
    // 1. Load input object.
    auto loader = args.length == 3 ? Loader.fromFile(args[2])
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
        return 251;
    }
    catch(MatchException e)
    {
        // TODO: msg
        return 33;
    }

    // 3. If there are multiple process objects (due to $graph) and which process object to start with is not specified in the input object (via a cwl:tool entry)
    // or by any other means (like a URL fragment) then choose the process with the id of "#main" or "main".
    // -> done by `importFromURI``

    // store current version of CWL for parameter references
    auto cwlVersion = cmd.cwlVersion_.tryMatch!((string s) => s);
    enforce(cwlVersion == "v1.0");
    // TODO: upgrade document to the latest version

    // 4. Validate the input object against the inputs schema for the process.
    import shaft.type : annotateInputParameters;

    //
    auto typedParams = annotateInputParameters(inp, cmd.dig!("inputs", CommandInputParameter[]),
                                               cmd.dig!(["requirements", "SchemaDefRequirement"],
                                                        SchemaDefRequirement));

    // 5. Validate process requirements are met.
    // DockeRequirement, SoftwareRequirement, ResourcceRequirement can be hints
    // others -> should be requirements

    import cwl.v1_0.schema : InlineJavascriptRequirement;
    import shaft.evaluator : Evaluator;

    auto evaluator = Evaluator(
        cmd.dig!(["requirements", "InlineJavascriptRequirement"], InlineJavascriptRequirement),
        cwlVersion
    );

    import cwl.v1_0.schema : ResourceRequirement;
    import shaft.runtime : Runtime;

    auto runtime = Runtime(typedParams.parameters, outdir, tmpdir,
                           cmd.dig!(["requirements", "ResourceRequirements"], ResourceRequirement),
                           cmd.dig!(["hints", "ResourceRequirements"], ResourceRequirement),
                           evaluator);

    // 6. Perform any further setup required by the specific process type.
    // 7. Execute the process.
    import shaft.command_line_tool : execute;

    auto ret = execute(cmd, typedParams, runtime, evaluator);


    // 8. Capture results of process execution into the output object.

    // 9. Validate the output object against the outputs schema for the process.

    // 10. Report the output object to the process caller.


    // 

    // get runtime
    // proess InitWorkDiRequirement
    // eval env
	// path mapping (hook)
    // construct args
    // process ShellCommandRequirement
    // container command prefix (hook)
    // spawnProcess
    // wait
    // return result
    return 0;
}


/// See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Discovering_CWL_documents_on_a_local_filesystem
auto discoverDocumentURI(string path) @safe
{
    import std.algorithm : canFind;

    // absolute URI
    if (path.canFind("://"))
    {
        return path;
    }

    // relative path
    import salad.resolver : fragment;
    import std.algorithm : find, map, splitter;
    import std.exception : enforce;
    import std.file : exists, isFile;
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
    auto pathWithoutFrag = path[0..$-frag.length+1];
    // TODO: check `absolutePath(".")` is appropriate
    auto fs = chain(["."], dirs, [data_home]).map!(d => pathWithoutFrag.absolutePath(d))
                                             .find!(p => p.exists && p.isFile);
    enforce(!fs.empty);
    return fs.front.toURI~(frag.empty ? "" : "#"~frag);
}
