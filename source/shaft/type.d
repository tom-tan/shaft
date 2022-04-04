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

///
alias TypedParameters = Tuple!(Node, "parameters", DeterminedType[string], "types");

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
        import salad.type : match;

        auto ex = expected.match!(
            (CWLType t) => cast(string)t.value_,
            other => other.stringof,
        );
        auto ac = actual.match!(
            (CWLType t) => cast(string)t.value_,
            other => other.stringof,
        );

        super(format!"Type conflicts for `%s` (expected: `%s`, actual: `%s`)"(id, ex, ac));
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
        else if (auto def = p.dig!("default", Any))
        {
            n = def.value_;
        }
        else
        {
            import dyaml : YAMLNull;
            n = Node(YAMLNull());
        }

        auto type = p.type_.match!(
            (None _) => DeclaredType("Any"), // v1.0 only: assumes Any, TODO: check corresponding conformance test
            (string s) => defMap[s], // TODO
            others => DeclaredType(others),
        );

        TypedValue v;
        try
        {
            v = n.bindType(type, defMap);
        }
        catch(TypeConflicts e)
        {
            throw new TypeConflicts(id, e.expected_, e.actual_);
        }
        retTuple ~= tuple(id, v.type);
        retNode.add(id.toJSONNode, v.value);
    }
    // TODO: reject undeclared parameters
    auto types = () @trusted { return retTuple.assocArray; }();
    return typeof(return)(retNode.toJSONNode, types);
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
            case "string":
                enforce(n.type == NodeType.string, new TypeConflicts("TODO: guess type", type, n.guessedType));
                return TypedValue(n, t);
            case "File":
                import std.path : dirName;
                enforce(n.type == NodeType.mapping, new TypeConflicts("TODO: guess type", type, n.guessedType));

                auto file = new File(n);
                file.enforceValid;
                file = file.canonicalForm(n.startMark.name.dirName);
                return TypedValue(file.toJSONNode, t);
            case "Directory":
                import std.path : dirName;
                enforce(n.type == NodeType.mapping, new TypeConflicts("TODO: guess type", type, n.guessedType));

                auto dir = new Directory(n);
                dir.enforceValid;
                dir = dir.canonicalForm(n.startMark.name.dirName);
                return TypedValue(dir.toJSONNode, t);
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
            import std.algorithm : fold, map;
            import std.array : array;
            enforce(n.type == NodeType.sequence, new TypeConflicts("TODO: guess type", type, n.guessedType));
            auto tvals = n.sequence
                          .map!(e => e.bindType(s.items_, defMap)).array
                          .fold!(
                              (acc, e) { acc.add(e.value); return acc; },
                              (acc, e) => acc ~ e.type,
                          )(Node.init, (DeterminedType[]).init);
            // bindType for each elem
            return TypedValue(tvals[0].toJSONNode, s);
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

///
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

    auto type = new CWLType("int");
    auto val = Node(10);
    auto bound = val.bindType(DeclaredType(type), (DeclaredType[string]).init);
    assert(bound.type.tryMatch!((CWLType t) => t.value_ == "int"));
}

/**
 * Throws: Exception if some fields are not valid
 */
void enforceValid(File file) pure
{
    import salad.type : match, None, tryMatch;
    import std.ascii : isHexDigit;
    import std.algorithm : all, canFind, each, endsWith, startsWith;
    import std.exception : enforce;

    match!(
        (None _1, None _2) => file.contents_.match!(
            (string s) => enforce(s.length <= 64*2^^10, "too large `contents` field"),
            none => enforce(false),
        ),
        (None _, string loc) => enforce(file.contents_.tryMatch!((None _) => true),
                                        "`location` and `contents` fields are exclusive"),
        (string path, None _) => enforce(file.contents_.tryMatch!((None _) => true),
                                         "`path` and `contents` fields are exclusive"),
        (string path, string loc) => enforce(loc.endsWith(path),
                                             "`path` and `location` have inconsistent values"), // TODO
    )(file.path_, file.location_);

    file.basename_.match!(
        (string s) => enforce(!s.canFind("/"), "basename must not include `/`"),
        _ => true,
    );

    // file.checksum_.match!(
    //     (string checksum) => enforce(checksum.startsWith("sha1$") && checksum[5..$].all!isHexDigit,
    //                                  "Invalid checksum: "~checksum),
    //     _ => true,
    // );

    // file.size_.match!(
    //     (long s) => enforce(s >= 0, "file size must be zero or positive"),
    //     _ => true,
    // );

    file.secondaryFiles_.match!(
        (Either!(File, Directory)[] files) => files.each!(
            ff => ff.match!(
                (File f) => f.enforceValid,
                (Directory d) => d.enforceValid,
            )
        ),
        _ => true,
    );
    // TODO: how to deal with dirname, nameroot, nameext, and format
}

