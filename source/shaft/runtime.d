/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.runtime;

import cwl.v1_0.schema : CommandLineTool, ResourceRequirement;
import dyaml : Node;
import salad.type : Optional;
import shaft.evaluator : Evaluator;
import std.file : isDir;

/// See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Runtime_environment
struct Runtime
{
    string outdir;
    string tmpdir;
    long cores;
    long ram;
    long outdirSize;
    long tmpdirSize;
    Optional!int exitCode; // v1.1 and later

    InternalInfo internal;

    ///
    this(Node inputs, string outdir, string tmpdir,
         ResourceRequirement req, ResourceRequirement hint,
         Evaluator evaluator) @safe
    in(outdir.isDir)
    in(tmpdir.isDir)
    {
        this.outdir = outdir;
        this.tmpdir = tmpdir;

        cores = reserved!"cores"(availableCores, inputs, req, hint, evaluator);
        ram = reserved!"ram"(availableRam, inputs, req, hint, evaluator);

        outdirSize = reserved!"outdir"(availableOutdir(outdir), inputs, req, hint, evaluator);
        tmpdirSize = reserved!"tmpdir"(availableTmpdir(tmpdir), inputs, req, hint, evaluator);
    }

    ///
    void setupInternalInfo(CommandLineTool cmd, Node inputs, string logdir, Evaluator evaluator)
    {
        import salad.type : match;

        internal.logdir = logdir;

        internal.stdin = cmd.stdin_.match!(
            (string exp) => Optional!string(evaluator.eval!string(exp, inputs, this)),
            _ => Optional!string.init,
        );

        internal.stdout = cmd.stdout_.match!(
            (string exp) {
                import std.algorithm : canFind;
                import std.exception : enforce;

                auto ret = evaluator.eval!string(exp, inputs, this);
                //  If ... the resulting path contains illegal characters (such as the path separator `/`) it is an error.
                enforce(!ret.canFind("/"));
                return Optional!string(ret);
            },
            (_) {
                import cwl.v1_0.schema : stdout;
                import std.algorithm : any;

                auto needStdout = cmd
                    .outputs_
                    .any!(cop => cop.type_.match!((stdout _) => true, others => false));
                if (needStdout)
                {
                    import std.uuid : randomUUID;
                    return Optional!string(randomUUID().toString());
                }
                else
                {
                    return Optional!string.init;
                }
            },
        );

        internal.stderr = cmd.stderr_.match!(
            (string exp) {
                import std.algorithm : canFind;
                import std.exception : enforce;

                auto ret = evaluator.eval!string(exp, inputs, this);
                //  If ... the resulting path contains illegal characters (such as the path separator `/`) it is an error.
                enforce(!ret.canFind("/"));
                return Optional!string(ret);
            },
            (_) {
                import cwl.v1_0.schema : stderr;
                import std.algorithm : any;

                auto needStderr = cmd
                    .outputs_
                    .any!(cop => cop.type_.match!((stderr _) => true, others => false));
                if (needStderr)
                {
                    import std.uuid : randomUUID;
                    return Optional!string(randomUUID().toString());
                }
                else
                {
                    return Optional!string.init;
                }
            },
        );
    }

    ///
    Node opCast(T: Node)() const @safe
    {
        import salad.type : match;

        Node ret;

        ret.add("outdir", outdir);
        ret.add("tmpdir", tmpdir);
        ret.add("cores", cores);
        ret.add("ram", ram);
        ret.add("outdirSize", outdirSize);
        ret.add("tmpdirSize", tmpdirSize);

        exitCode.match!(
            (int c) => ret.add("exitCode", c),
            (none) {},
        );

        return ret;
    }
}

/// Extra runtime information for internal use
struct InternalInfo
{
    string logdir;
    Optional!string stdin;
    Optional!string stdout;
    Optional!string stderr;
}

///
auto availableCores() @safe
{
    import std.parallelism : totalCPUs;

    // TODO: use `sched_getaffinity` in Linux to check CPUs reserved to this process
    // It cares `sched_getaffinity` since dmd 2.099.0
    return totalCPUs;
}

/// See_Also: getrlimi(2), sysctl(8)
auto availableRam() @trusted
{
    import core.sys.posix.sys.resource : getrlimit, rlimit, RLIMIT_AS, RLIM_INFINITY;
    import shaft.exception : SystemException;
    import std.exception : enforce, errnoEnforce, ErrnoException, ifThrown;

    rlimit lim; // in bytes
    errnoEnforce(
        getrlimit(RLIMIT_AS, &lim) == 0
    ).ifThrown!ErrnoException((e) {
        enforce(false, new SystemException(e.msg));
        return false;
    });

    version(linux)
    {
        import std.array : split;
        import std.conv : to;
        import std.stdio : File;
        auto meminfo = File("/proc/meminfo").readln.split; // in kilobyte
        enforce!SystemException(meminfo[0] == "MemTotal:");
        enforce!SystemException(meminfo[2] == "kB");
        auto totalMem = meminfo[1].to!ulong*10^^3/2^^10; // in mebibytes
    }
    else version(OSX)
    {
        // sysctl systemcall is unreliable on 64bit systems
        // See_Also: https://github.com/vim/vim/issues/2646
        // TODO: use `host_statistics64`
        import core.sys.darwin.mach.port;
        import std.array : split;
        import std.conv : to;
        import std.process : execute;
        auto ret = execute(["sysctl", "hw.memsize"]); // in bytes
        enforce!SystemException(ret.status == 0);
        auto meminfo = ret.output.split;
        enforce!SystemException(meminfo[0] == "hw.memsize:");
        auto totalMeem = meminfo[1].to!size_t/2^^20; // in mebibytes
    }

    if (lim.rlim_cur == RLIM_INFINITY)
    {
        return totalMem;
    }
    else
    {
        import std.algorithm : min;
        return min(lim.rlim_cur/2^^20, totalMem);
    }
}

///
auto availableOutdir(string outdir) @safe
in(outdir.isDir)
{
    import std.file : getAvailableDiskSpace;
    return getAvailableDiskSpace(outdir)/2^^20;
}

///
auto availableTmpdir(string tmpdir) @safe
in(tmpdir.isDir)
{
    import std.file : getAvailableDiskSpace;
    return getAvailableDiskSpace(tmpdir)/2^^20;
}

/// TODO: eval req or hint, or eval for each parameter?
auto reserved(string prop)(
    long avail, Node inputs,
    ResourceRequirement req, ResourceRequirement hint,
    Evaluator evaluator) @safe // must be pure
{
    import salad.type : match, None;
    import std.algorithm : min;
    import std.exception : enforce;

    auto rr = req is null ? hint : req;

    if (rr is null)
    {
        return avail;
    }

    auto rmin = __traits(getMember, rr, prop~"Min_").match!(
        (None _) => 0,
        (long l) => l,
        (string exp) => evaluator.eval!long(exp, inputs, Runtime.init),
    );
    enforce(rmin <= avail);

    auto rmax = __traits(getMember, rr, prop~"Max_").match!(
        (None _) => rmin,
        (long l) => l,
        (string exp) => evaluator.eval!long(exp, inputs, Runtime.init),
    );
    enforce(rmin <= rmax);

    return min(rmax, avail);
}

@safe unittest
{
    auto hint = new ResourceRequirement;
    (() @trusted =>  hint.coresMin_ = 2)();
    assert(reserved!"cores"(10, Node(), null, hint, Evaluator.init) == 2);
}
