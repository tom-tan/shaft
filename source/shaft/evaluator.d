/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.evaluator;

import shaft.exception : ExpressionFailed, FeatureUnsupported;
import shaft.runtime : Runtime;

import std.algorithm : endsWith, startsWith;
import std.range : empty;

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
    enum nodebin = "node";

    static canSupportJavaScript() @safe
    {
        import std.process : executeShell;
        auto ret = executeShell("which "~nodebin);
        return ret.status == 0;
     }

    /**
     * Params: 
     *   req = is `null` when expressions in the doccument are parameter references
     *         and non-null when expressions are JavaScript expressions
     *   cwlVersion = is used to encapsulate the difference of interpretation of parameter references
     *   enableExtProps = enables `null` value and `length` property for arrays in parameter references.
     *                    It does nothing since v1.2.
     */
    this(InlineJavascriptRequirement req, string cwlVersion, bool enableExtProps) @safe
    {
        if (req !is null)
        {
            import salad.util : dig;
            import std.exception : enforce;

            enforce!FeatureUnsupported(
                canSupportJavaScript,
                "nodejs is not available"
            );

            isJS = true;
            expressionLibs = req.dig!("expressionLib", string[]);
        }
        this.cwlVersion = cwlVersion;
        this.enableExtProps = enableExtProps;
    }

    /**
     * Evaluate an expression
     * Returns: evaluated expression as `T`
     * Throws:
     *   - NodeExpression if the evaluated expression cannot be converted to `T`
     */
    T eval(T)(string expression, Node inputs, Runtime runtime, Node self = YAMLNull()) const /+ pure +/ @safe
    {
        return eval(expression, inputs, runtime, self).as!T;
    }

    /**
     * Evaluate an expression
     * Returns: evaluated expression as `Node` instance
     */
    Node eval(string expression, Node inputs, Runtime runtime, Node self = YAMLNull()) const /+ pure +/ @safe
    {
        import salad.type : Either, match;
        import std.algorithm : map;
        import std.array : join;
        import std.range : empty;

        auto matchFirst = isJS ? &matchJSExpressionFirst : &matchParameterReferenceFirst;
        auto evaluate = isJS ? &evalJSExpression : &evalParameterReference;

        auto exp = expression;

        Either!(string, Node)[] evaled;
        while (auto c = matchFirst(exp))
        {
            if (!c.pre.empty)
            {
                evaled ~= Either!(string, Node)(c.pre);
            }

            auto result = evaluate(c.hit, inputs, runtime, self, expressionLibs, enableExtProps, nodebin);
            evaled ~= Either!(string, Node)(result);

            exp = c.post;
            if (exp.empty)
            {
                break;
            }
        }

        if (!exp.empty)
        {
            evaled ~= Either!(string, Node)(exp);
        }

        if (evaled.length == 1)
        {
            return evaled[0].match!(
                (string s) => Node(s),
                node => node,
            );
        }
        else
        {
            auto str = evaled.map!(e =>
                e.match!(
                    (string s) => s,
                    (Node n) {
                        import dyaml : NodeType;
                        switch (n.type)
                        {
                        case NodeType.mapping, NodeType.sequence:
                            import shaft.type.common : toJSON;
                    
                            return n.toJSON.toString;
                        default:
                            return n.as!string;
                        }
                    },
                )
            ).join;
            return Node(str);
        }
    }

private:
    bool isJS;
    string[] expressionLibs;
    string cwlVersion;
    bool enableExtProps;
}

@safe unittest
{
    import dyaml : Loader;

    enum inp = q"EOS
        bar: {
            'b"az': null,
        }
EOS";
    auto inputs = Loader.fromString(inp).load;
    auto evaluator = Evaluator(null, "v1.0", true);
    auto n = evaluator.eval(`$(inputs.bar['b"az']) $(inputs.bar['b"az'])`, inputs, Runtime.init);
    assert(n.as!string == "null null", n.as!string);
}

auto matchParameterReferenceFirst(string exp) pure @safe
{
    import std.format : format;
    import std.regex : ctRegex, matchFirst;

    enum symbol = `\w+`;
    enum singleq = `\['(?:[^']|\\')*'\]`;
    enum doubleq = `\["(?:[^"]|\\")*"\]`;
    enum index = `\[\d+\]`;
    enum segment = format!`(?:\.%s)|(?:%s)|(?:%s)|(?:%s)`(symbol, singleq, doubleq, index);
    enum parameterReference = ctRegex!(format!`\$\((%s(?:%s)*)\)`(symbol, segment));

    if (auto c = exp.matchFirst(parameterReference))
    {
        return ExpCapture(c.pre, c.hit, c.post);
    }
    else
    {
        return ExpCapture(exp, "", "");
    }
}

