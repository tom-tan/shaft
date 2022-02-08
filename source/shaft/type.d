/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.type;

import dyaml : Node;

import cwl.schema : InputRecordSchema, InputEnumSchema, InputArraySchema;
import salad.type : Either;

///
void enforceValidInput(InputParameter, SchemaDefRequirement)(Node param, InputParameter[] paramDefs,
                       SchemaDefRequirement defs)
{
    import dyaml : NodeType;
    import salad.type : tryMatch;
    import salad.util : edig;
    import std.algorithm : map;
    import std.exception : enforce;
    import std.range : assocArray;
    import std.typecons : tuple;

    enforce(param.type == NodeType.mapping, "Input should be a mapping but it is not");

    Either!(InputRecordSchema, InputEnumSchema, InputArraySchema)[string] defMap;
    if (defs !is null)
    {
        defMap = defs.types_
                     .map!(d => tuple(d.tryMatch!(t => t.edig!("name", string)), d))
                     .assocArray;
    }

    foreach(p; paramDefs)
    {
        import cwl : Any;
        import salad.util : dig;

        auto id = p.id_;
        Node n;
        if (auto val = id in param)
        {
            n = *val;
        }
        else if (auto def = p.dig!(["inputBinding", "default"], Any))
        {
            n = def.value_;
        }
        else
        {
            import std.format : format;
            throw new Exception(format!"missing input parameter `%s`"(id));
        }
        enforce(isValidParameter(n, p.type_, defMap));
    }
}

/** 
 * Returns: true if a given `node` is valid value of type `type` or false otherwise
 */
bool isValidParameter(Type)(
    Node n, Type type, Either!(InputRecordSchema, InputEnumSchema, InputArraySchema)[string] defMap
)
{
    import dyaml : NodeType;
    import salad.type : match, tryMatch;
 
    template matchFuns(funs...)
    {
        import std.meta : AliasSeq, Filter, templateAnd, templateNot;
        import std.traits : isArray, isSomeString;

        alias isArrayType = templateAnd!(isArray, templateNot!isSomeString);
        alias ArrayTypes = Filter!(isArrayType, Type.Types);
        static if (ArrayTypes.length > 0)
        {
            import std.algorithm : any;

            static assert(ArrayTypes.length == 1);

            alias matchFuns = AliasSeq!(
                funs,
                (ArrayTypes[0] union_) => union_.any!(t => n.isValidParameter(t, defMap)),
                _ => false,
            );
        }
        else
        {
            alias matchFuns = AliasSeq!(
                funs,
                _ => false,
            );
        }
    }

    switch(n.type)
    {
    case NodeType.boolean:
        import cwl.schema : CWLType;
        return type.match!(
            matchFuns!(
                (CWLType t) => t.type_ == CWLType.Symbols.boolean_
            ),
        );
    case NodeType.integer:
        import cwl.schema : CWLType;
        return type.match!(
            matchFuns!(
                (CWLType t) => t.type_ == CWLType.Symbols.int_ ||
                               t.type_ == CWLType.Symbols.long_
            ),
        );
    case NodeType.decimal:
        import cwl.schema : CWLType;
        return type.match!(
            matchFuns!(
                (CWLType t) => t.type_ == CWLType.Symbols.float_ ||
                               t.type_ == CWLType.Symbols.double_
            ),
        );
    case NodeType.string:
        import cwl.schema : CWLType, CommandInputEnumSchema, InputEnumSchema;
        import std.meta : Filter;

        enum isCommandInputEnumSchema(T) = is(T == CommandInputEnumSchema);
        static if (Filter!(isCommandInputEnumSchema, Type.Types).length > 0)
        {
            alias EnumDecl = (CommandInputEnumSchema s) => n.isValidEnum(s);
        }
        else
        {
            alias EnumDecl = (InputEnumSchema s) => n.isValidEnum(s);
        }
        return type.match!(
            matchFuns!(
                (CWLType t) => t.type_ == CWLType.Symbols.string_,
                // TODO: MatchException
                (string s) => s in defMap && n.isValidEnum(defMap[s].tryMatch!((InputEnumSchema s) => s)),
                EnumDecl,
            ),
        );
    case NodeType.mapping:
        import cwl.schema : CWLType, CommandInputRecordSchema, InputRecordSchema;
        import std.meta : Filter;

        enum isCommandInputRecordSchema(T) = is(T == CommandInputRecordSchema);
        static if (Filter!(isCommandInputRecordSchema, Type.Types).length > 0)
        {
            alias RecordDecl = (CommandInputRecordSchema s) => n.isValidRecord(s, defMap);
        }
        else
        {
            alias RecordDecl = (InputRecordSchema s) => n.isValidRecord(s, defMap);
        }
        return type.match!(
            matchFuns!(
                (CWLType t) => (t.type_ == CWLType.Symbols.File_ && n.isValidFile) ||
                               (t.type_ == CWLType.Symbols.Directory_ && n.isValidDirectory),
                // TODO: MatchException
                (string s) => s in defMap && n.isValidRecord(defMap[s].tryMatch!((InputRecordSchema s) => s), defMap),
                RecordDecl,
            ),
        );
    case NodeType.sequence:
        import cwl.schema : CommandInputArraySchema, InputArraySchema;
        import std.algorithm : all;
        import std.meta : Filter;

        enum isCommandInputArraySchema(T) = is(T == CommandInputArraySchema);
        static if (Filter!(isCommandInputArraySchema, Type.Types).length > 0)
        {
            alias ArrayDecl = (CommandInputArraySchema s) => n.isValidArray(s, defMap);
        }
        else
        {
            alias ArrayDecl = (InputArraySchema s) => n.isValidArray(s, defMap);
        }
        return type.match!(
            matchFuns!(
                // TODO: MatchException
                (string s) => s in defMap && n.isValidArray(defMap[s].tryMatch!((InputArraySchema s) => s), defMap),
                ArrayDecl,
            ),
        );
    default:
        return false;
    }
    /*
    v1.0: CWLType | CommandInputRecordSchema | CommandInputEnumSchema | CommandInputArraySchema | string | array<CWLType | CommandInputRecordSchema | CommandInputEnumSchema | CommandInputArraySchema | string>
    v1.2: CWLType | stdin | CommandInputRecordSchema | CommandInputEnumSchema | CommandInputArraySchema | string | array<CWLType | CommandInputRecordSchema | CommandInputEnumSchema | CommandInputArraySchema | string>
    */
}

