/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.runtime;

import cwl.v1_0.schema : ResourceRequirement;
import dyaml : Node;
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
    Node opCast(T: Node)() const @safe
    {
        import dyaml : CollectionStyle, ScalarStyle;
        import shaft.type : toJSONNode;

        Node ret;
        ret.setStyle(CollectionStyle.flow);

        ret.add("outdir".toJSONNode, outdir.toJSONNode);
        ret.add("tmpdir".toJSONNode, tmpdir.toJSONNode);
        ret.add("cores".toJSONNode, cores.toJSONNode);
        ret.add("ram".toJSONNode, ram.toJSONNode);
        ret.add("outdirSize".toJSONNode, outdirSize.toJSONNode);
        ret.add("tmpdirSize".toJSONNode, tmpdirSize.toJSONNode);

        return ret;
    }
}

///
auto availableCores() @safe
{
    import std.parallelism : totalCPUs;

    // TODO: use `sched_getaffinity` in Linux to check CPUs reserved to this process
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
