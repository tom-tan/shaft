/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.requirement;

import cwl : CommandLineTool, DocumentRootType;
import dyaml : Node, NodeType;

/**
 * See_Also: https://www.commonwl.org/v1.2/CommandLineTool.html#Requirements_and_hints
 */
Req getRequirement(alias Req)(DocumentRootType document, Node inputs)
in(inputs.type == NodeType.mapping)
{
    import salad.exception : InputCannotBeLoaded;
    import salad.meta.impl : as_;
    import salad.util : dig;
    import std.algorithm : find;
    import std.exception : enforce;

    // Optionally, implementations may allow requirements to be specified in the input object document as an array of requirements under the field name `cwl:requirements`.
    if (auto reqs = "cwl:requirements" in inputs)
    {
        enforce(
            reqs.type == NodeType.sequence,
            new InputCannotBeLoaded("`cwl:requirements` must be an array of process requirements", reqs.startMark)
        );
        auto rng = reqs.find(r => r.dig!("class", string) == Req.stringof);
        if (!rng.empty)
        {
            return rng.front.as_!Req;
        }
    }
    
    if (auto req = document.dig!("requirements", Req.stringof)(Req.init))
    {
        return *req;
    }
    
    if (auto reqs = "shaft:inherited-requirements" in inputs)
    {
        enforce(
            reqs.type == NodeType.sequence,
            new InputCannotBeLoaded("`shaft:inherited-requirements` must be an array of process requirements", reqs.startMark)
        );
        auto rng = reqs.find(r => r.dig!("class", string) == Req.stringof);
        if (!rng.empty)
        {
            return rng.front.as_!Req;
        }
    }
    
    if (auto hint = document.dig!("hints", Req.stringof)(Req.init))
    {
        return *hint;
    }
    
    if (auto hints = "shaft:inherited-hints" in inputs)
    {
        enforce(
            hints.type == NodeType.sequence,
            new InputCannotBeLoaded("`shaft:inherited-hints` must be an array of process requirements", hints.startMark)
        );
        auto rng = hints.find(r => r.dig!("class", string) == Req.stringof);
        if (!rng.empty)
        {
            return rng.front.as_!Req;
        }
    }
    return null;
}
