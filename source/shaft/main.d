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
    import salad.fetcher : scheme;
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

int shaftMain(string[] args)
{
    import dyaml : Loader, Node;

    import std.file : getcwd;
    import std.exception : enforce;
    import std.format : format;
    import std.getopt : getopt;
	import std.range : empty;

    import cwl : CommandInputParameter, CommandLineTool, DocumentRootType, importFromURI;
    import salad.fetcher : Fetcher;
    import salad.type : tryMatch;
    import salad.util : dig;

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

    auto cwlfile = args[1].toURI;
    auto cwl = importFromURI(cwlfile).tryMatch!(
        (DocumentRootType doc) => doc.tryMatch!((CommandLineTool com) => com)
    );

    auto loader = args.length == 3 ? Loader.fromFile(args[2])
                                   : Loader.fromString("{}");
    auto param = parseInput(loader.load, cwl.dig!(["inputs"], CommandInputParameter[]));

	// hook: make a path mapping
	// eval expressions
	// generate command
	// hook: tweaks command for container runtimes
    return 0;
}

///
auto parseInput(InputParameter)(Node param, InputParameter[] paramDefs)
{
    import salad.util : dig;
    import dyaml : NodeType;
    import std.exception : enforce;
    enforce(param.type == NodeType.mapping, "Input should be a mapping but it is not");
    Node ret;
    foreach(p; paramDefs)
    {
        import cwl : Any;
        auto id = p.id_;
        Node n;
        if (auto val = id in param)
        {
            n = *val;
        }
        else if (auto def = p.dig!(["inputBinding", "default"], Any))
        {
            n = def.value_;
        }
        else
        {
            import std.format : format;
            throw new Exception(format!"missing input parameter `%s`"(id));
        }
        enforceValidParameter(n, paramDefs.type_);
        ret.add(n);
    }
    return ret;
}

///
auto enforceValidParameter(Type, DefSchemaRequirement)(Node n, Type type, DefSchemaRequirement defs)
{
    static if (isOptional!Type && Type.Types.length == 2)
    {
        type.match!(
            (None none) => true, // TODO
            others => enforceValidParameter(n, others, defs),
        );
    }
    // array<CWLType | CommandInputRecordSchema | CommandInputEnumSchema | CommandInputArraySchema | string>
    // CWLType: null, boolean, int, long, float, double, string, file, dir
    // Any
    // T[]
    // CWLType, Enum, Record, File, Directory
    // SchemaDef-ed type (not supported)
    return;
}

string toJSON(Node node) @safe
{
    import std.algorithm : map;
    import std.array : appender, array;
    import std.conv : to;
    import std.format : format;
    import dyaml : NodeType;

    switch(node.type)
    {
    case NodeType.null_: return "null";
    case NodeType.boolean: return node.as!bool.to!string;
    case NodeType.integer: return node.as!int.to!string;
    case NodeType.decimal: return node.as!real.to!string;
    case NodeType.string: return '"'~node.as!string~'"';
    case NodeType.mapping:
        return format!"{%-(%s, %)}"(node.mapping.map!((pair) {
            return format!`"%s": %s`(pair.key.as!string, pair.value.toJSON);
        }));
    case NodeType.sequence:
        return format!"[%-(%s, %)]"(node.sequence.map!toJSON.array);
    default:
        assert(false);
    }
}

@safe unittest
{
    import dyaml : Loader;

    enum yml = q"EOS
        - 1
        - 2
        - 3
EOS";
    auto arr = Loader.fromString(yml).load;
    assert(arr.toJSON == "[1, 2, 3]", arr.toJSON);
}

@safe unittest
{
    import dyaml : Loader;

    enum yml = q"EOS
        foo: 1
        bar: 2
        buzz: 3
EOS";
    auto map = Loader.fromString(yml).load;
    assert(map.toJSON == `{"foo": 1, "bar": 2, "buzz": 3}`, map.toJSON);
}
