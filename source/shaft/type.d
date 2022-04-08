/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.type;

import dyaml : Node, NodeType;

import cwl.v1_0.schema;
import salad.type : Either, Optional, This;

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
alias EnumType = Tuple!(string, "name", Optional!CommandLineBinding, "inputBinding");

///
alias DeterminedType = Either!(
    CWLType,
    EnumType,
    Tuple!(This*[], "types", Optional!CommandLineBinding, "inputBinding"),
    Tuple!(string, "name", This*[string], "fields"),
);

///
alias ArrayType = Tuple!(DeterminedType*[], "types", Optional!CommandLineBinding, "inputBinding");

///
alias RecordType = Tuple!(string, "name", DeterminedType*[string], "fields");

///
alias TypedParameters = Tuple!(Node, "parameters", DeterminedType[string], "types");

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
    this(string id, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure @safe
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
         string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure @trusted
    {
        import std.format : format;
        import salad.type : match;

        auto ex = expected.match!(
            (CWLType t) => cast(string)t.value_,
            other => other.stringof,
        );
        auto ac = actual.match!(
            (CWLType t) => cast(string)t.value_,
            (ArrayType arr) => "Array[]",
            other => other.name.length == 0 ? other.stringof : other.name,
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
            import salad.type : None;
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
            import std.algorithm : fold, map;
            enforce(n.type == NodeType.mapping, new TypeConflicts("TODO: guess type", type, n.guessedType));

            auto tv = s.fields_
                       .match!(
                           (CommandInputRecordField[] fs) => fs,
                           _ => (CommandInputRecordField[]).init,
                       )
                       .map!((f) {
                           import std.typecons : tuple;
                           auto name = f.name_;
                           auto dt = n[name].bindType(f.type_, defMap);
                           return tuple(name, dt.type, dt.value);
                       })
                       .fold!(
                           (acc, e) { acc.add(e[0].toJSONNode, e[2]); return acc; },
                           (acc, e) {
                               acc[e[0]] = &e[1];
                               return acc;
                           },
                       )(Node.init, (DeterminedType*[string]).init);
            return TypedValue(tv[0], RecordType(s.name_.match!((string n) => n, _ => ""), tv[1]));
        },
        (CommandInputEnumSchema s) {
            import std.algorithm : canFind;
            enforce(n.type == NodeType.string, new TypeConflicts("TODO: guess type", type, n.guessedType));
            enforce(s.symbols_.canFind(n.as!string));
            return TypedValue(n, EnumType(s.name_.match!((string n) => n, _ => ""), s.inputBinding_));
        },
        (CommandInputArraySchema s) {
            import std.algorithm : fold, map;
            enforce(n.type == NodeType.sequence, new TypeConflicts("TODO: guess type", type, n.guessedType));

            auto tvals = n.sequence
                          .map!(e => e.bindType(s.items_, defMap))
                          .fold!(
                              (acc, e) { acc.add(e.value); return acc; },
                              (acc, e) @trusted {
                                  import std.algorithm : moveEmplace;
                                  auto dt = new DeterminedType;
                                  moveEmplace(e.type, *dt);
                                  return acc ~ dt;
                              },
                          )(Node.init, (DeterminedType*[]).init);
            return TypedValue(tvals[0].toJSONNode, ArrayType(tvals[1], s.inputBinding_));
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
                         auto t = guessedType(e.value);
                         auto dt = new DeterminedType;
                         moveEmplace(t, *dt);
                         acc[e.key.as!string] = dt;
                         return acc;
                     })((DeterminedType*[string]).init);
        return DeterminedType(RecordType("", ts));
    case NodeType.sequence:
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
void enforceValid(File file) pure @safe
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

/**
 * It canonicalizes a given File object. A canonicalized File object can be:
 * - a file literal, or
 * - a File object that has only `location` to show an absolute URI, `basename`,
 *   `secondaryFiles` (optional) and `format`.
 *
 * Returns: A canonicalized File object
 */
File canonicalForm(File file, string baseURI)
{
    import salad.resolver : absoluteURI;
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
void enforceValid(Directory dir) pure @safe
{
}

/// TODO
Directory canonicalForm(Directory dir, string baseURI)
{
    return dir;
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
CommandInputEnumSchema toCommandSchema(InputEnumSchema schema) nothrow pure
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
