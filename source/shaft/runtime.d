/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.runtime;

import cwl.schema : ResourceRequirement;
import dyaml : Node;
import shaft.evaluator : Evaluator;

struct Runtime
{
    string outdir;
    string tmpdir;
    long cores;
    long ram;
    long outdirSize;
    long tmpdirSize;

    this(Node inputs, string outdir, string tmpdir,
         ResourceRequirement req, ResourceRequirement hint,
         Evaluator evaluator)
    {
        this.outdir = outdir;
        this.tmpdir = tmpdir;

        cores = reserved!"cores"(availableCores, inputs, req, hint, evaluator);
        ram = reserved!"ram"(availableRam, inputs, req, hint, evaluator);

        outdirSize = reserved!"outdir"(availableOutdir, inputs, req, hint, evaluator);
        tmpdirSize = reserved!"tmpdir"(availableTmpdir, inputs, req, hint, evaluator);
    }
}

///
auto availableCores()
{
    import std.parallelism : totalCPUs;

    // TODO: use `sched_getaffinity` in Linux to check CPUs reserved to this process
    return totalCPUs;
}

///
auto availableRam()
{
    return 1024; // default in cwltool
}

///
auto availableOutdir()
{
    return long.init;
}

///
auto availableTmpdir()
{
    return long.init;
}

/// TODO: eval req or hint, or eval for each parameter?
auto reserved(string prop)(
    long avail, Node inputs,
    ResourceRequirement req, ResourceRequirement hint,
    Evaluator evaluator) // must be pure
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
        (string exp) => evaluator.eval(exp, inputs, Runtime.init, Node.init).as!long,
    );
    enforce(rmin <= avail);

    auto rmax = __traits(getMember, rr, prop~"Max_").match!(
        (None _) => rmin,
        (long l) => l,
        (string exp) => evaluator.eval(exp, inputs, Runtime.init, Node.init).as!long,
    );
    enforce(rmin <= rmax);

    return min(rmax, avail);
}