@safe pure unittest
{
    auto m = "foo$(inputs.inp1)bar".matchParameterReferenceFirst;
    assert(m);
    assert(m.pre == "foo");
    assert(m.hit == "$(inputs.inp1)");
    assert(m.post == "bar");
}

@safe pure unittest
{
    auto m = "$(self[0].contents)".matchParameterReferenceFirst;
    assert(m);
    assert(m.pre == "");
    assert(m.hit == "$(self[0].contents)");
    assert(m.post == "");
}

@safe pure unittest
{
    auto m = "$(self['foo'])".matchParameterReferenceFirst;
    assert(m);
    assert(m.pre == "");
    assert(m.hit == "$(self['foo'])");
    assert(m.post == "");
}

@safe pure unittest
{
    auto m = `$(self["foo"])`.matchParameterReferenceFirst;
    assert(m);
    assert(m.pre == "");
    assert(m.hit == `$(self["foo"])`);
    assert(m.post == "");
}

Node evalParameterReference(
    string exp, Node inputs, Runtime runtime, Node self,
    in string[] _, bool enableExtProps, string _node
) @safe
in(exp.startsWith("$("))
in(exp.endsWith(")"))
{
    import std.algorithm : filter, map;
    import std.regex : ctRegex, matchFirst, replaceAll, splitter;
    enum delim = ctRegex!`(\.|(?:\[['"]?)|(?:['"]?\])\.?)`;

    Node node;
    node.add("inputs", inputs);
    node.add("runtime", Node(runtime));
    node.add("self", self);

    if (exp[2..$-1] == "null")
    {
        import std.exception : enforce;

        enforce!FeatureUnsupported(
            enableExtProps,
            "`null` is not supported in parametr reference. Use --enable-compat=extended-props",
        );
        return Node(YAMLNull());
    }

    foreach(f; exp[2..$-1]
        .splitter(delim)
        .filter!"a.length > 0"
        .map!(f => f.replaceAll(ctRegex!`\\(['"])`, `$1`)))
    {
        import dyaml : NodeType;
        import std.exception : enforce;
        import std.format : format;

        if (f.matchFirst(ctRegex!`^\d+$`))
        {
            import std.conv : to;

            auto idx = f.to!int;
            enforce!ExpressionFailed(
                node.type == NodeType.sequence,
                format!"Invalid index access `%s` in `%s`"(idx, exp),
            );
            enforce!ExpressionFailed(idx < node.length, format!"Out of index `%s` in `%s`"(f, exp));
            node = node[idx];
        }
        else
        {
            if (node.type == NodeType.sequence && f == "length")
            {
                import std.exception : enforce;
        
                enforce!FeatureUnsupported(
                    enableExtProps,
                    "`length` property is not supported in parametr reference. Use --enable-compat=extended-props"
                );
                node = Node(node.length);
            }
            else
            {
                enforce!ExpressionFailed(
                    node.type == NodeType.mapping,
                    format!"Invalid index access `%s` in `%s`"(f, exp),
                );
                node = *enforce!ExpressionFailed(f in node, format!"Missing field `%s` in `%s`"(f, exp));
            }
        }
    }
    return node;
}

