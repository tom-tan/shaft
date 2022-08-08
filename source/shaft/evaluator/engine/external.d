/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.evaluator.engine.external;

import shaft.evaluator.engine.interface_ : JSEngine;
import shaft.exception : ExpressionFailed, FeatureUnsupported;
import dyaml : Node;
import shaft.runtime : Runtime;

@safe:

abstract class ExternalEngine : JSEngine
{
    this(string bin)
    in(bin.length != 0)
    {
        import std.exception : enforce;
        import std.format : format;
        import std.process : executeShell;

        this.bin = bin;
        auto ret = executeShell("which "~bin);
        enforce!FeatureUnsupported(
            ret.status == 0,
            format!"`%s` is not available"(bin),
        );
    }

    override string evaluate(scope string exp, Node inputs, Runtime runtime, Node self, in string[] libs) const
    in(exp.length != 0)
    {
        import std.exception : enforce;
        import std.format : format;
        import std.process : Config, execute;

        auto code = toJSCode(exp, inputs, runtime, self, libs);
        auto args = generateArgs(code);

        auto ret = execute(args, null, Config.newEnv);
        enforce!ExpressionFailed(ret.status == 0, format!"Evaluation failed: `%s`, output: `%s`"(code, ret.output));
        return ret.output;
    }

protected:
    string[] generateArgs(return string exp) const;
    string toJSCode(string exp, Node inputs, Runtime runtime, Node self, in string[] libs) const;

private:
    string bin;
}

class ExternalNodeEngine : ExternalEngine
{
    this(string bin = "node")
    in(bin.length != 0)
    {
        super(bin);
    }

protected:
    override string[] generateArgs(return string exp) const
    {
        return [bin, "--eval", exp];
    }

    override string toJSCode(string exp, Node inputs, Runtime runtime, Node self,
        in string[] libs) const
    {
        import shaft.type.common : toJSON;
        import std.array : join;
        import std.format : format;
        import std.range : chain;

        auto expBody = exp[1] == '('
            ? exp[1..$]
            : format!"(function() { %s })()"(exp[2..$-1]);
        auto toBeEvaled = chain(libs, [expBody]).join(";\n").escape;

        return format!q"EOS
            'use strict';
            try
            {
                const exp = "%s";
                process.stdout.write(JSON.stringify(require('vm').runInNewContext(exp, {
                    'runtime': %s,
                    'inputs': %s,
                    'self': %s,
                })));
            } catch(e) {
                process.stdout.write(JSON.stringify({ 'class': 'exception', 'message': `${e.name}: ${e.message}`}));
            }
EOS"(toBeEvaled, Node(runtime).toJSON, inputs.toJSON, self.toJSON);
    }
}

auto escape(string exp) @safe
{
    import std.regex : ctRegex, replaceAll;
    return exp
        .replaceAll(ctRegex!`\\`, `\\`)
        .replaceAll(ctRegex!`"`, `\"`)
        .replaceAll(ctRegex!`\n`, `\n`);
}

class ExternalNJSEngine : ExternalEngine
{
    this(string bin = "njs")
    in(bin.length != 0)
    {
        super(bin);
    }

protected:
    override string[] generateArgs(return string exp) const
    {
        return [bin, "-s", "-c", exp];
    }

    override string toJSCode(string exp, Node inputs, Runtime runtime, Node self,
        in string[] libs) const
    {
        import shaft.type.common : toJSON;
        import std.array : join;
        import std.format : format;
        import std.range : chain;

        auto expBody = exp[1] == '('
            ? format!"(function() { return %s ;})()"(exp[1..$])
            : format!"(function() { %s })()"(exp[2..$-1]);
        auto toBeEvaled = chain(libs, [expBody]).join(";\n");

        return format!q"EOS
            "use strict";
            this.global = {};
            delete this.global;
            delete this.njs;
            delete this.process;
            if ("$262" in this)
            {
                delete this["$262"];
            }
            var globalThis = {};
            try
            {
                var runtime = %s;
                var inputs = %s;
                var self = %s;
                console.log(JSON.stringify(%s));
            }
            catch(e)
            {
                console.log(JSON.stringify({ 'class': 'exception', 'message': `${e.name}: ${e.message}`}));
            }
EOS"(Node(runtime).toJSON, inputs.toJSON, self.toJSON, toBeEvaled);
    }
}
