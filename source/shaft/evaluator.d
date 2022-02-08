/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.evaluator;

import shaft.runtime : Runtime;

import dyaml : Node;

/// TODO: need cwlVersion to switch handling of `null` and `length` in parameter reference

///
auto evaluate(JSExpReq)(string exp, Node self, Node inputs, Runtime runtime, JSExpReq req)
{
    if (req is null)
    {
        return evaluate_paremeter_reference(exp, self, inputs, runtime);
    }
    else
    {
        return evaluate_js_expression(exp, self, inputs, runtime, req.expressionLib_);
    }
}

/// Evaluate string with parameter references
auto evaluate_paremeter_reference(string exp, Node self, Node inputs, Runtime runtime)
{
    // v1.2 has replacing rules such as `\$(` with `$(`
}

/// Evaluate string with JavaScript expressions
auto evaluate_js_expression(string exp, Node self, Node inputs, Runtime runtime, string[] expressionLibs)
{
    //
}

struct Evaluator
{
    this(JSExpReq)(JSExpReq req)
    {
        //
    }
}