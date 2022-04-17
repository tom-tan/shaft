/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.type.input;

import dyaml : Node, NodeType;

import cwl.v1_0.schema;
import salad.type : Either, Optional, This;
import shaft.type.common : DeterminedType, TypedParameters, TypedValue, TypeException;
import shaft.type.common : TC_ = TypeConflicts;

import std.typecons : Flag, Tuple, Yes;

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

string toStr(DeclaredType dt) pure @safe
{
    import salad.type : match, orElse;

    import std.algorithm : map;
    import std.array : array;
    import std.format : format;
    import std.meta : AliasSeq;

    alias funs = AliasSeq!(
        (CWLType t) => cast(string)t.value_,
        (CommandInputRecordSchema s) => 
            s.name_.orElse(format!"Record(%-(%s, %))"(s.fields_
                                                      .orElse([])
                                                      .map!(f => f.name_~": "~toStr(f.type_)).array)),
        (CommandInputEnumSchema s) => s.name_.orElse("enum"),
        (CommandInputArraySchema s) => "array",
        (string s) => s,
    );

    return dt.match!(
        funs,
        (Either!(
            CWLType,
            CommandInputRecordSchema,
            CommandInputEnumSchema,
            CommandInputArraySchema,
            string
        )[] un) => format!"(%-(%s|%))"(un.map!(e => e.match!funs).array),
    );
}

alias TypeConflicts = TC_!(DeclaredType, toStr);

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
    import shaft.type.common : toJSONNode;
    import std.algorithm : map;
    import std.container.rbtree : redBlackTree;
    import std.exception : enforce;
    import std.typecons : tuple, Tuple;

    DeclaredType[string] defMap;
    if (defs !is null)
    {
        import salad.type : match;
        import salad.util : edig;
        import std.algorithm : map;
        import std.range : assocArray;

        defMap = () @trusted {
            return defs.types_
                       .map!(d => d.match!(t => tuple(t.edig!("name", string),
                                                      DeclaredType(t.toCommandSchema))))
                       .assocArray;
        }();
    }

    auto rest = redBlackTree(params.mappingKeys.map!(a => a.as!string));

    auto retNode = Node((Node[string]).init);
    DeterminedType[string] types;
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
            (None _) { // v1.0 only
                // See_Also: https://www.commonwl.org/v1.1/CommandLineTool.html#Changelog
                // > Fixed schema error where the `type` field inside the `inputs` and `outputs` field was incorrectly listed as optional.
                import std.format : format;
                enforce(false, format!"`type` field is missing in `%s` input parameter"(id));
                return DeclaredType("Any");
            },
            others => DeclaredType(others),
        );

        TypedValue v;
        try
        {
            v = n.bindType(type, defMap);
        }
        catch(TypeConflicts e)
        {
            throw new TypeConflicts(e.expected_, e.actual_, id);
        }
        types[id] = v.type;
        retNode.add(id.toJSONNode, v.value);
        rest.removeKey(id);
    }

    if (!rest.empty)
    {
        import std.array : array;
        // must not be permanent failure
        // See_Also: conformance test #2
        // warning: Input parameters contain undeclared parameters: rest.array
    }
    return typeof(return)(retNode.toJSONNode, types);
}

