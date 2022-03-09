/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.type;

import dyaml : Node, NodeType;

import cwl.v1_0.schema;
import salad.type : Either;

import std.typecons : Tuple;

///
alias DeclaredType = Either!(
    CWLType,
    CommandInputRecordSchema,
    CommandInputEnumSchema,
    CommandInputArraySchema,
    string,
    Either!(
        CWLType,
        CommandInputRecordSchema,
        CommandInputEnumSchema,
        CommandInputArraySchema,
        string
    )[],
);

///
alias DeterminedType = Either!(
    CWLType,
    CommandInputRecordSchema,
    CommandInputEnumSchema,
    CommandInputArraySchema,
);


/*
parameter missing: missig/`%s` is missing
confilcts: (expected, actual) -> id, expected, actual
Invalid: (missing, type) -> id, missing, type
*/

///
class TypeException : Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

///
class ParameterMissing : TypeException
{
    ///
    this(string id, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) @safe
    {
        import std.format : format;

        super(format!"Missing input parameter: `%s`"(id), file, line, nextInChain);
        id_ = id;
    }

    string id_;
}

///
class TypeConflicts : TypeException
{
    this(string id, DeclaredType expected, DeterminedType actual,
         string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) @trusted
    {
        import std.format : format;

        super(format!"Type conflicts for `%s` (expected: `%s`, actual: `%s`)"(id, expected, actual));
        id_ = id;
        expected_ = expected;
        actual_ = actual;
    }

    string id_;
    DeclaredType expected_;
    DeterminedType actual_;
}

class InvalidObject : TypeException
{
    this(string id, string field, DeterminedType actual,
         string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) @trusted
    {
        import std.format : format;

        super(format!"Invalid field `%s` in type `%s` `%s`"(field_, type_, id_));
        id_ = id;
        field_ = field;
        type_ = actual;
    }

    string id_;
    string field_;
    DeterminedType type_;
}

///
alias TypedParameters = Tuple!(Node, "parameters", DeterminedType[string], "types");

/**
 *
 * Returns: a tuple that consists of:
 *    - `params`: a node as an input parameters (`default` is considered)
 *    - `types`: a mapping from an input parameter ID to its determined type
 * Throws:
 *    - MissingParameter if there are missing input parameters
 *    - TypeConflict if some input parameters conflict with their type declaration
 *    - InvalidObject if type matched but there are missing fields for File, Directory or Record objects
 */
TypedParameters annotateInputParameters(
    ref Node params, CommandInputParameter[] paramDefs,
    SchemaDefRequirement defs)
