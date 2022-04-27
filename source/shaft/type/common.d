/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.type.common;

import cwl.v1_0.schema;

import dyaml : Node;

import salad.type : Either, Optional, This;
import shaft.exception : TypeException;
import std.json : JSONValue;
import std.range : isOutputRange;
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
        value = v;
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

///
alias TypedParameters = Tuple!(Node, "parameters", DeterminedType[string], "types");

/// 
class TypeConflicts(DeclType, alias toStrFun) : TypeException
{
    this(DeclType expected, DeterminedType actual, string id = "",
         string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure @trusted
    {
        import std.format : format;

        super(format!"Type conflicts for `%s` (expected: `%s`, actual: `%s`)"(id, toStrFun(expected), actual.toStr));
        id_ = id;
        expected_ = expected;
        actual_ = actual;
    }

    string id_;
    DeclType expected_;
    DeterminedType actual_;
}

///
auto guessedType(Node val) @safe
{
    import dyaml : NodeType;
    import salad.type : None;

    switch(val.type)
    {
    case NodeType.null_:
        return DeterminedType(new CWLType("null"));
    case NodeType.boolean:
        return DeterminedType(new CWLType("boolean"));
    case NodeType.integer:
        return DeterminedType(new CWLType("long"));
    case NodeType.decimal:
        return DeterminedType(new CWLType("double"));
    case NodeType.string:
        return DeterminedType(new CWLType("string"));
    case NodeType.mapping:
        import shaft.type.common : RecordType;
        import std.algorithm : fold;

        if (auto class_ = "class" in val)
        {
            if (*class_ == "File" || *class_ == "Directory")
            {
                return DeterminedType(new CWLType(*class_));
            }
        }
        auto ts = val.mapping
                     .fold!((acc, e) @trusted {
                         import std.algorithm : moveEmplace;
                         import std.typecons : tuple;
                         auto t = guessedType(e.value);
                         auto dt = new DeterminedType;
                         moveEmplace(t, *dt);
                         acc[e.key.as!string] = tuple(dt, Optional!CommandLineBinding.init);
                         return acc;
                     })((Tuple!(DeterminedType*, Optional!CommandLineBinding)[string]).init);
        return DeterminedType(RecordType("", ts));
    case NodeType.sequence:
        import shaft.type.common : ArrayType;
        import std.algorithm : map;
        import std.array : array;

        return DeterminedType(
            ArrayType(
                val.sequence
                   .map!((e) @trusted {
                       import std.algorithm : moveEmplace;
                       auto t = guessedType(e);
                       auto dt = new DeterminedType;
                       moveEmplace(t, *dt);
                       return dt;
                   })
                   .array,
                Optional!CommandLineBinding.init
            )
        );
    default:
        throw new TypeException("Unsuppported type: "~val.nodeTypeString);
    }
}

JSONValue toJSON(Node node) @safe
{
    import dyaml : NodeType;
    import std.algorithm : fold, map;
    import std.array : array;
    import std.format : format;

    switch(node.type)
    {
    case NodeType.null_: return JSONValue(null);
    case NodeType.boolean: return JSONValue(node.as!bool);
    case NodeType.integer: return JSONValue(node.as!long);
    case NodeType.decimal: return JSONValue(node.as!real);
    case NodeType.string: return JSONValue(node.as!string);
    case NodeType.mapping:
        return node.mapping.fold!((acc, e) {
            acc[e.key.as!string] = e.value.toJSON;
            return acc;
        })(JSONValue((JSONValue[string]).init));
    case NodeType.sequence:
        return JSONValue(node.sequence.map!(e => e.toJSON).array);
    default: assert(false, format!"Invalid node type: %s"(node.type));
    }
}