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

/// Process requirements for CommandLineTool
static immutable SupportedRequirementsForCLT = [
    "InlineJavascriptRequirement", "SchemaDefRequirement", "DockerRequirement", "SoftwareRequirement",
    "InitialWorkDirRequirement", "EnvVarRequirement", "ShellCommandRequirement", "ResourceRequirement",
    // "LoadListingRequirement", "WorkReuse", "NetworkAccess", "InplaceUpdateRequirement", "ToolTimeLimit" // since v1.1
];

/**
 * See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Requirements_and_hints
 */
Req getRequirement(alias Req, DocType)(DocType document, Node inputs, bool includeHints = true)
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

    if (!includeHints)
    {
        return null;
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

/// cwl:requirements vs Process.requirements
/// shaft uses cwl:requirements (platform dependent).
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

/// Process.requirements vs shaft:inherited-requirements
/// shaft uses Process.requirements.
/// > If the same process requirement appears at different levels of the workflow, the most specific instance of the requirement is used, ...
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
        shaft:inherited-requirements:
            - class: DockerRequirement
              dockerPull: debian:slim
EOS";

    auto cmd = Loader
        .fromString(cmdStr)
        .load
        .as_!CommandLineTool(LoadingContext.init);

    auto inp = Loader.fromString(inpStr).load;

    assert(cmd.getRequirement!DockerRequirement(inp).edig!("dockerPull", string) == "alpine:latest");
}

/// shaft:inherited-requirements vs hints
/// shaft uses shaft:inherited-requirements.
/// > Requirements override hints.
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

        hints:
            - class: DockerRequirement
              dockerPull: alpine:latest
EOS";

    enum inpStr = q"EOS
        in1: 3
        shaft:inherited-requirements:
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

/// hints vs shaft:inherited-hints
/// shaft uses hints.
/// > If the same process requirement appears at different levels of the workflow, the most specific instance of the requirement is used, ...
/// > ...
/// > Entries in `hints`` are resolved the same way.
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

        hints:
            - class: DockerRequirement
              dockerPull: alpine:latest
EOS";

    enum inpStr = q"EOS
        in1: 3
        shaft:inherited-hints:
            - class: DockerRequirement
              dockerPull: debian:slim
EOS";

    auto cmd = Loader
        .fromString(cmdStr)
        .load
        .as_!CommandLineTool(LoadingContext.init);

    auto inp = Loader.fromString(inpStr).load;

    assert(cmd.getRequirement!DockerRequirement(inp).edig!("dockerPull", string) == "alpine:latest");
}
