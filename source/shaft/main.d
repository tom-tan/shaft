/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.main;

import std.experimental.logger : LogLevel, sharedLog;

version(unittest)
{
    static this()
    {
        sharedLog.logLevel = LogLevel.off;
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

    import cwl : CWLVersion, CommandLineTool, DocumentRootType, ExpressionTool,
                 importFromURI, SchemaDefRequirement;
    import salad.exception : DocumentException;
    import salad.fetcher : Fetcher;
    import salad.type : tryMatch;
    import salad.util : dig, edig;

    import shaft.exception;

    import std;

    try
    {
    	string baseTmpdir;
    	string outdir = getcwd;
	    LeaveTmpdir ltopt = LeaveTmpdir.onErrors;
	    bool computeChecksum = true;
        Flag!"overwrite" forceOverwrite = No.overwrite;
        string[] compatOptions;

    	bool showVersion;
        bool showSupportedVersions;

        sharedLog.logLevel = LogLevel.info;

	    auto opts = args.getopt(
    		"base-tmpdir", "directory for temporary files", (string _, string dir) { baseTmpdir = dir.absolutePath; },
	    	"outdir", "directory for output objects", (string _, string dir) { outdir = dir.absolutePath; },
    		"leave-tmpdir", "always leave temporary directory", () { ltopt = LeaveTmpdir.always; },
	    	"leave-tmpdir-on-errors", "leave temporary directory on errors (default)", () { ltopt = LeaveTmpdir.onErrors; },
    		"remove-tmpdir", "always remove temporary directory", () { ltopt = LeaveTmpdir.never; },
	    	"quiet", "only print warnings and errors", () { sharedLog.logLevel = LogLevel.warning; },
    		"verbose", "verbose output (default)", () { sharedLog.logLevel = LogLevel.info; },
	    	"veryverbose", "more verbose output", () { sharedLog.logLevel = LogLevel.trace; },
    		"compute-checksum", "compute checksum of contents (default)", () { computeChecksum = true; },
	    	"no-compute-checksum", "do not compute checksum of contents", () { computeChecksum = false; },
            "force-overwrite", "overwrite existing files and directories with output object",
            () { forceOverwrite = Yes.overwrite; },
            "enable-compat", "enable compatibility options (`--enable-compat=help` for details)", &compatOptions,
    		"print-supported-versions", "print supported CWL specs", &showSupportedVersions,
		    "version", "show version information", &showVersion,
    	).ifThrown!GetOptException((e) {
            enforce!SystemException(false, e.msg);
            return GetoptResult.init;
        });

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

        sharedLog.trace("Setup fetcher");

        Fetcher.instance.removeSchemeFetcher("http");
        Fetcher.instance.removeSchemeFetcher("https");

        sharedLog.trace("Setup temporary directories");
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
        auto rtmpdir = buildPath(baseTmpdir, "temporary");
        mkdirRecurse(rtmpdir);
        // directory to store non-captured stdout and stderr
        auto rlogdir = buildPath(baseTmpdir, "log");
        mkdirRecurse(rlogdir);
        scope(success)
        {
            if (ltopt != LeaveTmpdir.always)
            {
                sharedLog.trace("On success: Remove temporary directories");
                rmdirRecurse(baseTmpdir);    
            }
            else
            {
                sharedLog.trace("On success: Leave temporary directories as is");
            }
        }
        scope(failure)
        {
            if (ltopt == LeaveTmpdir.never)
            {
                sharedLog.trace("On failure: Remove temporary directories");
                rmdirRecurse(baseTmpdir);
            }
            else
            {
                sharedLog.trace("On failure: Leave temporary directories as is");
            }
        }

        // See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Generic_execution_process
        // 1. Load input object.
        sharedLog.trace("Load input object");
        auto loader = args.length == 3 ? Loader.fromFile(args[2].absolutePath)
                                               .ifThrown!YAMLException((e) {
                                                   enforce!SystemException(
                                                       false,
                                                       "Input parameter file not found: "~args[2].absolutePath,
                                                   );
                                                   return Loader.init;
                                               })
                                       : Loader.fromString("{}");
        auto inp = loader.load
            .ifThrown!MarkedYAMLException((e) {
                enforce(false, new InputCannotBeLoaded(e.msg.chomp, e.mark));
                return Node.init;
            });
        enforce(inp.type == NodeType.mapping,
                new InputCannotBeLoaded("Input should be a mapping but it is not", inp.startMark));
        sharedLog.info("Success loading input object");

        // TODO: handle `cwl:tool` (input object must start with shebang and marked as executable)
        // - load as YAMl
        //   - check shebang and executable
        //   - check cwl:tool
        //     - yes -> input object
        //     - no
        // TODO: handle `cwl:requirements`

        // 2. Load, process and validate a CWL document, yielding one or more process objects. The $namespaces present in the CWL document are also used when validating and processing the input object.
        sharedLog.info("Load CWL document");
        auto path = args[1];
        auto cwlfile = discoverDocumentURI(path);
        CommandLineTool cmd = importFromURI(cwlfile, "main").tryMatch!(
            (DocumentRootType doc) => doc.tryMatch!(
                (CommandLineTool cmd) => cmd,
                (ExpressionTool _) {
                    enforce!NotYetImplemented(false, "Document class `ExpressionTool` is not implemented yet");
                    return null;
                },
                (other) {
                    enforce!FeatureUnsupported(false, format!"Document class `%s` is not supported"(other.class_));
                    return null;
                }
            ),
        )
        .ifThrown!DocumentException((e) {
            enforce(false, new InvalidDocument(e.msg, e.node.startMark));
            return null;
        })
        .ifThrown!MarkedYAMLException((e) {
            import std.string : chomp;
            enforce(false, new InputCannotBeLoaded(e.msg.chomp, e.mark));
            return null;
        });
        sharedLog.info("Success loading CWL document");

        // 3. If there are multiple process objects (due to $graph) and which process object to start with is not specified in the input object (via a cwl:tool entry)
        // or by any other means (like a URL fragment) then choose the process with the id of "#main" or "main".
        // -> done by `importFromURI`

        // store current version of CWL for parameter references
        auto cwlVersion = cmd.cwlVersion_.tryMatch!((CWLVersion ver) => ver.value_);
        enforce!FeatureUnsupported(cwlVersion == "v1.0", format!"CWL %s is not supported yet"(cwlVersion));
        // TODO: upgrade document to the latest version

        import cwl.v1_0.schema : InlineJavascriptRequirement;
        import shaft.evaluator : Evaluator;

        sharedLog.trace("Set up evaluator");
        auto evaluator = Evaluator(
            cmd.dig!(["requirements", "InlineJavascriptRequirement"], InlineJavascriptRequirement),
            cwlVersion, compatOptions.canFind("extended-props"),
        );
        sharedLog.trace("Success setting up evaluator");

        // 4. Validate the input object against the inputs schema for the process.
        import shaft.type.input : annotateInputParameters;

        // TODO: pass evaluator (CommandInputRecordField may have an Expression)
        sharedLog.trace("Annotate input object");
        auto typedParams = annotateInputParameters(inp, cmd.inputs_,
                                                   cmd.dig!(["requirements", "SchemaDefRequirement"],
                                                            SchemaDefRequirement),
                                                   cmd.context);
        sharedLog.trace("Success annotating input object");

        import shaft.staging : fetch;
        sharedLog.trace("Set up remote files and file literals");
        auto fetched = typedParams.fetch(rstagedir);
        sharedLog.trace("Success setting up remote files and file literals");

        // 5. Validate process requirements are met.
        // DockerRequirement, SoftwareRequirement, ResourceRequirement can be hints
        // others -> should be requirements (warning if exists in reqs)
        import cwl.v1_0.schema : DockerRequirement, SoftwareRequirement, InitialWorkDirRequirement,
                                 ResourceRequirement;

        alias UnsupportedRequirements = AliasSeq!(
            DockerRequirement,
            SoftwareRequirement,
            InitialWorkDirRequirement,
        );
        static foreach(req; UnsupportedRequirements)
        {
            enforce!FeatureUnsupported(
                cmd.dig!(["requirements", req.stringof], req) is null,
                format!"%s is not supported"(req.stringof),
            );
        }

        import cwl.v1_0.schema : ResourceRequirement;
        import shaft.runtime : Runtime;

        sharedLog.trace("Set up runtime information");
        auto runtime = Runtime(fetched.parameters, routdir, rtmpdir,
                               cmd.dig!(["requirements", "ResourceRequirement"], ResourceRequirement),
                               cmd.dig!(["hints", "ResourceRequirement"], ResourceRequirement),
                               evaluator);

        sharedLog.trace("Set up extra runtime information");
        runtime.setupInternalInfo(cmd, fetched.parameters, rlogdir, evaluator);
        sharedLog.trace("Succuss setting up runtime information");

        // 6. Perform any further setup required by the specific process type.
        // 7. Execute the process.
        import shaft.command_line_tool : execute;

        sharedLog.info("Execute CommandLineTool");
        auto ret = execute(cmd, fetched, runtime, evaluator);
        sharedLog.info("Success executing CommandLineTool");

        // runtime.exitCode = ret; // v1.1 and later

        // 8. Capture results of process execution into the output object.
        // 9. Validate the output object against the outputs schema for the process.
        import shaft.type.output : captureOutputs;
        sharedLog.trace("Capture output object");
        auto outs = captureOutputs(cmd, fetched.parameters, runtime, evaluator);
        sharedLog.trace("Success capturing output objct");

        import shaft.staging : stageOut;
        sharedLog.trace("Stage out output object");
        mkdirRecurse(outdir);
        auto staged = stageOut(outs, outdir, forceOverwrite);

        // 10. Report the output object to the process caller.
        import shaft.type.common : toJSON;
        stdout.writeln(staged.parameters.toJSON);

        return 0;
    }
    catch(TypeException e)
    {
        sharedLog.error("Uncaught TypeException: "~e.msg);
        return 1;
    }
    catch(ShaftException e)
    {
        sharedLog.error(e.msg);
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
