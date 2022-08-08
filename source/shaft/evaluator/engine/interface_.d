/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.evaluator.engine.interface_;

import dyaml : Node;
import shaft.runtime : Runtime;

interface JSEngine
{
    string evaluate(scope string exp, Node inputs, Runtime runtime, Node self, in string[] libs) const;
}