in(params.type == NodeType.mapping)
{
    import std.range : assocArray;
    import std.typecons : tuple, Tuple;

    DeclaredType[string] defMap;
    if (defs !is null)
    {
        import salad.type : match;
        import salad.util : edig;
        import std.algorithm : map;

        defMap = () @trusted {
            return defs.types_
                       .map!(d => d.match!(t => tuple(t.edig!("name", string),
                                                      DeclaredType(t.toCommandSchema))))
                       .assocArray;
        }();
    }

    Node retNode;
    Tuple!(string, DeterminedType)[] retTuple;
    foreach(p; paramDefs)
    {
        import cwl : Any;
        import dyaml : ScalarStyle;
        import salad.type : match, None;
        import salad.util : dig;

        auto id = p.id_;
        Node n;
        if (auto val = id in params)
        {
            n = *val;
        }
        else if (auto def = p.dig!(["inputBinding", "default"], Any))
        {
            n = def.value_;
        }
        else
        {
            import dyaml : YAMLNull;
            n = Node(YAMLNull());
        }

        DeclaredType type = p.type_.match!(
            (None _) => DeclaredType("Any"), // v1.0 only: assumes Any, TODO: investigate corresponding conformance test
            (string s) => defMap[s], // TODO
            others => DeclaredType(others),
        );

        auto v = n.bindType(type, defMap);
        retTuple ~= tuple(id, v.type);
        auto k = Node(id);
        k.setStyle(ScalarStyle.doubleQuoted);
        retNode.add(k, v.value);
    }
    auto types = () @trusted { return retTuple.assocArray; }();
    return typeof(return)(retNode, types);
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

    ///
    this(Node v, DeclaredType t) @safe
    {
        import salad.type : match;

        value = v.toJSONNode;

        alias T = DeterminedType;
        type = t.match!(
            (CWLType t) => T(t),
            (CommandInputRecordSchema s) => T(s),
            (CommandInputEnumSchema s) => T(s),
            (CommandInputArraySchema s) => T(s),
            others => assert(false),
        );
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

/// 
TypedValue bindType(ref Node n, DeclaredType type, DeclaredType[string] defMap)
{
    import salad.type : match;
    import std.exception : enforce;

    return type.match!(
        (CWLType t) {
            final switch(t.value_)
            {
            case "null":
                enforce(n.type == NodeType.null_, new TypeConflicts("TODO: guess type", type, n.guessedType));
                return TypedValue(n, t);
            case "boolean":
                enforce(n.type == NodeType.boolean, new TypeConflicts("TODO: guess type", type, n.guessedType));
                return TypedValue(n, t);
            case "int", "long":
                enforce(n.type == NodeType.integer, new TypeConflicts("TODO: guess type", type, n.guessedType));
                return TypedValue(n, t);
            case "float", "double":
                enforce(n.type == NodeType.decimal, new TypeConflicts("TODO: guess type", type, n.guessedType));
                return TypedValue(n, t);
            case "File":
                enforce(n.type == NodeType.mapping, new TypeConflicts("TODO: guess type", type, n.guessedType));
                n.enforceValidFile;
                return TypedValue(n, t);
            case "Directory":
                enforce(n.type == NodeType.mapping, new TypeConflicts("TODO: guess type", type, n.guessedType));
                n.enforceValidDirectory;
                return TypedValue(n, t);
            }
        },
        (CommandInputRecordSchema s) {
            enforce(n.type == NodeType.mapping, new TypeConflicts("TODO: guess type", type, n.guessedType));
            // bindType for each field
            return TypedValue(n, s);
        },
        (CommandInputEnumSchema s) {
            enforce(n.type == NodeType.string, new TypeConflicts("TODO: guess type", type, n.guessedType));
            // enum or string?
            return TypedValue(n, s);
        },
        (CommandInputArraySchema s) {
            enforce(n.type == NodeType.sequence, new TypeConflicts("TODO: guess type", type, n.guessedType));
            // bindType for each elem
            return TypedValue(n, s);
        },
        (string s) {
            if (s == "Any")
            {
                throw new Exception("TODO: guess type");
            }
            else
            {
                auto def = *enforce(s in defMap);
                return n.bindType(def, defMap);
            }
        },
        (Either!(
            CWLType,
            CommandInputRecordSchema,
            CommandInputEnumSchema,
            CommandInputArraySchema,
            string,
        )[] union_) {
            import salad.type : None, tryMatch;
            import std.algorithm : find, map;
            auto rng = union_.map!((t) {
                import salad.type : Optional;
                try
                {
                    return Optional!TypedValue(n.bindType(t.match!(a => DeclaredType(a)), defMap));
                }
                catch (TypeException e)
                {
                    return Optional!TypedValue.init;
                }
            }).find!(t => t.match!((None _) => false, another => true));
            enforce(rng.empty);
            return rng.front.tryMatch!((TypedValue v) => v);
        },
    );
}

auto guessedType(Node val) @safe
{
    import dyaml : NodeType;

    switch(val.type)
    {
    case NodeType.null_:
        return DeterminedType(new CWLType(Node("null")));
    case NodeType.boolean:
        return DeterminedType(new CWLType(Node("boolean")));
    case NodeType.integer:
        return DeterminedType(new CWLType(Node("long")));
    case NodeType.decimal:
        return DeterminedType(new CWLType(Node("double")));
    case NodeType.string:
        return DeterminedType(new CWLType(Node("string")));
    case NodeType.mapping:
        if (auto class_ = "class" in val)
        {
            if (*class_ == "File" || *class_ == "Directory")
            {
                return DeterminedType(new CWLType(Node(*class_)));
            }
        }
        auto record = new CommandInputRecordSchema;
        // TODO
        return DeterminedType(record);
    case NodeType.sequence:
        import std.algorithm : map;
        import std.array : array;
        auto seq = new CommandInputArraySchema;
        // seq.items_ = val.sequence
        //                 .map!(e => guessType(e))
        //                 // .uniq
        //                 // .map!toItemType
        //                 .array;
        return DeterminedType(seq);
    default:
        assert(false);
    }
}

///
unittest
{
    import salad.type : tryMatch;

    auto type = new CWLType(Node("int"));
    auto val = Node(10);
    auto bound = val.bindType(DeclaredType(type), (DeclaredType[string]).init);
    assert(bound.type.tryMatch!((CWLType t) => t.value_ == "int"));
}

///
auto enforceValidFile(ref Node node)
in(node.type == NodeType.mapping)
{
    import std.exception : enforce;

    auto f = new File(node);
    enforce(f.isValidFile);
    //f.lowered; // TODO

    return node; /// ?
}

///
bool isValidFile(File file)
{
    import salad.type : match, None;
    import std.algorithm : canFind;
    import std.file : exists;

    match!(
        (None _1, None _2) => file.contents_.match!(
            (string s) => s.length <= 64*2^^10,
            none => false,
        ),
        (string path, string loc) => true, // TODO
        (string path, None _) => path.exists, // TODO: resolve relative path
        (None _, string loc) {
            /+
            import salad.resolver : scheme;
            auto sch = loc.scheme;
            if (sch.empty)
            {
                sch = "file";
            }
            if (sch == "file")
            {
                return loc.path.exists;
            }
            else
            {
                return sch.empty || Fetcher.instance.canSupport(sch);
            }+/
            return true;
        },
    )(file.path_, file.location_);

    file.basename_.match!(
        (string s) => !s.canFind("/"),
        _ => true,
    );

    // TODO: how to deal with dirname, nameroot, nameext
    // skip checksum and size

    import std.algorithm : all;

    file.secondaryFiles_.match!(
        (Either!(File, Directory)[] files) => files.all!(
            ff => ff.match!(
                (File f) => f.isValidFile,
                (Directory d) => d.isValidDirectory,
            )
        ),
        _ => true,
    );

    return true;
}

///
auto enforceValidDirectory(ref Node node)
in(node.type == NodeType.mapping)
{
    return node;
}

/** 
 * Returns: true if a given `node` is a valid Directory object or false otherwise
 */
bool isValidDirectory(Directory directory)
{
    return true;
}

///
bool isValidRecord(RecordSchema)(
    in Node node, RecordSchema schema,
    Either!(InputRecordSchema, InputEnumSchema, InputArraySchema)[string] defMap
)
{
    import dyaml : NodeType;
    import salad.type : match, None;
    import std.algorithm : all;

    return node.type == NodeType.mapping &&
        schema.fields_.match!(
            (None _) => true,
            fs => fs.all!(f => f.name_ in node && node[f.name_].isValidParameter(f.type_, defMap)),
        );
}

///
bool isValidEnum(EnumSchema)(in Node node, EnumSchema schema)
{
    import dyaml : NodeType;
    import std.algorithm : canFind;
    return node.type == NodeType.string && schema.symbols_.canFind(node.as!string);
}

///
bool isValidArray(ArraySchema)(
    in Node node, ArraySchema schema,
    Either!(InputRecordSchema, InputEnumSchema, InputArraySchema)[string] defMap
)
{
    import dyaml : NodeType;
    import std.algorithm : all;
    return node.type == NodeType.sequence &&
        node.sequence.all!(e => isValidParameter(e, schema.items_, defMap));
}

/// only for v1.0
CommandInputRecordSchema toCommandSchema(InputRecordSchema schema)
{
    import salad.type : match, None;
    import std.algorithm : map;
    import std.array : array;
    
    auto ret = new typeof(return);
    ret.fields_ = schema.fields_.match!(
        (None none) => typeof(ret.fields_)(none),
        fs => typeof(ret.fields_)(fs.map!toCommandField.array),
    );
    ret.label_ = schema.label_;
    ret.name_ = schema.name_;
    return ret;
}

CommandInputRecordField toCommandField(InputRecordField field)
{
    import salad.type : match;
    import std.algorithm : map;
    import std.array : array;

    alias EType = Either!(
        CWLType,
        CommandInputRecordSchema,
        CommandInputEnumSchema,
        CommandInputArraySchema,
        string,
    );

    auto ret = new typeof(return);
    ret.name_ = field.name_;
    ret.type_ = field.type_.match!(
        (Either!(
            CWLType,
            InputRecordSchema,
            InputEnumSchema,
            InputArraySchema,
            string,
        )[] union_) => typeof(ret.type_)(union_.map!(t => t.match!(
            (InputRecordSchema s) => EType(s.toCommandSchema),
            (InputEnumSchema s) => EType(s.toCommandSchema),
            (InputArraySchema s) => EType(s.toCommandSchema),
            others => EType(others),
        )).array),
        (InputRecordSchema s) => typeof(ret.type_)(s.toCommandSchema),
        (InputEnumSchema s) => typeof(ret.type_)(s.toCommandSchema),
        (InputArraySchema s) => typeof(ret.type_)(s.toCommandSchema),
        others => typeof(ret.type_)(others),
    );
    ret.doc_ = field.doc_;
    ret.inputBinding_ = field.inputBinding_;
    ret.label_ = field.label_;
    return ret;
}

/// only for v1.0
CommandInputEnumSchema toCommandSchema(InputEnumSchema schema)
{
    auto ret = new typeof(return);
    ret.symbols_ = schema.symbols_;
    ret.label_ = schema.label_;
    ret.name_ = schema.name_;
    ret.inputBinding_ = schema.inputBinding_;
    return ret;
}

/// only for v1.0
CommandInputArraySchema toCommandSchema(InputArraySchema schema)
{
    import salad.type : match;
    import std.algorithm : map;
    import std.array : array;

    alias EType = Either!(
        CWLType,
        CommandInputRecordSchema,
        CommandInputEnumSchema,
        CommandInputArraySchema,
        string,
    );

    auto ret = new typeof(return);
    ret.items_ = schema.items_.match!(
        (Either!(
            CWLType,
            InputRecordSchema,
            InputEnumSchema,
            InputArraySchema,
            string,
        )[] union_) => typeof(ret.items_)(union_.map!(t => t.match!(
            (InputRecordSchema s) => EType(s.toCommandSchema),
            (InputEnumSchema s) => EType(s.toCommandSchema),
            (InputArraySchema s) => EType(s.toCommandSchema),
            others => EType(others),
        )).array),
        (InputRecordSchema s) => typeof(ret.items_)(s.toCommandSchema),
        (InputEnumSchema s) => typeof(ret.items_)(s.toCommandSchema),
        (InputArraySchema s) => typeof(ret.items_)(s.toCommandSchema),
        others => typeof(ret.items_)(others),
    );
    ret.label_ = schema.label_;
    ret.inputBinding_ = schema.inputBinding_;
    return ret;
}
