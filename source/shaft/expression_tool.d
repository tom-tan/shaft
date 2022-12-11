/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.expression_tool;

import cwl.v1_0 : ExpressionTool;

import shaft.evaluator : Evaluator;
import shaft.runtime : Runtime;
import shaft.type.common : TypedParameters;

int execute(ExpressionTool exp, TypedParameters params, Runtime runtime, Evaluator evaluator)
{
    import shaft.type.common : toJSON;
    import std.file : write;
    import std.path : buildPath;

    auto evaled = evaluator.eval(exp.expression_, params.parameters, runtime);
    buildPath(runtime.outdir, "cwl.output.json").write(evaled.toJSON.toString);

    return 0;
}
