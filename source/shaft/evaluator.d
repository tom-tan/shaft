/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.evaluator;

import shaft.runtime : Runtime;

import std.algorithm : endsWith, startsWith;

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
    this(InlineJavascriptRequirement req, string cwlVersion) @nogc nothrow pure @safe
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

            auto result = evaluate(c.hit, inputs, runtime, self, expressionLibs);
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
                        // TODO: fix duplication of dumpOutput
                        import dyaml : dumper;
                        import std.array : appender;
                        import std.regex : ctRegex, replaceAll;
                        import std.stdio : write;

                        auto d = dumper();
                        d.YAMLVersion = null;

                        auto app = appender!string;
                        d.dump(app, n);
                        return app[].replaceAll(ctRegex!`\n\s+`, " ");
                    },
                )
            ).join;
            return Node(str);
        }
    }

private:
    bool isJS;
    string[] expressionLibs;
    string cwlVer;
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

Node evalParameterReference(string exp, Node inputs, Runtime runtime, Node self, in string[] _) @safe
in(exp.startsWith("$("))
in(exp.endsWith(")"))
{
    import std.regex : ctRegex, matchFirst, splitter;
    // v1.2: null and length
    enum delim = ctRegex!`(\.|\[|\]\.?)`;

    Node node;
    node.add("inputs", inputs);
    node.add("runtime", Node(runtime));
    node.add("self", self);

    foreach(f; exp[2..$-1].splitter(delim))
    {
        import dyaml : NodeType;
        import std.exception : enforce;

        if (f.matchFirst(ctRegex!`^\d+$`))
        {
            import std.conv : to;

            auto idx = f.to!int;
            enforce(node.type == NodeType.sequence);
            enforce(idx < node.length, "Out of index: "~f);
            node = node[idx];
        }
        else
        {
            enforce(node.type == NodeType.mapping);
            node = *enforce(f in node, "Missing field: "~f);
        }
    }
    return node;
}

auto matchJSExpressionFirst(string exp) @safe
{
    // [pre, exp, post]
    return ExpCapture.init;
}

Node evalJSExpression(string exp, Node inputs, Runtime runtime, Node self, in string[] libs) @trusted
{
    //
    return Node();
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
