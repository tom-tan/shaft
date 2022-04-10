/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.type.common;

import cwl.v1_0.schema;

import dyaml : Node;

import salad.type : Either, Optional, This;
import std.typecons : Tuple;

///
alias EnumType = Tuple!(string, "name", Optional!CommandLineBinding, "inputBinding");

///
alias DeterminedType = Either!(
    CWLType,
    EnumType,
    Tuple!(This*[], "types", Optional!CommandLineBinding, "inputBinding"),
    Tuple!(string, "name", Tuple!(This*, Optional!CommandLineBinding)[string], "fields"),
);

///
alias ArrayType = Tuple!(DeterminedType*[], "types", Optional!CommandLineBinding, "inputBinding");

///
alias RecordType = Tuple!(string, "name", Tuple!(DeterminedType*, Optional!CommandLineBinding)[string], "fields");

string toStr(DeterminedType dt) pure @safe
{
    import salad.type : match;
    import std.algorithm : map;
    import std.array : array, byPair;
    import std.format : format;
    import std.range : empty;

    return dt.match!(
        (CWLType t) => cast(string)t.value_,
        (EnumType e) => e.name.empty ? "enum" : e.name,
        (ArrayType a) => format!"[%-(%s, %)]"(a.types.map!(e => toStr(*e)).array),
        (RecordType r) => 
            r.name.length > 0 ? r.name
                              : format!"Record(%-(%s, %))"(
                                    r.fields
                                     .byPair
                                     .map!(kv => kv.key~": "~toStr(*kv.value[0]))
                                     .array),
    );
}

///
struct TypedValue
{
    Node value;
    DeterminedType type;

    ///
    this(Node v, DeterminedType t) @safe
    {
        value = v.toJSONNode;
        type = t;
    }

    private import std.meta : ApplyLeft, Filter;
    private import std.traits : isImplicitlyConvertible;
    ///
    this(Type)(Node v, Type t) @safe
        if (Filter!(ApplyLeft!(isImplicitlyConvertible, Type), DeterminedType.Types).length > 0)
    {
        this(v, DeterminedType(t));
    }
}

/*
 * Returns: a shallow copied node with JSON-compatible style
 * See_Also: https://github.com/dlang-community/D-YAML/issues/284
 */
Node toJSONNode(Node v) @safe
{
    import dyaml : CollectionStyle, NodeType, ScalarStyle;

    auto ret = Node(v);
    switch (v.type)
    {
    case NodeType.null_, NodeType.boolean, NodeType.integer, NodeType.decimal:
        ret.setStyle(ScalarStyle.plain);
        break;
    case NodeType.string:
        ret.setStyle(ScalarStyle.doubleQuoted);
        break;
    case NodeType.mapping, NodeType.sequence: // may be redundant
        ret.setStyle(CollectionStyle.flow);
        break;
    default:
        assert(false);
    }
    return ret;
}

/// ditto
Node toJSONNode(T)(T val) @safe
{
    return Node(val).toJSONNode;
}