auto matchJSExpressionFirst(string str) pure @safe
{
    import std.exception : enforce;
    import std.format : format;
    import std.range : empty;
    import std.regex : ctRegex, matchFirst;

    auto m = str.matchFirst(ctRegex!`\$([({])`);
    if (!m)
    {
        return ExpCapture(str, "", "");
    }
    auto pre = m.pre;

    auto stack = [m[1]];
    auto rest = m.post;
    string exp;

    while (auto mm = rest.matchFirst(ctRegex!`["'(){}]`))
    {
        auto v = mm.hit;
        auto rst = mm.post;
        exp ~= mm.pre;

        final switch(v)
        {
        case `"`: {
            auto mmm = enforce!ExpressionFailed(
                (v~rst).matchFirst(ctRegex!`"("|([^"]|\\")*[^\\]")`),
                format!"Unmatched `%s` in `%s`"(v, str)
            );
            rest = mmm.post;
            exp ~= mmm[0];
            break;
        }
        case `'`: {
            auto mmm = enforce!ExpressionFailed(
                (v~rst).matchFirst(ctRegex!`'('|([^']|\\')*[^\\]')`),
                format!"Unmatched `%s` in `%s`"(v, str)
            );
            rest = mmm.post;
            exp ~= mmm[0];
            break;
        }
        case `(`, `{`: {
            stack ~= v;
            rest = rst;
            exp ~= v;
            break;
        }
        case `)`: {
            enforce!ExpressionFailed(!stack.empty, format!"Missing `%s` in `%s`"(v, str));
            assert(stack[$-1] == "(", format!"`(` is expected but `%s` is occured"(stack[$-1]));
            stack = stack[0..$-1];
            rest = rst;
            if (stack.empty)
            {
                return ExpCapture(pre, "$("~exp~")", rest);
            }
            exp ~= v;
            break;
        }
        case `}`: {
            enforce!ExpressionFailed(!stack.empty, format!"Missing `%s` in `%s`"(v, str));
            assert(stack[$-1] == "{", format!"`{` is expected but `%s` is occured"(stack[$-1]));
            stack = stack[0..$-1];
            rest = rst;
            if (stack.empty)
            {
                return ExpCapture(pre, "${"~exp~"}", rest);
            }
            exp ~= v;
            break;
        }
        }
    }
    throw new ExpressionFailed(format!"Missing `%s` in `%s`"(stack[$-1] == "(" ? ")" : "}", str));
}

@safe pure unittest
{
    import std.format : format;
    auto m = "foo$(inputs.inp1)bar".matchJSExpressionFirst;
    assert(m);
    assert(m.pre == "foo");
    assert(m.hit == "$(inputs.inp1)", format!"`$(inputs.inp1)` is expected but actual: `%s`"(m.hit));
    assert(m.post == "bar");
}

@safe pure unittest
{
    auto m = "$(self[0].contents)".matchJSExpressionFirst;
    assert(m);
    assert(m.pre == "");
    assert(m.hit == "$(self[0].contents)");
    assert(m.post == "");
}

@safe pure unittest
{
    auto m = "$(self['foo'])".matchJSExpressionFirst;
    assert(m);
    assert(m.pre == "");
    assert(m.hit == "$(self['foo'])");
    assert(m.post == "");
}

@safe pure unittest
{
    auto m = `$(self["foo"])`.matchJSExpressionFirst;
    assert(m);
    assert(m.pre == "");
    assert(m.hit == `$(self["foo"])`);
    assert(m.post == "");
}

Node evalJSExpression(
    string exp, Node inputs, Runtime runtime, Node self,
    in string[] libs, bool _, string node
) @trusted
{
    import dyaml : Loader, NodeType;
    import std.exception : enforce;
    import std.format : format;
    import std.process : execute;

    auto cmd = exp.toJSCode(inputs, runtime, self, libs);
    auto ret = execute([node, "--eval", cmd]);
    
    enforce!ExpressionFailed(ret.status == 0, format!"Evaluation failed: `%s`"(exp));
    auto retNode = Loader.fromString(ret.output).load; // TODO: ifThrown
    
    if (retNode.type == NodeType.mapping)
    {
        auto cl = "class" in retNode;
        enforce!ExpressionFailed(
            cl is null || *cl != "exception",
            format!"Exception is thrown from the expression `%s`: %s"(
                exp, retNode["message"].as!string
            )
        );
    }
    return retNode;
}

auto escape(string exp) @safe
{
    import std.regex : ctRegex, replaceAll;
    return exp
        .replaceAll(ctRegex!`\\`, `\\`)
        .replaceAll(ctRegex!`"`, `\"`)
        .replaceAll(ctRegex!`\n`, `\n`);
}

auto toJSCode(
    string exp, Node inputs, Runtime runtime, Node self,
    in string[] libs
) @safe
in(!exp.empty)
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
        'use strict'
        try{
            const exp = "%s";
            process.stdout.write(JSON.stringify(require('vm').runInNewContext(exp, {
                'runtime': %s,
                'inputs': %s,
                'self': %s,
            })));
        } catch(e) {
            process.stdout.write(JSON.stringify({ 'class': 'exception', 'message': `${e.name}: ${e.message}`}))
        }
EOS"(toBeEvaled, Node(runtime).toJSON, inputs.toJSON, self.toJSON);
}

// similar to std.regex.Captures
struct ExpCapture
{
    //
    string pre, hit, post;

    //
    bool opCast(T: bool)() const @nogc nothrow pure @safe
    {
        import std.range : empty;
        return !hit.empty;
    }
}