///
auto absoluteURI(string pathOrURI, string base) nothrow pure @safe
{
    import salad.resolver : isAbsoluteURI;
    import std.path : isAbsolute;

    if (pathOrURI.isAbsoluteURI)
    {
        return pathOrURI;
    }
    else if (pathOrURI.isAbsolute)
    {
        return pathOrURI;
    }
    else if (base.isAbsolute)
    {
        import std.exception : assumeUnique, assumeWontThrow;
        import std.path : absolutePath, asNormalizedPath;
        import std.array : array;
        auto absPath = pathOrURI.absolutePath(base)
                                .assumeWontThrow
                                .asNormalizedPath
                                .array;
        return "file://"~(() @trusted => absPath.assumeUnique)();
    }
    else
    {
        import salad.resolver : scheme;

        assert(base.isAbsoluteURI);
        auto sc = base.scheme; // assumes `base` starts with `$sc://`
        auto abs = pathOrURI.absoluteURI(base[sc.length+2..$]);
        return sc~abs[4..$];
    }
}

/**
 * Returns: File object
 */
File canonicalForm(File file, string baseURI)
{
    import salad.type : match, None, Optional, tryMatch;
    import std.algorithm : map;
    import std.array : array;
    import std.path : baseName, dirName, extension, stripExtension;

    alias OStr = Optional!string;

    auto ret = new File;
    ret.location_ = match!(
        (None _1, None _2) => OStr.init,
        (None _, string loc) => OStr(loc.absoluteURI(baseURI)),
        (string path, None _) => OStr(path.absoluteURI(baseURI)), // TODO
        (string path, string loc) => OStr(loc.absoluteURI(baseURI)),
    )(file.path_, file.location_);

    ret.basename_ = file.basename_.match!(
        (string name) => name,
        _ => ret.location_.tryMatch!((string s) => s.baseName),
    );

    // ret.dirname_ = file.dirname_.match!(
    //     (string name) => name,
    //     _ => ret.location_.tryMatch!((string s) => s.dirName),
    // );
    // ret.nameroot_ = file.nameroot_.match!(
    //     (string root) => root,
    //     _ => ret.basename_.tryMatch!((string s) => s.stripExtension),
    // );
    // ret.nameext_ = file.nameext_.match!(
    //     (string ext) => ext,
    //     _ => ret.basename_.tryMatch!((string s) => s.extension),
    // );

    // ret.checksum_ = file.checksum_; // TODO
    // ret.size_ = file.size_; // TODO

    ret.secondaryFiles_ = file.secondaryFiles_.match!(
        (Either!(File, Directory)[] ff) => typeof(ret.secondaryFiles_)(ff.map!(f => f.match!(
            (File f) => Either!(File, Directory)(f.canonicalForm(baseURI)),
            (Directory dir) => Either!(File, Directory)(dir.canonicalForm(baseURI)),
        )).array),
        _ => typeof(ret.secondaryFiles_).init,
    );
    
    ret.format_ = file.format_;
    ret.contents_ = file.contents_;

    return ret;
}

/**
 * Throws: Exception if some fields are not valid
 */
void enforceValid(Directory dir) pure
{
}

/// TODO
Directory canonicalForm(Directory dir, string baseURI)
{
    return dir;
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
