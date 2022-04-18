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
    {
        this.outdir = outdir;
        this.tmpdir = tmpdir;

        cores = reserved!"cores"(availableCores, inputs, req, hint, evaluator);
        ram = reserved!"ram"(availableRam, inputs, req, hint, evaluator);

        outdirSize = reserved!"outdir"(availableOutdir, inputs, req, hint, evaluator);
        tmpdirSize = reserved!"tmpdir"(availableTmpdir, inputs, req, hint, evaluator);
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
        import dyaml : CollectionStyle, ScalarStyle;
        import salad.type : match;
        import shaft.type.common : toJSONNode;

        Node ret;
        ret.setStyle(CollectionStyle.flow);

        ret.add("outdir".toJSONNode, outdir.toJSONNode);
        ret.add("tmpdir".toJSONNode, tmpdir.toJSONNode);
        ret.add("cores".toJSONNode, cores.toJSONNode);
        ret.add("ram".toJSONNode, ram.toJSONNode);
        ret.add("outdirSize".toJSONNode, outdirSize.toJSONNode);
        ret.add("tmpdirSize".toJSONNode, tmpdirSize.toJSONNode);

        exitCode.match!(
            (int c) => ret.add("exitCode".toJSONNode, c.toJSONNode),
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

///
auto availableRam() @safe
{
    return 1024; // default in cwltool
}

///
auto availableOutdir() @safe
{
    return long.init;
}

///
auto availableTmpdir() @safe
{
    return long.init;
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
        (string exp) => evaluator.eval!long(exp, inputs, Runtime.init, Node.init),
    );
    enforce(rmin <= avail);

    auto rmax = __traits(getMember, rr, prop~"Max_").match!(
        (None _) => rmin,
        (long l) => l,
        (string exp) => evaluator.eval!long(exp, inputs, Runtime.init, Node.init),
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