/** 
 * Returns: true if a given `node` is a valid File object or false otherwise
 */
bool isValidFile(in Node node)
{
    import dyaml : NodeType;

    if (node.type != NodeType.mapping)
    {
        return false;
    }

    if ("class" !in node || node["class"] != "File")
    {
        return false;
    }

    if ("location" in node && node["location"].type == NodeType.string)
    {
        // TODO: valid URI supported by fetchers
    }
    else if ("path" in node && node["path"].type == NodeType.string)
    {
        // TODO: valid local path
    }
    else if ("contents" !in node)
    {
        return false;
    }

    if (auto sf = "secondaryFiles" in node)
    {
        if (sf.type == NodeType.null_)
        {
            // equivalent that "secondaryFiles" is not provided
        }
        else if (sf.type == NodeType.sequence)
        {
            import std.algorithm : any;

            if (sf.sequence.any!(e => !e.isValidFile && !e.isValidDirectory))
            {
                return false;
            }
        }
        else
        {
            return false;
        }
    }
    return true;
}

/** 
 * Returns: true if a given `node` is a valid Directory object or false otherwise
 */
bool isValidDirectory(in Node node)
{
    import dyaml : NodeType;

    if (node.type != NodeType.mapping)
    {
        return false;
    }

    if ("class" !in node || node["class"] != "Directory")
    {
        return false;
    }

    if ("location" in node && node["location"].type == NodeType.string)
    {
        // TODO: valid URI supported by fetchers
    }
    else if ("path" in node && node["path"].type == NodeType.string)
    {
        // TODO: valid local path
    }

    if (auto lst = "listing" in node)
    {
        if (lst.type == NodeType.null_)
        {
            // equivalent that "listing" is not provided
        }
        else if (lst.type == NodeType.sequence)
        {
            import std.algorithm : any;

            if (lst.sequence.any!(e => !e.isValidFile && !e.isValidDirectory))
            {
                return false;
            }
        }
        else
        {
            return false;
        }
    }
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
