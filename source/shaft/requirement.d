/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.requirement;

import cwl : DocumentRootType;
import dyaml : Node, NodeType;
import std.meta : anySatisfy, ApplyLeft;
import std.traits : allSameType;

/**
 * See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Requirements_and_hints
 */
Req getRequirement(alias Req, DocType)(DocType document, Node inputs)
in(anySatisfy!(ApplyLeft!(allSameType, DocType), DocumentRootType.Types))
in(inputs.type == NodeType.mapping)
{
    import salad.context : LoadingContext;
    import salad.meta.impl : as_;
    import salad.util : dig;
    import shaft.exception : InputCannotBeLoaded;
    import std.algorithm : find;
    import std.exception : enforce;

    // Optionally, implementations may allow requirements to be specified in the input object document as an array of requirements under the field name `cwl:requirements`.
    if (auto reqs = "cwl:requirements" in inputs)
    {
        enforce(
            reqs.type == NodeType.sequence,
            new InputCannotBeLoaded("`cwl:requirements` must be an array of process requirements", reqs.startMark)
        );
        auto rng = reqs.sequence.find!(r => r.dig("class", "") == Req.stringof);
        if (!rng.empty)
        {
            return rng.front.as_!Req(LoadingContext.init);
        }
    }
    
    if (auto req = document.dig!(["requirements", Req.stringof], Req))
    {
        return req;
    }
    
    if (auto reqs = "shaft:inherited-requirements" in inputs)
    {
        enforce(
            reqs.type == NodeType.sequence,
            new InputCannotBeLoaded("`shaft:inherited-requirements` must be an array of process requirements", reqs.startMark)
        );
        auto rng = reqs.sequence.find!(r => r.dig("class", "") == Req.stringof);
        if (!rng.empty)
        {
            return rng.front.as_!Req(LoadingContext.init);
        }
    }
    
    if (auto hint = document.dig!(["hints", Req.stringof], Req))
    {
        return hint;
    }
    
    if (auto hints = "shaft:inherited-hints" in inputs)
    {
        enforce(
            hints.type == NodeType.sequence,
            new InputCannotBeLoaded("`shaft:inherited-hints` must be an array of process requirements", hints.startMark)
        );
        auto rng = hints.sequence.find!(r => r.dig("class", "") == Req.stringof);
        if (!rng.empty)
        {
            return rng.front.as_!Req(LoadingContext.init);
        }
    }
    return null;
}

unittest
{
    import cwl : CommandLineTool, DockerRequirement;
    import dyaml : Loader;

    import salad.context : LoadingContext;
    import salad.meta.impl : as_;
    import salad.util : edig;

    enum cmdStr = q"EOS
        cwlVersion: v1.0
        class: CommandLineTool
        inputs:
            in1: int
        outputs: []

        requirements:
            - class: DockerRequirement
              dockerPull: alpine:latest
EOS";

    enum inpStr = q"EOS
        in1: 3
        cwl:requirements:
            - class: DockerRequirement
              dockerPull: debian:slim
EOS";

    auto cmd = Loader
        .fromString(cmdStr)
        .load
        .as_!CommandLineTool(LoadingContext.init);

    auto inp = Loader.fromString(inpStr).load;

    assert(cmd.getRequirement!DockerRequirement(inp).edig!("dockerPull", string) == "debian:slim");
}

unittest
{
    // TODO: Process.requirements vs shaft:inherited-requirements
}

unittest
{
    // TODO: shaft:inherited-requirements vs Process.hints
}

unittest
{
    // TODO: Process.hints vs shaft:inherited-hints
}
