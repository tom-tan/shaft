/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.evaluator;

import shaft.runtime : Runtime;

import dyaml : Node, YAMLNull;

/**
 * Evaluator for parameter references and JavaScript expressions.
 * It encapsulates the diffference of interpretation of parameter references for each CWL release.
 *
 * Note:
 *   - v1.2 introduce [string interpolation](https://www.commonwl.org/v1.2/CommandLineTool.html#String_interpolation).
 *   - `length` and `null` in parameter references are rejected until v1.2.0 but they are accepted since v1.2.1
 * See_Also:
 *   - https://www.commonwl.org/v1.0/CommandLineTool.html#Parameter_references
 *   - https://www.commonwl.org/v1.2/CommandLineTool.html#Parameter_references
 *   - https://www.commonwl.org/v1.2/CommandLineTool.html#Expressions_(Optional)
 */
struct Evaluator
{
    private import cwl.v1_0.schema : InlineJavascriptRequirement;

    /**
     * Params: 
     *   req = is `null` when expressions in the doccument are parameter references
     *         and non-null when expressions are JavaScript expressions
     *   cwlVersion = is used to encapsulate the difference of interpretation of parameter references
     */
    this(InlineJavascriptRequirement req, string cwlVersion) @safe
    {
        if (req !is null)
        {
            import salad.util : dig;

            isJS = true;
            expressionLibs = req.dig!("expressionLib", string[]);
        }
        cwlVer = cwlVersion;
    }

    /**
     * Evaluate an expression
     * Returns: evaluated expression as `T`
     * Throws:
     *   - NodeExpression if the evaluated expression cannot be converted to `T`
     */
    T eval(T)(string exp, Node inputs, Runtime runtime, Node self = YAMLNull()) const /+ pure +/ @safe
    {
        return eval(exp, inputs, runtime, self).as!T;
    }

    /**
     * Evaluate an expression
     * Returns: evaluated expression as `Node` instance
     */
    Node eval(string exp, Node inputs, Runtime runtime, Node self = YAMLNull()) const /+ pure +/ @safe
    {
        auto rtNode = Node(runtime);
        return Node(exp); // TODO
    }

private:
    bool isJS;
    string[] expressionLibs;
    string cwlVer;
}