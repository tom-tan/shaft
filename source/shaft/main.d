/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.main;

import std.logger : LogLevel, stdThreadLocalLog;

version(unittest)
{
    static this()
    {
        stdThreadLocalLog.logLevel = LogLevel.off;
    }
}

///
static immutable suppertedVersions = ["v1.0"];

///
enum LeaveTmpdir
{
    always,
    onErrors,
    never,
}

/// Entry point of shaft
int shaftMain(string[] args)
{
    import dyaml : Loader, Mark, Node, NodeType, MarkedYAMLException, YAMLException;

    import cwl.v1_0 : CWLVersion, CommandLineTool, DocumentRootType, ExpressionTool,
                      importFromURI, SchemaDefRequirement, Workflow;
    import salad.exception : DocumentException;
    import salad.fetcher : Fetcher;
    import salad.type : tryMatch;
    import salad.util : dig, edig;

    import shaft.exception;
    import shaft.requirement;

    import std;

    try
    {
        import std.logger : sharedLog;
        import shaft.logger : JSONLogger;

    	string baseTmpdir;
    	string outdir = getcwd;
	    LeaveTmpdir ltopt = LeaveTmpdir.onErrors;
	    bool computeChecksum = true;
        Flag!"overwrite" forceOverwrite = No.overwrite;
        string[] compatOptions;

    	bool showVersion;
        bool showSupportedVersions;
        bool showLicense;

        sharedLog = cast(shared)(new JSONLogger(stderr, LogLevel.all));
        (cast()sharedLog).logLevel = LogLevel.all;
        stdThreadLocalLog.logLevel = LogLevel.info;

	    auto opts = args.getopt(
    		"base-tmpdir", "directory for temporary files", (string _, string dir) { baseTmpdir = dir.absolutePath; },
	    	"outdir", "directory for output objects", (string _, string dir) { outdir = dir.absolutePath; },
    		"leave-tmpdir", "always leave temporary directory", () { ltopt = LeaveTmpdir.always; },
	    	"leave-tmpdir-on-errors", "leave temporary directory on errors (default)", () { ltopt = LeaveTmpdir.onErrors; },
    		"remove-tmpdir", "always remove temporary directory", () { ltopt = LeaveTmpdir.never; },
	    	"quiet", "only print warnings and errors", () { stdThreadLocalLog.logLevel = LogLevel.warning; },
    		"verbose", "verbose output (default)", () { stdThreadLocalLog.logLevel = LogLevel.info; },
	    	"veryverbose", "more verbose output", () { stdThreadLocalLog.logLevel = LogLevel.trace; },
    		"compute-checksum", "compute checksum of contents (default)", () { computeChecksum = true; },
	    	"no-compute-checksum", "do not compute checksum of contents", () { computeChecksum = false; },
            "force-overwrite", "overwrite existing files and directories with output object",
            () { forceOverwrite = Yes.overwrite; },
            "enable-compat", "enable compatibility options (`--enable-compat=help` for details)", &compatOptions,
    		"show-supported-versions", "show supported CWL specs", &showSupportedVersions,
            "license", "show license information", &showLicense,
		    "version", "show version information", &showVersion,
    	).ifThrown!GetOptException(e => throw new SystemException(e.msg));

        if (!compatOptions.empty)
        {
            enum compats = [ // @suppress(dscanner.performance.enum_array_literal)
                Option("", "extended-props", "Enable `null` and `length` in parameter references (for v1.0 and v1.1)",
                    false),
                Option("", "help", "show this message", false),
            ];

            if (compatOptions.canFind("help"))
            {
                defaultGetoptFormatter(
                    stdout.lockingTextWriter, "List of compatibility options:",
                    compats, "    %-*s %-*s%*s%s\x0a",
                );
                return 0;
            }
            
            auto rng = compatOptions.find!(o => compats.all!(co => co.optLong != o));
            enforce!SystemException(rng.empty, format!"Unrecognized compatibility options: %-(%s, %)"(rng.array));
        }

        if (showVersion)
        {
            write(import("version"));
            return 0;
        }
        else if (showSupportedVersions)
        {
            writefln("%-(%s\n%)", suppertedVersions);
            return 0;
        }
        else if (showLicense)
        {
            import shaft.license : licenseString;
            write(licenseString);
            return 0;
        }
        else if (opts.helpWanted || args.length <= 1 || args.length > 3)
        {
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

        stdThreadLocalLog.info(() {
            import std : chomp, getcwd, thisProcessID;
            return JSONValue([
                "message": JSONValue("Start executor"),
                "executor": JSONValue(["name": "shaft", "version": import("version").chomp]),
                "args": JSONValue(args),
                "pwd": JSONValue(getcwd),
                "pid": JSONValue(thisProcessID)
            ]);
        }());
        scope(success)
        {
            stdThreadLocalLog.info(JSONValue(["message": "Finish executor", "result": "success"]));
        }
        scope(failure)
        {
            stdThreadLocalLog.info(JSONValue(["message": "Finish executor", "result": "failure"]));
        }

        stdThreadLocalLog.trace("Setup fetcher");

        Fetcher.instance.removeSchemeFetcher("http");
        Fetcher.instance.removeSchemeFetcher("https");

        stdThreadLocalLog.trace("Setup temporary directories");
        if (baseTmpdir.empty)
        {
            baseTmpdir = buildPath(tempDir, "shaft-"~randomUUID().toString()).absolutePath;
        }
        else
        {
            baseTmpdir = baseTmpdir;
        }

        enforce!SystemException(!baseTmpdir.exists, format!"%s already exists"(baseTmpdir));

        // fetched inputs for remote files and literals
        auto rstagedir = buildPath(baseTmpdir, "stagein");
        mkdirRecurse(rstagedir);
        // designated output directory
        auto routdir = buildPath(baseTmpdir, "output");
        mkdirRecurse(routdir);
        // designated temporary directory
        auto rtmpdir = buildPath(baseTmpdir, "tmp");
        mkdirRecurse(rtmpdir);
        // directory to store non-captured stdout and stderr
        auto rlogdir = buildPath(baseTmpdir, "log");
        mkdirRecurse(rlogdir);
        scope(success)
        {
            if (ltopt != LeaveTmpdir.always)
            {
                stdThreadLocalLog.trace("On success: Remove temporary directories");
                rmdirRecurse(baseTmpdir);    
            }
            else
            {
                stdThreadLocalLog.trace("On success: Leave temporary directories as is");
            }
        }
        scope(failure)
        {
            if (ltopt == LeaveTmpdir.never)
            {
                stdThreadLocalLog.trace("On failure: Remove temporary directories");
                rmdirRecurse(baseTmpdir);
            }
            else
            {
                stdThreadLocalLog.trace("On failure: Leave temporary directories as is");
            }
        }

        // See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Generic_execution_process
        // 1. Load input object.
        auto loader = args.length == 3 ? Loader.fromFile(args[2].absolutePath)
                                               .ifThrown!YAMLException(e => throw new SystemException(
                                                    "Input parameter file not found: "~args[2].absolutePath
                                                ))
                                       : Loader.fromString("{}");
        auto inp = loader.load
            .ifThrown!MarkedYAMLException(e => throw new InputCannotBeLoaded(e.msg.chomp, e.mark));
        enforce(inp.type == NodeType.mapping,
                new InputCannotBeLoaded("Input should be a mapping but it is not", inp.startMark));

        stdThreadLocalLog.info((){
            import shaft.type.common : toJSONString;
            auto j = Node([
                "message": Node("Input object is loaded"),
                "input": inp
            ]);
            if (args.length == 3)
            {
                j["path"] = args[2].absolutePath;
            }
            return j.toJSONString;
        }());

        if (auto reqs = "cwl:requirements" in inp)
        {
            enforce(
                reqs.type == NodeType.sequence,
                new InputCannotBeLoaded("`cwl:requirements` must be an array of process requirements", reqs.startMark)
            );
            foreach(r; reqs.sequence)
            {
                auto name = "class" in r;
                enforce(
                    name !is null,
                    new InputCannotBeLoaded(
                        "`cwl:requirements` has process requirement without `class` field",
                        reqs.startMark
                    )
                );
                enforce!FeatureUnsupported(
                    SupportedRequirementsForCLT.canFind(*name),
                    format!"`%s` specified in `cwl:requirements` is not supported"(*name)
                );
            }
        }
        if (auto reqs = "shaft:inherited-requirements" in inp)
        {
            enforce(
                reqs.type == NodeType.sequence,
                new InputCannotBeLoaded(
                    "`shaft:inherited-requirements` must be an array of process requirements",
                    reqs.startMark
                )
            );
            foreach(r; reqs.sequence)
            {
                auto name = "class" in r;
                enforce(
                    name !is null,
                    new InputCannotBeLoaded(
                        "`shaft:inherited-requirements` has process requirement without `class` field",
                        reqs.startMark
                    )
                );
                enforce!FeatureUnsupported(
                    SupportedRequirementsForCLT.canFind(*name),
                    format!"`%s` specified in `shaft:inherited-requirements` is not supported"(*name)
                );
            }
        }
        stdThreadLocalLog.trace("Success verifying input object");

        // TODO: handle `cwl:tool` (input object must start with shebang and marked as executable)
        // - load as YAMl
        //   - check shebang and executable
        //   - check cwl:tool
        //     - yes -> input object
        //     - no

        // 2. Load, process and validate a CWL document, yielding one or more process objects. The $namespaces present in the CWL document are also used when validating and processing the input object.
        import std.string : chomp;

        auto path = args[1];
        auto cwlfile = discoverDocumentURI(path);
        auto process = importFromURI(cwlfile, "main").tryMatch!(
            (DocumentRootType doc) => doc.tryMatch!(
                (CommandLineTool _) => doc,
                (ExpressionTool _) => doc,
                other => throw new FeatureUnsupported(format!"Document class `%s` is not supported"(other.class_)),
            ),
        )
        .ifThrown!DocumentException(e => throw new InvalidDocument(e.msg, e.mark))
        .ifThrown!MarkedYAMLException(e => throw new InputCannotBeLoaded(e.msg.chomp, e.mark));

        stdThreadLocalLog.info((){
            import salad.resolver : path_ = path;
            import shaft.type.common : toJSONNode;

            auto n = process.tryMatch!(
                (CommandLineTool c) => Node(c),
                (ExpressionTool e) => Node(e),
            );

            return Node([
                "message": Node("Success loading CWL document"),
                "document": n,
                "path": Node(cwlfile.path_)
            ]).toJSONNode;
        }());

        // 3. If there are multiple process objects (due to $graph) and which process object to start with is not specified in the input object (via a cwl:tool entry)
        // or by any other means (like a URL fragment) then choose the process with the id of "#main" or "main".
        // -> done by `importFromURI`

        // store current version of CWL for parameter references
        auto cwlVersion = process.edig!("cwlVersion", CWLVersion).value;
        enforce!FeatureUnsupported(cwlVersion == "v1.0", format!"CWL %s is not supported yet"(cwlVersion));
        // TODO: upgrade document to the latest version

        import cwl.v1_0 : InlineJavascriptRequirement;
        import shaft.evaluator : Evaluator;

        stdThreadLocalLog.trace("Set up evaluator");
        auto evaluator = Evaluator(
            process.getRequirement!InlineJavascriptRequirement(inp),
            cwlVersion, compatOptions.canFind("extended-props"),
        );
        stdThreadLocalLog.trace("Success setting up evaluator");

        // 4. Validate the input object against the inputs schema for the process.
        import shaft.type.input : annotateInputParameters;

        // TODO: pass evaluator (CommandInputRecordField may have an Expression)
        auto typedParams = process.tryMatch!(
            c => annotateInputParameters(
                    inp, c.inputs_,
                    c.getRequirement!SchemaDefRequirement(inp),
                    c.context
                )
        );
        stdThreadLocalLog.trace("Success annotating input object");

        import shaft.staging : fetch;
        stdThreadLocalLog.trace("Set up remote files and file literals");
        auto fetched = typedParams.fetch(rstagedir);
        stdThreadLocalLog.trace("Success setting up remote files and file literals");

        // 5. Validate process requirements are met.
        // DockerRequirement, SoftwareRequirement, ResourceRequirement can be hints
        // others -> should be requirements (warning if exists in reqs)
        import cwl.v1_0 : DockerRequirement, SoftwareRequirement, InitialWorkDirRequirement,
                                 ResourceRequirement;

        alias UnsupportedRequirements = AliasSeq!(
            DockerRequirement,
            SoftwareRequirement,
            InitialWorkDirRequirement,
        );
        static foreach(req; UnsupportedRequirements)
        {
            enforce!FeatureUnsupported(
                process.dig!(["requirements", req.stringof], req) is null,
                format!"%s is not supported"(req.stringof),
            );
        }

        import cwl.v1_0 : ResourceRequirement;
        import shaft.runtime : Runtime;

        stdThreadLocalLog.trace("Set up runtime information");
        auto runtime = Runtime(
            fetched.parameters, routdir, rtmpdir,
            process.getRequirement!ResourceRequirement(inp),
            evaluator
        );

        process.match!(
            (CommandLineTool c) {
                stdThreadLocalLog.trace("Set up extra runtime information");
                runtime.setupInternalInfo(c, fetched.parameters, rlogdir, evaluator);
                stdThreadLocalLog.trace("Succuss setting up runtime information");
            },
            (others) {}
        );

        // 6. Perform any further setup required by the specific process type.
        // 7. Execute the process.
        stdThreadLocalLog.trace("Execute Process");
        auto ret = process.tryMatch!(
            (CommandLineTool cmd) {
                import shaft.command_line_tool : execute;
                return execute(cmd, fetched, runtime, evaluator);
            },
            (ExpressionTool exp) {
                import shaft.expression_tool : execute;
                return execute(exp, fetched, runtime, evaluator);
            },
        );
        stdThreadLocalLog.trace("Success executing Process");

        // runtime.exitCode = ret; // v1.1 and later

        // 8. Capture results of process execution into the output object.
        // 9. Validate the output object against the outputs schema for the process.
        import shaft.type.output : captureOutputs;
        stdThreadLocalLog.trace("Capture output object");
        auto outs = process.tryMatch!(
            c => captureOutputs(
                c.outputs_, fetched.parameters,
                runtime, evaluator, c.context
            )
        );
        stdThreadLocalLog.trace("Success capturing output object");

        import shaft.staging : stageOut;
        stdThreadLocalLog.trace("Stage out output object");
        mkdirRecurse(outdir);
        auto staged = stageOut(outs, outdir, forceOverwrite);

        // 10. Report the output object to the process caller.
        import shaft.type.common : toJSONString;
        stdout.writeln(staged.parameters.toJSONString);

        return 0;
    }
    catch(TypeException e)
    {
        stdThreadLocalLog.error(JSONValue(["message": "Uncaught TypeException", "detail": e.msg]));
        return 1;
    }
    catch(ShaftException e)
    {
        stdThreadLocalLog.error(e.msg);
        return e.code;
    }
}


/// See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Discovering_CWL_documents_on_a_local_filesystem
auto discoverDocumentURI(string path) @safe
{
    import salad.resolver : isAbsoluteURI;
    import shaft.exception : SystemException;

    import std.exception : enforce;
    import std.file : exists, getcwd, isFile;

    if (path.isAbsoluteURI)
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
    enforce!SystemException(!fs.empty, "CWL document not found: "~path);
    return fs.front.absoluteURI~(frag.empty ? "" : "#"~frag);
}
