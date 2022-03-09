/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.evaluator;

import shaft.runtime : Runtime;

import dyaml : Node, YAMLNull;

// generate evaluator for parameter references
// v1.0, v1.1 => reject `length` and `null`
// v1.2 => will accept `length` and `null`, escape with '\'
// upgrade to the latest version

///
struct Evaluator
{
    ///
    this(JSExpReq)(JSExpReq req, string cwlVersion)
    {
        if (req !is null)
        {
            import salad.util : dig;

            isJS = true;
            expressionLibs = req.dig!("expressionLib", string[]);
        }
        cwlVer = cwlVersion;
    }

    ///
    T eval(T)(string exp, Node inputs, Runtime runtime, Node self = YAMLNull()) const /+ pure +/
    {
        return eval(exp, inputs, runtime, self).as!T;
    }

    Node eval(string exp, Node inputs, Runtime runtime, Node self = YAMLNull()) const /+ pure +/
    {
        return Node.init;
    }

private:
    bool isJS;
    string[] expressionLibs;
    string cwlVer;
}

string toJSON(Node node) @safe
{
    import std.algorithm : map;
    import std.array : appender, array;
    import std.conv : to;
    import std.format : format;
    import dyaml : NodeType;

    switch(node.type)
    {
    case NodeType.null_: return "null";
    case NodeType.boolean: return node.as!bool.to!string;
    case NodeType.integer: return node.as!int.to!string;
    case NodeType.decimal: return node.as!real.to!string;
    case NodeType.string: return '"'~node.as!string~'"';
    case NodeType.mapping:
        return format!"{%-(%s, %)}"(node.mapping.map!((pair) {
            return format!`"%s": %s`(pair.key.as!string, pair.value.toJSON);
        }));
    case NodeType.sequence:
        return format!"[%-(%s, %)]"(node.sequence.map!toJSON.array);
    default:
        assert(false);
    }
}

@safe unittest
{
    import dyaml : Loader;

    enum yml = q"EOS
        - 1
        - 2
        - 3
EOS";
    auto arr = Loader.fromString(yml).load;
    assert(arr.toJSON == "[1, 2, 3]", arr.toJSON);
}

@safe unittest
{
    import dyaml : Loader;

    enum yml = q"EOS
        foo: 1
        bar: 2
        buzz: 3
EOS";
    auto map = Loader.fromString(yml).load;
    assert(map.toJSON == `{"foo": 1, "bar": 2, "buzz": 3}`, map.toJSON);
}