///
TypedValue bindType(ref Node n, DeclaredType type, DeclaredType[string] defMap, Flag!"declared" declared = Yes.declared)
{
    import salad.type : match;
    import shaft.type.common : guessedType, toJSONNode;
    import std.exception : enforce;

    return type.match!(
        (CWLType t) {
            import salad.type : None;
            final switch(t.value_)
            {
            case "null":
                enforce(n.type == NodeType.null_, new TypeConflicts(type, n.guessedType));
                return TypedValue(n, t);
            case "boolean":
                enforce(n.type == NodeType.boolean, new TypeConflicts(type, n.guessedType));
                return TypedValue(n, t);
            case "int", "long":
                enforce(n.type == NodeType.integer, new TypeConflicts(type, n.guessedType));
                return TypedValue(n, t);
            case "float", "double":
                enforce(n.type == NodeType.decimal, new TypeConflicts(type, n.guessedType));
                return TypedValue(n, t);
            case "string":
                enforce(n.type == NodeType.string, new TypeConflicts(type, n.guessedType));
                return TypedValue(n, t);
            case "File":
                import shaft.file : enforceValid, toURIFile;
                import std.path : dirName;
                enforce(n.type == NodeType.mapping, new TypeConflicts(type, n.guessedType));

                auto file = new File(n);
                file.enforceValid;
                file = file.toURIFile(n.startMark.name.dirName);
                return TypedValue(file.toJSONNode, t);
            case "Directory":
                import shaft.file : enforceValid, toURIDirectory;
                import std.path : dirName;
                enforce(n.type == NodeType.mapping, new TypeConflicts(type, n.guessedType));

                auto dir = new Directory(n);
                dir.enforceValid;
                dir = dir.toURIDirectory(n.startMark.name.dirName);
                return TypedValue(dir.toJSONNode, t);
            }
        },
        (CommandInputRecordSchema s) {
            import salad.type : orElse;
            import shaft.type.common : RecordType;
            import std.algorithm : fold, map;
            enforce(n.type == NodeType.mapping, new TypeConflicts(type, n.guessedType));

            auto tv = s.fields_
                       .orElse([])
                       .map!((f) {
                           import std.typecons : tuple;
                           auto name = f.name_;
                           auto dt = n[name].bindType(f.type_, defMap, declared);
                           return tuple(name, dt.type, dt.value, f.inputBinding_);
                       })
                       .fold!(
                           (acc, e) { acc.add(e[0].toJSONNode, e[2]); return acc; },
                           (acc, e) {
                               import std.typecons : tuple;
                               acc[e[0]] = tuple(&e[1], e[3]);
                               return acc;
                           },
                       )(Node((Node[string]).init), (Tuple!(DeterminedType*, Optional!CommandLineBinding)[string]).init);
            return TypedValue(tv[0], RecordType(s.name_.orElse(""), tv[1]));
        },
        (CommandInputEnumSchema s) {
            import salad.type : orElse;
            import shaft.type.common : EnumType;
            import std.algorithm : canFind;
            enforce(n.type == NodeType.string, new TypeConflicts(type, n.guessedType));
            enforce(s.symbols_.canFind(n.as!string), new TypeConflicts(type, n.guessedType));
            return TypedValue(n, EnumType(s.name_.orElse(""), s.inputBinding_));
        },
        (CommandInputArraySchema s) {
            import shaft.type.common : ArrayType;
            import std.algorithm : fold, map;
            enforce(n.type == NodeType.sequence, new TypeConflicts(type, n.guessedType));

            auto tvals = n.sequence
                          .map!(e => e.bindType(s.items_, defMap, declared))
                          .fold!(
                              (acc, e) { acc.add(e.value); return acc; },
                              (acc, e) @trusted {
                                  import std.algorithm : moveEmplace;
                                  auto dt = new DeterminedType;
                                  moveEmplace(e.type, *dt);
                                  return acc ~ dt;
                              },
                          )(Node((Node[]).init), (DeterminedType*[]).init);
            return TypedValue(tvals[0].toJSONNode, ArrayType(tvals[1], s.inputBinding_));
        },
        (string s) {
            if (s == "Any")
            {
                import salad.type : tryMatch;
                import shaft.type.common : ArrayType, RecordType;
                import std.typecons : No;

                return n.guessedType.tryMatch!(
                    (CWLType t) {
                        enforce(t.value_ != "null" || declared == No.declared,
                                new TypeConflicts(type, n.guessedType));
                        return n.bindType(DeclaredType(t), defMap);
                    },
                    (ArrayType _) {
                        assert(n.type == NodeType.sequence);
                        auto schema = new CommandInputArraySchema;
                        schema.items_ = "Any";
                        return n.bindType(DeclaredType(schema), defMap, No.declared);
                    },
                    (RecordType r) {
                        import std.algorithm : map;
                        import std.array : array;

                        assert(n.type == NodeType.mapping);
                        auto schema = new CommandInputRecordSchema;
                        schema.fields_ = r.fields.byKey.map!((k) {
                            auto fschema = new CommandInputRecordField;
                            fschema.name_ = k;
                            fschema.type_ = "Any";
                            return fschema;
                        }).array;
                        return n.bindType(DeclaredType(schema), defMap, No.declared);
                    },
                );
            }
            else
            {
                auto def = *enforce(s in defMap, new TypeConflicts(type, n.guessedType));
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
            }).find!(t => t.match!((TypedValue _) => true, none => false));
            enforce(!rng.empty, new TypeConflicts(type, n.guessedType));
            return rng.front.tryMatch!((TypedValue v) => v);
        },
    );
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
