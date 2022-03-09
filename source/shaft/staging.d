/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.staging;

import cwl.v1_0.schema : InitialWorkDirRequirement;
version(none):
import dyaml : Node;
import shaft.evaluator : Evaluator;
import shaft.runtime : Runtime;


///
auto stageIn(Node inputs, Runtime runtime,
             InitialWorkDirRequirement req, Evaluator evaluator)
{
    if (req is null)
    {
        //
    }
    //
}
/+
auto processInitialWorkDir(InitialWorkDirRequirement req, Node inputs, Runtime runtime, Evaluator evaluator)
{
    import cwl.schema : Directory, Dirent, File;
    import salad.type : Either;

    req.listing_.match!(
        (string exp) => evaluator.eval!(Either!(File, Directory)[])(exp, inputs, runtime)
                                 .map!(e => staging(e, inputs, runtime, evaluator)),
        others => others.each!((e) {
            e.match!(
                (File file) => staging(file, inputs, runtime, evaluator),
                (Directory dir) => staging(dir, inputs, runtime, evaluator),
                (Dirent ent) => staging(ent, inputs, runtime, evaluator),
                (string exp) => evaluator.eval!(Either!(File, Directory)[])(exp, inputs, runtime)
                                         .map!(e => staging(e, inputs, runtime, evaluator)),
            ),
        }),
    );
}

auto staging(File file, Node inputs, Runtime runtime, Evaluator evaluator)
{
    //
}

auto staging(Directory dir, Node inputs, Runtime runtime, Evaluator evaluator)
{
    //
}

auto staging(Dirent ent, Node inputs, Runtime runtime, Evaluator evaluator)
{
    evaluator.eval!(Either!(string, File))(ent.entry_, inputs, runtime);
}
+/
