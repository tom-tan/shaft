
/* Copyright (C) 1991-2020 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <https://www.gnu.org/licenses/>.  */




/* This header is separate from features.h so that the compiler can
   include it implicitly at the start of every compilation.  It must
   not itself include <features.h> or any other header that includes
   <features.h> because the implicit include comes before any feature
   test macros that may be defined in a source file before it first
   explicitly includes a system header.  GCC knows the name of this
   header in order to preinclude it.  */

/* glibc's intent is to support the IEC 559 math functionality, real
   and complex.  If the GCC (4.9 and later) predefined macros
   specifying compiler intent are available, use them to determine
   whether the overall intent is to support these features; otherwise,
   presume an older compiler has intent to support these features and
   define these macros by default.  */
/* wchar_t uses Unicode 10.0.0.  Version 10.0 of the Unicode Standard is
   synchronized with ISO/IEC 10646:2017, fifth edition, plus
   the following additions from Amendment 1 to the fifth edition:
   - 56 emoji characters
   - 285 hentaigana
   - 3 additional Zanabazar Square characters */

module shaft.evaluator.engine.embedded;


        import core.stdc.config;
        import core.stdc.stdarg: va_list;
        static import core.simd;
        static import std.conv;

        struct Int128 { long lower; long upper; }
        struct UInt128 { ulong lower; ulong upper; }

        struct __locale_data { int dummy; } // FIXME



alias _Bool = bool;
struct dpp {
    static struct Opaque(int N) {
        void[N] bytes;
    }
    // Replacement for the gcc/clang intrinsic
    static bool isEmpty(T)() {
        return T.tupleof.length == 0;
    }
    static struct Move(T) {
        T* ptr;
    }
    // dmd bug causes a crash if T is passed by value.
    // Works fine with ldc.
    static auto move(T)(ref T value) {
        return Move!T(&value);
    }
    mixin template EnumD(string name, T, string prefix) if(is(T == enum)) {
        private static string _memberMixinStr(string member) {
            import std.conv: text;
            import std.array: replace;
            return text(` `, member.replace(prefix, ""), ` = `, T.stringof, `.`, member, `,`);
        }
        private static string _enumMixinStr() {
            import std.array: join;
            string[] ret;
            ret ~= "enum " ~ name ~ "{";
            static foreach(member; __traits(allMembers, T)) {
                ret ~= _memberMixinStr(member);
            }
            ret ~= "}";
            return ret.join("\n");
        }
        mixin(_enumMixinStr());
    }
}

extern(C)
{

    alias njs_index_t = c_ulong;

    alias njs_vm_t = njs_vm_s;

    struct njs_vm_s
    {

        njs_value_s retval;

        njs_arr_t* paths;

        njs_arr_t* protos;

        njs_arr_t* scope_absolute;

        njs_value_s**[4] levels;

        c_ulong global_items;

        void* external;

        njs_native_frame_s* top_frame;

        njs_frame_s* active_frame;

        njs_rbtree_t* variables_hash;

        njs_lvlhsh_t keywords_hash;

        njs_lvlhsh_t values_hash;

        njs_arr_t* modules;

        njs_lvlhsh_t modules_hash;

        uint event_id;

        njs_lvlhsh_t events_hash;

        njs_queue_t posted_events;

        njs_queue_t promise_events;

        njs_vm_opt_t options;

        njs_object_prototype_t[38] prototypes;

        njs_function_s[38] constructors;

        njs_function_s*[1] hooks;

        njs_mp_s* mem_pool;

        ubyte* start;

        c_ulong stack_size;

        njs_vm_shared_s* shared_;

        void* regex_generic_ctx;

        void* regex_compile_ctx;

        void* single_match_data;

        njs_array_s* promise_reason;

        njs_parser_scope_s* global_scope;

        njs_object_s memory_error_object;

        njs_object_s string_object;

        njs_object_s global_object;

        njs_value_s global_value;

        njs_arr_t* codes;

        njs_arr_t* functions_name_cache;

        njs_trace_s trace;

        njs_random_t random;

        njs_rbtree_t global_symbols;

        c_ulong symbol_generator;
    }

    alias njs_mod_t = njs_mod_s;

    struct njs_mod_s
    {

        njs_str_t name;

        njs_value_s value;

        c_ulong index;

        njs_function_s function_;
    }

    alias njs_value_t = njs_value_s;

    union njs_value_s
    {
        import std.bitmanip: bitfields;

        align(4):

        static struct _Anonymous_0
        {
            import std.bitmanip: bitfields;

            align(4):
            mixin(bitfields!(

                njs_value_type_t, "type", 8,
            ));

            ubyte truth;

            ushort magic16;

            uint magic32;

            static union _Anonymous_1
            {

                double number;

                njs_object_s* object;

                njs_array_s* array;

                njs_array_buffer_s* array_buffer;

                njs_typed_array_s* typed_array;

                njs_typed_array_s* data_view;

                njs_object_value_s* object_value;

                njs_function_s* function_;

                njs_function_lambda_s* lambda;

                njs_regexp_s* regexp;

                njs_date_s* date;

                njs_object_value_s* promise;

                int function(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) prop_handler;

                njs_value_s* value;

                void* data;
            }

            _Anonymous_1 u;
        }

        _Anonymous_0 data;

        static struct _Anonymous_2
        {
            import std.bitmanip: bitfields;

            align(4):
            mixin(bitfields!(

                njs_value_type_t, "type", 8,

                ubyte, "size", 4,

                ubyte, "length", 4,
            ));

            ubyte[14] start;
        }

        _Anonymous_2 short_string;

        static struct _Anonymous_3
        {
            import std.bitmanip: bitfields;

            align(4):
            mixin(bitfields!(

                njs_value_type_t, "type", 8,
            ));

            ubyte truth;

            ubyte external;

            ubyte _spare;

            uint size;

            njs_string_s* data;
        }

        _Anonymous_3 long_string;
        mixin(bitfields!(

            njs_value_type_t, "type", 8,
        ));
    }

    alias njs_function_t = njs_function_s;

    struct njs_function_s
    {
        import std.bitmanip: bitfields;

        align(4):

        njs_object_s object;

        ubyte bound_args;
        mixin(bitfields!(

            ubyte, "args_count", 4,

            ubyte, "closure_copied", 1,

            ubyte, "native", 1,

            ubyte, "ctor", 1,

            ubyte, "global_this", 1,

            ubyte, "global", 1,
            uint, "_padding_0", 7
        ));

        ubyte magic8;

        static union _Anonymous_4
        {

            njs_function_lambda_s* lambda;

            int function(njs_vm_s*, njs_value_s*, uint, c_ulong) native;
        }

        _Anonymous_4 u;

        void* context;

        njs_value_s* bound;
    }

    alias njs_vm_shared_t = njs_vm_shared_s;

    struct njs_vm_shared_s
    {

        njs_lvlhsh_t keywords_hash;

        njs_lvlhsh_t values_hash;

        njs_lvlhsh_t array_instance_hash;

        njs_lvlhsh_t string_instance_hash;

        njs_lvlhsh_t function_instance_hash;

        njs_lvlhsh_t async_function_instance_hash;

        njs_lvlhsh_t arrow_instance_hash;

        njs_lvlhsh_t arguments_object_instance_hash;

        njs_lvlhsh_t regexp_instance_hash;

        c_ulong module_items;

        njs_lvlhsh_t modules_hash;

        njs_lvlhsh_t env_hash;

        njs_object_s string_object;

        njs_object_s[5] objects;

        njs_exotic_slots_t global_slots;

        njs_object_prototype_t[38] prototypes;

        njs_function_s[38] constructors;

        njs_regexp_pattern_s* empty_regexp_pattern;
    }

    alias njs_object_prop_t = njs_object_prop_s;

    struct njs_object_prop_s
    {
        import std.bitmanip: bitfields;

        align(4):

        njs_value_s value;

        njs_value_s name;

        njs_value_s getter;

        njs_value_s setter;
        mixin(bitfields!(

            njs_object_prop_type_t, "type", 8,

            njs_object_attribute_t, "writable", 8,

            njs_object_attribute_t, "enumerable", 8,

            njs_object_attribute_t, "configurable", 8,
        ));
    }

    alias njs_external_t = njs_external_s;

    struct njs_external_s
    {

        njs_extern_flag_t flags;

        static union _Anonymous_5
        {

            njs_str_t string_;

            uint symbol;
        }

        _Anonymous_5 name;

        uint writable;

        uint configurable;

        uint enumerable;

        static union _Anonymous_6
        {

            static struct _Anonymous_7
            {

                const(char)[15] value;

                int function(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) handler;

                ushort magic16;

                uint magic32;
            }

            _Anonymous_7 property;

            static struct _Anonymous_8
            {

                int function(njs_vm_s*, njs_value_s*, uint, c_ulong) native;

                ubyte magic8;

                ubyte ctor;
            }

            _Anonymous_8 method;

            static struct _Anonymous_9
            {

                njs_external_s* properties;

                uint nproperties;

                uint writable;

                uint configurable;

                uint enumerable;

                int function(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) prop_handler;

                uint magic32;

                int function(njs_vm_s*, njs_value_s*, njs_value_s*) keys;
            }

            _Anonymous_9 object;
        }

        _Anonymous_6 u;
    }

    struct njs_opaque_value_t
    {

        c_ulong[2] filler;
    }

    alias njs_log_level_t = _Anonymous_10;

    enum _Anonymous_10
    {

        NJS_LOG_LEVEL_ERROR = 4,

        NJS_LOG_LEVEL_WARN = 5,

        NJS_LOG_LEVEL_INFO = 7,
    }
    enum NJS_LOG_LEVEL_ERROR = _Anonymous_10.NJS_LOG_LEVEL_ERROR;
    enum NJS_LOG_LEVEL_WARN = _Anonymous_10.NJS_LOG_LEVEL_WARN;
    enum NJS_LOG_LEVEL_INFO = _Anonymous_10.NJS_LOG_LEVEL_INFO;

    extern __gshared const(njs_value_s) njs_value_undefined;
    alias njs_prop_handler_t = int function(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*);
    alias njs_exotic_keys_t = int function(njs_vm_s*, njs_value_s*, njs_value_s*);
    alias njs_function_native_t = int function(njs_vm_s*, njs_value_s*, uint, c_ulong);

    alias njs_wellknown_symbol_t = _Anonymous_11;

    enum _Anonymous_11
    {

        NJS_SYMBOL_INVALID = 0,

        NJS_SYMBOL_ASYNC_ITERATOR = 1,

        NJS_SYMBOL_HAS_INSTANCE = 2,

        NJS_SYMBOL_IS_CONCAT_SPREADABLE = 3,

        NJS_SYMBOL_ITERATOR = 4,

        NJS_SYMBOL_MATCH = 5,

        NJS_SYMBOL_MATCH_ALL = 6,

        NJS_SYMBOL_REPLACE = 7,

        NJS_SYMBOL_SEARCH = 8,

        NJS_SYMBOL_SPECIES = 9,

        NJS_SYMBOL_SPLIT = 10,

        NJS_SYMBOL_TO_PRIMITIVE = 11,

        NJS_SYMBOL_TO_STRING_TAG = 12,

        NJS_SYMBOL_UNSCOPABLES = 13,

        NJS_SYMBOL_KNOWN_MAX = 14,
    }
    enum NJS_SYMBOL_INVALID = _Anonymous_11.NJS_SYMBOL_INVALID;
    enum NJS_SYMBOL_ASYNC_ITERATOR = _Anonymous_11.NJS_SYMBOL_ASYNC_ITERATOR;
    enum NJS_SYMBOL_HAS_INSTANCE = _Anonymous_11.NJS_SYMBOL_HAS_INSTANCE;
    enum NJS_SYMBOL_IS_CONCAT_SPREADABLE = _Anonymous_11.NJS_SYMBOL_IS_CONCAT_SPREADABLE;
    enum NJS_SYMBOL_ITERATOR = _Anonymous_11.NJS_SYMBOL_ITERATOR;
    enum NJS_SYMBOL_MATCH = _Anonymous_11.NJS_SYMBOL_MATCH;
    enum NJS_SYMBOL_MATCH_ALL = _Anonymous_11.NJS_SYMBOL_MATCH_ALL;
    enum NJS_SYMBOL_REPLACE = _Anonymous_11.NJS_SYMBOL_REPLACE;
    enum NJS_SYMBOL_SEARCH = _Anonymous_11.NJS_SYMBOL_SEARCH;
    enum NJS_SYMBOL_SPECIES = _Anonymous_11.NJS_SYMBOL_SPECIES;
    enum NJS_SYMBOL_SPLIT = _Anonymous_11.NJS_SYMBOL_SPLIT;
    enum NJS_SYMBOL_TO_PRIMITIVE = _Anonymous_11.NJS_SYMBOL_TO_PRIMITIVE;
    enum NJS_SYMBOL_TO_STRING_TAG = _Anonymous_11.NJS_SYMBOL_TO_STRING_TAG;
    enum NJS_SYMBOL_UNSCOPABLES = _Anonymous_11.NJS_SYMBOL_UNSCOPABLES;
    enum NJS_SYMBOL_KNOWN_MAX = _Anonymous_11.NJS_SYMBOL_KNOWN_MAX;

    alias njs_extern_flag_t = _Anonymous_12;

    enum _Anonymous_12
    {

        NJS_EXTERN_PROPERTY = 0,

        NJS_EXTERN_METHOD = 1,

        NJS_EXTERN_OBJECT = 2,

        NJS_EXTERN_SYMBOL = 4,
    }
    enum NJS_EXTERN_PROPERTY = _Anonymous_12.NJS_EXTERN_PROPERTY;
    enum NJS_EXTERN_METHOD = _Anonymous_12.NJS_EXTERN_METHOD;
    enum NJS_EXTERN_OBJECT = _Anonymous_12.NJS_EXTERN_OBJECT;
    enum NJS_EXTERN_SYMBOL = _Anonymous_12.NJS_EXTERN_SYMBOL;

    alias njs_extern_type_t = _Anonymous_13;

    enum _Anonymous_13
    {

        NJS_EXTERN_TYPE_INT = 0,

        NJS_EXTERN_TYPE_UINT = 1,

        NJS_EXTERN_TYPE_VALUE = 2,
    }
    enum NJS_EXTERN_TYPE_INT = _Anonymous_13.NJS_EXTERN_TYPE_INT;
    enum NJS_EXTERN_TYPE_UINT = _Anonymous_13.NJS_EXTERN_TYPE_UINT;
    enum NJS_EXTERN_TYPE_VALUE = _Anonymous_13.NJS_EXTERN_TYPE_VALUE;

    alias njs_vm_event_t = void*;

    alias njs_host_event_t = void*;

    alias njs_external_ptr_t = void*;
    alias njs_set_timer_t = void* function(void*, c_ulong, void*);
    alias njs_event_destructor_t = void function(void*, void*);
    alias njs_module_loader_t = njs_mod_s* function(njs_vm_s*, void*, njs_str_t*);
    alias njs_logger_t = void function(njs_vm_s*, void*, njs_log_level_t, const(ubyte)*, c_ulong);

    struct njs_vm_ops_t
    {

        void* function(void*, c_ulong, void*) set_timer;

        void function(void*, void*) clear_timer;

        njs_mod_s* function(njs_vm_s*, void*, njs_str_t*) module_loader;

        void function(njs_vm_s*, void*, njs_log_level_t, const(ubyte)*, c_ulong) logger;
    }

    struct njs_vm_meta_t
    {

        c_ulong size;

        c_ulong* values;
    }
    alias njs_addon_init_pt = int function(njs_vm_s*);

    struct njs_module_t
    {

        njs_str_t name;

        int function(njs_vm_s*) init;
    }

    struct njs_vm_opt_t
    {

        void* external;

        njs_vm_shared_s* shared_;

        njs_vm_ops_t* ops;

        njs_vm_meta_t* metas;

        njs_module_t** addons;

        njs_str_t file;

        char** argv;

        uint argc;

        njs_log_level_t log_level;

        ubyte interactive;

        ubyte trailer;

        ubyte init;

        ubyte disassemble;

        ubyte backtrace;

        ubyte quiet;

        ubyte sandbox;

        ubyte unsafe;

        ubyte module_;

        ubyte ast;

        ubyte unhandled_rejection;
    }

    void njs_vm_opt_init(njs_vm_opt_t*) @nogc nothrow;

    njs_vm_s* njs_vm_create(njs_vm_opt_t*) @nogc nothrow;

    void njs_vm_destroy(njs_vm_s*) @nogc nothrow;

    int njs_vm_compile(njs_vm_s*, ubyte**, ubyte*) @nogc nothrow;

    njs_mod_s* njs_vm_compile_module(njs_vm_s*, njs_str_t*, ubyte**, ubyte*) @nogc nothrow;

    njs_vm_s* njs_vm_clone(njs_vm_s*, void*) @nogc nothrow;

    void* njs_vm_add_event(njs_vm_s*, njs_function_s*, uint, void*, void function(void*, void*)) @nogc nothrow;

    void njs_vm_del_event(njs_vm_s*, void*) @nogc nothrow;

    int njs_vm_post_event(njs_vm_s*, void*, const(njs_value_s)*, uint) @nogc nothrow;

    int njs_vm_waiting(njs_vm_s*) @nogc nothrow;

    int njs_vm_posted(njs_vm_s*) @nogc nothrow;

    int njs_vm_call(njs_vm_s*, njs_function_s*, const(njs_value_s)*, uint) @nogc nothrow;

    int njs_vm_invoke(njs_vm_s*, njs_function_s*, const(njs_value_s)*, uint, njs_value_s*) @nogc nothrow;

    int njs_vm_run(njs_vm_s*) @nogc nothrow;

    int njs_vm_start(njs_vm_s*) @nogc nothrow;

    int njs_vm_add_path(njs_vm_s*, const(njs_str_t)*) @nogc nothrow;

    int njs_vm_external_prototype(njs_vm_s*, const(njs_external_s)*, uint) @nogc nothrow;

    int njs_vm_external_create(njs_vm_s*, njs_value_s*, int, void*, uint) @nogc nothrow;

    void* njs_vm_external(njs_vm_s*, int, const(njs_value_s)*) @nogc nothrow;

    int njs_external_property(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    c_ulong njs_vm_meta(njs_vm_s*, uint) @nogc nothrow;

    njs_function_s* njs_vm_function_alloc(njs_vm_s*, int function(njs_vm_s*, njs_value_s*, uint, c_ulong)) @nogc nothrow;

    void njs_disassembler(njs_vm_s*) @nogc nothrow;

    int njs_vm_bind(njs_vm_s*, const(njs_str_t)*, const(njs_value_s)*, uint) @nogc nothrow;

    int njs_vm_value(njs_vm_s*, const(njs_str_t)*, njs_value_s*) @nogc nothrow;

    njs_function_s* njs_vm_function(njs_vm_s*, const(njs_str_t)*) @nogc nothrow;

    njs_value_s* njs_vm_retval(njs_vm_s*) @nogc nothrow;

    void njs_vm_retval_set(njs_vm_s*, const(njs_value_s)*) @nogc nothrow;

    njs_mp_s* njs_vm_memory_pool(njs_vm_s*) @nogc nothrow;

    void njs_value_string_get(njs_value_s*, njs_str_t*) @nogc nothrow;

    int njs_vm_value_string_set(njs_vm_s*, njs_value_s*, const(ubyte)*, uint) @nogc nothrow;

    ubyte* njs_vm_value_string_alloc(njs_vm_s*, njs_value_s*, uint) @nogc nothrow;

    int njs_vm_value_string_copy(njs_vm_s*, njs_str_t*, njs_value_s*, c_ulong*) @nogc nothrow;

    int njs_vm_value_array_buffer_set(njs_vm_s*, njs_value_s*, const(ubyte)*, uint) @nogc nothrow;

    int njs_vm_value_buffer_set(njs_vm_s*, njs_value_s*, const(ubyte)*, uint) @nogc nothrow;

    int njs_vm_value_to_bytes(njs_vm_s*, njs_str_t*, njs_value_s*) @nogc nothrow;

    int njs_vm_value_to_string(njs_vm_s*, njs_str_t*, njs_value_s*) @nogc nothrow;

    int njs_vm_value_string(njs_vm_s*, njs_str_t*, njs_value_s*) @nogc nothrow;

    int njs_vm_retval_string(njs_vm_s*, njs_str_t*) @nogc nothrow;

    int njs_vm_value_dump(njs_vm_s*, njs_str_t*, njs_value_s*, uint, uint) @nogc nothrow;

    int njs_vm_retval_dump(njs_vm_s*, njs_str_t*, uint) @nogc nothrow;

    void njs_vm_value_error_set(njs_vm_s*, njs_value_s*, const(char)*, ...) @nogc nothrow;

    void njs_vm_memory_error(njs_vm_s*) @nogc nothrow;

    void njs_vm_logger(njs_vm_s*, njs_log_level_t, const(char)*, ...) @nogc nothrow;

    void njs_value_undefined_set(njs_value_s*) @nogc nothrow;

    void njs_value_null_set(njs_value_s*) @nogc nothrow;

    void njs_value_invalid_set(njs_value_s*) @nogc nothrow;

    void njs_value_boolean_set(njs_value_s*, int) @nogc nothrow;

    void njs_value_number_set(njs_value_s*, double) @nogc nothrow;

    ubyte njs_value_bool(const(njs_value_s)*) @nogc nothrow;

    double njs_value_number(const(njs_value_s)*) @nogc nothrow;

    njs_function_s* njs_value_function(const(njs_value_s)*) @nogc nothrow;

    int njs_value_external_tag(const(njs_value_s)*) @nogc nothrow;

    ushort njs_vm_prop_magic16(njs_object_prop_s*) @nogc nothrow;

    uint njs_vm_prop_magic32(njs_object_prop_s*) @nogc nothrow;

    int njs_vm_prop_name(njs_vm_s*, njs_object_prop_s*, njs_str_t*) @nogc nothrow;

    int njs_value_is_null(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_undefined(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_null_or_undefined(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_valid(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_boolean(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_number(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_valid_number(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_string(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_object(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_array(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_function(const(njs_value_s)*) @nogc nothrow;

    int njs_value_is_buffer(const(njs_value_s)*) @nogc nothrow;

    int njs_vm_object_alloc(njs_vm_s*, njs_value_s*, ...) @nogc nothrow;

    njs_value_s* njs_vm_object_keys(njs_vm_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    njs_value_s* njs_vm_object_prop(njs_vm_s*, njs_value_s*, const(njs_str_t)*, njs_opaque_value_t*) @nogc nothrow;

    int njs_vm_array_alloc(njs_vm_s*, njs_value_s*, uint) @nogc nothrow;

    int njs_vm_array_length(njs_vm_s*, njs_value_s*, c_long*) @nogc nothrow;

    njs_value_s* njs_vm_array_start(njs_vm_s*, njs_value_s*) @nogc nothrow;

    njs_value_s* njs_vm_array_prop(njs_vm_s*, njs_value_s*, c_long, njs_opaque_value_t*) @nogc nothrow;

    njs_value_s* njs_vm_array_push(njs_vm_s*, njs_value_s*) @nogc nothrow;

    int njs_vm_json_parse(njs_vm_s*, njs_value_s*, uint) @nogc nothrow;

    int njs_vm_json_stringify(njs_vm_s*, njs_value_s*, uint) @nogc nothrow;

    int njs_vm_query_string_parse(njs_vm_s*, ubyte*, ubyte*, njs_value_s*) @nogc nothrow;

    int njs_vm_promise_create(njs_vm_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    ubyte* _njs_addr2line(ubyte*, ubyte*, void*) @nogc nothrow;

    struct njs_arr_t
    {

        void* start;

        uint items;

        uint available;

        ushort item_size;

        ubyte pointer;

        ubyte separate;

        njs_mp_s* mem_pool;
    }

    njs_arr_t* njs_arr_create(njs_mp_s*, uint, c_ulong) @nogc nothrow;

    void* njs_arr_init(njs_mp_s*, njs_arr_t*, void*, uint, c_ulong) @nogc nothrow;

    void njs_arr_destroy(njs_arr_t*) @nogc nothrow;

    void* njs_arr_add(njs_arr_t*) @nogc nothrow;

    void* njs_arr_add_multiple(njs_arr_t*, uint) @nogc nothrow;

    void* njs_arr_zero_add(njs_arr_t*) @nogc nothrow;

    void njs_arr_remove(njs_arr_t*, void*) @nogc nothrow;

    njs_array_s* njs_array_alloc(njs_vm_s*, uint, c_ulong, uint) @nogc nothrow;

    void njs_array_destroy(njs_vm_s*, njs_array_s*) @nogc nothrow;

    int njs_array_add(njs_vm_s*, njs_array_s*, njs_value_s*) @nogc nothrow;

    int njs_array_convert_to_slow_array(njs_vm_s*, njs_array_s*) @nogc nothrow;

    int njs_array_length_redefine(njs_vm_s*, njs_value_s*, uint, int) @nogc nothrow;

    int njs_array_length_set(njs_vm_s*, njs_value_s*, njs_object_prop_s*, njs_value_s*) @nogc nothrow;

    njs_array_s* njs_array_keys(njs_vm_s*, njs_value_s*, uint) @nogc nothrow;

    njs_array_s* njs_array_indices(njs_vm_s*, njs_value_s*) @nogc nothrow;

    int njs_array_string_add(njs_vm_s*, njs_array_s*, const(ubyte)*, c_ulong, c_ulong) @nogc nothrow;

    int njs_array_expand(njs_vm_s*, njs_array_s*, uint, uint) @nogc nothrow;

    int njs_array_prototype_to_string(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    extern __gshared const(njs_object_init_s) njs_array_instance_init;

    extern __gshared const(njs_object_type_init_t) njs_array_type_init;

    njs_array_buffer_s* njs_array_buffer_alloc(njs_vm_s*, c_ulong, uint) @nogc nothrow;

    int njs_array_buffer_writable(njs_vm_s*, njs_array_buffer_s*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_array_buffer_type_init;

    struct njs_async_ctx_t
    {

        njs_promise_capability_t* capability;

        njs_frame_s* await;

        c_ulong index;

        ubyte* pc;
    }

    int njs_async_function_frame_invoke(njs_vm_s*, njs_value_s*) @nogc nothrow;

    int njs_await_fulfilled(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_await_rejected(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_async_function_type_init;

    extern __gshared const(njs_object_init_s) njs_async_function_instance_init;

    extern __gshared const(njs_object_type_init_t) njs_boolean_type_init;
    alias njs_buffer_encode_t = int function(njs_vm_s*, njs_value_s*, const(njs_str_t)*);
    alias njs_buffer_encode_length_t = c_ulong function(const(njs_str_t)*, c_ulong*);

    struct njs_buffer_encoding_t
    {

        njs_str_t name;

        int function(njs_vm_s*, njs_value_s*, const(njs_str_t)*) encode;

        int function(njs_vm_s*, njs_value_s*, const(njs_str_t)*) decode;

        c_ulong function(const(njs_str_t)*, c_ulong*) decode_length;
    }

    njs_typed_array_s* njs_buffer_slot(njs_vm_s*, njs_value_s*, const(char)*) @nogc nothrow;

    int njs_buffer_set(njs_vm_s*, njs_value_s*, const(ubyte)*, uint) @nogc nothrow;

    int njs_buffer_new(njs_vm_s*, njs_value_s*, const(ubyte)*, uint) @nogc nothrow;

    njs_typed_array_s* njs_buffer_alloc(njs_vm_s*, c_ulong, uint) @nogc nothrow;

    const(njs_buffer_encoding_t)* njs_buffer_encoding(njs_vm_s*, const(njs_value_s)*) @nogc nothrow;

    int njs_buffer_decode_string(njs_vm_s*, const(njs_value_s)*, njs_value_s*, const(njs_buffer_encoding_t)*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_buffer_type_init;

    alias njs_chb_node_t = njs_chb_node_s;

    struct njs_chb_node_s
    {

        njs_chb_node_s* next;

        ubyte* start;

        ubyte* pos;

        ubyte* end;
    }

    struct njs_chb_t
    {

        uint error;

        njs_mp_s* pool;

        njs_chb_node_s* nodes;

        njs_chb_node_s* last;
    }

    void njs_chb_append0(njs_chb_t*, const(char)*, c_ulong) @nogc nothrow;

    void njs_chb_vsprintf(njs_chb_t*, c_ulong, const(char)*, va_list*) @nogc nothrow;

    void njs_chb_sprintf(njs_chb_t*, c_ulong, const(char)*, ...) @nogc nothrow;

    ubyte* njs_chb_reserve(njs_chb_t*, c_ulong) @nogc nothrow;

    void njs_chb_drain(njs_chb_t*, c_ulong) @nogc nothrow;

    void njs_chb_drop(njs_chb_t*, c_ulong) @nogc nothrow;

    int njs_chb_join(njs_chb_t*, njs_str_t*) @nogc nothrow;

    void njs_chb_join_to(njs_chb_t*, ubyte*) @nogc nothrow;

    void njs_chb_destroy(njs_chb_t*) @nogc nothrow;

    njs_date_s* njs_date_alloc(njs_vm_s*, double) @nogc nothrow;

    int njs_date_to_string(njs_vm_s*, njs_value_s*, const(njs_value_s)*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_date_type_init;

    struct njs_diyfp_t
    {

        c_ulong significand;

        int exp;
    }

    union njs_diyfp_conv_t
    {

        double d;

        c_ulong u64;
    }

    njs_diyfp_t njs_cached_power_dec(int, int*) @nogc nothrow;

    njs_diyfp_t njs_cached_power_bin(int, int*) @nogc nothrow;

    uint njs_djb_hash(const(void)*, c_ulong) @nogc nothrow;

    uint njs_djb_hash_lowcase(const(void)*, c_ulong) @nogc nothrow;

    c_ulong njs_dtoa(double, char*) @nogc nothrow;

    c_ulong njs_dtoa_precision(double, char*, c_ulong) @nogc nothrow;

    c_ulong njs_dtoa_exponential(double, char*, int) @nogc nothrow;

    c_ulong njs_fixed_dtoa(double, uint, char*, int*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_text_encoder_type_init;

    extern __gshared const(njs_object_type_init_t) njs_text_decoder_type_init;

    void njs_error_new(njs_vm_s*, njs_value_s*, njs_object_type_t, ubyte*, c_ulong) @nogc nothrow;

    void njs_error_fmt_new(njs_vm_s*, njs_value_s*, njs_object_type_t, const(char)*, ...) @nogc nothrow;

    void njs_memory_error(njs_vm_s*) @nogc nothrow;

    void njs_memory_error_set(njs_vm_s*, njs_value_s*) @nogc nothrow;

    njs_object_s* njs_error_alloc(njs_vm_s*, njs_object_type_t, const(njs_value_s)*, const(njs_value_s)*, const(njs_value_s)*) @nogc nothrow;

    int njs_error_to_string(njs_vm_s*, njs_value_s*, const(njs_value_s)*) @nogc nothrow;

    int njs_error_stack(njs_vm_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_error_stack_attach(njs_vm_s*, njs_value_s*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_error_type_init;

    extern __gshared const(njs_object_type_init_t) njs_eval_error_type_init;

    extern __gshared const(njs_object_type_init_t) njs_internal_error_type_init;

    extern __gshared const(njs_object_type_init_t) njs_range_error_type_init;

    extern __gshared const(njs_object_type_init_t) njs_reference_error_type_init;

    extern __gshared const(njs_object_type_init_t) njs_syntax_error_type_init;

    extern __gshared const(njs_object_type_init_t) njs_type_error_type_init;

    extern __gshared const(njs_object_type_init_t) njs_uri_error_type_init;

    extern __gshared const(njs_object_type_init_t) njs_memory_error_type_init;

    extern __gshared const(njs_object_type_init_t) njs_aggregate_error_type_init;

    struct njs_event_t
    {
        import std.bitmanip: bitfields;

        align(4):

        njs_function_s* function_;

        njs_value_s* args;

        uint nargs;

        void* host_event;

        void function(void*, void*) destructor;

        njs_value_s id;

        njs_queue_link_s link;
        mixin(bitfields!(

            uint, "posted", 1,

            uint, "once", 1,
            uint, "_padding_0", 6
        ));
    }

    int njs_add_event(njs_vm_s*, njs_event_t*) @nogc nothrow;

    void njs_del_event(njs_vm_s*, njs_event_t*, uint) @nogc nothrow;

    extern __gshared const(njs_lvlhsh_proto_t) njs_event_hash_proto;

    void njs_file_basename(const(njs_str_t)*, njs_str_t*) @nogc nothrow;

    void njs_file_dirname(const(njs_str_t)*, njs_str_t*) @nogc nothrow;

    alias njs_exception_t = njs_exception_s;

    struct njs_exception_s
    {

        njs_exception_s* next;

        ubyte* catch_;
    }

    njs_function_s* njs_function_alloc(njs_vm_s*, njs_function_lambda_s*, uint) @nogc nothrow;

    njs_function_s* njs_function_value_copy(njs_vm_s*, njs_value_s*) @nogc nothrow;

    int njs_function_name_set(njs_vm_s*, njs_function_s*, njs_value_s*, const(char)*) @nogc nothrow;

    njs_function_s* njs_function_copy(njs_vm_s*, njs_function_s*) @nogc nothrow;

    int njs_function_arguments_object_init(njs_vm_s*, njs_native_frame_s*) @nogc nothrow;

    int njs_function_rest_parameters_init(njs_vm_s*, njs_native_frame_s*) @nogc nothrow;

    int njs_function_prototype_create(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_function_constructor(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_function_instance_length(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_function_instance_name(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_eval_function(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_function_native_frame(njs_vm_s*, njs_function_s*, const(njs_value_s)*, const(njs_value_s)*, uint, uint) @nogc nothrow;

    int njs_function_lambda_frame(njs_vm_s*, njs_function_s*, const(njs_value_s)*, const(njs_value_s)*, uint, uint) @nogc nothrow;

    int njs_function_call2(njs_vm_s*, njs_function_s*, const(njs_value_s)*, const(njs_value_s)*, uint, njs_value_s*, uint) @nogc nothrow;

    int njs_function_lambda_call(njs_vm_s*, void*) @nogc nothrow;

    int njs_function_native_call(njs_vm_s*) @nogc nothrow;

    njs_native_frame_s* njs_function_frame_alloc(njs_vm_s*, c_ulong) @nogc nothrow;

    void njs_function_frame_free(njs_vm_s*, njs_native_frame_s*) @nogc nothrow;

    int njs_function_frame_save(njs_vm_s*, njs_frame_s*, ubyte*) @nogc nothrow;

    njs_object_type_t njs_function_object_type(njs_vm_s*, njs_function_s*) @nogc nothrow;

    int njs_function_capture_closure(njs_vm_s*, njs_function_s*, njs_function_lambda_s*) @nogc nothrow;

    int njs_function_capture_global_closures(njs_vm_s*, njs_function_s*) @nogc nothrow;

    int njs_function_frame_invoke(njs_vm_s*, njs_value_s*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_function_type_init;

    extern __gshared const(njs_object_init_s) njs_function_instance_init;

    extern __gshared const(njs_object_init_s) njs_arrow_instance_init;

    extern __gshared const(njs_object_init_s) njs_arguments_object_instance_init;

    alias njs_generator_block_t = njs_generator_block_s;
    struct njs_generator_block_s;
    alias njs_generator_state_func_t = int function(njs_vm_s*, njs_generator_s*, njs_parser_node_s*);

    int njs_generator_init(njs_generator_s*, njs_str_t*, int, uint) @nogc nothrow;

    njs_vm_code_t* njs_generate_scope(njs_vm_s*, njs_generator_s*, njs_parser_scope_s*, const(njs_str_t)*) @nogc nothrow;

    njs_vm_code_t* njs_lookup_code(njs_vm_s*, ubyte*) @nogc nothrow;

    uint njs_lookup_line(njs_arr_t*, uint) @nogc nothrow;

    struct njs_iterator_args_t
    {

        njs_function_s* function_;

        njs_value_s* argument;

        njs_value_s* value;

        void* data;

        c_long from;

        c_long to;
    }
    alias njs_iterator_handler_t = int function(njs_vm_s*, njs_iterator_args_t*, njs_value_s*, c_long);

    int njs_array_iterator_create(njs_vm_s*, const(njs_value_s)*, njs_value_s*, njs_object_enum_t) @nogc nothrow;

    int njs_array_iterator_next(njs_vm_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_object_iterate(njs_vm_s*, njs_iterator_args_t*, int function(njs_vm_s*, njs_iterator_args_t*, njs_value_s*, c_long)) @nogc nothrow;

    int njs_object_iterate_reverse(njs_vm_s*, njs_iterator_args_t*, int function(njs_vm_s*, njs_iterator_args_t*, njs_value_s*, c_long)) @nogc nothrow;

    njs_array_s* njs_iterator_to_array(njs_vm_s*, njs_value_s*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_iterator_type_init;

    extern __gshared const(njs_object_type_init_t) njs_array_iterator_type_init;

    extern __gshared const(njs_object_init_s) njs_json_object_init;

    alias njs_token_type_t = _Anonymous_14;

    enum _Anonymous_14
    {

        NJS_TOKEN_ERROR = -1,

        NJS_TOKEN_ILLEGAL = 0,

        NJS_TOKEN_END = 1,

        NJS_TOKEN_SPACE = 2,

        NJS_TOKEN_LINE_END = 3,

        NJS_TOKEN_DOUBLE_QUOTE = 4,

        NJS_TOKEN_SINGLE_QUOTE = 5,

        NJS_TOKEN_OPEN_PARENTHESIS = 6,

        NJS_TOKEN_CLOSE_PARENTHESIS = 7,

        NJS_TOKEN_OPEN_BRACKET = 8,

        NJS_TOKEN_CLOSE_BRACKET = 9,

        NJS_TOKEN_OPEN_BRACE = 10,

        NJS_TOKEN_CLOSE_BRACE = 11,

        NJS_TOKEN_COMMA = 12,

        NJS_TOKEN_DOT = 13,

        NJS_TOKEN_ELLIPSIS = 14,

        NJS_TOKEN_SEMICOLON = 15,

        NJS_TOKEN_COLON = 16,

        NJS_TOKEN_CONDITIONAL = 17,

        NJS_TOKEN_COMMENT = 18,

        NJS_TOKEN_ASSIGNMENT = 19,

        NJS_TOKEN_ARROW = 20,

        NJS_TOKEN_ADDITION_ASSIGNMENT = 21,

        NJS_TOKEN_SUBSTRACTION_ASSIGNMENT = 22,

        NJS_TOKEN_MULTIPLICATION_ASSIGNMENT = 23,

        NJS_TOKEN_EXPONENTIATION_ASSIGNMENT = 24,

        NJS_TOKEN_DIVISION_ASSIGNMENT = 25,

        NJS_TOKEN_REMAINDER_ASSIGNMENT = 26,

        NJS_TOKEN_LEFT_SHIFT_ASSIGNMENT = 27,

        NJS_TOKEN_RIGHT_SHIFT_ASSIGNMENT = 28,

        NJS_TOKEN_UNSIGNED_RIGHT_SHIFT_ASSIGNMENT = 29,

        NJS_TOKEN_BITWISE_OR_ASSIGNMENT = 30,

        NJS_TOKEN_BITWISE_XOR_ASSIGNMENT = 31,

        NJS_TOKEN_BITWISE_AND_ASSIGNMENT = 32,

        NJS_TOKEN_INCREMENT = 33,

        NJS_TOKEN_DECREMENT = 34,

        NJS_TOKEN_POST_INCREMENT = 35,

        NJS_TOKEN_POST_DECREMENT = 36,

        NJS_TOKEN_EQUAL = 37,

        NJS_TOKEN_STRICT_EQUAL = 38,

        NJS_TOKEN_NOT_EQUAL = 39,

        NJS_TOKEN_STRICT_NOT_EQUAL = 40,

        NJS_TOKEN_ADDITION = 41,

        NJS_TOKEN_UNARY_PLUS = 42,

        NJS_TOKEN_SUBSTRACTION = 43,

        NJS_TOKEN_UNARY_NEGATION = 44,

        NJS_TOKEN_MULTIPLICATION = 45,

        NJS_TOKEN_EXPONENTIATION = 46,

        NJS_TOKEN_DIVISION = 47,

        NJS_TOKEN_REMAINDER = 48,

        NJS_TOKEN_LESS = 49,

        NJS_TOKEN_LESS_OR_EQUAL = 50,

        NJS_TOKEN_LEFT_SHIFT = 51,

        NJS_TOKEN_GREATER = 52,

        NJS_TOKEN_GREATER_OR_EQUAL = 53,

        NJS_TOKEN_RIGHT_SHIFT = 54,

        NJS_TOKEN_UNSIGNED_RIGHT_SHIFT = 55,

        NJS_TOKEN_BITWISE_OR = 56,

        NJS_TOKEN_LOGICAL_OR = 57,

        NJS_TOKEN_BITWISE_XOR = 58,

        NJS_TOKEN_BITWISE_AND = 59,

        NJS_TOKEN_LOGICAL_AND = 60,

        NJS_TOKEN_BITWISE_NOT = 61,

        NJS_TOKEN_LOGICAL_NOT = 62,

        NJS_TOKEN_COALESCE = 63,

        NJS_TOKEN_IN = 64,

        NJS_TOKEN_OF = 65,

        NJS_TOKEN_INSTANCEOF = 66,

        NJS_TOKEN_TYPEOF = 67,

        NJS_TOKEN_VOID = 68,

        NJS_TOKEN_NEW = 69,

        NJS_TOKEN_DELETE = 70,

        NJS_TOKEN_YIELD = 71,

        NJS_TOKEN_DIGIT = 72,

        NJS_TOKEN_LETTER = 73,

        NJS_TOKEN_NULL = 74,

        NJS_TOKEN_NUMBER = 75,

        NJS_TOKEN_TRUE = 76,

        NJS_TOKEN_UNDEFINED = 77,

        NJS_TOKEN_FALSE = 78,

        NJS_TOKEN_STRING = 79,

        NJS_TOKEN_ESCAPE_STRING = 80,

        NJS_TOKEN_UNTERMINATED_STRING = 81,

        NJS_TOKEN_NAME = 82,

        NJS_TOKEN_OBJECT = 83,

        NJS_TOKEN_OBJECT_VALUE = 84,

        NJS_TOKEN_PROPERTY = 85,

        NJS_TOKEN_PROPERTY_INIT = 86,

        NJS_TOKEN_PROPERTY_DELETE = 87,

        NJS_TOKEN_PROPERTY_GETTER = 88,

        NJS_TOKEN_PROPERTY_SETTER = 89,

        NJS_TOKEN_PROTO_INIT = 90,

        NJS_TOKEN_ARRAY = 91,

        NJS_TOKEN_GRAVE = 92,

        NJS_TOKEN_TEMPLATE_LITERAL = 93,

        NJS_TOKEN_FUNCTION = 94,

        NJS_TOKEN_FUNCTION_DECLARATION = 95,

        NJS_TOKEN_FUNCTION_EXPRESSION = 96,

        NJS_TOKEN_FUNCTION_CALL = 97,

        NJS_TOKEN_METHOD_CALL = 98,

        NJS_TOKEN_ARGUMENT = 99,

        NJS_TOKEN_RETURN = 100,

        NJS_TOKEN_ASYNC_FUNCTION = 101,

        NJS_TOKEN_ASYNC_FUNCTION_DECLARATION = 102,

        NJS_TOKEN_ASYNC_FUNCTION_EXPRESSION = 103,

        NJS_TOKEN_REGEXP = 104,

        NJS_TOKEN_EXTERNAL = 105,

        NJS_TOKEN_STATEMENT = 106,

        NJS_TOKEN_BLOCK = 107,

        NJS_TOKEN_VAR = 108,

        NJS_TOKEN_IF = 109,

        NJS_TOKEN_ELSE = 110,

        NJS_TOKEN_BRANCHING = 111,

        NJS_TOKEN_WHILE = 112,

        NJS_TOKEN_DO = 113,

        NJS_TOKEN_FOR = 114,

        NJS_TOKEN_FOR_IN = 115,

        NJS_TOKEN_BREAK = 116,

        NJS_TOKEN_CONTINUE = 117,

        NJS_TOKEN_SWITCH = 118,

        NJS_TOKEN_CASE = 119,

        NJS_TOKEN_DEFAULT = 120,

        NJS_TOKEN_WITH = 121,

        NJS_TOKEN_TRY = 122,

        NJS_TOKEN_CATCH = 123,

        NJS_TOKEN_FINALLY = 124,

        NJS_TOKEN_THROW = 125,

        NJS_TOKEN_THIS = 126,

        NJS_TOKEN_ARGUMENTS = 127,

        NJS_TOKEN_EVAL = 128,

        NJS_TOKEN_IMPORT = 129,

        NJS_TOKEN_EXPORT = 130,

        NJS_TOKEN_TARGET = 131,

        NJS_TOKEN_FROM = 132,

        NJS_TOKEN_META = 133,

        NJS_TOKEN_AWAIT = 134,

        NJS_TOKEN_ASYNC = 135,

        NJS_TOKEN_CLASS = 136,

        NJS_TOKEN_CONST = 137,

        NJS_TOKEN_DEBUGGER = 138,

        NJS_TOKEN_ENUM = 139,

        NJS_TOKEN_EXTENDS = 140,

        NJS_TOKEN_IMPLEMENTS = 141,

        NJS_TOKEN_INTERFACE = 142,

        NJS_TOKEN_LET = 143,

        NJS_TOKEN_PACKAGE = 144,

        NJS_TOKEN_PRIVATE = 145,

        NJS_TOKEN_PROTECTED = 146,

        NJS_TOKEN_PUBLIC = 147,

        NJS_TOKEN_STATIC = 148,

        NJS_TOKEN_SUPER = 149,

        NJS_TOKEN_RESERVED = 150,
    }
    enum NJS_TOKEN_ERROR = _Anonymous_14.NJS_TOKEN_ERROR;
    enum NJS_TOKEN_ILLEGAL = _Anonymous_14.NJS_TOKEN_ILLEGAL;
    enum NJS_TOKEN_END = _Anonymous_14.NJS_TOKEN_END;
    enum NJS_TOKEN_SPACE = _Anonymous_14.NJS_TOKEN_SPACE;
    enum NJS_TOKEN_LINE_END = _Anonymous_14.NJS_TOKEN_LINE_END;
    enum NJS_TOKEN_DOUBLE_QUOTE = _Anonymous_14.NJS_TOKEN_DOUBLE_QUOTE;
    enum NJS_TOKEN_SINGLE_QUOTE = _Anonymous_14.NJS_TOKEN_SINGLE_QUOTE;
    enum NJS_TOKEN_OPEN_PARENTHESIS = _Anonymous_14.NJS_TOKEN_OPEN_PARENTHESIS;
    enum NJS_TOKEN_CLOSE_PARENTHESIS = _Anonymous_14.NJS_TOKEN_CLOSE_PARENTHESIS;
    enum NJS_TOKEN_OPEN_BRACKET = _Anonymous_14.NJS_TOKEN_OPEN_BRACKET;
    enum NJS_TOKEN_CLOSE_BRACKET = _Anonymous_14.NJS_TOKEN_CLOSE_BRACKET;
    enum NJS_TOKEN_OPEN_BRACE = _Anonymous_14.NJS_TOKEN_OPEN_BRACE;
    enum NJS_TOKEN_CLOSE_BRACE = _Anonymous_14.NJS_TOKEN_CLOSE_BRACE;
    enum NJS_TOKEN_COMMA = _Anonymous_14.NJS_TOKEN_COMMA;
    enum NJS_TOKEN_DOT = _Anonymous_14.NJS_TOKEN_DOT;
    enum NJS_TOKEN_ELLIPSIS = _Anonymous_14.NJS_TOKEN_ELLIPSIS;
    enum NJS_TOKEN_SEMICOLON = _Anonymous_14.NJS_TOKEN_SEMICOLON;
    enum NJS_TOKEN_COLON = _Anonymous_14.NJS_TOKEN_COLON;
    enum NJS_TOKEN_CONDITIONAL = _Anonymous_14.NJS_TOKEN_CONDITIONAL;
    enum NJS_TOKEN_COMMENT = _Anonymous_14.NJS_TOKEN_COMMENT;
    enum NJS_TOKEN_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_ASSIGNMENT;
    enum NJS_TOKEN_ARROW = _Anonymous_14.NJS_TOKEN_ARROW;
    enum NJS_TOKEN_ADDITION_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_ADDITION_ASSIGNMENT;
    enum NJS_TOKEN_SUBSTRACTION_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_SUBSTRACTION_ASSIGNMENT;
    enum NJS_TOKEN_MULTIPLICATION_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_MULTIPLICATION_ASSIGNMENT;
    enum NJS_TOKEN_EXPONENTIATION_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_EXPONENTIATION_ASSIGNMENT;
    enum NJS_TOKEN_DIVISION_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_DIVISION_ASSIGNMENT;
    enum NJS_TOKEN_REMAINDER_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_REMAINDER_ASSIGNMENT;
    enum NJS_TOKEN_LEFT_SHIFT_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_LEFT_SHIFT_ASSIGNMENT;
    enum NJS_TOKEN_RIGHT_SHIFT_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_RIGHT_SHIFT_ASSIGNMENT;
    enum NJS_TOKEN_UNSIGNED_RIGHT_SHIFT_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_UNSIGNED_RIGHT_SHIFT_ASSIGNMENT;
    enum NJS_TOKEN_BITWISE_OR_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_BITWISE_OR_ASSIGNMENT;
    enum NJS_TOKEN_BITWISE_XOR_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_BITWISE_XOR_ASSIGNMENT;
    enum NJS_TOKEN_BITWISE_AND_ASSIGNMENT = _Anonymous_14.NJS_TOKEN_BITWISE_AND_ASSIGNMENT;
    enum NJS_TOKEN_INCREMENT = _Anonymous_14.NJS_TOKEN_INCREMENT;
    enum NJS_TOKEN_DECREMENT = _Anonymous_14.NJS_TOKEN_DECREMENT;
    enum NJS_TOKEN_POST_INCREMENT = _Anonymous_14.NJS_TOKEN_POST_INCREMENT;
    enum NJS_TOKEN_POST_DECREMENT = _Anonymous_14.NJS_TOKEN_POST_DECREMENT;
    enum NJS_TOKEN_EQUAL = _Anonymous_14.NJS_TOKEN_EQUAL;
    enum NJS_TOKEN_STRICT_EQUAL = _Anonymous_14.NJS_TOKEN_STRICT_EQUAL;
    enum NJS_TOKEN_NOT_EQUAL = _Anonymous_14.NJS_TOKEN_NOT_EQUAL;
    enum NJS_TOKEN_STRICT_NOT_EQUAL = _Anonymous_14.NJS_TOKEN_STRICT_NOT_EQUAL;
    enum NJS_TOKEN_ADDITION = _Anonymous_14.NJS_TOKEN_ADDITION;
    enum NJS_TOKEN_UNARY_PLUS = _Anonymous_14.NJS_TOKEN_UNARY_PLUS;
    enum NJS_TOKEN_SUBSTRACTION = _Anonymous_14.NJS_TOKEN_SUBSTRACTION;
    enum NJS_TOKEN_UNARY_NEGATION = _Anonymous_14.NJS_TOKEN_UNARY_NEGATION;
    enum NJS_TOKEN_MULTIPLICATION = _Anonymous_14.NJS_TOKEN_MULTIPLICATION;
    enum NJS_TOKEN_EXPONENTIATION = _Anonymous_14.NJS_TOKEN_EXPONENTIATION;
    enum NJS_TOKEN_DIVISION = _Anonymous_14.NJS_TOKEN_DIVISION;
    enum NJS_TOKEN_REMAINDER = _Anonymous_14.NJS_TOKEN_REMAINDER;
    enum NJS_TOKEN_LESS = _Anonymous_14.NJS_TOKEN_LESS;
    enum NJS_TOKEN_LESS_OR_EQUAL = _Anonymous_14.NJS_TOKEN_LESS_OR_EQUAL;
    enum NJS_TOKEN_LEFT_SHIFT = _Anonymous_14.NJS_TOKEN_LEFT_SHIFT;
    enum NJS_TOKEN_GREATER = _Anonymous_14.NJS_TOKEN_GREATER;
    enum NJS_TOKEN_GREATER_OR_EQUAL = _Anonymous_14.NJS_TOKEN_GREATER_OR_EQUAL;
    enum NJS_TOKEN_RIGHT_SHIFT = _Anonymous_14.NJS_TOKEN_RIGHT_SHIFT;
    enum NJS_TOKEN_UNSIGNED_RIGHT_SHIFT = _Anonymous_14.NJS_TOKEN_UNSIGNED_RIGHT_SHIFT;
    enum NJS_TOKEN_BITWISE_OR = _Anonymous_14.NJS_TOKEN_BITWISE_OR;
    enum NJS_TOKEN_LOGICAL_OR = _Anonymous_14.NJS_TOKEN_LOGICAL_OR;
    enum NJS_TOKEN_BITWISE_XOR = _Anonymous_14.NJS_TOKEN_BITWISE_XOR;
    enum NJS_TOKEN_BITWISE_AND = _Anonymous_14.NJS_TOKEN_BITWISE_AND;
    enum NJS_TOKEN_LOGICAL_AND = _Anonymous_14.NJS_TOKEN_LOGICAL_AND;
    enum NJS_TOKEN_BITWISE_NOT = _Anonymous_14.NJS_TOKEN_BITWISE_NOT;
    enum NJS_TOKEN_LOGICAL_NOT = _Anonymous_14.NJS_TOKEN_LOGICAL_NOT;
    enum NJS_TOKEN_COALESCE = _Anonymous_14.NJS_TOKEN_COALESCE;
    enum NJS_TOKEN_IN = _Anonymous_14.NJS_TOKEN_IN;
    enum NJS_TOKEN_OF = _Anonymous_14.NJS_TOKEN_OF;
    enum NJS_TOKEN_INSTANCEOF = _Anonymous_14.NJS_TOKEN_INSTANCEOF;
    enum NJS_TOKEN_TYPEOF = _Anonymous_14.NJS_TOKEN_TYPEOF;
    enum NJS_TOKEN_VOID = _Anonymous_14.NJS_TOKEN_VOID;
    enum NJS_TOKEN_NEW = _Anonymous_14.NJS_TOKEN_NEW;
    enum NJS_TOKEN_DELETE = _Anonymous_14.NJS_TOKEN_DELETE;
    enum NJS_TOKEN_YIELD = _Anonymous_14.NJS_TOKEN_YIELD;
    enum NJS_TOKEN_DIGIT = _Anonymous_14.NJS_TOKEN_DIGIT;
    enum NJS_TOKEN_LETTER = _Anonymous_14.NJS_TOKEN_LETTER;
    enum NJS_TOKEN_NULL = _Anonymous_14.NJS_TOKEN_NULL;
    enum NJS_TOKEN_NUMBER = _Anonymous_14.NJS_TOKEN_NUMBER;
    enum NJS_TOKEN_TRUE = _Anonymous_14.NJS_TOKEN_TRUE;
    enum NJS_TOKEN_UNDEFINED = _Anonymous_14.NJS_TOKEN_UNDEFINED;
    enum NJS_TOKEN_FALSE = _Anonymous_14.NJS_TOKEN_FALSE;
    enum NJS_TOKEN_STRING = _Anonymous_14.NJS_TOKEN_STRING;
    enum NJS_TOKEN_ESCAPE_STRING = _Anonymous_14.NJS_TOKEN_ESCAPE_STRING;
    enum NJS_TOKEN_UNTERMINATED_STRING = _Anonymous_14.NJS_TOKEN_UNTERMINATED_STRING;
    enum NJS_TOKEN_NAME = _Anonymous_14.NJS_TOKEN_NAME;
    enum NJS_TOKEN_OBJECT = _Anonymous_14.NJS_TOKEN_OBJECT;
    enum NJS_TOKEN_OBJECT_VALUE = _Anonymous_14.NJS_TOKEN_OBJECT_VALUE;
    enum NJS_TOKEN_PROPERTY = _Anonymous_14.NJS_TOKEN_PROPERTY;
    enum NJS_TOKEN_PROPERTY_INIT = _Anonymous_14.NJS_TOKEN_PROPERTY_INIT;
    enum NJS_TOKEN_PROPERTY_DELETE = _Anonymous_14.NJS_TOKEN_PROPERTY_DELETE;
    enum NJS_TOKEN_PROPERTY_GETTER = _Anonymous_14.NJS_TOKEN_PROPERTY_GETTER;
    enum NJS_TOKEN_PROPERTY_SETTER = _Anonymous_14.NJS_TOKEN_PROPERTY_SETTER;
    enum NJS_TOKEN_PROTO_INIT = _Anonymous_14.NJS_TOKEN_PROTO_INIT;
    enum NJS_TOKEN_ARRAY = _Anonymous_14.NJS_TOKEN_ARRAY;
    enum NJS_TOKEN_GRAVE = _Anonymous_14.NJS_TOKEN_GRAVE;
    enum NJS_TOKEN_TEMPLATE_LITERAL = _Anonymous_14.NJS_TOKEN_TEMPLATE_LITERAL;
    enum NJS_TOKEN_FUNCTION = _Anonymous_14.NJS_TOKEN_FUNCTION;
    enum NJS_TOKEN_FUNCTION_DECLARATION = _Anonymous_14.NJS_TOKEN_FUNCTION_DECLARATION;
    enum NJS_TOKEN_FUNCTION_EXPRESSION = _Anonymous_14.NJS_TOKEN_FUNCTION_EXPRESSION;
    enum NJS_TOKEN_FUNCTION_CALL = _Anonymous_14.NJS_TOKEN_FUNCTION_CALL;
    enum NJS_TOKEN_METHOD_CALL = _Anonymous_14.NJS_TOKEN_METHOD_CALL;
    enum NJS_TOKEN_ARGUMENT = _Anonymous_14.NJS_TOKEN_ARGUMENT;
    enum NJS_TOKEN_RETURN = _Anonymous_14.NJS_TOKEN_RETURN;
    enum NJS_TOKEN_ASYNC_FUNCTION = _Anonymous_14.NJS_TOKEN_ASYNC_FUNCTION;
    enum NJS_TOKEN_ASYNC_FUNCTION_DECLARATION = _Anonymous_14.NJS_TOKEN_ASYNC_FUNCTION_DECLARATION;
    enum NJS_TOKEN_ASYNC_FUNCTION_EXPRESSION = _Anonymous_14.NJS_TOKEN_ASYNC_FUNCTION_EXPRESSION;
    enum NJS_TOKEN_REGEXP = _Anonymous_14.NJS_TOKEN_REGEXP;
    enum NJS_TOKEN_EXTERNAL = _Anonymous_14.NJS_TOKEN_EXTERNAL;
    enum NJS_TOKEN_STATEMENT = _Anonymous_14.NJS_TOKEN_STATEMENT;
    enum NJS_TOKEN_BLOCK = _Anonymous_14.NJS_TOKEN_BLOCK;
    enum NJS_TOKEN_VAR = _Anonymous_14.NJS_TOKEN_VAR;
    enum NJS_TOKEN_IF = _Anonymous_14.NJS_TOKEN_IF;
    enum NJS_TOKEN_ELSE = _Anonymous_14.NJS_TOKEN_ELSE;
    enum NJS_TOKEN_BRANCHING = _Anonymous_14.NJS_TOKEN_BRANCHING;
    enum NJS_TOKEN_WHILE = _Anonymous_14.NJS_TOKEN_WHILE;
    enum NJS_TOKEN_DO = _Anonymous_14.NJS_TOKEN_DO;
    enum NJS_TOKEN_FOR = _Anonymous_14.NJS_TOKEN_FOR;
    enum NJS_TOKEN_FOR_IN = _Anonymous_14.NJS_TOKEN_FOR_IN;
    enum NJS_TOKEN_BREAK = _Anonymous_14.NJS_TOKEN_BREAK;
    enum NJS_TOKEN_CONTINUE = _Anonymous_14.NJS_TOKEN_CONTINUE;
    enum NJS_TOKEN_SWITCH = _Anonymous_14.NJS_TOKEN_SWITCH;
    enum NJS_TOKEN_CASE = _Anonymous_14.NJS_TOKEN_CASE;
    enum NJS_TOKEN_DEFAULT = _Anonymous_14.NJS_TOKEN_DEFAULT;
    enum NJS_TOKEN_WITH = _Anonymous_14.NJS_TOKEN_WITH;
    enum NJS_TOKEN_TRY = _Anonymous_14.NJS_TOKEN_TRY;
    enum NJS_TOKEN_CATCH = _Anonymous_14.NJS_TOKEN_CATCH;
    enum NJS_TOKEN_FINALLY = _Anonymous_14.NJS_TOKEN_FINALLY;
    enum NJS_TOKEN_THROW = _Anonymous_14.NJS_TOKEN_THROW;
    enum NJS_TOKEN_THIS = _Anonymous_14.NJS_TOKEN_THIS;
    enum NJS_TOKEN_ARGUMENTS = _Anonymous_14.NJS_TOKEN_ARGUMENTS;
    enum NJS_TOKEN_EVAL = _Anonymous_14.NJS_TOKEN_EVAL;
    enum NJS_TOKEN_IMPORT = _Anonymous_14.NJS_TOKEN_IMPORT;
    enum NJS_TOKEN_EXPORT = _Anonymous_14.NJS_TOKEN_EXPORT;
    enum NJS_TOKEN_TARGET = _Anonymous_14.NJS_TOKEN_TARGET;
    enum NJS_TOKEN_FROM = _Anonymous_14.NJS_TOKEN_FROM;
    enum NJS_TOKEN_META = _Anonymous_14.NJS_TOKEN_META;
    enum NJS_TOKEN_AWAIT = _Anonymous_14.NJS_TOKEN_AWAIT;
    enum NJS_TOKEN_ASYNC = _Anonymous_14.NJS_TOKEN_ASYNC;
    enum NJS_TOKEN_CLASS = _Anonymous_14.NJS_TOKEN_CLASS;
    enum NJS_TOKEN_CONST = _Anonymous_14.NJS_TOKEN_CONST;
    enum NJS_TOKEN_DEBUGGER = _Anonymous_14.NJS_TOKEN_DEBUGGER;
    enum NJS_TOKEN_ENUM = _Anonymous_14.NJS_TOKEN_ENUM;
    enum NJS_TOKEN_EXTENDS = _Anonymous_14.NJS_TOKEN_EXTENDS;
    enum NJS_TOKEN_IMPLEMENTS = _Anonymous_14.NJS_TOKEN_IMPLEMENTS;
    enum NJS_TOKEN_INTERFACE = _Anonymous_14.NJS_TOKEN_INTERFACE;
    enum NJS_TOKEN_LET = _Anonymous_14.NJS_TOKEN_LET;
    enum NJS_TOKEN_PACKAGE = _Anonymous_14.NJS_TOKEN_PACKAGE;
    enum NJS_TOKEN_PRIVATE = _Anonymous_14.NJS_TOKEN_PRIVATE;
    enum NJS_TOKEN_PROTECTED = _Anonymous_14.NJS_TOKEN_PROTECTED;
    enum NJS_TOKEN_PUBLIC = _Anonymous_14.NJS_TOKEN_PUBLIC;
    enum NJS_TOKEN_STATIC = _Anonymous_14.NJS_TOKEN_STATIC;
    enum NJS_TOKEN_SUPER = _Anonymous_14.NJS_TOKEN_SUPER;
    enum NJS_TOKEN_RESERVED = _Anonymous_14.NJS_TOKEN_RESERVED;

    alias njs_keyword_type_t = _Anonymous_15;

    enum _Anonymous_15
    {

        NJS_KEYWORD_TYPE_UNDEF = 0,

        NJS_KEYWORD_TYPE_RESERVED = 1,

        NJS_KEYWORD_TYPE_KEYWORD = 2,
    }
    enum NJS_KEYWORD_TYPE_UNDEF = _Anonymous_15.NJS_KEYWORD_TYPE_UNDEF;
    enum NJS_KEYWORD_TYPE_RESERVED = _Anonymous_15.NJS_KEYWORD_TYPE_RESERVED;
    enum NJS_KEYWORD_TYPE_KEYWORD = _Anonymous_15.NJS_KEYWORD_TYPE_KEYWORD;

    struct njs_lexer_entry_t
    {

        njs_str_t name;
    }

    struct njs_keyword_t
    {

        njs_lexer_entry_t entry;

        njs_token_type_t type;

        uint reserved;
    }

    struct njs_lexer_keyword_entry_t
    {

        const(char)* key;

        const(njs_keyword_t)* value;

        c_ulong length;

        c_ulong next;
    }

    struct njs_lexer_token_t
    {
        import std.bitmanip: bitfields;

        align(4):
        mixin(bitfields!(

            njs_token_type_t, "type", 16,
        ));

        njs_keyword_type_t keyword_type;

        uint line;

        c_ulong unique_id;

        njs_str_t text;

        double number;

        njs_queue_link_s link;
    }

    struct njs_lexer_t
    {
        import std.bitmanip: bitfields;

        align(4):

        njs_lexer_token_t* token;

        njs_queue_t preread;

        ubyte* prev_start;
        mixin(bitfields!(

            njs_token_type_t, "prev_type", 16,

            njs_token_type_t, "last_type", 16,
        ));

        uint line;

        njs_str_t file;

        njs_lvlhsh_t* keywords_hash;

        njs_mp_s* mem_pool;

        ubyte* start;

        ubyte* end;
    }

    int njs_lexer_init(njs_vm_s*, njs_lexer_t*, njs_str_t*, ubyte*, ubyte*, uint) @nogc nothrow;

    njs_lexer_token_t* njs_lexer_token(njs_lexer_t*, uint) @nogc nothrow;

    njs_lexer_token_t* njs_lexer_peek_token(njs_lexer_t*, njs_lexer_token_t*, uint) @nogc nothrow;

    void njs_lexer_consume_token(njs_lexer_t*, uint) @nogc nothrow;

    int njs_lexer_make_token(njs_lexer_t*, njs_lexer_token_t*) @nogc nothrow;

    const(njs_lexer_keyword_entry_t)* njs_lexer_keyword(const(ubyte)*, c_ulong) @nogc nothrow;

    int njs_lexer_keywords(njs_arr_t*) @nogc nothrow;

    extern __gshared const(njs_lvlhsh_proto_t) njs_lexer_hash_proto;

    alias njs_lvlhsh_query_t = njs_lvlhsh_query_s;

    struct njs_lvlhsh_query_s
    {

        uint key_hash;

        njs_str_t key;

        ubyte replace;

        void* value;

        const(njs_lvlhsh_proto_t)* proto;

        void* pool;

        void* data;
    }
    alias njs_lvlhsh_test_t = int function(njs_lvlhsh_query_s*, void*);
    alias njs_lvlhsh_alloc_t = void* function(void*, c_ulong);
    alias njs_lvlhsh_free_t = void function(void*, void*, c_ulong);

    struct njs_lvlhsh_proto_t
    {

        uint bucket_end;

        uint bucket_size;

        uint bucket_mask;

        ubyte[8] shift;

        int function(njs_lvlhsh_query_s*, void*) test;

        void* function(void*, c_ulong) alloc;

        void function(void*, void*, c_ulong) free;
    }

    struct njs_lvlhsh_t
    {

        void* slot;
    }

    int njs_lvlhsh_find(const(njs_lvlhsh_t)*, njs_lvlhsh_query_s*) @nogc nothrow;

    int njs_lvlhsh_insert(njs_lvlhsh_t*, njs_lvlhsh_query_s*) @nogc nothrow;

    int njs_lvlhsh_delete(njs_lvlhsh_t*, njs_lvlhsh_query_s*) @nogc nothrow;

    struct njs_lvlhsh_each_t
    {

        const(njs_lvlhsh_proto_t)* proto;

        uint* bucket;

        uint current;

        uint entry;

        uint entries;

        uint key_hash;
    }

    void* njs_lvlhsh_each(const(njs_lvlhsh_t)*, njs_lvlhsh_each_t*) @nogc nothrow;

    void* njs_zalloc(c_ulong) @nogc nothrow;

    void* njs_memalign(c_ulong, c_ulong) @nogc nothrow;

    extern __gshared const(njs_object_init_s) njs_math_object_init;

    struct njs_md5_t
    {

        c_ulong bytes;

        uint a;

        uint b;

        uint c;

        uint d;

        ubyte[64] buffer;
    }

    void njs_md5_init(njs_md5_t*) @nogc nothrow;

    void njs_md5_update(njs_md5_t*, const(void)*, c_ulong) @nogc nothrow;

    void njs_md5_final(ubyte*, njs_md5_t*) @nogc nothrow;

    njs_mod_s* njs_module_add(njs_vm_s*, njs_str_t*) @nogc nothrow;

    njs_mod_s* njs_module_find(njs_vm_s*, njs_str_t*, uint) @nogc nothrow;

    njs_mod_s* njs_parser_module(njs_parser_s*, njs_str_t*) @nogc nothrow;

    int njs_module_require(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    extern __gshared njs_module_t*[0] njs_modules;

    extern __gshared const(njs_lvlhsh_proto_t) njs_modules_hash_proto;

    alias njs_mp_t = njs_mp_s;
    struct njs_mp_s;

    alias njs_mp_cleanup_t = njs_mp_cleanup_s;

    struct njs_mp_cleanup_s
    {

        void function(void*) handler;

        void* data;

        njs_mp_cleanup_s* next;
    }
    alias njs_mp_cleanup_pt = void function(void*);

    struct njs_mp_stat_t
    {

        c_ulong size;

        c_ulong nblocks;

        c_ulong page_size;

        c_ulong cluster_size;
    }

    njs_mp_s* njs_mp_create(c_ulong, c_ulong, c_ulong, c_ulong) @nogc nothrow;

    njs_mp_s* njs_mp_fast_create(c_ulong, c_ulong, c_ulong, c_ulong) @nogc nothrow;

    uint njs_mp_is_empty(njs_mp_s*) @nogc nothrow;

    void njs_mp_destroy(njs_mp_s*) @nogc nothrow;

    void njs_mp_stat(njs_mp_s*, njs_mp_stat_t*) @nogc nothrow;

    void* njs_mp_alloc(njs_mp_s*, c_ulong) @nogc nothrow;

    void* njs_mp_zalloc(njs_mp_s*, c_ulong) @nogc nothrow;

    void* njs_mp_align(njs_mp_s*, c_ulong, c_ulong) @nogc nothrow;

    void* njs_mp_zalign(njs_mp_s*, c_ulong, c_ulong) @nogc nothrow;

    njs_mp_cleanup_s* njs_mp_cleanup_add(njs_mp_s*, c_ulong) @nogc nothrow;

    void njs_mp_free(njs_mp_s*, void*) @nogc nothrow;

    uint njs_murmur_hash2(const(void)*, c_ulong) @nogc nothrow;

    uint njs_murmur_hash2_uint32(const(void)*) @nogc nothrow;

    double njs_key_to_index(const(njs_value_s)*) @nogc nothrow;

    double njs_number_dec_parse(const(ubyte)**, const(ubyte)*, uint) @nogc nothrow;

    double njs_number_oct_parse(const(ubyte)**, const(ubyte)*) @nogc nothrow;

    double njs_number_bin_parse(const(ubyte)**, const(ubyte)*) @nogc nothrow;

    double njs_number_hex_parse(const(ubyte)**, const(ubyte)*, uint) @nogc nothrow;

    int njs_number_to_string(njs_vm_s*, njs_value_s*, const(njs_value_s)*) @nogc nothrow;

    int njs_number_to_chain(njs_vm_s*, njs_chb_t*, double) @nogc nothrow;

    int njs_number_global_is_nan(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_number_global_is_finite(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_number_parse_int(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_number_parse_float(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_number_type_init;

    alias njs_object_prop_define_t = _Anonymous_16;

    enum _Anonymous_16
    {

        NJS_OBJECT_PROP_DESCRIPTOR = 0,

        NJS_OBJECT_PROP_GETTER = 1,

        NJS_OBJECT_PROP_SETTER = 2,
    }
    enum NJS_OBJECT_PROP_DESCRIPTOR = _Anonymous_16.NJS_OBJECT_PROP_DESCRIPTOR;
    enum NJS_OBJECT_PROP_GETTER = _Anonymous_16.NJS_OBJECT_PROP_GETTER;
    enum NJS_OBJECT_PROP_SETTER = _Anonymous_16.NJS_OBJECT_PROP_SETTER;

    alias njs_traverse_t = njs_traverse_s;

    struct njs_traverse_s
    {

        njs_traverse_s* parent;

        njs_object_prop_s* prop;

        njs_value_s value;

        njs_array_s* keys;

        c_long index;
    }
    alias njs_object_traverse_cb_t = int function(njs_vm_s*, njs_traverse_s*, void*);

    njs_object_s* njs_object_alloc(njs_vm_s*) @nogc nothrow;

    njs_object_s* njs_object_value_copy(njs_vm_s*, njs_value_s*) @nogc nothrow;

    njs_object_value_s* njs_object_value_alloc(njs_vm_s*, uint, c_ulong, const(njs_value_s)*) @nogc nothrow;

    njs_array_s* njs_object_enumerate(njs_vm_s*, const(njs_object_s)*, njs_object_enum_t, njs_object_enum_type_t, uint) @nogc nothrow;

    njs_array_s* njs_object_own_enumerate(njs_vm_s*, const(njs_object_s)*, njs_object_enum_t, njs_object_enum_type_t, uint) @nogc nothrow;

    int njs_object_traverse(njs_vm_s*, njs_object_s*, void*, int function(njs_vm_s*, njs_traverse_s*, void*)) @nogc nothrow;

    int njs_object_hash_create(njs_vm_s*, njs_lvlhsh_t*, const(njs_object_prop_s)*, uint) @nogc nothrow;

    int njs_primitive_prototype_get_proto(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_object_prototype_create(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    njs_value_s* njs_property_prototype_create(njs_vm_s*, njs_lvlhsh_t*, njs_object_s*) @nogc nothrow;

    int njs_object_prototype_proto(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_object_prototype_create_constructor(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    njs_value_s* njs_property_constructor_set(njs_vm_s*, njs_lvlhsh_t*, njs_value_s*) @nogc nothrow;

    int njs_object_to_string(njs_vm_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_object_prototype_to_string(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_object_length(njs_vm_s*, njs_value_s*, c_long*) @nogc nothrow;

    int njs_prop_private_copy(njs_vm_s*, njs_property_query_t*) @nogc nothrow;

    njs_object_prop_s* njs_object_prop_alloc(njs_vm_s*, const(njs_value_s)*, const(njs_value_s)*, ubyte) @nogc nothrow;

    int njs_object_property(njs_vm_s*, const(njs_value_s)*, njs_lvlhsh_query_s*, njs_value_s*) @nogc nothrow;

    njs_object_prop_s* njs_object_property_add(njs_vm_s*, njs_value_s*, njs_value_s*, uint) @nogc nothrow;

    int njs_object_prop_define(njs_vm_s*, njs_value_s*, njs_value_s*, njs_value_s*, njs_object_prop_define_t) @nogc nothrow;

    int njs_object_prop_descriptor(njs_vm_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    const(char)* njs_prop_type_string(njs_object_prop_type_t) @nogc nothrow;

    int njs_object_prop_init(njs_vm_s*, const(njs_object_init_s)*, const(njs_object_prop_s)*, njs_value_s*, njs_value_s*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_obj_type_init;
    alias njs_parser_state_func_t = int function(njs_parser_s*, njs_lexer_token_t*, njs_queue_link_s*);

    struct njs_parser_stack_entry_t
    {

        int function(njs_parser_s*, njs_lexer_token_t*, njs_queue_link_s*) state;

        njs_queue_link_s link;

        njs_parser_node_s* node;

        uint optional;
    }

    struct njs_parser_rbtree_node_t
    {

        njs_rbtree_part_t node;

        ubyte node_color;

        c_ulong key;

        c_ulong index;
    }

    struct njs_declaration_t
    {

        njs_value_s* value;

        c_ulong index;
    }
    alias njs_parser_traverse_cb_t = int function(njs_vm_s*, njs_parser_node_s*, void*);

    int njs_parser_failed_state(njs_parser_s*, njs_lexer_token_t*, njs_queue_link_s*) @nogc nothrow;

    c_long njs_parser_scope_rbtree_compare(njs_rbtree_node_s*, njs_rbtree_node_s*) @nogc nothrow;

    int njs_parser_init(njs_vm_s*, njs_parser_s*, njs_parser_scope_s*, njs_str_t*, ubyte*, ubyte*, uint) @nogc nothrow;

    int njs_parser(njs_vm_s*, njs_parser_s*) @nogc nothrow;

    uint njs_variable_closure_test(njs_parser_scope_s*, njs_parser_scope_s*) @nogc nothrow;

    njs_variable_t* njs_variable_resolve(njs_vm_s*, njs_parser_node_s*) @nogc nothrow;

    c_ulong njs_variable_index(njs_vm_s*, njs_parser_node_s*) @nogc nothrow;

    uint njs_parser_has_side_effect(njs_parser_node_s*) @nogc nothrow;

    int njs_parser_variable_reference(njs_parser_s*, njs_parser_scope_s*, njs_parser_node_s*, c_ulong, njs_reference_type_t) @nogc nothrow;

    njs_token_type_t njs_parser_unexpected_token(njs_vm_s*, njs_parser_s*, njs_str_t*, njs_token_type_t) @nogc nothrow;

    int njs_parser_string_create(njs_vm_s*, njs_lexer_token_t*, njs_value_s*) @nogc nothrow;

    void njs_parser_lexer_error(njs_parser_s*, njs_object_type_t, const(char)*, ...) @nogc nothrow;

    void njs_parser_node_error(njs_vm_s*, njs_object_type_t, njs_parser_node_s*, njs_str_t*, const(char)*, ...) @nogc nothrow;

    int njs_parser_traverse(njs_vm_s*, njs_parser_node_s*, void*, int function(njs_vm_s*, njs_parser_node_s*, void*)) @nogc nothrow;

    int njs_parser_serialize_ast(njs_parser_node_s*, njs_chb_t*) @nogc nothrow;

    alias njs_promise_type_t = _Anonymous_17;

    enum _Anonymous_17
    {

        NJS_PROMISE_PENDING = 0,

        NJS_PROMISE_FULFILL = 1,

        NJS_PROMISE_REJECTED = 2,
    }
    enum NJS_PROMISE_PENDING = _Anonymous_17.NJS_PROMISE_PENDING;
    enum NJS_PROMISE_FULFILL = _Anonymous_17.NJS_PROMISE_FULFILL;
    enum NJS_PROMISE_REJECTED = _Anonymous_17.NJS_PROMISE_REJECTED;

    struct njs_promise_capability_t
    {

        njs_value_s promise;

        njs_value_s resolve;

        njs_value_s reject;
    }

    struct njs_promise_data_t
    {

        njs_promise_type_t state;

        njs_value_s result;

        njs_queue_t fulfill_queue;

        njs_queue_t reject_queue;

        uint is_handled;
    }

    int njs_promise_constructor(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    njs_promise_capability_t* njs_promise_new_capability(njs_vm_s*, njs_value_s*) @nogc nothrow;

    njs_function_s* njs_promise_create_function(njs_vm_s*, c_ulong) @nogc nothrow;

    int njs_promise_perform_then(njs_vm_s*, njs_value_s*, njs_value_s*, njs_value_s*, njs_promise_capability_t*) @nogc nothrow;

    njs_object_value_s* njs_promise_resolve(njs_vm_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_promise_type_init;

    alias njs_queue_link_t = njs_queue_link_s;

    struct njs_queue_link_s
    {

        njs_queue_link_s* prev;

        njs_queue_link_s* next;
    }

    struct njs_queue_t
    {

        njs_queue_link_s head;
    }

    njs_queue_link_s* njs_queue_middle(njs_queue_t*) @nogc nothrow;

    void njs_queue_sort(njs_queue_t*, int function(const(void)*, const(njs_queue_link_s)*, const(njs_queue_link_s)*), const(void)*) @nogc nothrow;

    struct njs_random_t
    {

        int count;

        int pid;

        ubyte i;

        ubyte j;

        ubyte[256] s;
    }

    void njs_random_init(njs_random_t*, int) @nogc nothrow;

    void njs_random_stir(njs_random_t*, int) @nogc nothrow;

    void njs_random_add(njs_random_t*, const(ubyte)*, uint) @nogc nothrow;

    uint njs_random(njs_random_t*) @nogc nothrow;

    alias njs_rbtree_node_t = njs_rbtree_node_s;

    struct njs_rbtree_node_s
    {

        njs_rbtree_node_s* left;

        njs_rbtree_node_s* right;

        njs_rbtree_node_s* parent;

        ubyte color;
    }

    struct njs_rbtree_part_t
    {

        njs_rbtree_node_s* left;

        njs_rbtree_node_s* right;

        njs_rbtree_node_s* parent;
    }

    struct njs_rbtree_t
    {

        njs_rbtree_node_s sentinel;
    }
    alias njs_rbtree_compare_t = c_long function(njs_rbtree_node_s*, njs_rbtree_node_s*);

    void njs_rbtree_init(njs_rbtree_t*, c_long function(njs_rbtree_node_s*, njs_rbtree_node_s*)) @nogc nothrow;

    void njs_rbtree_insert(njs_rbtree_t*, njs_rbtree_part_t*) @nogc nothrow;

    njs_rbtree_node_s* njs_rbtree_find(njs_rbtree_t*, njs_rbtree_part_t*) @nogc nothrow;

    njs_rbtree_node_s* njs_rbtree_find_less_or_equal(njs_rbtree_t*, njs_rbtree_part_t*) @nogc nothrow;

    njs_rbtree_node_s* njs_rbtree_find_greater_or_equal(njs_rbtree_t*, njs_rbtree_part_t*) @nogc nothrow;

    void njs_rbtree_delete(njs_rbtree_t*, njs_rbtree_part_t*) @nogc nothrow;

    njs_rbtree_node_s* njs_rbtree_destroy_next(njs_rbtree_t*, njs_rbtree_node_s**) @nogc nothrow;

    alias njs_regex_flags_t = _Anonymous_18;

    enum _Anonymous_18
    {

        NJS_REGEX_INVALID_FLAG = -1,

        NJS_REGEX_NO_FLAGS = 0,

        NJS_REGEX_GLOBAL = 1,

        NJS_REGEX_IGNORE_CASE = 2,

        NJS_REGEX_MULTILINE = 4,

        NJS_REGEX_STICKY = 8,

        NJS_REGEX_UTF8 = 16,
    }
    enum NJS_REGEX_INVALID_FLAG = _Anonymous_18.NJS_REGEX_INVALID_FLAG;
    enum NJS_REGEX_NO_FLAGS = _Anonymous_18.NJS_REGEX_NO_FLAGS;
    enum NJS_REGEX_GLOBAL = _Anonymous_18.NJS_REGEX_GLOBAL;
    enum NJS_REGEX_IGNORE_CASE = _Anonymous_18.NJS_REGEX_IGNORE_CASE;
    enum NJS_REGEX_MULTILINE = _Anonymous_18.NJS_REGEX_MULTILINE;
    enum NJS_REGEX_STICKY = _Anonymous_18.NJS_REGEX_STICKY;
    enum NJS_REGEX_UTF8 = _Anonymous_18.NJS_REGEX_UTF8;
    alias njs_pcre_malloc_t = void* function(c_ulong, void*);
    alias njs_pcre_free_t = void function(void*, void*);

    struct njs_regex_t
    {

        void* code;

        void* extra;

        int ncaptures;

        int backrefmax;

        int nentries;

        int entry_size;

        char* entries;
    }

    void* njs_regex_generic_ctx_create(void* function(c_ulong, void*), void function(void*, void*), void*) @nogc nothrow;

    void* njs_regex_compile_ctx_create(void*) @nogc nothrow;

    int njs_regex_escape(njs_mp_s*, njs_str_t*) @nogc nothrow;

    int njs_regex_compile(njs_regex_t*, ubyte*, c_ulong, njs_regex_flags_t, void*, njs_trace_s*) @nogc nothrow;

    uint njs_regex_is_valid(njs_regex_t*) @nogc nothrow;

    int njs_regex_named_captures(njs_regex_t*, njs_str_t*, int) @nogc nothrow;

    void* njs_regex_match_data(njs_regex_t*, void*) @nogc nothrow;

    void njs_regex_match_data_free(void*, void*) @nogc nothrow;

    int njs_regex_match(njs_regex_t*, const(ubyte)*, c_ulong, c_ulong, void*, njs_trace_s*) @nogc nothrow;

    c_ulong njs_regex_capture(void*, uint) @nogc nothrow;

    int njs_regexp_init(njs_vm_s*) @nogc nothrow;

    int njs_regexp_create(njs_vm_s*, njs_value_s*, ubyte*, c_ulong, njs_regex_flags_t) @nogc nothrow;

    njs_regex_flags_t njs_regexp_flags(ubyte**, ubyte*) @nogc nothrow;

    njs_regexp_pattern_s* njs_regexp_pattern_create(njs_vm_s*, ubyte*, c_ulong, njs_regex_flags_t) @nogc nothrow;

    int njs_regexp_match(njs_vm_s*, njs_regex_t*, const(ubyte)*, c_ulong, c_ulong, void*) @nogc nothrow;

    njs_regexp_s* njs_regexp_alloc(njs_vm_s*, njs_regexp_pattern_s*) @nogc nothrow;

    int njs_regexp_exec(njs_vm_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_regexp_prototype_exec(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_regexp_to_string(njs_vm_s*, njs_value_s*, const(njs_value_s)*) @nogc nothrow;

    extern __gshared const(njs_object_init_s) njs_regexp_instance_init;

    extern __gshared const(njs_object_type_init_t) njs_regexp_type_init;

    alias njs_regexp_utf8_t = _Anonymous_19;

    enum _Anonymous_19
    {

        NJS_REGEXP_BYTE = 0,

        NJS_REGEXP_UTF8 = 1,
    }
    enum NJS_REGEXP_BYTE = _Anonymous_19.NJS_REGEXP_BYTE;
    enum NJS_REGEXP_UTF8 = _Anonymous_19.NJS_REGEXP_UTF8;

    alias njs_regexp_group_t = njs_regexp_group_s;
    struct njs_regexp_group_s;

    c_ulong njs_scope_temp_index(njs_parser_scope_s*) @nogc nothrow;

    njs_value_s* njs_scope_create_index_value(njs_vm_s*, c_ulong) @nogc nothrow;

    njs_value_s** njs_scope_make(njs_vm_s*, uint) @nogc nothrow;

    c_ulong njs_scope_global_index(njs_vm_s*, const(njs_value_s)*, uint) @nogc nothrow;

    njs_value_s* njs_scope_value_get(njs_vm_s*, c_ulong) @nogc nothrow;

    struct njs_sha1_t
    {

        c_ulong bytes;

        uint a;

        uint b;

        uint c;

        uint d;

        uint e;

        ubyte[64] buffer;
    }

    void njs_sha1_init(njs_sha1_t*) @nogc nothrow;

    void njs_sha1_update(njs_sha1_t*, const(void)*, c_ulong) @nogc nothrow;

    void njs_sha1_final(ubyte*, njs_sha1_t*) @nogc nothrow;

    struct njs_sha2_t
    {

        c_ulong bytes;

        uint a;

        uint b;

        uint c;

        uint d;

        uint e;

        uint f;

        uint g;

        uint h;

        ubyte[64] buffer;
    }

    void njs_sha2_init(njs_sha2_t*) @nogc nothrow;

    void njs_sha2_update(njs_sha2_t*, const(void)*, c_ulong) @nogc nothrow;

    void njs_sha2_final(ubyte*, njs_sha2_t*) @nogc nothrow;

    ubyte* njs_sprintf(ubyte*, ubyte*, const(char)*, ...) @nogc nothrow;

    ubyte* njs_vsprintf(ubyte*, ubyte*, const(char)*, va_list*) @nogc nothrow;

    int njs_dprint(int, ubyte*, c_ulong) @nogc nothrow;

    int njs_dprintf(int, const(char)*, ...) @nogc nothrow;

    struct njs_str_t
    {

        c_ulong length;

        ubyte* start;
    }

    int njs_strncasecmp(ubyte*, ubyte*, c_ulong) @nogc nothrow;

    struct njs_string_prop_t
    {

        c_ulong size;

        c_ulong length;

        ubyte* start;
    }

    struct njs_slice_prop_t
    {

        c_ulong start;

        c_ulong length;

        c_ulong string_length;
    }

    alias njs_utf8_t = _Anonymous_20;

    enum _Anonymous_20
    {

        NJS_STRING_BYTE = 0,

        NJS_STRING_ASCII = 1,

        NJS_STRING_UTF8 = 2,
    }
    enum NJS_STRING_BYTE = _Anonymous_20.NJS_STRING_BYTE;
    enum NJS_STRING_ASCII = _Anonymous_20.NJS_STRING_ASCII;
    enum NJS_STRING_UTF8 = _Anonymous_20.NJS_STRING_UTF8;

    alias njs_trim_t = _Anonymous_21;

    enum _Anonymous_21
    {

        NJS_TRIM_START = 1,

        NJS_TRIM_END = 2,
    }
    enum NJS_TRIM_START = _Anonymous_21.NJS_TRIM_START;
    enum NJS_TRIM_END = _Anonymous_21.NJS_TRIM_END;

    int njs_string_set(njs_vm_s*, njs_value_s*, const(ubyte)*, uint) @nogc nothrow;

    ubyte* njs_string_alloc(njs_vm_s*, njs_value_s*, c_ulong, c_ulong) @nogc nothrow;

    int njs_string_new(njs_vm_s*, njs_value_s*, const(ubyte)*, uint, uint) @nogc nothrow;

    int njs_string_create(njs_vm_s*, njs_value_s*, const(char)*, c_ulong) @nogc nothrow;

    void njs_encode_hex(njs_str_t*, const(njs_str_t)*) @nogc nothrow;

    c_ulong njs_encode_hex_length(const(njs_str_t)*, c_ulong*) @nogc nothrow;

    void njs_encode_base64(njs_str_t*, const(njs_str_t)*) @nogc nothrow;

    c_ulong njs_encode_base64_length(const(njs_str_t)*, c_ulong*) @nogc nothrow;

    void njs_decode_utf8(njs_str_t*, const(njs_str_t)*) @nogc nothrow;

    c_ulong njs_decode_utf8_length(const(njs_str_t)*, c_ulong*) @nogc nothrow;

    void njs_decode_hex(njs_str_t*, const(njs_str_t)*) @nogc nothrow;

    c_ulong njs_decode_hex_length(const(njs_str_t)*, c_ulong*) @nogc nothrow;

    void njs_decode_base64(njs_str_t*, const(njs_str_t)*) @nogc nothrow;

    c_ulong njs_decode_base64_length(const(njs_str_t)*, c_ulong*) @nogc nothrow;

    void njs_decode_base64url(njs_str_t*, const(njs_str_t)*) @nogc nothrow;

    c_ulong njs_decode_base64url_length(const(njs_str_t)*, c_ulong*) @nogc nothrow;

    int njs_string_hex(njs_vm_s*, njs_value_s*, const(njs_str_t)*) @nogc nothrow;

    int njs_string_base64(njs_vm_s*, njs_value_s*, const(njs_str_t)*) @nogc nothrow;

    int njs_string_base64url(njs_vm_s*, njs_value_s*, const(njs_str_t)*) @nogc nothrow;

    int njs_string_decode_utf8(njs_vm_s*, njs_value_s*, const(njs_str_t)*) @nogc nothrow;

    int njs_string_decode_hex(njs_vm_s*, njs_value_s*, const(njs_str_t)*) @nogc nothrow;

    int njs_string_decode_base64(njs_vm_s*, njs_value_s*, const(njs_str_t)*) @nogc nothrow;

    int njs_string_decode_base64url(njs_vm_s*, njs_value_s*, const(njs_str_t)*) @nogc nothrow;

    void njs_string_truncate(njs_value_s*, uint, uint) @nogc nothrow;

    uint njs_string_trim(const(njs_value_s)*, njs_string_prop_t*, uint) @nogc nothrow;

    void njs_string_copy(njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_string_validate(njs_vm_s*, njs_string_prop_t*, njs_value_s*) @nogc nothrow;

    c_ulong njs_string_prop(njs_string_prop_t*, const(njs_value_s)*) @nogc nothrow;

    int njs_string_cmp(const(njs_value_s)*, const(njs_value_s)*) @nogc nothrow;

    void njs_string_slice_string_prop(njs_string_prop_t*, const(njs_string_prop_t)*, const(njs_slice_prop_t)*) @nogc nothrow;

    int njs_string_slice(njs_vm_s*, njs_value_s*, const(njs_string_prop_t)*, const(njs_slice_prop_t)*) @nogc nothrow;

    const(ubyte)* njs_string_offset(const(ubyte)*, const(ubyte)*, c_ulong) @nogc nothrow;

    uint njs_string_index(njs_string_prop_t*, uint) @nogc nothrow;

    void njs_string_offset_map_init(const(ubyte)*, c_ulong) @nogc nothrow;

    double njs_string_to_index(const(njs_value_s)*) @nogc nothrow;

    const(char)* njs_string_to_c_string(njs_vm_s*, njs_value_s*) @nogc nothrow;

    int njs_string_encode_uri(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_string_decode_uri(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_string_btoa(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_string_atob(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_string_prototype_concat(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_string_split_part_add(njs_vm_s*, njs_array_s*, njs_utf8_t, const(ubyte)*, c_ulong) @nogc nothrow;

    int njs_string_get_substitution(njs_vm_s*, njs_value_s*, njs_value_s*, c_long, njs_value_s*, c_long, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    extern __gshared const(njs_object_init_s) njs_string_instance_init;

    extern __gshared const(njs_object_type_init_t) njs_string_type_init;

    double njs_strtod(const(ubyte)**, const(ubyte)*, uint) @nogc nothrow;

    struct njs_rb_symbol_node_t
    {

        njs_rbtree_part_t node;

        ubyte node_color;

        uint key;

        njs_value_s name;
    }

    const(njs_value_s)* njs_symbol_description(const(njs_value_s)*) @nogc nothrow;

    int njs_symbol_descriptive_string(njs_vm_s*, njs_value_s*, const(njs_value_s)*) @nogc nothrow;

    c_long njs_symbol_rbtree_cmp(njs_rbtree_node_s*, njs_rbtree_node_s*) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_symbol_type_init;

    c_ulong njs_time() @nogc nothrow;

    int njs_set_timeout(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_set_immediate(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    int njs_clear_timeout(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    alias njs_trace_level_t = _Anonymous_22;

    enum _Anonymous_22
    {

        NJS_LEVEL_CRIT = 0,

        NJS_LEVEL_ERROR = 1,

        NJS_LEVEL_WARN = 2,

        NJS_LEVEL_INFO = 3,

        NJS_LEVEL_TRACE = 4,
    }
    enum NJS_LEVEL_CRIT = _Anonymous_22.NJS_LEVEL_CRIT;
    enum NJS_LEVEL_ERROR = _Anonymous_22.NJS_LEVEL_ERROR;
    enum NJS_LEVEL_WARN = _Anonymous_22.NJS_LEVEL_WARN;
    enum NJS_LEVEL_INFO = _Anonymous_22.NJS_LEVEL_INFO;
    enum NJS_LEVEL_TRACE = _Anonymous_22.NJS_LEVEL_TRACE;

    struct njs_trace_data_t
    {

        uint level;

        ubyte* end;

        const(char)* fmt;

        va_list[1] args;
    }

    alias njs_trace_t = njs_trace_s;

    struct njs_trace_s
    {

        uint level;

        uint size;

        ubyte* function(njs_trace_s*, njs_trace_data_t*, ubyte*) handler;

        void* data;

        njs_trace_s* prev;

        njs_trace_s* next;
    }
    alias njs_trace_handler_t = ubyte* function(njs_trace_s*, njs_trace_data_t*, ubyte*);

    void njs_trace_handler(njs_trace_s*, uint, const(char)*, ...) @nogc nothrow;

    njs_typed_array_s* njs_typed_array_alloc(njs_vm_s*, njs_value_s*, uint, uint, njs_object_type_t) @nogc nothrow;

    njs_array_buffer_s* njs_typed_array_writable(njs_vm_s*, njs_typed_array_s*) @nogc nothrow;

    int njs_typed_array_set_value(njs_vm_s*, njs_typed_array_s*, uint, njs_value_s*) @nogc nothrow;

    int njs_typed_array_to_chain(njs_vm_s*, njs_chb_t*, njs_typed_array_s*, njs_value_s*) @nogc nothrow;

    int njs_typed_array_prototype_slice(njs_vm_s*, njs_value_s*, uint, c_ulong) @nogc nothrow;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_type_init;

    extern __gshared const(njs_object_type_init_t) njs_data_view_type_init;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_u8_type_init;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_u8clamped_type_init;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_i8_type_init;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_u16_type_init;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_i16_type_init;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_u32_type_init;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_i32_type_init;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_f32_type_init;

    extern __gshared const(njs_object_type_init_t) njs_typed_array_f64_type_init;

    alias njs_int_t = int;

    alias njs_uint_t = uint;

    alias njs_uint128_t = UInt128;

    alias njs_bool_t = uint;

    alias njs_err_t = int;

    alias njs_off_t = c_long;

    alias njs_time_t = c_long;

    alias njs_pid_t = int;

    enum _Anonymous_23
    {

        NJS_UNICODE_BOM = 65279,

        NJS_UNICODE_REPLACEMENT = 65533,

        NJS_UNICODE_MAX_CODEPOINT = 1114111,

        NJS_UNICODE_ERROR = 2097151,

        NJS_UNICODE_CONTINUE = 3145727,
    }
    enum NJS_UNICODE_BOM = _Anonymous_23.NJS_UNICODE_BOM;
    enum NJS_UNICODE_REPLACEMENT = _Anonymous_23.NJS_UNICODE_REPLACEMENT;
    enum NJS_UNICODE_MAX_CODEPOINT = _Anonymous_23.NJS_UNICODE_MAX_CODEPOINT;
    enum NJS_UNICODE_ERROR = _Anonymous_23.NJS_UNICODE_ERROR;
    enum NJS_UNICODE_CONTINUE = _Anonymous_23.NJS_UNICODE_CONTINUE;

    struct njs_unicode_decode_t
    {

        uint codepoint;

        uint need;

        ubyte lower;

        ubyte upper;
    }

    extern __gshared char** environ;

    c_long njs_utf16_encode(uint, ubyte**, const(ubyte)*) @nogc nothrow;

    uint njs_utf16_decode(njs_unicode_decode_t*, const(ubyte)**, const(ubyte)*) @nogc nothrow;

    uint njs_utf8_decode(njs_unicode_decode_t*, const(ubyte)**, const(ubyte)*) @nogc nothrow;

    ubyte* njs_utf8_encode(ubyte*, uint) @nogc nothrow;

    ubyte* njs_utf8_stream_encode(njs_unicode_decode_t*, const(ubyte)*, const(ubyte)*, ubyte*, uint, uint) @nogc nothrow;

    int njs_utf8_casecmp(const(ubyte)*, const(ubyte)*, c_ulong, c_ulong) @nogc nothrow;

    uint njs_utf8_lower_case(const(ubyte)**, const(ubyte)*) @nogc nothrow;

    uint njs_utf8_upper_case(const(ubyte)**, const(ubyte)*) @nogc nothrow;

    c_long njs_utf8_stream_length(njs_unicode_decode_t*, const(ubyte)*, c_ulong, uint, uint, c_ulong*) @nogc nothrow;

    uint njs_utf8_is_valid(const(ubyte)*, c_ulong) @nogc nothrow;

    union njs_conv_f32_t
    {

        float f;

        uint u;
    }

    union njs_conv_f64_t
    {

        double f;

        c_ulong u;
    }

    struct njs_packed_u16_t
    {
    align(1):

        ushort v;
    }

    struct njs_packed_u32_t
    {
    align(1):

        uint v;
    }

    struct njs_packed_u64_t
    {
    align(1):

        c_ulong v;
    }
    alias njs_sort_cmp_t = int function(const(void)*, const(void)*, void*);

    void njs_qsort(void*, c_ulong, c_ulong, int function(const(void)*, const(void)*, void*), void*) @nogc nothrow;

    const(char)* njs_errno_string(int) @nogc nothrow;

    alias njs_value_type_t = _Anonymous_24;

    enum _Anonymous_24
    {

        NJS_NULL = 0,

        NJS_UNDEFINED = 1,

        NJS_BOOLEAN = 2,

        NJS_NUMBER = 3,

        NJS_SYMBOL = 4,

        NJS_STRING = 5,

        NJS_DATA = 6,

        NJS_INVALID = 7,

        NJS_OBJECT = 16,

        NJS_ARRAY = 17,

        NJS_FUNCTION = 18,

        NJS_REGEXP = 19,

        NJS_DATE = 20,

        NJS_TYPED_ARRAY = 21,

        NJS_PROMISE = 22,

        NJS_OBJECT_VALUE = 23,

        NJS_ARRAY_BUFFER = 24,

        NJS_DATA_VIEW = 25,

        NJS_VALUE_TYPE_MAX = 26,
    }
    enum NJS_NULL = _Anonymous_24.NJS_NULL;
    enum NJS_UNDEFINED = _Anonymous_24.NJS_UNDEFINED;
    enum NJS_BOOLEAN = _Anonymous_24.NJS_BOOLEAN;
    enum NJS_NUMBER = _Anonymous_24.NJS_NUMBER;
    enum NJS_SYMBOL = _Anonymous_24.NJS_SYMBOL;
    enum NJS_STRING = _Anonymous_24.NJS_STRING;
    enum NJS_DATA = _Anonymous_24.NJS_DATA;
    enum NJS_INVALID = _Anonymous_24.NJS_INVALID;
    enum NJS_OBJECT = _Anonymous_24.NJS_OBJECT;
    enum NJS_ARRAY = _Anonymous_24.NJS_ARRAY;
    enum NJS_FUNCTION = _Anonymous_24.NJS_FUNCTION;
    enum NJS_REGEXP = _Anonymous_24.NJS_REGEXP;
    enum NJS_DATE = _Anonymous_24.NJS_DATE;
    enum NJS_TYPED_ARRAY = _Anonymous_24.NJS_TYPED_ARRAY;
    enum NJS_PROMISE = _Anonymous_24.NJS_PROMISE;
    enum NJS_OBJECT_VALUE = _Anonymous_24.NJS_OBJECT_VALUE;
    enum NJS_ARRAY_BUFFER = _Anonymous_24.NJS_ARRAY_BUFFER;
    enum NJS_DATA_VIEW = _Anonymous_24.NJS_DATA_VIEW;
    enum NJS_VALUE_TYPE_MAX = _Anonymous_24.NJS_VALUE_TYPE_MAX;

    alias njs_data_tag_t = _Anonymous_25;

    enum _Anonymous_25
    {

        NJS_DATA_TAG_ANY = 0,

        NJS_DATA_TAG_EXTERNAL = 1,

        NJS_DATA_TAG_TEXT_ENCODER = 2,

        NJS_DATA_TAG_TEXT_DECODER = 3,

        NJS_DATA_TAG_ARRAY_ITERATOR = 4,

        NJS_DATA_TAG_FOREACH_NEXT = 5,

        NJS_DATA_TAG_MAX = 6,
    }
    enum NJS_DATA_TAG_ANY = _Anonymous_25.NJS_DATA_TAG_ANY;
    enum NJS_DATA_TAG_EXTERNAL = _Anonymous_25.NJS_DATA_TAG_EXTERNAL;
    enum NJS_DATA_TAG_TEXT_ENCODER = _Anonymous_25.NJS_DATA_TAG_TEXT_ENCODER;
    enum NJS_DATA_TAG_TEXT_DECODER = _Anonymous_25.NJS_DATA_TAG_TEXT_DECODER;
    enum NJS_DATA_TAG_ARRAY_ITERATOR = _Anonymous_25.NJS_DATA_TAG_ARRAY_ITERATOR;
    enum NJS_DATA_TAG_FOREACH_NEXT = _Anonymous_25.NJS_DATA_TAG_FOREACH_NEXT;
    enum NJS_DATA_TAG_MAX = _Anonymous_25.NJS_DATA_TAG_MAX;

    alias njs_string_t = njs_string_s;

    struct njs_string_s
    {

        ubyte* start;

        uint length;

        uint retain;
    }

    alias njs_object_t = njs_object_s;

    struct njs_object_s
    {
        import std.bitmanip: bitfields;

        align(4):

        njs_lvlhsh_t hash;

        njs_lvlhsh_t shared_hash;

        njs_object_s* __proto__;

        njs_exotic_slots_t* slots;
        mixin(bitfields!(

            njs_value_type_t, "type", 8,
        ));

        ubyte shared_;
        mixin(bitfields!(

            ubyte, "extensible", 1,

            ubyte, "error_data", 1,

            ubyte, "fast_array", 1,
            uint, "_padding_0", 5
        ));
    }

    alias njs_object_value_t = njs_object_value_s;

    struct njs_object_value_s
    {

        njs_object_s object;

        njs_value_s value;
    }

    alias njs_function_lambda_t = njs_function_lambda_s;

    struct njs_function_lambda_s
    {

        c_ulong* closures;

        uint nclosures;

        uint nlocal;

        njs_declaration_t* declarations;

        uint ndeclarations;

        c_ulong self;

        uint nargs;

        ubyte ctor;

        ubyte rest_parameters;

        njs_value_s name;

        ubyte* start;
    }

    alias njs_regexp_pattern_t = njs_regexp_pattern_s;

    struct njs_regexp_pattern_s
    {

        njs_regex_t[2] regex;

        ubyte* source;

        ushort ncaptures;

        ushort ngroups;

        ubyte global;

        ubyte ignore_case;

        ubyte multiline;

        ubyte sticky;

        njs_regexp_group_s* groups;
    }

    alias njs_array_t = njs_array_s;

    struct njs_array_s
    {

        njs_object_s object;

        uint size;

        uint length;

        njs_value_s* start;

        njs_value_s* data;
    }

    alias njs_array_buffer_t = njs_array_buffer_s;

    struct njs_array_buffer_s
    {

        njs_object_s object;

        c_ulong size;

        static union _Anonymous_26
        {

            ubyte* u8;

            ushort* u16;

            uint* u32;

            c_ulong* u64;

            byte* i8;

            short* i16;

            int* i32;

            c_long* i64;

            float* f32;

            double* f64;

            void* data;
        }

        _Anonymous_26 u;
    }

    alias njs_typed_array_t = njs_typed_array_s;

    struct njs_typed_array_s
    {

        njs_object_s object;

        njs_array_buffer_s* buffer;

        c_ulong offset;

        c_ulong byte_length;

        ubyte type;
    }

    alias njs_data_view_t = njs_typed_array_s;

    alias njs_regexp_t = njs_regexp_s;

    struct njs_regexp_s
    {

        njs_object_s object;

        njs_value_s last_index;

        njs_regexp_pattern_s* pattern;

        njs_value_s string_;
    }

    alias njs_date_t = njs_date_s;

    struct njs_date_s
    {

        njs_object_s object;

        double time;
    }

    alias njs_promise_t = njs_object_value_s;

    alias njs_property_next_t = njs_property_next_s;
    struct njs_property_next_s;

    alias njs_object_init_t = njs_object_init_s;

    struct njs_object_init_s
    {

        const(njs_object_prop_s)* properties;

        uint items;
    }

    struct njs_exotic_slots_t
    {
        import std.bitmanip: bitfields;

        align(4):

        int function(njs_vm_s*, njs_object_prop_s*, njs_value_s*, njs_value_s*, njs_value_s*) prop_handler;

        uint magic32;
        mixin(bitfields!(

            uint, "writable", 1,

            uint, "configurable", 1,

            uint, "enumerable", 1,
            uint, "_padding_0", 5
        ));

        int function(njs_vm_s*, njs_value_s*, njs_value_s*) keys;

        njs_lvlhsh_t external_shared_hash;
    }

    union njs_object_prototype_t
    {

        njs_object_s object;

        njs_object_value_s object_value;

        njs_array_s array;

        njs_function_s function_;

        njs_regexp_s regexp;

        njs_date_s date;

        njs_object_value_s promise;
    }

    struct njs_object_type_init_t
    {

        njs_function_s constructor;

        const(njs_object_init_s)* constructor_props;

        const(njs_object_init_s)* prototype_props;

        njs_object_prototype_t prototype_value;
    }

    alias njs_object_enum_t = _Anonymous_27;

    enum _Anonymous_27
    {

        NJS_ENUM_KEYS = 0,

        NJS_ENUM_VALUES = 1,

        NJS_ENUM_BOTH = 2,
    }
    enum NJS_ENUM_KEYS = _Anonymous_27.NJS_ENUM_KEYS;
    enum NJS_ENUM_VALUES = _Anonymous_27.NJS_ENUM_VALUES;
    enum NJS_ENUM_BOTH = _Anonymous_27.NJS_ENUM_BOTH;

    alias njs_object_enum_type_t = _Anonymous_28;

    enum _Anonymous_28
    {

        NJS_ENUM_STRING = 1,

        NJS_ENUM_SYMBOL = 2,
    }
    enum NJS_ENUM_STRING = _Anonymous_28.NJS_ENUM_STRING;
    enum NJS_ENUM_SYMBOL = _Anonymous_28.NJS_ENUM_SYMBOL;

    alias njs_object_prop_type_t = _Anonymous_29;

    enum _Anonymous_29
    {

        NJS_PROPERTY = 0,

        NJS_PROPERTY_REF = 1,

        NJS_PROPERTY_TYPED_ARRAY_REF = 2,

        NJS_PROPERTY_HANDLER = 3,

        NJS_WHITEOUT = 4,
    }
    enum NJS_PROPERTY = _Anonymous_29.NJS_PROPERTY;
    enum NJS_PROPERTY_REF = _Anonymous_29.NJS_PROPERTY_REF;
    enum NJS_PROPERTY_TYPED_ARRAY_REF = _Anonymous_29.NJS_PROPERTY_TYPED_ARRAY_REF;
    enum NJS_PROPERTY_HANDLER = _Anonymous_29.NJS_PROPERTY_HANDLER;
    enum NJS_WHITEOUT = _Anonymous_29.NJS_WHITEOUT;

    alias njs_object_attribute_t = _Anonymous_30;

    enum _Anonymous_30
    {

        NJS_ATTRIBUTE_FALSE = 0,

        NJS_ATTRIBUTE_TRUE = 1,

        NJS_ATTRIBUTE_UNSET = 2,
    }
    enum NJS_ATTRIBUTE_FALSE = _Anonymous_30.NJS_ATTRIBUTE_FALSE;
    enum NJS_ATTRIBUTE_TRUE = _Anonymous_30.NJS_ATTRIBUTE_TRUE;
    enum NJS_ATTRIBUTE_UNSET = _Anonymous_30.NJS_ATTRIBUTE_UNSET;

    struct njs_property_query_t
    {

        njs_lvlhsh_query_s lhq;

        njs_object_prop_s scratch;

        njs_value_s key;

        njs_object_s* prototype;

        njs_object_prop_s* own_whiteout;

        ubyte query;

        ubyte shared_;

        ubyte temp;

        ubyte own;
    }

    extern __gshared const(njs_value_s) njs_value_null;

    extern __gshared const(njs_value_s) njs_value_false;

    extern __gshared const(njs_value_s) njs_value_true;

    extern __gshared const(njs_value_s) njs_value_zero;

    extern __gshared const(njs_value_s) njs_value_nan;

    extern __gshared const(njs_value_s) njs_value_invalid;

    extern __gshared const(njs_value_s) njs_string_empty;

    extern __gshared const(njs_value_s) njs_string_empty_regexp;

    extern __gshared const(njs_value_s) njs_string_comma;

    extern __gshared const(njs_value_s) njs_string_null;

    extern __gshared const(njs_value_s) njs_string_undefined;

    extern __gshared const(njs_value_s) njs_string_boolean;

    extern __gshared const(njs_value_s) njs_string_false;

    extern __gshared const(njs_value_s) njs_string_true;

    extern __gshared const(njs_value_s) njs_string_number;

    extern __gshared const(njs_value_s) njs_string_minus_zero;

    extern __gshared const(njs_value_s) njs_string_minus_infinity;

    extern __gshared const(njs_value_s) njs_string_plus_infinity;

    extern __gshared const(njs_value_s) njs_string_nan;

    extern __gshared const(njs_value_s) njs_string_symbol;

    extern __gshared const(njs_value_s) njs_string_string;

    extern __gshared const(njs_value_s) njs_string_data;

    extern __gshared const(njs_value_s) njs_string_type;

    extern __gshared const(njs_value_s) njs_string_name;

    extern __gshared const(njs_value_s) njs_string_external;

    extern __gshared const(njs_value_s) njs_string_invalid;

    extern __gshared const(njs_value_s) njs_string_object;

    extern __gshared const(njs_value_s) njs_string_function;

    extern __gshared const(njs_value_s) njs_string_anonymous;

    extern __gshared const(njs_value_s) njs_string_memory_error;

    void njs_value_retain(njs_value_s*) @nogc nothrow;

    void njs_value_release(njs_vm_s*, njs_value_s*) @nogc nothrow;

    int njs_value_to_primitive(njs_vm_s*, njs_value_s*, njs_value_s*, uint) @nogc nothrow;

    njs_array_s* njs_value_enumerate(njs_vm_s*, njs_value_s*, njs_object_enum_t, njs_object_enum_type_t, uint) @nogc nothrow;

    njs_array_s* njs_value_own_enumerate(njs_vm_s*, njs_value_s*, njs_object_enum_t, njs_object_enum_type_t, uint) @nogc nothrow;

    int njs_value_of(njs_vm_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_value_length(njs_vm_s*, njs_value_s*, c_long*) @nogc nothrow;

    const(char)* njs_type_string(njs_value_type_t) @nogc nothrow;

    int njs_primitive_value_to_string(njs_vm_s*, njs_value_s*, const(njs_value_s)*) @nogc nothrow;

    int njs_primitive_value_to_chain(njs_vm_s*, njs_chb_t*, const(njs_value_s)*) @nogc nothrow;

    double njs_string_to_number(const(njs_value_s)*, uint) @nogc nothrow;

    int njs_int64_to_string(njs_vm_s*, njs_value_s*, c_long) @nogc nothrow;

    uint njs_string_eq(const(njs_value_s)*, const(njs_value_s)*) @nogc nothrow;

    int njs_property_query(njs_vm_s*, njs_property_query_t*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_value_property(njs_vm_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_value_property_set(njs_vm_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_value_property_delete(njs_vm_s*, njs_value_s*, njs_value_s*, njs_value_s*, uint) @nogc nothrow;

    int njs_value_to_object(njs_vm_s*, njs_value_s*) @nogc nothrow;

    void njs_symbol_conversion_failed(njs_vm_s*, uint) @nogc nothrow;

    int njs_value_species_constructor(njs_vm_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    int njs_value_method(njs_vm_s*, njs_value_s*, njs_value_s*, njs_value_s*) @nogc nothrow;

    alias njs_variable_type_t = _Anonymous_31;

    enum _Anonymous_31
    {

        NJS_VARIABLE_CONST = 0,

        NJS_VARIABLE_LET = 1,

        NJS_VARIABLE_CATCH = 2,

        NJS_VARIABLE_VAR = 3,

        NJS_VARIABLE_FUNCTION = 4,
    }
    enum NJS_VARIABLE_CONST = _Anonymous_31.NJS_VARIABLE_CONST;
    enum NJS_VARIABLE_LET = _Anonymous_31.NJS_VARIABLE_LET;
    enum NJS_VARIABLE_CATCH = _Anonymous_31.NJS_VARIABLE_CATCH;
    enum NJS_VARIABLE_VAR = _Anonymous_31.NJS_VARIABLE_VAR;
    enum NJS_VARIABLE_FUNCTION = _Anonymous_31.NJS_VARIABLE_FUNCTION;

    struct njs_variable_t
    {
        import std.bitmanip: bitfields;

        align(4):

        c_ulong unique_id;
        mixin(bitfields!(

            njs_variable_type_t, "type", 8,
        ));

        uint argument;

        uint arguments_object;

        uint self;

        uint init;

        uint closure;

        uint function_;

        njs_parser_scope_s* scope_;

        njs_parser_scope_s* original;

        c_ulong index;

        njs_value_s value;
    }

    alias njs_reference_type_t = _Anonymous_32;

    enum _Anonymous_32
    {

        NJS_DECLARATION = 0,

        NJS_REFERENCE = 1,

        NJS_TYPEOF = 2,
    }
    enum NJS_DECLARATION = _Anonymous_32.NJS_DECLARATION;
    enum NJS_REFERENCE = _Anonymous_32.NJS_REFERENCE;
    enum NJS_TYPEOF = _Anonymous_32.NJS_TYPEOF;

    struct njs_variable_reference_t
    {

        njs_reference_type_t type;

        c_ulong unique_id;

        njs_variable_t* variable;

        njs_parser_scope_s* scope_;

        uint not_defined;
    }

    struct njs_variable_node_t
    {

        njs_rbtree_part_t node;

        ubyte node_color;

        c_ulong key;

        njs_variable_t* variable;
    }

    njs_variable_t* njs_variable_add(njs_parser_s*, njs_parser_scope_s*, c_ulong, njs_variable_type_t) @nogc nothrow;

    njs_variable_t* njs_variable_function_add(njs_parser_s*, njs_parser_scope_s*, c_ulong, njs_variable_type_t) @nogc nothrow;

    njs_variable_t* njs_label_add(njs_vm_s*, njs_parser_scope_s*, c_ulong) @nogc nothrow;

    njs_variable_t* njs_label_find(njs_vm_s*, njs_parser_scope_s*, c_ulong) @nogc nothrow;

    int njs_label_remove(njs_vm_s*, njs_parser_scope_s*, c_ulong) @nogc nothrow;

    njs_variable_t* njs_variable_reference(njs_vm_s*, njs_parser_node_s*) @nogc nothrow;

    njs_variable_t* njs_variable_scope_add(njs_parser_s*, njs_parser_scope_s*, njs_parser_scope_s*, c_ulong, njs_variable_type_t, c_ulong) @nogc nothrow;

    int njs_name_copy(njs_vm_s*, njs_str_t*, const(njs_str_t)*) @nogc nothrow;

    alias njs_frame_t = njs_frame_s;

    struct njs_frame_s
    {

        njs_native_frame_s native;

        njs_exception_s exception;

        njs_frame_s* previous_active_frame;
    }

    alias njs_native_frame_t = njs_native_frame_s;

    struct njs_native_frame_s
    {

        ubyte* free;

        ubyte* pc;

        njs_function_s* function_;

        njs_native_frame_s* previous;

        njs_value_s* arguments;

        njs_object_s* arguments_object;

        njs_value_s** local;

        uint size;

        uint free_size;

        njs_value_s* retval;

        uint nargs;

        uint put_args;

        ubyte native;

        ubyte ctor;

        ubyte skip;
    }

    alias njs_parser_t = njs_parser_s;

    struct njs_parser_s
    {

        int function(njs_parser_s*, njs_lexer_token_t*, njs_queue_link_s*) state;

        njs_queue_t stack;

        njs_lexer_t lexer0;

        njs_lexer_t* lexer;

        njs_vm_s* vm;

        njs_parser_node_s* node;

        njs_parser_node_s* target;

        njs_parser_scope_s* scope_;

        njs_variable_type_t var_type;

        int ret;

        c_ulong undefined_id;

        ubyte module_;

        uint strict_semicolon;

        njs_str_t file;

        uint line;
    }

    alias njs_parser_scope_t = njs_parser_scope_s;

    struct njs_parser_scope_s
    {
        import std.bitmanip: bitfields;

        align(4):

        njs_parser_node_s* top;

        njs_parser_scope_s* parent;

        njs_rbtree_t variables;

        njs_rbtree_t labels;

        njs_rbtree_t references;

        njs_arr_t* closures;

        njs_arr_t* declarations;

        uint items;
        mixin(bitfields!(

            njs_scope_t, "type", 8,
        ));

        ubyte arrow_function;

        ubyte dest_disable;

        ubyte async;

        ubyte in_args;
    }

    alias njs_parser_node_t = njs_parser_node_s;

    struct njs_parser_node_s
    {
        import std.bitmanip: bitfields;

        align(4):
        mixin(bitfields!(

            njs_token_type_t, "token_type", 16,

            ubyte, "ctor", 1,

            ubyte, "hoist", 1,
            uint, "_padding_0", 14
        ));

        ubyte temporary;

        uint token_line;

        static union _Anonymous_33
        {

            uint length;

            njs_variable_reference_t reference;

            njs_value_s value;

            ubyte operation;

            njs_parser_node_s* object;

            njs_mod_s* module_;
        }

        _Anonymous_33 u;

        njs_str_t name;

        c_ulong index;

        njs_parser_scope_s* scope_;

        njs_parser_node_s* left;

        njs_parser_node_s* right;

        njs_parser_node_s* dest;
    }

    alias njs_generator_t = njs_generator_s;

    struct njs_generator_s
    {

        int function(njs_vm_s*, njs_generator_s*, njs_parser_node_s*) state;

        njs_queue_t stack;

        njs_parser_node_s* node;

        void* context;

        njs_value_s* local_scope;

        njs_generator_block_s* block;

        njs_arr_t* index_cache;

        njs_arr_t* closures;

        njs_str_t file;

        njs_arr_t* lines;

        c_ulong code_size;

        ubyte* code_start;

        ubyte* code_end;

        ubyte runtime;

        uint depth;
    }

    alias njs_scope_t = _Anonymous_34;

    enum _Anonymous_34
    {

        NJS_SCOPE_GLOBAL = 0,

        NJS_SCOPE_FUNCTION = 1,

        NJS_SCOPE_BLOCK = 2,
    }
    enum NJS_SCOPE_GLOBAL = _Anonymous_34.NJS_SCOPE_GLOBAL;
    enum NJS_SCOPE_FUNCTION = _Anonymous_34.NJS_SCOPE_FUNCTION;
    enum NJS_SCOPE_BLOCK = _Anonymous_34.NJS_SCOPE_BLOCK;

    alias njs_object_type_t = _Anonymous_35;

    enum _Anonymous_35
    {

        NJS_OBJ_TYPE_OBJECT = 0,

        NJS_OBJ_TYPE_ARRAY = 1,

        NJS_OBJ_TYPE_BOOLEAN = 2,

        NJS_OBJ_TYPE_NUMBER = 3,

        NJS_OBJ_TYPE_SYMBOL = 4,

        NJS_OBJ_TYPE_STRING = 5,

        NJS_OBJ_TYPE_FUNCTION = 6,

        NJS_OBJ_TYPE_ASYNC_FUNCTION = 7,

        NJS_OBJ_TYPE_REGEXP = 8,

        NJS_OBJ_TYPE_DATE = 9,

        NJS_OBJ_TYPE_PROMISE = 10,

        NJS_OBJ_TYPE_ARRAY_BUFFER = 11,

        NJS_OBJ_TYPE_DATA_VIEW = 12,

        NJS_OBJ_TYPE_TEXT_DECODER = 13,

        NJS_OBJ_TYPE_TEXT_ENCODER = 14,

        NJS_OBJ_TYPE_BUFFER = 15,

        NJS_OBJ_TYPE_ITERATOR = 16,

        NJS_OBJ_TYPE_ARRAY_ITERATOR = 17,

        NJS_OBJ_TYPE_TYPED_ARRAY = 18,

        NJS_OBJ_TYPE_UINT8_ARRAY = 19,

        NJS_OBJ_TYPE_UINT8_CLAMPED_ARRAY = 20,

        NJS_OBJ_TYPE_INT8_ARRAY = 21,

        NJS_OBJ_TYPE_UINT16_ARRAY = 22,

        NJS_OBJ_TYPE_INT16_ARRAY = 23,

        NJS_OBJ_TYPE_UINT32_ARRAY = 24,

        NJS_OBJ_TYPE_INT32_ARRAY = 25,

        NJS_OBJ_TYPE_FLOAT32_ARRAY = 26,

        NJS_OBJ_TYPE_FLOAT64_ARRAY = 27,

        NJS_OBJ_TYPE_ERROR = 28,

        NJS_OBJ_TYPE_EVAL_ERROR = 29,

        NJS_OBJ_TYPE_INTERNAL_ERROR = 30,

        NJS_OBJ_TYPE_RANGE_ERROR = 31,

        NJS_OBJ_TYPE_REF_ERROR = 32,

        NJS_OBJ_TYPE_SYNTAX_ERROR = 33,

        NJS_OBJ_TYPE_TYPE_ERROR = 34,

        NJS_OBJ_TYPE_URI_ERROR = 35,

        NJS_OBJ_TYPE_MEMORY_ERROR = 36,

        NJS_OBJ_TYPE_AGGREGATE_ERROR = 37,

        NJS_OBJ_TYPE_MAX = 38,
    }
    enum NJS_OBJ_TYPE_OBJECT = _Anonymous_35.NJS_OBJ_TYPE_OBJECT;
    enum NJS_OBJ_TYPE_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_ARRAY;
    enum NJS_OBJ_TYPE_BOOLEAN = _Anonymous_35.NJS_OBJ_TYPE_BOOLEAN;
    enum NJS_OBJ_TYPE_NUMBER = _Anonymous_35.NJS_OBJ_TYPE_NUMBER;
    enum NJS_OBJ_TYPE_SYMBOL = _Anonymous_35.NJS_OBJ_TYPE_SYMBOL;
    enum NJS_OBJ_TYPE_STRING = _Anonymous_35.NJS_OBJ_TYPE_STRING;
    enum NJS_OBJ_TYPE_FUNCTION = _Anonymous_35.NJS_OBJ_TYPE_FUNCTION;
    enum NJS_OBJ_TYPE_ASYNC_FUNCTION = _Anonymous_35.NJS_OBJ_TYPE_ASYNC_FUNCTION;
    enum NJS_OBJ_TYPE_REGEXP = _Anonymous_35.NJS_OBJ_TYPE_REGEXP;
    enum NJS_OBJ_TYPE_DATE = _Anonymous_35.NJS_OBJ_TYPE_DATE;
    enum NJS_OBJ_TYPE_PROMISE = _Anonymous_35.NJS_OBJ_TYPE_PROMISE;
    enum NJS_OBJ_TYPE_ARRAY_BUFFER = _Anonymous_35.NJS_OBJ_TYPE_ARRAY_BUFFER;
    enum NJS_OBJ_TYPE_DATA_VIEW = _Anonymous_35.NJS_OBJ_TYPE_DATA_VIEW;
    enum NJS_OBJ_TYPE_TEXT_DECODER = _Anonymous_35.NJS_OBJ_TYPE_TEXT_DECODER;
    enum NJS_OBJ_TYPE_TEXT_ENCODER = _Anonymous_35.NJS_OBJ_TYPE_TEXT_ENCODER;
    enum NJS_OBJ_TYPE_BUFFER = _Anonymous_35.NJS_OBJ_TYPE_BUFFER;
    enum NJS_OBJ_TYPE_ITERATOR = _Anonymous_35.NJS_OBJ_TYPE_ITERATOR;
    enum NJS_OBJ_TYPE_ARRAY_ITERATOR = _Anonymous_35.NJS_OBJ_TYPE_ARRAY_ITERATOR;
    enum NJS_OBJ_TYPE_TYPED_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_TYPED_ARRAY;
    enum NJS_OBJ_TYPE_UINT8_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_UINT8_ARRAY;
    enum NJS_OBJ_TYPE_UINT8_CLAMPED_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_UINT8_CLAMPED_ARRAY;
    enum NJS_OBJ_TYPE_INT8_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_INT8_ARRAY;
    enum NJS_OBJ_TYPE_UINT16_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_UINT16_ARRAY;
    enum NJS_OBJ_TYPE_INT16_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_INT16_ARRAY;
    enum NJS_OBJ_TYPE_UINT32_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_UINT32_ARRAY;
    enum NJS_OBJ_TYPE_INT32_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_INT32_ARRAY;
    enum NJS_OBJ_TYPE_FLOAT32_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_FLOAT32_ARRAY;
    enum NJS_OBJ_TYPE_FLOAT64_ARRAY = _Anonymous_35.NJS_OBJ_TYPE_FLOAT64_ARRAY;
    enum NJS_OBJ_TYPE_ERROR = _Anonymous_35.NJS_OBJ_TYPE_ERROR;
    enum NJS_OBJ_TYPE_EVAL_ERROR = _Anonymous_35.NJS_OBJ_TYPE_EVAL_ERROR;
    enum NJS_OBJ_TYPE_INTERNAL_ERROR = _Anonymous_35.NJS_OBJ_TYPE_INTERNAL_ERROR;
    enum NJS_OBJ_TYPE_RANGE_ERROR = _Anonymous_35.NJS_OBJ_TYPE_RANGE_ERROR;
    enum NJS_OBJ_TYPE_REF_ERROR = _Anonymous_35.NJS_OBJ_TYPE_REF_ERROR;
    enum NJS_OBJ_TYPE_SYNTAX_ERROR = _Anonymous_35.NJS_OBJ_TYPE_SYNTAX_ERROR;
    enum NJS_OBJ_TYPE_TYPE_ERROR = _Anonymous_35.NJS_OBJ_TYPE_TYPE_ERROR;
    enum NJS_OBJ_TYPE_URI_ERROR = _Anonymous_35.NJS_OBJ_TYPE_URI_ERROR;
    enum NJS_OBJ_TYPE_MEMORY_ERROR = _Anonymous_35.NJS_OBJ_TYPE_MEMORY_ERROR;
    enum NJS_OBJ_TYPE_AGGREGATE_ERROR = _Anonymous_35.NJS_OBJ_TYPE_AGGREGATE_ERROR;
    enum NJS_OBJ_TYPE_MAX = _Anonymous_35.NJS_OBJ_TYPE_MAX;

    enum njs_object_e
    {

        NJS_OBJECT_THIS = 0,

        NJS_OBJECT_NJS = 1,

        NJS_OBJECT_PROCESS = 2,

        NJS_OBJECT_MATH = 3,

        NJS_OBJECT_JSON = 4,

        NJS_OBJECT_MAX = 5,
    }
    enum NJS_OBJECT_THIS = njs_object_e.NJS_OBJECT_THIS;
    enum NJS_OBJECT_NJS = njs_object_e.NJS_OBJECT_NJS;
    enum NJS_OBJECT_PROCESS = njs_object_e.NJS_OBJECT_PROCESS;
    enum NJS_OBJECT_MATH = njs_object_e.NJS_OBJECT_MATH;
    enum NJS_OBJECT_JSON = njs_object_e.NJS_OBJECT_JSON;
    enum NJS_OBJECT_MAX = njs_object_e.NJS_OBJECT_MAX;

    enum njs_hook_e
    {

        NJS_HOOK_EXIT = 0,

        NJS_HOOK_MAX = 1,
    }
    enum NJS_HOOK_EXIT = njs_hook_e.NJS_HOOK_EXIT;
    enum NJS_HOOK_MAX = njs_hook_e.NJS_HOOK_MAX;

    alias njs_level_type_t = _Anonymous_36;

    enum _Anonymous_36
    {

        NJS_LEVEL_LOCAL = 0,

        NJS_LEVEL_CLOSURE = 1,

        NJS_LEVEL_GLOBAL = 2,

        NJS_LEVEL_STATIC = 3,

        NJS_LEVEL_MAX = 4,
    }
    enum NJS_LEVEL_LOCAL = _Anonymous_36.NJS_LEVEL_LOCAL;
    enum NJS_LEVEL_CLOSURE = _Anonymous_36.NJS_LEVEL_CLOSURE;
    enum NJS_LEVEL_GLOBAL = _Anonymous_36.NJS_LEVEL_GLOBAL;
    enum NJS_LEVEL_STATIC = _Anonymous_36.NJS_LEVEL_STATIC;
    enum NJS_LEVEL_MAX = _Anonymous_36.NJS_LEVEL_MAX;

    struct njs_vm_line_num_t
    {

        uint offset;

        uint line;
    }

    struct njs_vm_code_t
    {

        ubyte* start;

        ubyte* end;

        njs_str_t file;

        njs_str_t name;

        njs_arr_t* lines;
    }

    void njs_vm_scopes_restore(njs_vm_s*, njs_native_frame_s*, njs_native_frame_s*) @nogc nothrow;

    int njs_builtin_objects_create(njs_vm_s*) @nogc nothrow;

    int njs_builtin_objects_clone(njs_vm_s*, njs_value_s*) @nogc nothrow;

    int njs_builtin_match_native_function(njs_vm_s*, njs_function_s*, njs_str_t*) @nogc nothrow;

    void njs_disassemble(ubyte*, ubyte*, int, njs_arr_t*) @nogc nothrow;

    njs_arr_t* njs_vm_completions(njs_vm_s*, njs_str_t*) @nogc nothrow;

    void* njs_lvlhsh_alloc(void*, c_ulong) @nogc nothrow;

    void njs_lvlhsh_free(void*, void*, c_ulong) @nogc nothrow;

    extern __gshared const(njs_str_t) njs_entry_empty;

    extern __gshared const(njs_str_t) njs_entry_main;

    extern __gshared const(njs_str_t) njs_entry_module;

    extern __gshared const(njs_str_t) njs_entry_native;

    extern __gshared const(njs_str_t) njs_entry_unknown;

    extern __gshared const(njs_str_t) njs_entry_anonymous;

    extern __gshared const(njs_lvlhsh_proto_t) njs_object_hash_proto;

    alias njs_jump_off_t = c_long;

    alias njs_vmcode_operation_t = ubyte;

    enum _Anonymous_37
    {

        NJS_VMCODE_PUT_ARG = 0,

        NJS_VMCODE_STOP = 1,

        NJS_VMCODE_JUMP = 2,

        NJS_VMCODE_PROPERTY_SET = 3,

        NJS_VMCODE_PROPERTY_ACCESSOR = 4,

        NJS_VMCODE_IF_TRUE_JUMP = 5,

        NJS_VMCODE_IF_FALSE_JUMP = 6,

        NJS_VMCODE_IF_EQUAL_JUMP = 7,

        NJS_VMCODE_PROPERTY_INIT = 8,

        NJS_VMCODE_RETURN = 9,

        NJS_VMCODE_FUNCTION_COPY = 10,

        NJS_VMCODE_FUNCTION_FRAME = 11,

        NJS_VMCODE_METHOD_FRAME = 12,

        NJS_VMCODE_FUNCTION_CALL = 13,

        NJS_VMCODE_PROPERTY_NEXT = 14,

        NJS_VMCODE_THIS = 15,

        NJS_VMCODE_ARGUMENTS = 16,

        NJS_VMCODE_PROTO_INIT = 17,

        NJS_VMCODE_TO_PROPERTY_KEY = 18,

        NJS_VMCODE_TO_PROPERTY_KEY_CHK = 19,

        NJS_VMCODE_SET_FUNCTION_NAME = 20,

        NJS_VMCODE_IMPORT = 21,

        NJS_VMCODE_AWAIT = 22,

        NJS_VMCODE_TRY_START = 23,

        NJS_VMCODE_THROW = 24,

        NJS_VMCODE_TRY_BREAK = 25,

        NJS_VMCODE_TRY_CONTINUE = 26,

        NJS_VMCODE_TRY_END = 27,

        NJS_VMCODE_CATCH = 28,

        NJS_VMCODE_FINALLY = 29,

        NJS_VMCODE_LET = 30,

        NJS_VMCODE_LET_UPDATE = 31,

        NJS_VMCODE_INITIALIZATION_TEST = 32,

        NJS_VMCODE_NOT_INITIALIZED = 33,

        NJS_VMCODE_ASSIGNMENT_ERROR = 34,

        NJS_VMCODE_ERROR = 35,

        NJS_VMCODE_NORET = 127,
    }
    enum NJS_VMCODE_PUT_ARG = _Anonymous_37.NJS_VMCODE_PUT_ARG;
    enum NJS_VMCODE_STOP = _Anonymous_37.NJS_VMCODE_STOP;
    enum NJS_VMCODE_JUMP = _Anonymous_37.NJS_VMCODE_JUMP;
    enum NJS_VMCODE_PROPERTY_SET = _Anonymous_37.NJS_VMCODE_PROPERTY_SET;
    enum NJS_VMCODE_PROPERTY_ACCESSOR = _Anonymous_37.NJS_VMCODE_PROPERTY_ACCESSOR;
    enum NJS_VMCODE_IF_TRUE_JUMP = _Anonymous_37.NJS_VMCODE_IF_TRUE_JUMP;
    enum NJS_VMCODE_IF_FALSE_JUMP = _Anonymous_37.NJS_VMCODE_IF_FALSE_JUMP;
    enum NJS_VMCODE_IF_EQUAL_JUMP = _Anonymous_37.NJS_VMCODE_IF_EQUAL_JUMP;
    enum NJS_VMCODE_PROPERTY_INIT = _Anonymous_37.NJS_VMCODE_PROPERTY_INIT;
    enum NJS_VMCODE_RETURN = _Anonymous_37.NJS_VMCODE_RETURN;
    enum NJS_VMCODE_FUNCTION_COPY = _Anonymous_37.NJS_VMCODE_FUNCTION_COPY;
    enum NJS_VMCODE_FUNCTION_FRAME = _Anonymous_37.NJS_VMCODE_FUNCTION_FRAME;
    enum NJS_VMCODE_METHOD_FRAME = _Anonymous_37.NJS_VMCODE_METHOD_FRAME;
    enum NJS_VMCODE_FUNCTION_CALL = _Anonymous_37.NJS_VMCODE_FUNCTION_CALL;
    enum NJS_VMCODE_PROPERTY_NEXT = _Anonymous_37.NJS_VMCODE_PROPERTY_NEXT;
    enum NJS_VMCODE_THIS = _Anonymous_37.NJS_VMCODE_THIS;
    enum NJS_VMCODE_ARGUMENTS = _Anonymous_37.NJS_VMCODE_ARGUMENTS;
    enum NJS_VMCODE_PROTO_INIT = _Anonymous_37.NJS_VMCODE_PROTO_INIT;
    enum NJS_VMCODE_TO_PROPERTY_KEY = _Anonymous_37.NJS_VMCODE_TO_PROPERTY_KEY;
    enum NJS_VMCODE_TO_PROPERTY_KEY_CHK = _Anonymous_37.NJS_VMCODE_TO_PROPERTY_KEY_CHK;
    enum NJS_VMCODE_SET_FUNCTION_NAME = _Anonymous_37.NJS_VMCODE_SET_FUNCTION_NAME;
    enum NJS_VMCODE_IMPORT = _Anonymous_37.NJS_VMCODE_IMPORT;
    enum NJS_VMCODE_AWAIT = _Anonymous_37.NJS_VMCODE_AWAIT;
    enum NJS_VMCODE_TRY_START = _Anonymous_37.NJS_VMCODE_TRY_START;
    enum NJS_VMCODE_THROW = _Anonymous_37.NJS_VMCODE_THROW;
    enum NJS_VMCODE_TRY_BREAK = _Anonymous_37.NJS_VMCODE_TRY_BREAK;
    enum NJS_VMCODE_TRY_CONTINUE = _Anonymous_37.NJS_VMCODE_TRY_CONTINUE;
    enum NJS_VMCODE_TRY_END = _Anonymous_37.NJS_VMCODE_TRY_END;
    enum NJS_VMCODE_CATCH = _Anonymous_37.NJS_VMCODE_CATCH;
    enum NJS_VMCODE_FINALLY = _Anonymous_37.NJS_VMCODE_FINALLY;
    enum NJS_VMCODE_LET = _Anonymous_37.NJS_VMCODE_LET;
    enum NJS_VMCODE_LET_UPDATE = _Anonymous_37.NJS_VMCODE_LET_UPDATE;
    enum NJS_VMCODE_INITIALIZATION_TEST = _Anonymous_37.NJS_VMCODE_INITIALIZATION_TEST;
    enum NJS_VMCODE_NOT_INITIALIZED = _Anonymous_37.NJS_VMCODE_NOT_INITIALIZED;
    enum NJS_VMCODE_ASSIGNMENT_ERROR = _Anonymous_37.NJS_VMCODE_ASSIGNMENT_ERROR;
    enum NJS_VMCODE_ERROR = _Anonymous_37.NJS_VMCODE_ERROR;
    enum NJS_VMCODE_NORET = _Anonymous_37.NJS_VMCODE_NORET;

    enum _Anonymous_38
    {

        NJS_VMCODE_MOVE = 128,

        NJS_VMCODE_PROPERTY_GET = 129,

        NJS_VMCODE_INCREMENT = 130,

        NJS_VMCODE_POST_INCREMENT = 131,

        NJS_VMCODE_DECREMENT = 132,

        NJS_VMCODE_POST_DECREMENT = 133,

        NJS_VMCODE_TRY_RETURN = 134,

        NJS_VMCODE_GLOBAL_GET = 135,

        NJS_VMCODE_LESS = 136,

        NJS_VMCODE_GREATER = 137,

        NJS_VMCODE_LESS_OR_EQUAL = 138,

        NJS_VMCODE_GREATER_OR_EQUAL = 139,

        NJS_VMCODE_ADDITION = 140,

        NJS_VMCODE_EQUAL = 141,

        NJS_VMCODE_NOT_EQUAL = 142,

        NJS_VMCODE_SUBSTRACTION = 143,

        NJS_VMCODE_MULTIPLICATION = 144,

        NJS_VMCODE_EXPONENTIATION = 145,

        NJS_VMCODE_DIVISION = 146,

        NJS_VMCODE_REMAINDER = 147,

        NJS_VMCODE_BITWISE_AND = 148,

        NJS_VMCODE_BITWISE_OR = 149,

        NJS_VMCODE_BITWISE_XOR = 150,

        NJS_VMCODE_LEFT_SHIFT = 151,

        NJS_VMCODE_RIGHT_SHIFT = 152,

        NJS_VMCODE_UNSIGNED_RIGHT_SHIFT = 153,

        NJS_VMCODE_OBJECT_COPY = 154,

        NJS_VMCODE_TEMPLATE_LITERAL = 155,

        NJS_VMCODE_PROPERTY_IN = 156,

        NJS_VMCODE_PROPERTY_DELETE = 157,

        NJS_VMCODE_PROPERTY_FOREACH = 158,

        NJS_VMCODE_STRICT_EQUAL = 159,

        NJS_VMCODE_STRICT_NOT_EQUAL = 160,

        NJS_VMCODE_TEST_IF_TRUE = 161,

        NJS_VMCODE_TEST_IF_FALSE = 162,

        NJS_VMCODE_COALESCE = 163,

        NJS_VMCODE_UNARY_PLUS = 164,

        NJS_VMCODE_UNARY_NEGATION = 165,

        NJS_VMCODE_BITWISE_NOT = 166,

        NJS_VMCODE_LOGICAL_NOT = 167,

        NJS_VMCODE_OBJECT = 168,

        NJS_VMCODE_ARRAY = 169,

        NJS_VMCODE_FUNCTION = 170,

        NJS_VMCODE_REGEXP = 171,

        NJS_VMCODE_INSTANCE_OF = 172,

        NJS_VMCODE_TYPEOF = 173,

        NJS_VMCODE_VOID = 174,

        NJS_VMCODE_DELETE = 175,

        NJS_VMCODE_DEBUGGER = 176,

        NJS_VMCODE_NOP = 255,
    }
    enum NJS_VMCODE_MOVE = _Anonymous_38.NJS_VMCODE_MOVE;
    enum NJS_VMCODE_PROPERTY_GET = _Anonymous_38.NJS_VMCODE_PROPERTY_GET;
    enum NJS_VMCODE_INCREMENT = _Anonymous_38.NJS_VMCODE_INCREMENT;
    enum NJS_VMCODE_POST_INCREMENT = _Anonymous_38.NJS_VMCODE_POST_INCREMENT;
    enum NJS_VMCODE_DECREMENT = _Anonymous_38.NJS_VMCODE_DECREMENT;
    enum NJS_VMCODE_POST_DECREMENT = _Anonymous_38.NJS_VMCODE_POST_DECREMENT;
    enum NJS_VMCODE_TRY_RETURN = _Anonymous_38.NJS_VMCODE_TRY_RETURN;
    enum NJS_VMCODE_GLOBAL_GET = _Anonymous_38.NJS_VMCODE_GLOBAL_GET;
    enum NJS_VMCODE_LESS = _Anonymous_38.NJS_VMCODE_LESS;
    enum NJS_VMCODE_GREATER = _Anonymous_38.NJS_VMCODE_GREATER;
    enum NJS_VMCODE_LESS_OR_EQUAL = _Anonymous_38.NJS_VMCODE_LESS_OR_EQUAL;
    enum NJS_VMCODE_GREATER_OR_EQUAL = _Anonymous_38.NJS_VMCODE_GREATER_OR_EQUAL;
    enum NJS_VMCODE_ADDITION = _Anonymous_38.NJS_VMCODE_ADDITION;
    enum NJS_VMCODE_EQUAL = _Anonymous_38.NJS_VMCODE_EQUAL;
    enum NJS_VMCODE_NOT_EQUAL = _Anonymous_38.NJS_VMCODE_NOT_EQUAL;
    enum NJS_VMCODE_SUBSTRACTION = _Anonymous_38.NJS_VMCODE_SUBSTRACTION;
    enum NJS_VMCODE_MULTIPLICATION = _Anonymous_38.NJS_VMCODE_MULTIPLICATION;
    enum NJS_VMCODE_EXPONENTIATION = _Anonymous_38.NJS_VMCODE_EXPONENTIATION;
    enum NJS_VMCODE_DIVISION = _Anonymous_38.NJS_VMCODE_DIVISION;
    enum NJS_VMCODE_REMAINDER = _Anonymous_38.NJS_VMCODE_REMAINDER;
    enum NJS_VMCODE_BITWISE_AND = _Anonymous_38.NJS_VMCODE_BITWISE_AND;
    enum NJS_VMCODE_BITWISE_OR = _Anonymous_38.NJS_VMCODE_BITWISE_OR;
    enum NJS_VMCODE_BITWISE_XOR = _Anonymous_38.NJS_VMCODE_BITWISE_XOR;
    enum NJS_VMCODE_LEFT_SHIFT = _Anonymous_38.NJS_VMCODE_LEFT_SHIFT;
    enum NJS_VMCODE_RIGHT_SHIFT = _Anonymous_38.NJS_VMCODE_RIGHT_SHIFT;
    enum NJS_VMCODE_UNSIGNED_RIGHT_SHIFT = _Anonymous_38.NJS_VMCODE_UNSIGNED_RIGHT_SHIFT;
    enum NJS_VMCODE_OBJECT_COPY = _Anonymous_38.NJS_VMCODE_OBJECT_COPY;
    enum NJS_VMCODE_TEMPLATE_LITERAL = _Anonymous_38.NJS_VMCODE_TEMPLATE_LITERAL;
    enum NJS_VMCODE_PROPERTY_IN = _Anonymous_38.NJS_VMCODE_PROPERTY_IN;
    enum NJS_VMCODE_PROPERTY_DELETE = _Anonymous_38.NJS_VMCODE_PROPERTY_DELETE;
    enum NJS_VMCODE_PROPERTY_FOREACH = _Anonymous_38.NJS_VMCODE_PROPERTY_FOREACH;
    enum NJS_VMCODE_STRICT_EQUAL = _Anonymous_38.NJS_VMCODE_STRICT_EQUAL;
    enum NJS_VMCODE_STRICT_NOT_EQUAL = _Anonymous_38.NJS_VMCODE_STRICT_NOT_EQUAL;
    enum NJS_VMCODE_TEST_IF_TRUE = _Anonymous_38.NJS_VMCODE_TEST_IF_TRUE;
    enum NJS_VMCODE_TEST_IF_FALSE = _Anonymous_38.NJS_VMCODE_TEST_IF_FALSE;
    enum NJS_VMCODE_COALESCE = _Anonymous_38.NJS_VMCODE_COALESCE;
    enum NJS_VMCODE_UNARY_PLUS = _Anonymous_38.NJS_VMCODE_UNARY_PLUS;
    enum NJS_VMCODE_UNARY_NEGATION = _Anonymous_38.NJS_VMCODE_UNARY_NEGATION;
    enum NJS_VMCODE_BITWISE_NOT = _Anonymous_38.NJS_VMCODE_BITWISE_NOT;
    enum NJS_VMCODE_LOGICAL_NOT = _Anonymous_38.NJS_VMCODE_LOGICAL_NOT;
    enum NJS_VMCODE_OBJECT = _Anonymous_38.NJS_VMCODE_OBJECT;
    enum NJS_VMCODE_ARRAY = _Anonymous_38.NJS_VMCODE_ARRAY;
    enum NJS_VMCODE_FUNCTION = _Anonymous_38.NJS_VMCODE_FUNCTION;
    enum NJS_VMCODE_REGEXP = _Anonymous_38.NJS_VMCODE_REGEXP;
    enum NJS_VMCODE_INSTANCE_OF = _Anonymous_38.NJS_VMCODE_INSTANCE_OF;
    enum NJS_VMCODE_TYPEOF = _Anonymous_38.NJS_VMCODE_TYPEOF;
    enum NJS_VMCODE_VOID = _Anonymous_38.NJS_VMCODE_VOID;
    enum NJS_VMCODE_DELETE = _Anonymous_38.NJS_VMCODE_DELETE;
    enum NJS_VMCODE_DEBUGGER = _Anonymous_38.NJS_VMCODE_DEBUGGER;
    enum NJS_VMCODE_NOP = _Anonymous_38.NJS_VMCODE_NOP;

    struct njs_vmcode_t
    {

        ubyte operation;

        ubyte operands;
    }

    struct njs_vmcode_generic_t
    {

        njs_vmcode_t code;

        c_ulong operand1;

        c_ulong operand2;

        c_ulong operand3;
    }

    struct njs_vmcode_1addr_t
    {

        njs_vmcode_t code;

        c_ulong index;
    }

    struct njs_vmcode_2addr_t
    {

        njs_vmcode_t code;

        c_ulong dst;

        c_ulong src;
    }

    struct njs_vmcode_3addr_t
    {

        njs_vmcode_t code;

        c_ulong dst;

        c_ulong src1;

        c_ulong src2;
    }

    struct njs_vmcode_move_t
    {

        njs_vmcode_t code;

        c_ulong dst;

        c_ulong src;
    }

    struct njs_vmcode_object_t
    {

        njs_vmcode_t code;

        c_ulong retval;
    }

    struct njs_vmcode_this_t
    {

        njs_vmcode_t code;

        c_ulong dst;
    }

    struct njs_vmcode_arguments_t
    {

        njs_vmcode_t code;

        c_ulong dst;
    }

    struct njs_vmcode_array_t
    {

        njs_vmcode_t code;

        c_ulong retval;

        c_ulong length;

        ubyte ctor;
    }

    struct njs_vmcode_template_literal_t
    {

        njs_vmcode_t code;

        c_ulong retval;
    }

    struct njs_vmcode_function_t
    {

        njs_vmcode_t code;

        c_ulong retval;

        njs_function_lambda_s* lambda;

        uint async;
    }

    struct njs_vmcode_regexp_t
    {

        njs_vmcode_t code;

        c_ulong retval;

        njs_regexp_pattern_s* pattern;
    }

    struct njs_vmcode_object_copy_t
    {

        njs_vmcode_t code;

        c_ulong retval;

        c_ulong object;
    }

    struct njs_vmcode_jump_t
    {

        njs_vmcode_t code;

        c_long offset;
    }

    struct njs_vmcode_cond_jump_t
    {

        njs_vmcode_t code;

        c_long offset;

        c_ulong cond;
    }

    struct njs_vmcode_equal_jump_t
    {

        njs_vmcode_t code;

        c_long offset;

        c_ulong value1;

        c_ulong value2;
    }

    struct njs_vmcode_test_jump_t
    {

        njs_vmcode_t code;

        c_ulong retval;

        c_ulong value;

        c_long offset;
    }

    struct njs_vmcode_prop_get_t
    {

        njs_vmcode_t code;

        c_ulong value;

        c_ulong object;

        c_ulong property;
    }

    struct njs_vmcode_prop_set_t
    {

        njs_vmcode_t code;

        c_ulong value;

        c_ulong object;

        c_ulong property;
    }

    struct njs_vmcode_prop_accessor_t
    {

        njs_vmcode_t code;

        c_ulong value;

        c_ulong object;

        c_ulong property;

        ubyte type;
    }

    struct njs_vmcode_prop_foreach_t
    {

        njs_vmcode_t code;

        c_ulong next;

        c_ulong object;

        c_long offset;
    }

    struct njs_vmcode_prop_next_t
    {

        njs_vmcode_t code;

        c_ulong retval;

        c_ulong object;

        c_ulong next;

        c_long offset;
    }

    struct njs_vmcode_instance_of_t
    {

        njs_vmcode_t code;

        c_ulong value;

        c_ulong constructor;

        c_ulong object;
    }

    struct njs_vmcode_function_frame_t
    {

        njs_vmcode_t code;

        c_ulong nargs;

        c_ulong name;

        ubyte ctor;
    }

    struct njs_vmcode_method_frame_t
    {

        njs_vmcode_t code;

        c_ulong nargs;

        c_ulong object;

        c_ulong method;

        ubyte ctor;
    }

    struct njs_vmcode_function_call_t
    {

        njs_vmcode_t code;

        c_ulong retval;
    }

    struct njs_vmcode_return_t
    {

        njs_vmcode_t code;

        c_ulong retval;
    }

    struct njs_vmcode_stop_t
    {

        njs_vmcode_t code;

        c_ulong retval;
    }

    struct njs_vmcode_try_start_t
    {

        njs_vmcode_t code;

        c_long offset;

        c_ulong exception_value;

        c_ulong exit_value;
    }

    struct njs_vmcode_try_trampoline_t
    {

        njs_vmcode_t code;

        c_long offset;

        c_ulong exit_value;
    }

    struct njs_vmcode_catch_t
    {

        njs_vmcode_t code;

        c_long offset;

        c_ulong exception;
    }

    struct njs_vmcode_throw_t
    {

        njs_vmcode_t code;

        c_ulong retval;
    }

    struct njs_vmcode_try_end_t
    {

        njs_vmcode_t code;

        c_long offset;
    }

    struct njs_vmcode_try_return_t
    {

        njs_vmcode_t code;

        c_ulong save;

        c_ulong retval;

        c_long offset;
    }

    struct njs_vmcode_finally_t
    {

        njs_vmcode_t code;

        c_ulong retval;

        c_ulong exit_value;

        c_long continue_offset;

        c_long break_offset;
    }

    struct njs_vmcode_error_t
    {

        njs_vmcode_t code;

        njs_object_type_t type;

        static union _Anonymous_39
        {

            njs_str_t name;

            njs_str_t message;
        }

        _Anonymous_39 u;
    }

    struct njs_vmcode_function_copy_t
    {

        njs_vmcode_t code;

        njs_value_s* function_;

        c_ulong retval;
    }

    struct njs_vmcode_import_t
    {

        njs_vmcode_t code;

        c_ulong retval;

        njs_mod_s* module_;
    }

    struct njs_vmcode_variable_t
    {

        njs_vmcode_t code;

        c_ulong dst;
    }

    struct njs_vmcode_debugger_t
    {

        njs_vmcode_t code;

        c_ulong retval;
    }

    struct njs_vmcode_await_t
    {

        njs_vmcode_t code;

        c_ulong retval;
    }

    int njs_vmcode_interpreter(njs_vm_s*, ubyte*, void*, void*) @nogc nothrow;

    njs_object_s* njs_function_new_object(njs_vm_s*, njs_value_s*) @nogc nothrow;





    static if(!is(typeof(NJS_VMCODE_2OPERANDS))) {
        private enum enumMixinStr_NJS_VMCODE_2OPERANDS = `enum NJS_VMCODE_2OPERANDS = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_VMCODE_2OPERANDS); }))) {
            mixin(enumMixinStr_NJS_VMCODE_2OPERANDS);
        }
    }




    static if(!is(typeof(NJS_VMCODE_3OPERANDS))) {
        private enum enumMixinStr_NJS_VMCODE_3OPERANDS = `enum NJS_VMCODE_3OPERANDS = 0;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_VMCODE_3OPERANDS); }))) {
            mixin(enumMixinStr_NJS_VMCODE_3OPERANDS);
        }
    }




    static if(!is(typeof(NJS_PREEMPT))) {
        private enum enumMixinStr_NJS_PREEMPT = `enum NJS_PREEMPT = ( - 11 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PREEMPT); }))) {
            mixin(enumMixinStr_NJS_PREEMPT);
        }
    }
    static if(!is(typeof(NJS_OBJ_TYPE_TYPED_ARRAY_SIZE))) {
        private enum enumMixinStr_NJS_OBJ_TYPE_TYPED_ARRAY_SIZE = `enum NJS_OBJ_TYPE_TYPED_ARRAY_SIZE = ( NJS_OBJ_TYPE_TYPED_ARRAY_MAX - NJS_OBJ_TYPE_TYPED_ARRAY_MIN );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OBJ_TYPE_TYPED_ARRAY_SIZE); }))) {
            mixin(enumMixinStr_NJS_OBJ_TYPE_TYPED_ARRAY_SIZE);
        }
    }




    static if(!is(typeof(NJS_OBJ_TYPE_TYPED_ARRAY_MAX))) {
        private enum enumMixinStr_NJS_OBJ_TYPE_TYPED_ARRAY_MAX = `enum NJS_OBJ_TYPE_TYPED_ARRAY_MAX = ( NJS_OBJ_TYPE_FLOAT64_ARRAY + 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OBJ_TYPE_TYPED_ARRAY_MAX); }))) {
            mixin(enumMixinStr_NJS_OBJ_TYPE_TYPED_ARRAY_MAX);
        }
    }






    static if(!is(typeof(NJS_OBJ_TYPE_TYPED_ARRAY_MIN))) {
        private enum enumMixinStr_NJS_OBJ_TYPE_TYPED_ARRAY_MIN = `enum NJS_OBJ_TYPE_TYPED_ARRAY_MIN = ( NJS_OBJ_TYPE_UINT8_ARRAY );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OBJ_TYPE_TYPED_ARRAY_MIN); }))) {
            mixin(enumMixinStr_NJS_OBJ_TYPE_TYPED_ARRAY_MIN);
        }
    }




    static if(!is(typeof(NJS_OBJ_TYPE_NORMAL_MAX))) {
        private enum enumMixinStr_NJS_OBJ_TYPE_NORMAL_MAX = `enum NJS_OBJ_TYPE_NORMAL_MAX = ( NJS_OBJ_TYPE_HIDDEN_MAX );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OBJ_TYPE_NORMAL_MAX); }))) {
            mixin(enumMixinStr_NJS_OBJ_TYPE_NORMAL_MAX);
        }
    }




    static if(!is(typeof(NJS_OBJ_TYPE_HIDDEN_MAX))) {
        private enum enumMixinStr_NJS_OBJ_TYPE_HIDDEN_MAX = `enum NJS_OBJ_TYPE_HIDDEN_MAX = ( NJS_OBJ_TYPE_TYPED_ARRAY + 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OBJ_TYPE_HIDDEN_MAX); }))) {
            mixin(enumMixinStr_NJS_OBJ_TYPE_HIDDEN_MAX);
        }
    }




    static if(!is(typeof(NJS_OBJ_TYPE_HIDDEN_MIN))) {
        private enum enumMixinStr_NJS_OBJ_TYPE_HIDDEN_MIN = `enum NJS_OBJ_TYPE_HIDDEN_MIN = ( NJS_OBJ_TYPE_ITERATOR );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OBJ_TYPE_HIDDEN_MIN); }))) {
            mixin(enumMixinStr_NJS_OBJ_TYPE_HIDDEN_MIN);
        }
    }




    static if(!is(typeof(NJS_PROPERTY_QUERY_DELETE))) {
        private enum enumMixinStr_NJS_PROPERTY_QUERY_DELETE = `enum NJS_PROPERTY_QUERY_DELETE = 2;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PROPERTY_QUERY_DELETE); }))) {
            mixin(enumMixinStr_NJS_PROPERTY_QUERY_DELETE);
        }
    }




    static if(!is(typeof(NJS_PROPERTY_QUERY_SET))) {
        private enum enumMixinStr_NJS_PROPERTY_QUERY_SET = `enum NJS_PROPERTY_QUERY_SET = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PROPERTY_QUERY_SET); }))) {
            mixin(enumMixinStr_NJS_PROPERTY_QUERY_SET);
        }
    }




    static if(!is(typeof(NJS_PROPERTY_QUERY_GET))) {
        private enum enumMixinStr_NJS_PROPERTY_QUERY_GET = `enum NJS_PROPERTY_QUERY_GET = 0;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PROPERTY_QUERY_GET); }))) {
            mixin(enumMixinStr_NJS_PROPERTY_QUERY_GET);
        }
    }




    static if(!is(typeof(NJS_MAX_STACK_SIZE))) {
        private enum enumMixinStr_NJS_MAX_STACK_SIZE = `enum NJS_MAX_STACK_SIZE = ( 256 * 1024 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MAX_STACK_SIZE); }))) {
            mixin(enumMixinStr_NJS_MAX_STACK_SIZE);
        }
    }
    static if(!is(typeof(NJS_STRING_LONG))) {
        private enum enumMixinStr_NJS_STRING_LONG = `enum NJS_STRING_LONG = 15;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_STRING_LONG); }))) {
            mixin(enumMixinStr_NJS_STRING_LONG);
        }
    }




    static if(!is(typeof(NJS_STRING_SHORT))) {
        private enum enumMixinStr_NJS_STRING_SHORT = `enum NJS_STRING_SHORT = 14;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_STRING_SHORT); }))) {
            mixin(enumMixinStr_NJS_STRING_SHORT);
        }
    }




    static if(!is(typeof(NJS_OBJECT_SPECIAL_MAX))) {
        private enum enumMixinStr_NJS_OBJECT_SPECIAL_MAX = `enum NJS_OBJECT_SPECIAL_MAX = ( NJS_TYPED_ARRAY + 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OBJECT_SPECIAL_MAX); }))) {
            mixin(enumMixinStr_NJS_OBJECT_SPECIAL_MAX);
        }
    }




    static if(!is(typeof(NJS_OBJECT_SPECIAL_MIN))) {
        private enum enumMixinStr_NJS_OBJECT_SPECIAL_MIN = `enum NJS_OBJECT_SPECIAL_MIN = ( NJS_FUNCTION );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OBJECT_SPECIAL_MIN); }))) {
            mixin(enumMixinStr_NJS_OBJECT_SPECIAL_MIN);
        }
    }
    static if(!is(typeof(NJS_MAX_PATH))) {
        private enum enumMixinStr_NJS_MAX_PATH = `enum NJS_MAX_PATH = PATH_MAX;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MAX_PATH); }))) {
            mixin(enumMixinStr_NJS_MAX_PATH);
        }
    }
    static if(!is(typeof(NJS_MAX_ERROR_STR))) {
        private enum enumMixinStr_NJS_MAX_ERROR_STR = `enum NJS_MAX_ERROR_STR = 2048;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MAX_ERROR_STR); }))) {
            mixin(enumMixinStr_NJS_MAX_ERROR_STR);
        }
    }




    static if(!is(typeof(NJS_DOUBLE_LEN))) {
        private enum enumMixinStr_NJS_DOUBLE_LEN = `enum NJS_DOUBLE_LEN = ( 1 + DBL_MAX_10_EXP );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DOUBLE_LEN); }))) {
            mixin(enumMixinStr_NJS_DOUBLE_LEN);
        }
    }




    static if(!is(typeof(NJS_INT64_T_LEN))) {
        private enum enumMixinStr_NJS_INT64_T_LEN = `enum NJS_INT64_T_LEN = njs_length ( "-9223372036854775808" );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT64_T_LEN); }))) {
            mixin(enumMixinStr_NJS_INT64_T_LEN);
        }
    }




    static if(!is(typeof(NJS_INT32_T_LEN))) {
        private enum enumMixinStr_NJS_INT32_T_LEN = `enum NJS_INT32_T_LEN = njs_length ( "-2147483648" );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT32_T_LEN); }))) {
            mixin(enumMixinStr_NJS_INT32_T_LEN);
        }
    }




    static if(!is(typeof(NJS_INT_T_MAX))) {
        private enum enumMixinStr_NJS_INT_T_MAX = `enum NJS_INT_T_MAX = NJS_INT32_T_MAX;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT_T_MAX); }))) {
            mixin(enumMixinStr_NJS_INT_T_MAX);
        }
    }




    static if(!is(typeof(NJS_INT_T_HEXLEN))) {
        private enum enumMixinStr_NJS_INT_T_HEXLEN = `enum NJS_INT_T_HEXLEN = NJS_INT32_T_HEXLEN;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT_T_HEXLEN); }))) {
            mixin(enumMixinStr_NJS_INT_T_HEXLEN);
        }
    }




    static if(!is(typeof(NJS_INT_T_LEN))) {
        private enum enumMixinStr_NJS_INT_T_LEN = `enum NJS_INT_T_LEN = njs_length ( "-2147483648" );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT_T_LEN); }))) {
            mixin(enumMixinStr_NJS_INT_T_LEN);
        }
    }




    static if(!is(typeof(NJS_INT_T_SIZE))) {
        private enum enumMixinStr_NJS_INT_T_SIZE = `enum NJS_INT_T_SIZE = 4;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT_T_SIZE); }))) {
            mixin(enumMixinStr_NJS_INT_T_SIZE);
        }
    }




    static if(!is(typeof(NJS_PTR_SIZE))) {
        private enum enumMixinStr_NJS_PTR_SIZE = `enum NJS_PTR_SIZE = 8;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PTR_SIZE); }))) {
            mixin(enumMixinStr_NJS_PTR_SIZE);
        }
    }




    static if(!is(typeof(NJS_64BIT))) {
        private enum enumMixinStr_NJS_64BIT = `enum NJS_64BIT = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_64BIT); }))) {
            mixin(enumMixinStr_NJS_64BIT);
        }
    }




    static if(!is(typeof(_FILE_OFFSET_BITS))) {
        private enum enumMixinStr__FILE_OFFSET_BITS = `enum _FILE_OFFSET_BITS = 64;`;
        static if(is(typeof({ mixin(enumMixinStr__FILE_OFFSET_BITS); }))) {
            mixin(enumMixinStr__FILE_OFFSET_BITS);
        }
    }




    static if(!is(typeof(NJS_DONE))) {
        private enum enumMixinStr_NJS_DONE = `enum NJS_DONE = ( - 4 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DONE); }))) {
            mixin(enumMixinStr_NJS_DONE);
        }
    }




    static if(!is(typeof(NJS_DECLINED))) {
        private enum enumMixinStr_NJS_DECLINED = `enum NJS_DECLINED = ( - 3 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DECLINED); }))) {
            mixin(enumMixinStr_NJS_DECLINED);
        }
    }




    static if(!is(typeof(NJS_AGAIN))) {
        private enum enumMixinStr_NJS_AGAIN = `enum NJS_AGAIN = ( - 2 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_AGAIN); }))) {
            mixin(enumMixinStr_NJS_AGAIN);
        }
    }




    static if(!is(typeof(NJS_ERROR))) {
        private enum enumMixinStr_NJS_ERROR = `enum NJS_ERROR = ( - 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ERROR); }))) {
            mixin(enumMixinStr_NJS_ERROR);
        }
    }




    static if(!is(typeof(NJS_OK))) {
        private enum enumMixinStr_NJS_OK = `enum NJS_OK = 0;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OK); }))) {
            mixin(enumMixinStr_NJS_OK);
        }
    }
    static if(!is(typeof(NJS_STRING_MAP_STRIDE))) {
        private enum enumMixinStr_NJS_STRING_MAP_STRIDE = `enum NJS_STRING_MAP_STRIDE = 32;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_STRING_MAP_STRIDE); }))) {
            mixin(enumMixinStr_NJS_STRING_MAP_STRIDE);
        }
    }




    static if(!is(typeof(NJS_STRING_MAX_LENGTH))) {
        private enum enumMixinStr_NJS_STRING_MAX_LENGTH = `enum NJS_STRING_MAX_LENGTH = 0x7fffffff;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_STRING_MAX_LENGTH); }))) {
            mixin(enumMixinStr_NJS_STRING_MAX_LENGTH);
        }
    }
    static if(!is(typeof(njs_null_str))) {
        private enum enumMixinStr_njs_null_str = `enum njs_null_str = { 0 , null };`;
        static if(is(typeof({ mixin(enumMixinStr_njs_null_str); }))) {
            mixin(enumMixinStr_njs_null_str);
        }
    }
    static if(!is(typeof(NJS_INDEX_ERROR))) {
        private enum enumMixinStr_NJS_INDEX_ERROR = `enum NJS_INDEX_ERROR = ( cast( njs_index_t ) - 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INDEX_ERROR); }))) {
            mixin(enumMixinStr_NJS_INDEX_ERROR);
        }
    }




    static if(!is(typeof(NJS_INDEX_NONE))) {
        private enum enumMixinStr_NJS_INDEX_NONE = `enum NJS_INDEX_NONE = ( cast( njs_index_t ) 0 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INDEX_NONE); }))) {
            mixin(enumMixinStr_NJS_INDEX_NONE);
        }
    }




    static if(!is(typeof(NJS_SCOPE_TYPE_MASK))) {
        private enum enumMixinStr_NJS_SCOPE_TYPE_MASK = `enum NJS_SCOPE_TYPE_MASK = ( ( NJS_SCOPE_VALUE_MAX ) << NJS_SCOPE_VAR_SIZE );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SCOPE_TYPE_MASK); }))) {
            mixin(enumMixinStr_NJS_SCOPE_TYPE_MASK);
        }
    }




    static if(!is(typeof(NJS_SCOPE_VALUE_MAX))) {
        private enum enumMixinStr_NJS_SCOPE_VALUE_MAX = `enum NJS_SCOPE_VALUE_MAX = ( ( 1 << ( 32 - NJS_SCOPE_VALUE_OFFSET ) ) - 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SCOPE_VALUE_MAX); }))) {
            mixin(enumMixinStr_NJS_SCOPE_VALUE_MAX);
        }
    }




    static if(!is(typeof(NJS_SCOPE_VALUE_OFFSET))) {
        private enum enumMixinStr_NJS_SCOPE_VALUE_OFFSET = `enum NJS_SCOPE_VALUE_OFFSET = ( NJS_SCOPE_TYPE_OFFSET + 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SCOPE_VALUE_OFFSET); }))) {
            mixin(enumMixinStr_NJS_SCOPE_VALUE_OFFSET);
        }
    }




    static if(!is(typeof(NJS_SCOPE_TYPE_OFFSET))) {
        private enum enumMixinStr_NJS_SCOPE_TYPE_OFFSET = `enum NJS_SCOPE_TYPE_OFFSET = ( NJS_SCOPE_VAR_SIZE + 4 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SCOPE_TYPE_OFFSET); }))) {
            mixin(enumMixinStr_NJS_SCOPE_TYPE_OFFSET);
        }
    }




    static if(!is(typeof(NJS_SCOPE_VAR_SIZE))) {
        private enum enumMixinStr_NJS_SCOPE_VAR_SIZE = `enum NJS_SCOPE_VAR_SIZE = 4;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SCOPE_VAR_SIZE); }))) {
            mixin(enumMixinStr_NJS_SCOPE_VAR_SIZE);
        }
    }
    static if(!is(typeof(njs_regex_match_data_t))) {
        private enum enumMixinStr_njs_regex_match_data_t = `enum njs_regex_match_data_t = void;`;
        static if(is(typeof({ mixin(enumMixinStr_njs_regex_match_data_t); }))) {
            mixin(enumMixinStr_njs_regex_match_data_t);
        }
    }




    static if(!is(typeof(njs_regex_compile_ctx_t))) {
        private enum enumMixinStr_njs_regex_compile_ctx_t = `enum njs_regex_compile_ctx_t = void;`;
        static if(is(typeof({ mixin(enumMixinStr_njs_regex_compile_ctx_t); }))) {
            mixin(enumMixinStr_njs_regex_compile_ctx_t);
        }
    }




    static if(!is(typeof(njs_regex_generic_ctx_t))) {
        private enum enumMixinStr_njs_regex_generic_ctx_t = `enum njs_regex_generic_ctx_t = void;`;
        static if(is(typeof({ mixin(enumMixinStr_njs_regex_generic_ctx_t); }))) {
            mixin(enumMixinStr_njs_regex_generic_ctx_t);
        }
    }




    static if(!is(typeof(NJS_REGEX_UNSET))) {
        private enum enumMixinStr_NJS_REGEX_UNSET = `enum NJS_REGEX_UNSET = ( size_t ) ( - 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_REGEX_UNSET); }))) {
            mixin(enumMixinStr_NJS_REGEX_UNSET);
        }
    }
    static if(!is(typeof(NJS_RBTREE_NODE_INIT))) {
        private enum enumMixinStr_NJS_RBTREE_NODE_INIT = `enum NJS_RBTREE_NODE_INIT = { null , null , null } , 0;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_RBTREE_NODE_INIT); }))) {
            mixin(enumMixinStr_NJS_RBTREE_NODE_INIT);
        }
    }
    static if(!is(typeof(NJS_BUFFER_HASH))) {
        private enum enumMixinStr_NJS_BUFFER_HASH = `enum NJS_BUFFER_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'B' ) , 'u' ) , 'f' ) , 'f' ) , 'e' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_BUFFER_HASH); }))) {
            mixin(enumMixinStr_NJS_BUFFER_HASH);
        }
    }




    static if(!is(typeof(NJS_TEXT_ENCODER_HASH))) {
        private enum enumMixinStr_NJS_TEXT_ENCODER_HASH = `enum NJS_TEXT_ENCODER_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'T' ) , 'e' ) , 'x' ) , 't' ) , 'E' ) , 'n' ) , 'c' ) , 'o' ) , 'd' ) , 'e' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TEXT_ENCODER_HASH); }))) {
            mixin(enumMixinStr_NJS_TEXT_ENCODER_HASH);
        }
    }




    static if(!is(typeof(NJS_TEXT_DECODER_HASH))) {
        private enum enumMixinStr_NJS_TEXT_DECODER_HASH = `enum NJS_TEXT_DECODER_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'T' ) , 'e' ) , 'x' ) , 't' ) , 'D' ) , 'e' ) , 'c' ) , 'o' ) , 'd' ) , 'e' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TEXT_DECODER_HASH); }))) {
            mixin(enumMixinStr_NJS_TEXT_DECODER_HASH);
        }
    }




    static if(!is(typeof(NJS_UINT8CLAMPEDARRAY_HASH))) {
        private enum enumMixinStr_NJS_UINT8CLAMPEDARRAY_HASH = `enum NJS_UINT8CLAMPEDARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'U' ) , 'i' ) , 'n' ) , 't' ) , '8' ) , 'C' ) , 'l' ) , 'a' ) , 'm' ) , 'p' ) , 'e' ) , 'd' ) , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_UINT8CLAMPEDARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_UINT8CLAMPEDARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS_FLOAT64ARRAY_HASH))) {
        private enum enumMixinStr_NJS_FLOAT64ARRAY_HASH = `enum NJS_FLOAT64ARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'F' ) , 'l' ) , 'o' ) , 'a' ) , 't' ) , '6' ) , '4' ) , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_FLOAT64ARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_FLOAT64ARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS_FLOAT32ARRAY_HASH))) {
        private enum enumMixinStr_NJS_FLOAT32ARRAY_HASH = `enum NJS_FLOAT32ARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'F' ) , 'l' ) , 'o' ) , 'a' ) , 't' ) , '3' ) , '2' ) , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_FLOAT32ARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_FLOAT32ARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS_INT32ARRAY_HASH))) {
        private enum enumMixinStr_NJS_INT32ARRAY_HASH = `enum NJS_INT32ARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'I' ) , 'n' ) , 't' ) , '3' ) , '2' ) , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT32ARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_INT32ARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS_INT16ARRAY_HASH))) {
        private enum enumMixinStr_NJS_INT16ARRAY_HASH = `enum NJS_INT16ARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'I' ) , 'n' ) , 't' ) , '1' ) , '6' ) , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT16ARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_INT16ARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS_INT8ARRAY_HASH))) {
        private enum enumMixinStr_NJS_INT8ARRAY_HASH = `enum NJS_INT8ARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'I' ) , 'n' ) , 't' ) , '8' ) , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT8ARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_INT8ARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS_UINT32ARRAY_HASH))) {
        private enum enumMixinStr_NJS_UINT32ARRAY_HASH = `enum NJS_UINT32ARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'U' ) , 'i' ) , 'n' ) , 't' ) , '3' ) , '2' ) , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_UINT32ARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_UINT32ARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS_UINT16ARRAY_HASH))) {
        private enum enumMixinStr_NJS_UINT16ARRAY_HASH = `enum NJS_UINT16ARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'U' ) , 'i' ) , 'n' ) , 't' ) , '1' ) , '6' ) , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_UINT16ARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_UINT16ARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS_UINT8ARRAY_HASH))) {
        private enum enumMixinStr_NJS_UINT8ARRAY_HASH = `enum NJS_UINT8ARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'U' ) , 'i' ) , 'n' ) , 't' ) , '8' ) , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_UINT8ARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_UINT8ARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS_DATA_VIEW_HASH))) {
        private enum enumMixinStr_NJS_DATA_VIEW_HASH = `enum NJS_DATA_VIEW_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'D' ) , 'a' ) , 't' ) , 'a' ) , 'V' ) , 'i' ) , 'e' ) , 'w' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DATA_VIEW_HASH); }))) {
            mixin(enumMixinStr_NJS_DATA_VIEW_HASH);
        }
    }




    static if(!is(typeof(NJS_ARRAY_BUFFER_HASH))) {
        private enum enumMixinStr_NJS_ARRAY_BUFFER_HASH = `enum NJS_ARRAY_BUFFER_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' ) , 'B' ) , 'u' ) , 'f' ) , 'f' ) , 'e' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ARRAY_BUFFER_HASH); }))) {
            mixin(enumMixinStr_NJS_ARRAY_BUFFER_HASH);
        }
    }




    static if(!is(typeof(NJS_URI_ERROR_HASH))) {
        private enum enumMixinStr_NJS_URI_ERROR_HASH = `enum NJS_URI_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'U' ) , 'R' ) , 'I' ) , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_URI_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_URI_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_WRITABABLE_HASH))) {
        private enum enumMixinStr_NJS_WRITABABLE_HASH = `enum NJS_WRITABABLE_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'w' ) , 'r' ) , 'i' ) , 't' ) , 'a' ) , 'b' ) , 'l' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_WRITABABLE_HASH); }))) {
            mixin(enumMixinStr_NJS_WRITABABLE_HASH);
        }
    }




    static if(!is(typeof(NJS_VALUE_OF_HASH))) {
        private enum enumMixinStr_NJS_VALUE_OF_HASH = `enum NJS_VALUE_OF_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'v' ) , 'a' ) , 'l' ) , 'u' ) , 'e' ) , 'O' ) , 'f' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_VALUE_OF_HASH); }))) {
            mixin(enumMixinStr_NJS_VALUE_OF_HASH);
        }
    }




    static if(!is(typeof(NJS_VALUE_HASH))) {
        private enum enumMixinStr_NJS_VALUE_HASH = `enum NJS_VALUE_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'v' ) , 'a' ) , 'l' ) , 'u' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_VALUE_HASH); }))) {
            mixin(enumMixinStr_NJS_VALUE_HASH);
        }
    }




    static if(!is(typeof(NJS_TYPE_ERROR_HASH))) {
        private enum enumMixinStr_NJS_TYPE_ERROR_HASH = `enum NJS_TYPE_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'T' ) , 'y' ) , 'p' ) , 'e' ) , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TYPE_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_TYPE_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_TO_ISO_STRING_HASH))) {
        private enum enumMixinStr_NJS_TO_ISO_STRING_HASH = `enum NJS_TO_ISO_STRING_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 't' ) , 'o' ) , 'I' ) , 'S' ) , 'O' ) , 'S' ) , 't' ) , 'r' ) , 'i' ) , 'n' ) , 'g' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TO_ISO_STRING_HASH); }))) {
            mixin(enumMixinStr_NJS_TO_ISO_STRING_HASH);
        }
    }




    static if(!is(typeof(NJS_TO_STRING_HASH))) {
        private enum enumMixinStr_NJS_TO_STRING_HASH = `enum NJS_TO_STRING_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 't' ) , 'o' ) , 'S' ) , 't' ) , 'r' ) , 'i' ) , 'n' ) , 'g' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TO_STRING_HASH); }))) {
            mixin(enumMixinStr_NJS_TO_STRING_HASH);
        }
    }




    static if(!is(typeof(NJS_TO_JSON_HASH))) {
        private enum enumMixinStr_NJS_TO_JSON_HASH = `enum NJS_TO_JSON_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 't' ) , 'o' ) , 'J' ) , 'S' ) , 'O' ) , 'N' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TO_JSON_HASH); }))) {
            mixin(enumMixinStr_NJS_TO_JSON_HASH);
        }
    }




    static if(!is(typeof(NJS_SYSCALL_HASH))) {
        private enum enumMixinStr_NJS_SYSCALL_HASH = `enum NJS_SYSCALL_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 's' ) , 'y' ) , 's' ) , 'c' ) , 'a' ) , 'l' ) , 'l' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SYSCALL_HASH); }))) {
            mixin(enumMixinStr_NJS_SYSCALL_HASH);
        }
    }




    static if(!is(typeof(NJS_SYNTAX_ERROR_HASH))) {
        private enum enumMixinStr_NJS_SYNTAX_ERROR_HASH = `enum NJS_SYNTAX_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'S' ) , 'y' ) , 'n' ) , 't' ) , 'a' ) , 'x' ) , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SYNTAX_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_SYNTAX_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_SYMBOL_HASH))) {
        private enum enumMixinStr_NJS_SYMBOL_HASH = `enum NJS_SYMBOL_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'S' ) , 'y' ) , 'm' ) , 'b' ) , 'o' ) , 'l' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SYMBOL_HASH); }))) {
            mixin(enumMixinStr_NJS_SYMBOL_HASH);
        }
    }




    static if(!is(typeof(NJS_STRING_HASH))) {
        private enum enumMixinStr_NJS_STRING_HASH = `enum NJS_STRING_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'S' ) , 't' ) , 'r' ) , 'i' ) , 'n' ) , 'g' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_STRING_HASH); }))) {
            mixin(enumMixinStr_NJS_STRING_HASH);
        }
    }




    static if(!is(typeof(NJS_STACK_HASH))) {
        private enum enumMixinStr_NJS_STACK_HASH = `enum NJS_STACK_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 's' ) , 't' ) , 'a' ) , 'c' ) , 'k' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_STACK_HASH); }))) {
            mixin(enumMixinStr_NJS_STACK_HASH);
        }
    }




    static if(!is(typeof(NJS_SET_HASH))) {
        private enum enumMixinStr_NJS_SET_HASH = `enum NJS_SET_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 's' ) , 'e' ) , 't' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SET_HASH); }))) {
            mixin(enumMixinStr_NJS_SET_HASH);
        }
    }




    static if(!is(typeof(NJS_REGEXP_HASH))) {
        private enum enumMixinStr_NJS_REGEXP_HASH = `enum NJS_REGEXP_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'R' ) , 'e' ) , 'g' ) , 'E' ) , 'x' ) , 'p' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_REGEXP_HASH); }))) {
            mixin(enumMixinStr_NJS_REGEXP_HASH);
        }
    }




    static if(!is(typeof(NJS_REF_ERROR_HASH))) {
        private enum enumMixinStr_NJS_REF_ERROR_HASH = `enum NJS_REF_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'R' ) , 'e' ) , 'f' ) , 'e' ) , 'r' ) , 'e' ) , 'n' ) , 'c' ) , 'e' ) , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_REF_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_REF_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_RANGE_ERROR_HASH))) {
        private enum enumMixinStr_NJS_RANGE_ERROR_HASH = `enum NJS_RANGE_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'R' ) , 'a' ) , 'n' ) , 'g' ) , 'e' ) , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_RANGE_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_RANGE_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_PROTOTYPE_HASH))) {
        private enum enumMixinStr_NJS_PROTOTYPE_HASH = `enum NJS_PROTOTYPE_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'p' ) , 'r' ) , 'o' ) , 't' ) , 'o' ) , 't' ) , 'y' ) , 'p' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PROTOTYPE_HASH); }))) {
            mixin(enumMixinStr_NJS_PROTOTYPE_HASH);
        }
    }




    static if(!is(typeof(NJS_PROCESS_HASH))) {
        private enum enumMixinStr_NJS_PROCESS_HASH = `enum NJS_PROCESS_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'p' ) , 'r' ) , 'o' ) , 'c' ) , 'e' ) , 's' ) , 's' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PROCESS_HASH); }))) {
            mixin(enumMixinStr_NJS_PROCESS_HASH);
        }
    }




    static if(!is(typeof(NJS_PATH_HASH))) {
        private enum enumMixinStr_NJS_PATH_HASH = `enum NJS_PATH_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'p' ) , 'a' ) , 't' ) , 'h' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PATH_HASH); }))) {
            mixin(enumMixinStr_NJS_PATH_HASH);
        }
    }




    static if(!is(typeof(NJS_OBJECT_HASH))) {
        private enum enumMixinStr_NJS_OBJECT_HASH = `enum NJS_OBJECT_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'O' ) , 'b' ) , 'j' ) , 'e' ) , 'c' ) , 't' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OBJECT_HASH); }))) {
            mixin(enumMixinStr_NJS_OBJECT_HASH);
        }
    }




    static if(!is(typeof(NJS_MODE_HASH))) {
        private enum enumMixinStr_NJS_MODE_HASH = `enum NJS_MODE_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'm' ) , 'o' ) , 'd' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MODE_HASH); }))) {
            mixin(enumMixinStr_NJS_MODE_HASH);
        }
    }




    static if(!is(typeof(NJS_ERRORS_HASH))) {
        private enum enumMixinStr_NJS_ERRORS_HASH = `enum NJS_ERRORS_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'e' ) , 'r' ) , 'r' ) , 'o' ) , 'r' ) , 's' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ERRORS_HASH); }))) {
            mixin(enumMixinStr_NJS_ERRORS_HASH);
        }
    }




    static if(!is(typeof(NJS_MESSAGE_HASH))) {
        private enum enumMixinStr_NJS_MESSAGE_HASH = `enum NJS_MESSAGE_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'm' ) , 'e' ) , 's' ) , 's' ) , 'a' ) , 'g' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MESSAGE_HASH); }))) {
            mixin(enumMixinStr_NJS_MESSAGE_HASH);
        }
    }




    static if(!is(typeof(NJS_AGGREGATE_ERROR_HASH))) {
        private enum enumMixinStr_NJS_AGGREGATE_ERROR_HASH = `enum NJS_AGGREGATE_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'A' ) , 'g' ) , 'g' ) , 'r' ) , 'e' ) , 'g' ) , 'a' ) , 't' ) , 'e' ) , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_AGGREGATE_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_AGGREGATE_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_MEMORY_ERROR_HASH))) {
        private enum enumMixinStr_NJS_MEMORY_ERROR_HASH = `enum NJS_MEMORY_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'M' ) , 'e' ) , 'm' ) , 'o' ) , 'r' ) , 'y' ) , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MEMORY_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_MEMORY_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_MATH_HASH))) {
        private enum enumMixinStr_NJS_MATH_HASH = `enum NJS_MATH_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'M' ) , 'a' ) , 't' ) , 'h' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MATH_HASH); }))) {
            mixin(enumMixinStr_NJS_MATH_HASH);
        }
    }




    static if(!is(typeof(NJS_NUMBER_HASH))) {
        private enum enumMixinStr_NJS_NUMBER_HASH = `enum NJS_NUMBER_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'N' ) , 'u' ) , 'm' ) , 'b' ) , 'e' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_NUMBER_HASH); }))) {
            mixin(enumMixinStr_NJS_NUMBER_HASH);
        }
    }




    static if(!is(typeof(NJS_262_HASH))) {
        private enum enumMixinStr_NJS_262_HASH = `enum NJS_262_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , '$' ) , '2' ) , '6' ) , '2' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_262_HASH); }))) {
            mixin(enumMixinStr_NJS_262_HASH);
        }
    }




    static if(!is(typeof(NJS_NJS_HASH))) {
        private enum enumMixinStr_NJS_NJS_HASH = `enum NJS_NJS_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'n' ) , 'j' ) , 's' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_NJS_HASH); }))) {
            mixin(enumMixinStr_NJS_NJS_HASH);
        }
    }




    static if(!is(typeof(NJS_NAME_HASH))) {
        private enum enumMixinStr_NJS_NAME_HASH = `enum NJS_NAME_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'n' ) , 'a' ) , 'm' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_NAME_HASH); }))) {
            mixin(enumMixinStr_NJS_NAME_HASH);
        }
    }




    static if(!is(typeof(NJS_LENGTH_HASH))) {
        private enum enumMixinStr_NJS_LENGTH_HASH = `enum NJS_LENGTH_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'l' ) , 'e' ) , 'n' ) , 'g' ) , 't' ) , 'h' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_LENGTH_HASH); }))) {
            mixin(enumMixinStr_NJS_LENGTH_HASH);
        }
    }




    static if(!is(typeof(NJS_JSON_HASH))) {
        private enum enumMixinStr_NJS_JSON_HASH = `enum NJS_JSON_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'J' ) , 'S' ) , 'O' ) , 'N' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_JSON_HASH); }))) {
            mixin(enumMixinStr_NJS_JSON_HASH);
        }
    }




    static if(!is(typeof(NJS_JOIN_HASH))) {
        private enum enumMixinStr_NJS_JOIN_HASH = `enum NJS_JOIN_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'j' ) , 'o' ) , 'i' ) , 'n' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_JOIN_HASH); }))) {
            mixin(enumMixinStr_NJS_JOIN_HASH);
        }
    }




    static if(!is(typeof(NJS_GROUPS_HASH))) {
        private enum enumMixinStr_NJS_GROUPS_HASH = `enum NJS_GROUPS_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'g' ) , 'r' ) , 'o' ) , 'u' ) , 'p' ) , 's' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_GROUPS_HASH); }))) {
            mixin(enumMixinStr_NJS_GROUPS_HASH);
        }
    }




    static if(!is(typeof(NJS_INTERNAL_ERROR_HASH))) {
        private enum enumMixinStr_NJS_INTERNAL_ERROR_HASH = `enum NJS_INTERNAL_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'I' ) , 'n' ) , 't' ) , 'e' ) , 'r' ) , 'n' ) , 'a' ) , 'l' ) , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INTERNAL_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_INTERNAL_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_INPUT_HASH))) {
        private enum enumMixinStr_NJS_INPUT_HASH = `enum NJS_INPUT_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'i' ) , 'n' ) , 'p' ) , 'u' ) , 't' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INPUT_HASH); }))) {
            mixin(enumMixinStr_NJS_INPUT_HASH);
        }
    }




    static if(!is(typeof(NJS_INDEX_HASH))) {
        private enum enumMixinStr_NJS_INDEX_HASH = `enum NJS_INDEX_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'i' ) , 'n' ) , 'd' ) , 'e' ) , 'x' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INDEX_HASH); }))) {
            mixin(enumMixinStr_NJS_INDEX_HASH);
        }
    }




    static if(!is(typeof(NJS_FUNCTION_HASH))) {
        private enum enumMixinStr_NJS_FUNCTION_HASH = `enum NJS_FUNCTION_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'F' ) , 'u' ) , 'n' ) , 'c' ) , 't' ) , 'i' ) , 'o' ) , 'n' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_FUNCTION_HASH); }))) {
            mixin(enumMixinStr_NJS_FUNCTION_HASH);
        }
    }




    static if(!is(typeof(NJS_GLOBAL_THIS_HASH))) {
        private enum enumMixinStr_NJS_GLOBAL_THIS_HASH = `enum NJS_GLOBAL_THIS_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'g' ) , 'l' ) , 'o' ) , 'b' ) , 'a' ) , 'l' ) , 'T' ) , 'h' ) , 'i' ) , 's' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_GLOBAL_THIS_HASH); }))) {
            mixin(enumMixinStr_NJS_GLOBAL_THIS_HASH);
        }
    }




    static if(!is(typeof(NJS_GLOBAL_HASH))) {
        private enum enumMixinStr_NJS_GLOBAL_HASH = `enum NJS_GLOBAL_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'g' ) , 'l' ) , 'o' ) , 'b' ) , 'a' ) , 'l' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_GLOBAL_HASH); }))) {
            mixin(enumMixinStr_NJS_GLOBAL_HASH);
        }
    }




    static if(!is(typeof(NJS_GET_HASH))) {
        private enum enumMixinStr_NJS_GET_HASH = `enum NJS_GET_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'g' ) , 'e' ) , 't' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_GET_HASH); }))) {
            mixin(enumMixinStr_NJS_GET_HASH);
        }
    }




    static if(!is(typeof(NJS_FLAG_HASH))) {
        private enum enumMixinStr_NJS_FLAG_HASH = `enum NJS_FLAG_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'f' ) , 'l' ) , 'a' ) , 'g' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_FLAG_HASH); }))) {
            mixin(enumMixinStr_NJS_FLAG_HASH);
        }
    }




    static if(!is(typeof(NJS_EVAL_ERROR_HASH))) {
        private enum enumMixinStr_NJS_EVAL_ERROR_HASH = `enum NJS_EVAL_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'E' ) , 'v' ) , 'a' ) , 'l' ) , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_EVAL_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_EVAL_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_ENV_HASH))) {
        private enum enumMixinStr_NJS_ENV_HASH = `enum NJS_ENV_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'e' ) , 'n' ) , 'v' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ENV_HASH); }))) {
            mixin(enumMixinStr_NJS_ENV_HASH);
        }
    }




    static if(!is(typeof(NJS_ENCODING_HASH))) {
        private enum enumMixinStr_NJS_ENCODING_HASH = `enum NJS_ENCODING_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'e' ) , 'n' ) , 'c' ) , 'o' ) , 'd' ) , 'i' ) , 'n' ) , 'g' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ENCODING_HASH); }))) {
            mixin(enumMixinStr_NJS_ENCODING_HASH);
        }
    }




    static if(!is(typeof(NJS_ERROR_HASH))) {
        private enum enumMixinStr_NJS_ERROR_HASH = `enum NJS_ERROR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'E' ) , 'r' ) , 'r' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ERROR_HASH); }))) {
            mixin(enumMixinStr_NJS_ERROR_HASH);
        }
    }




    static if(!is(typeof(NJS_ERRNO_HASH))) {
        private enum enumMixinStr_NJS_ERRNO_HASH = `enum NJS_ERRNO_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'e' ) , 'r' ) , 'r' ) , 'n' ) , 'o' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ERRNO_HASH); }))) {
            mixin(enumMixinStr_NJS_ERRNO_HASH);
        }
    }




    static if(!is(typeof(NJS_ENUMERABLE_HASH))) {
        private enum enumMixinStr_NJS_ENUMERABLE_HASH = `enum NJS_ENUMERABLE_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'e' ) , 'n' ) , 'u' ) , 'm' ) , 'e' ) , 'r' ) , 'a' ) , 'b' ) , 'l' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ENUMERABLE_HASH); }))) {
            mixin(enumMixinStr_NJS_ENUMERABLE_HASH);
        }
    }




    static if(!is(typeof(NJS_PROMISE_HASH))) {
        private enum enumMixinStr_NJS_PROMISE_HASH = `enum NJS_PROMISE_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'P' ) , 'r' ) , 'o' ) , 'm' ) , 'i' ) , 's' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PROMISE_HASH); }))) {
            mixin(enumMixinStr_NJS_PROMISE_HASH);
        }
    }




    static if(!is(typeof(NJS_DATE_HASH))) {
        private enum enumMixinStr_NJS_DATE_HASH = `enum NJS_DATE_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'D' ) , 'a' ) , 't' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DATE_HASH); }))) {
            mixin(enumMixinStr_NJS_DATE_HASH);
        }
    }




    static if(!is(typeof(NJS_CONSTRUCTOR_HASH))) {
        private enum enumMixinStr_NJS_CONSTRUCTOR_HASH = `enum NJS_CONSTRUCTOR_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'c' ) , 'o' ) , 'n' ) , 's' ) , 't' ) , 'r' ) , 'u' ) , 'c' ) , 't' ) , 'o' ) , 'r' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_CONSTRUCTOR_HASH); }))) {
            mixin(enumMixinStr_NJS_CONSTRUCTOR_HASH);
        }
    }




    static if(!is(typeof(NJS_CONFIGURABLE_HASH))) {
        private enum enumMixinStr_NJS_CONFIGURABLE_HASH = `enum NJS_CONFIGURABLE_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'c' ) , 'o' ) , 'n' ) , 'f' ) , 'i' ) , 'g' ) , 'u' ) , 'r' ) , 'a' ) , 'b' ) , 'l' ) , 'e' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_CONFIGURABLE_HASH); }))) {
            mixin(enumMixinStr_NJS_CONFIGURABLE_HASH);
        }
    }




    static if(!is(typeof(NJS_BOOLEAN_HASH))) {
        private enum enumMixinStr_NJS_BOOLEAN_HASH = `enum NJS_BOOLEAN_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'B' ) , 'o' ) , 'o' ) , 'l' ) , 'e' ) , 'a' ) , 'n' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_BOOLEAN_HASH); }))) {
            mixin(enumMixinStr_NJS_BOOLEAN_HASH);
        }
    }




    static if(!is(typeof(NJS_ARGV_HASH))) {
        private enum enumMixinStr_NJS_ARGV_HASH = `enum NJS_ARGV_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'a' ) , 'r' ) , 'g' ) , 'v' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ARGV_HASH); }))) {
            mixin(enumMixinStr_NJS_ARGV_HASH);
        }
    }




    static if(!is(typeof(NJS_ARRAY_HASH))) {
        private enum enumMixinStr_NJS_ARRAY_HASH = `enum NJS_ARRAY_HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , 'A' ) , 'r' ) , 'r' ) , 'a' ) , 'y' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ARRAY_HASH); }))) {
            mixin(enumMixinStr_NJS_ARRAY_HASH);
        }
    }




    static if(!is(typeof(NJS___PROTO___HASH))) {
        private enum enumMixinStr_NJS___PROTO___HASH = `enum NJS___PROTO___HASH = njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( njs_djb_hash_add ( NJS_DJB_HASH_INIT , '_' ) , '_' ) , 'p' ) , 'r' ) , 'o' ) , 't' ) , 'o' ) , '_' ) , '_' );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS___PROTO___HASH); }))) {
            mixin(enumMixinStr_NJS___PROTO___HASH);
        }
    }
    static if(!is(typeof(NJS_TRAVERSE_MAX_DEPTH))) {
        private enum enumMixinStr_NJS_TRAVERSE_MAX_DEPTH = `enum NJS_TRAVERSE_MAX_DEPTH = 32;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TRAVERSE_MAX_DEPTH); }))) {
            mixin(enumMixinStr_NJS_TRAVERSE_MAX_DEPTH);
        }
    }






    static if(!is(typeof(NJS_INT64_DBL_MAX))) {
        private enum enumMixinStr_NJS_INT64_DBL_MAX = `enum NJS_INT64_DBL_MAX = ( 9.223372036854776e+18 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT64_DBL_MAX); }))) {
            mixin(enumMixinStr_NJS_INT64_DBL_MAX);
        }
    }




    static if(!is(typeof(NJS_INT64_DBL_MIN))) {
        private enum enumMixinStr_NJS_INT64_DBL_MIN = `enum NJS_INT64_DBL_MIN = ( - 9.223372036854776e+18 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT64_DBL_MIN); }))) {
            mixin(enumMixinStr_NJS_INT64_DBL_MIN);
        }
    }




    static if(!is(typeof(NJS_MAX_LENGTH))) {
        private enum enumMixinStr_NJS_MAX_LENGTH = `enum NJS_MAX_LENGTH = ( 0x1fffffffffffffL );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MAX_LENGTH); }))) {
            mixin(enumMixinStr_NJS_MAX_LENGTH);
        }
    }
    static if(!is(typeof(NJS_LVLHSH_LARGE_MEMALIGN))) {
        private enum enumMixinStr_NJS_LVLHSH_LARGE_MEMALIGN = `enum NJS_LVLHSH_LARGE_MEMALIGN = NJS_LVLHSH_BUCKET_SIZE ( NJS_LVLHSH_DEFAULT_BUCKET_SIZE ) , { NJS_LVLHSH_MAX_MEMALIGN_SHIFT , 4 , 4 , 4 , 4 , 0 , 0 , 0 };`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_LVLHSH_LARGE_MEMALIGN); }))) {
            mixin(enumMixinStr_NJS_LVLHSH_LARGE_MEMALIGN);
        }
    }




    static if(!is(typeof(NJS_LVLHSH_LARGE_SLAB))) {
        private enum enumMixinStr_NJS_LVLHSH_LARGE_SLAB = `enum NJS_LVLHSH_LARGE_SLAB = NJS_LVLHSH_BUCKET_SIZE ( NJS_LVLHSH_DEFAULT_BUCKET_SIZE ) , { 10 , 4 , 4 , 4 , 4 , 4 , 4 , 0 };`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_LVLHSH_LARGE_SLAB); }))) {
            mixin(enumMixinStr_NJS_LVLHSH_LARGE_SLAB);
        }
    }




    static if(!is(typeof(NJS_LVLHSH_DEFAULT))) {
        private enum enumMixinStr_NJS_LVLHSH_DEFAULT = `enum NJS_LVLHSH_DEFAULT = NJS_LVLHSH_BUCKET_SIZE ( NJS_LVLHSH_DEFAULT_BUCKET_SIZE ) , { 4 , 4 , 4 , 4 , 4 , 4 , 4 , 0 };`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_LVLHSH_DEFAULT); }))) {
            mixin(enumMixinStr_NJS_LVLHSH_DEFAULT);
        }
    }
    static if(!is(typeof(NJS_LVLHSH_MAX_MEMALIGN_SHIFT))) {
        private enum enumMixinStr_NJS_LVLHSH_MAX_MEMALIGN_SHIFT = `enum NJS_LVLHSH_MAX_MEMALIGN_SHIFT = NJS_LVLHSH_MEMALIGN_SHIFT;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_LVLHSH_MAX_MEMALIGN_SHIFT); }))) {
            mixin(enumMixinStr_NJS_LVLHSH_MAX_MEMALIGN_SHIFT);
        }
    }




    static if(!is(typeof(NJS_LVLHSH_MEMALIGN_SHIFT))) {
        private enum enumMixinStr_NJS_LVLHSH_MEMALIGN_SHIFT = `enum NJS_LVLHSH_MEMALIGN_SHIFT = ( NJS_MAX_MEMALIGN_SHIFT - 3 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_LVLHSH_MEMALIGN_SHIFT); }))) {
            mixin(enumMixinStr_NJS_LVLHSH_MEMALIGN_SHIFT);
        }
    }




    static if(!is(typeof(NJS_LVLHSH_ENTRY_SIZE))) {
        private enum enumMixinStr_NJS_LVLHSH_ENTRY_SIZE = `enum NJS_LVLHSH_ENTRY_SIZE = 3;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_LVLHSH_ENTRY_SIZE); }))) {
            mixin(enumMixinStr_NJS_LVLHSH_ENTRY_SIZE);
        }
    }




    static if(!is(typeof(NJS_LVLHSH_DEFAULT_BUCKET_SIZE))) {
        private enum enumMixinStr_NJS_LVLHSH_DEFAULT_BUCKET_SIZE = `enum NJS_LVLHSH_DEFAULT_BUCKET_SIZE = 128;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_LVLHSH_DEFAULT_BUCKET_SIZE); }))) {
            mixin(enumMixinStr_NJS_LVLHSH_DEFAULT_BUCKET_SIZE);
        }
    }






    static if(!is(typeof(NJS_TOKEN_LAST_CONST))) {
        private enum enumMixinStr_NJS_TOKEN_LAST_CONST = `enum NJS_TOKEN_LAST_CONST = NJS_TOKEN_STRING;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TOKEN_LAST_CONST); }))) {
            mixin(enumMixinStr_NJS_TOKEN_LAST_CONST);
        }
    }




    static if(!is(typeof(NJS_TOKEN_FIRST_CONST))) {
        private enum enumMixinStr_NJS_TOKEN_FIRST_CONST = `enum NJS_TOKEN_FIRST_CONST = NJS_TOKEN_NULL;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TOKEN_FIRST_CONST); }))) {
            mixin(enumMixinStr_NJS_TOKEN_FIRST_CONST);
        }
    }




    static if(!is(typeof(NJS_TOKEN_LAST_ASSIGNMENT))) {
        private enum enumMixinStr_NJS_TOKEN_LAST_ASSIGNMENT = `enum NJS_TOKEN_LAST_ASSIGNMENT = NJS_TOKEN_POST_DECREMENT;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TOKEN_LAST_ASSIGNMENT); }))) {
            mixin(enumMixinStr_NJS_TOKEN_LAST_ASSIGNMENT);
        }
    }
    static if(!is(typeof(NJS_FRAME_SPARE_SIZE))) {
        private enum enumMixinStr_NJS_FRAME_SPARE_SIZE = `enum NJS_FRAME_SPARE_SIZE = ( 4 * 1024 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_FRAME_SPARE_SIZE); }))) {
            mixin(enumMixinStr_NJS_FRAME_SPARE_SIZE);
        }
    }




    static if(!is(typeof(NJS_FRAME_SIZE))) {
        private enum enumMixinStr_NJS_FRAME_SIZE = `enum NJS_FRAME_SIZE = njs_align_size ( ( njs_frame_t ) .sizeof , ( njs_value_t ) .sizeof );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_FRAME_SIZE); }))) {
            mixin(enumMixinStr_NJS_FRAME_SIZE);
        }
    }




    static if(!is(typeof(NJS_NATIVE_FRAME_SIZE))) {
        private enum enumMixinStr_NJS_NATIVE_FRAME_SIZE = `enum NJS_NATIVE_FRAME_SIZE = njs_align_size ( ( njs_native_frame_t ) .sizeof , ( njs_value_t ) .sizeof );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_NATIVE_FRAME_SIZE); }))) {
            mixin(enumMixinStr_NJS_NATIVE_FRAME_SIZE);
        }
    }
    static if(!is(typeof(NJS_EVENT_DELETE))) {
        private enum enumMixinStr_NJS_EVENT_DELETE = `enum NJS_EVENT_DELETE = 2;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_EVENT_DELETE); }))) {
            mixin(enumMixinStr_NJS_EVENT_DELETE);
        }
    }




    static if(!is(typeof(NJS_EVENT_RELEASE))) {
        private enum enumMixinStr_NJS_EVENT_RELEASE = `enum NJS_EVENT_RELEASE = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_EVENT_RELEASE); }))) {
            mixin(enumMixinStr_NJS_EVENT_RELEASE);
        }
    }
    static if(!is(typeof(NJS_DJB_HASH_INIT))) {
        private enum enumMixinStr_NJS_DJB_HASH_INIT = `enum NJS_DJB_HASH_INIT = 5381;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DJB_HASH_INIT); }))) {
            mixin(enumMixinStr_NJS_DJB_HASH_INIT);
        }
    }






    static if(!is(typeof(NJS_DECIMAL_EXPONENT_DIST))) {
        private enum enumMixinStr_NJS_DECIMAL_EXPONENT_DIST = `enum NJS_DECIMAL_EXPONENT_DIST = 8;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DECIMAL_EXPONENT_DIST); }))) {
            mixin(enumMixinStr_NJS_DECIMAL_EXPONENT_DIST);
        }
    }




    static if(!is(typeof(NJS_DECIMAL_EXPONENT_MAX))) {
        private enum enumMixinStr_NJS_DECIMAL_EXPONENT_MAX = `enum NJS_DECIMAL_EXPONENT_MAX = 340;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DECIMAL_EXPONENT_MAX); }))) {
            mixin(enumMixinStr_NJS_DECIMAL_EXPONENT_MAX);
        }
    }




    static if(!is(typeof(NJS_DECIMAL_EXPONENT_MIN))) {
        private enum enumMixinStr_NJS_DECIMAL_EXPONENT_MIN = `enum NJS_DECIMAL_EXPONENT_MIN = ( - 348 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DECIMAL_EXPONENT_MIN); }))) {
            mixin(enumMixinStr_NJS_DECIMAL_EXPONENT_MIN);
        }
    }




    static if(!is(typeof(NJS_DECIMAL_EXPONENT_OFF))) {
        private enum enumMixinStr_NJS_DECIMAL_EXPONENT_OFF = `enum NJS_DECIMAL_EXPONENT_OFF = 348;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DECIMAL_EXPONENT_OFF); }))) {
            mixin(enumMixinStr_NJS_DECIMAL_EXPONENT_OFF);
        }
    }




    static if(!is(typeof(NJS_SIGNIFICAND_SHIFT))) {
        private enum enumMixinStr_NJS_SIGNIFICAND_SHIFT = `enum NJS_SIGNIFICAND_SHIFT = ( NJS_DIYFP_SIGNIFICAND_SIZE - NJS_DBL_SIGNIFICAND_SIZE );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SIGNIFICAND_SHIFT); }))) {
            mixin(enumMixinStr_NJS_SIGNIFICAND_SHIFT);
        }
    }




    static if(!is(typeof(NJS_SIGNIFICAND_SIZE))) {
        private enum enumMixinStr_NJS_SIGNIFICAND_SIZE = `enum NJS_SIGNIFICAND_SIZE = 53;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SIGNIFICAND_SIZE); }))) {
            mixin(enumMixinStr_NJS_SIGNIFICAND_SIZE);
        }
    }




    static if(!is(typeof(NJS_DIYFP_SIGNIFICAND_SIZE))) {
        private enum enumMixinStr_NJS_DIYFP_SIGNIFICAND_SIZE = `enum NJS_DIYFP_SIGNIFICAND_SIZE = 64;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DIYFP_SIGNIFICAND_SIZE); }))) {
            mixin(enumMixinStr_NJS_DIYFP_SIGNIFICAND_SIZE);
        }
    }




    static if(!is(typeof(NJS_DBL_SIGN_MASK))) {
        private enum enumMixinStr_NJS_DBL_SIGN_MASK = `enum NJS_DBL_SIGN_MASK = njs_uint64 ( 0x80000000 , 0x00000000 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_SIGN_MASK); }))) {
            mixin(enumMixinStr_NJS_DBL_SIGN_MASK);
        }
    }




    static if(!is(typeof(NJS_DBL_EXPONENT_MASK))) {
        private enum enumMixinStr_NJS_DBL_EXPONENT_MASK = `enum NJS_DBL_EXPONENT_MASK = njs_uint64 ( 0x7FF00000 , 0x00000000 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_EXPONENT_MASK); }))) {
            mixin(enumMixinStr_NJS_DBL_EXPONENT_MASK);
        }
    }




    static if(!is(typeof(NJS_DBL_HIDDEN_BIT))) {
        private enum enumMixinStr_NJS_DBL_HIDDEN_BIT = `enum NJS_DBL_HIDDEN_BIT = njs_uint64 ( 0x00100000 , 0x00000000 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_HIDDEN_BIT); }))) {
            mixin(enumMixinStr_NJS_DBL_HIDDEN_BIT);
        }
    }




    static if(!is(typeof(NJS_DBL_SIGNIFICAND_MASK))) {
        private enum enumMixinStr_NJS_DBL_SIGNIFICAND_MASK = `enum NJS_DBL_SIGNIFICAND_MASK = njs_uint64 ( 0x000FFFFF , 0xFFFFFFFF );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_SIGNIFICAND_MASK); }))) {
            mixin(enumMixinStr_NJS_DBL_SIGNIFICAND_MASK);
        }
    }




    static if(!is(typeof(NJS_DBL_EXPONENT_DENORMAL))) {
        private enum enumMixinStr_NJS_DBL_EXPONENT_DENORMAL = `enum NJS_DBL_EXPONENT_DENORMAL = ( - NJS_DBL_EXPONENT_BIAS + 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_EXPONENT_DENORMAL); }))) {
            mixin(enumMixinStr_NJS_DBL_EXPONENT_DENORMAL);
        }
    }




    static if(!is(typeof(NJS_DBL_EXPONENT_MAX))) {
        private enum enumMixinStr_NJS_DBL_EXPONENT_MAX = `enum NJS_DBL_EXPONENT_MAX = ( 0x7ff - NJS_DBL_EXPONENT_BIAS );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_EXPONENT_MAX); }))) {
            mixin(enumMixinStr_NJS_DBL_EXPONENT_MAX);
        }
    }




    static if(!is(typeof(NJS_DBL_EXPONENT_MIN))) {
        private enum enumMixinStr_NJS_DBL_EXPONENT_MIN = `enum NJS_DBL_EXPONENT_MIN = ( - NJS_DBL_EXPONENT_BIAS );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_EXPONENT_MIN); }))) {
            mixin(enumMixinStr_NJS_DBL_EXPONENT_MIN);
        }
    }




    static if(!is(typeof(NJS_DBL_EXPONENT_BIAS))) {
        private enum enumMixinStr_NJS_DBL_EXPONENT_BIAS = `enum NJS_DBL_EXPONENT_BIAS = ( NJS_DBL_EXPONENT_OFFSET + NJS_DBL_SIGNIFICAND_SIZE );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_EXPONENT_BIAS); }))) {
            mixin(enumMixinStr_NJS_DBL_EXPONENT_BIAS);
        }
    }




    static if(!is(typeof(NJS_DBL_EXPONENT_OFFSET))) {
        private enum enumMixinStr_NJS_DBL_EXPONENT_OFFSET = `enum NJS_DBL_EXPONENT_OFFSET = ( ( int64_t ) 0x3ff );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_EXPONENT_OFFSET); }))) {
            mixin(enumMixinStr_NJS_DBL_EXPONENT_OFFSET);
        }
    }




    static if(!is(typeof(NJS_DBL_SIGNIFICAND_SIZE))) {
        private enum enumMixinStr_NJS_DBL_SIGNIFICAND_SIZE = `enum NJS_DBL_SIGNIFICAND_SIZE = 52;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_DBL_SIGNIFICAND_SIZE); }))) {
            mixin(enumMixinStr_NJS_DBL_SIGNIFICAND_SIZE);
        }
    }
    static if(!is(typeof(NJS_MAX_ALIGNMENT))) {
        private enum enumMixinStr_NJS_MAX_ALIGNMENT = `enum NJS_MAX_ALIGNMENT = 16;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MAX_ALIGNMENT); }))) {
            mixin(enumMixinStr_NJS_MAX_ALIGNMENT);
        }
    }






    static if(!is(typeof(NJS_MM_DENORMALS_MASK))) {
        private enum enumMixinStr_NJS_MM_DENORMALS_MASK = `enum NJS_MM_DENORMALS_MASK = 0x8040;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MM_DENORMALS_MASK); }))) {
            mixin(enumMixinStr_NJS_MM_DENORMALS_MASK);
        }
    }
    static if(!is(typeof(NJS_MALLOC_LIKE))) {
        private enum enumMixinStr_NJS_MALLOC_LIKE = `enum NJS_MALLOC_LIKE = __attribute__ ( ( __malloc__ ) );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_MALLOC_LIKE); }))) {
            mixin(enumMixinStr_NJS_MALLOC_LIKE);
        }
    }




    static if(!is(typeof(NJS_PACKED))) {
        private enum enumMixinStr_NJS_PACKED = `enum NJS_PACKED = __attribute__ ( ( packed ) );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PACKED); }))) {
            mixin(enumMixinStr_NJS_PACKED);
        }
    }






    static if(!is(typeof(NJS_EXPORT))) {
        private enum enumMixinStr_NJS_EXPORT = `enum NJS_EXPORT = __attribute__ ( ( visibility ( "default" ) ) );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_EXPORT); }))) {
            mixin(enumMixinStr_NJS_EXPORT);
        }
    }
    static if(!is(typeof(njs_noinline))) {
        private enum enumMixinStr_njs_noinline = `enum njs_noinline = __attribute__ ( ( noinline ) );`;
        static if(is(typeof({ mixin(enumMixinStr_njs_noinline); }))) {
            mixin(enumMixinStr_njs_noinline);
        }
    }




    static if(!is(typeof(njs_inline))) {
        private enum enumMixinStr_njs_inline = `enum njs_inline = static inline __attribute__ ( ( always_inline ) );`;
        static if(is(typeof({ mixin(enumMixinStr_njs_inline); }))) {
            mixin(enumMixinStr_njs_inline);
        }
    }
    static if(!is(typeof(NJS_PCRE2_VERSION))) {
        private enum enumMixinStr_NJS_PCRE2_VERSION = `enum NJS_PCRE2_VERSION = 10.34;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PCRE2_VERSION); }))) {
            mixin(enumMixinStr_NJS_PCRE2_VERSION);
        }
    }




    static if(!is(typeof(NJS_HAVE_PCRE2))) {
        private enum enumMixinStr_NJS_HAVE_PCRE2 = `enum NJS_HAVE_PCRE2 = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_PCRE2); }))) {
            mixin(enumMixinStr_NJS_HAVE_PCRE2);
        }
    }




    static if(!is(typeof(NJS_HAVE_EXPLICIT_BZERO))) {
        private enum enumMixinStr_NJS_HAVE_EXPLICIT_BZERO = `enum NJS_HAVE_EXPLICIT_BZERO = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_EXPLICIT_BZERO); }))) {
            mixin(enumMixinStr_NJS_HAVE_EXPLICIT_BZERO);
        }
    }




    static if(!is(typeof(NJS_HAVE_STAT_ATIM))) {
        private enum enumMixinStr_NJS_HAVE_STAT_ATIM = `enum NJS_HAVE_STAT_ATIM = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_STAT_ATIM); }))) {
            mixin(enumMixinStr_NJS_HAVE_STAT_ATIM);
        }
    }




    static if(!is(typeof(NJS_HAVE_GETRANDOM))) {
        private enum enumMixinStr_NJS_HAVE_GETRANDOM = `enum NJS_HAVE_GETRANDOM = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_GETRANDOM); }))) {
            mixin(enumMixinStr_NJS_HAVE_GETRANDOM);
        }
    }




    static if(!is(typeof(NJS_HAVE_POSIX_MEMALIGN))) {
        private enum enumMixinStr_NJS_HAVE_POSIX_MEMALIGN = `enum NJS_HAVE_POSIX_MEMALIGN = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_POSIX_MEMALIGN); }))) {
            mixin(enumMixinStr_NJS_HAVE_POSIX_MEMALIGN);
        }
    }




    static if(!is(typeof(NJS_HAVE_TM_GMTOFF))) {
        private enum enumMixinStr_NJS_HAVE_TM_GMTOFF = `enum NJS_HAVE_TM_GMTOFF = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_TM_GMTOFF); }))) {
            mixin(enumMixinStr_NJS_HAVE_TM_GMTOFF);
        }
    }




    static if(!is(typeof(NJS_HAVE_CLOCK_MONOTONIC))) {
        private enum enumMixinStr_NJS_HAVE_CLOCK_MONOTONIC = `enum NJS_HAVE_CLOCK_MONOTONIC = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_CLOCK_MONOTONIC); }))) {
            mixin(enumMixinStr_NJS_HAVE_CLOCK_MONOTONIC);
        }
    }




    static if(!is(typeof(NJS_HAVE_DENORMALS_CONTROL))) {
        private enum enumMixinStr_NJS_HAVE_DENORMALS_CONTROL = `enum NJS_HAVE_DENORMALS_CONTROL = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_DENORMALS_CONTROL); }))) {
            mixin(enumMixinStr_NJS_HAVE_DENORMALS_CONTROL);
        }
    }




    static if(!is(typeof(NJS_HAVE_GCC_ATTRIBUTE_PACKED))) {
        private enum enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_PACKED = `enum NJS_HAVE_GCC_ATTRIBUTE_PACKED = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_PACKED); }))) {
            mixin(enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_PACKED);
        }
    }




    static if(!is(typeof(NJS_HAVE_GCC_ATTRIBUTE_ALIGNED))) {
        private enum enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_ALIGNED = `enum NJS_HAVE_GCC_ATTRIBUTE_ALIGNED = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_ALIGNED); }))) {
            mixin(enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_ALIGNED);
        }
    }




    static if(!is(typeof(NJS_HAVE_GCC_ATTRIBUTE_MALLOC))) {
        private enum enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_MALLOC = `enum NJS_HAVE_GCC_ATTRIBUTE_MALLOC = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_MALLOC); }))) {
            mixin(enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_MALLOC);
        }
    }




    static if(!is(typeof(NJS_HAVE_GCC_ATTRIBUTE_VISIBILITY))) {
        private enum enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_VISIBILITY = `enum NJS_HAVE_GCC_ATTRIBUTE_VISIBILITY = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_VISIBILITY); }))) {
            mixin(enumMixinStr_NJS_HAVE_GCC_ATTRIBUTE_VISIBILITY);
        }
    }




    static if(!is(typeof(NJS_HAVE_BUILTIN_CLZLL))) {
        private enum enumMixinStr_NJS_HAVE_BUILTIN_CLZLL = `enum NJS_HAVE_BUILTIN_CLZLL = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_BUILTIN_CLZLL); }))) {
            mixin(enumMixinStr_NJS_HAVE_BUILTIN_CLZLL);
        }
    }




    static if(!is(typeof(NJS_HAVE_BUILTIN_CLZ))) {
        private enum enumMixinStr_NJS_HAVE_BUILTIN_CLZ = `enum NJS_HAVE_BUILTIN_CLZ = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_BUILTIN_CLZ); }))) {
            mixin(enumMixinStr_NJS_HAVE_BUILTIN_CLZ);
        }
    }




    static if(!is(typeof(NJS_HAVE_BUILTIN_PREFETCH))) {
        private enum enumMixinStr_NJS_HAVE_BUILTIN_PREFETCH = `enum NJS_HAVE_BUILTIN_PREFETCH = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_BUILTIN_PREFETCH); }))) {
            mixin(enumMixinStr_NJS_HAVE_BUILTIN_PREFETCH);
        }
    }




    static if(!is(typeof(NJS_HAVE_BUILTIN_UNREACHABLE))) {
        private enum enumMixinStr_NJS_HAVE_BUILTIN_UNREACHABLE = `enum NJS_HAVE_BUILTIN_UNREACHABLE = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_BUILTIN_UNREACHABLE); }))) {
            mixin(enumMixinStr_NJS_HAVE_BUILTIN_UNREACHABLE);
        }
    }




    static if(!is(typeof(NJS_HAVE_BUILTIN_EXPECT))) {
        private enum enumMixinStr_NJS_HAVE_BUILTIN_EXPECT = `enum NJS_HAVE_BUILTIN_EXPECT = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_BUILTIN_EXPECT); }))) {
            mixin(enumMixinStr_NJS_HAVE_BUILTIN_EXPECT);
        }
    }




    static if(!is(typeof(NJS_HAVE_UNSIGNED_INT128))) {
        private enum enumMixinStr_NJS_HAVE_UNSIGNED_INT128 = `enum NJS_HAVE_UNSIGNED_INT128 = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_UNSIGNED_INT128); }))) {
            mixin(enumMixinStr_NJS_HAVE_UNSIGNED_INT128);
        }
    }




    static if(!is(typeof(NJS_HAVE_LITTLE_ENDIAN))) {
        private enum enumMixinStr_NJS_HAVE_LITTLE_ENDIAN = `enum NJS_HAVE_LITTLE_ENDIAN = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_HAVE_LITTLE_ENDIAN); }))) {
            mixin(enumMixinStr_NJS_HAVE_LITTLE_ENDIAN);
        }
    }




    static if(!is(typeof(NJS_BYTE_ORDER))) {
        private enum enumMixinStr_NJS_BYTE_ORDER = `enum NJS_BYTE_ORDER = little;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_BYTE_ORDER); }))) {
            mixin(enumMixinStr_NJS_BYTE_ORDER);
        }
    }




    static if(!is(typeof(NJS_TIME_T_SIZE))) {
        private enum enumMixinStr_NJS_TIME_T_SIZE = `enum NJS_TIME_T_SIZE = 8;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_TIME_T_SIZE); }))) {
            mixin(enumMixinStr_NJS_TIME_T_SIZE);
        }
    }




    static if(!is(typeof(NJS_OFF_T_SIZE))) {
        private enum enumMixinStr_NJS_OFF_T_SIZE = `enum NJS_OFF_T_SIZE = 8;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_OFF_T_SIZE); }))) {
            mixin(enumMixinStr_NJS_OFF_T_SIZE);
        }
    }




    static if(!is(typeof(NJS_SIZE_T_SIZE))) {
        private enum enumMixinStr_NJS_SIZE_T_SIZE = `enum NJS_SIZE_T_SIZE = 8;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_SIZE_T_SIZE); }))) {
            mixin(enumMixinStr_NJS_SIZE_T_SIZE);
        }
    }




    static if(!is(typeof(NJS_UINTPTR_T_SIZE))) {
        private enum enumMixinStr_NJS_UINTPTR_T_SIZE = `enum NJS_UINTPTR_T_SIZE = 8;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_UINTPTR_T_SIZE); }))) {
            mixin(enumMixinStr_NJS_UINTPTR_T_SIZE);
        }
    }




    static if(!is(typeof(NJS_UINT_SIZE))) {
        private enum enumMixinStr_NJS_UINT_SIZE = `enum NJS_UINT_SIZE = 4;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_UINT_SIZE); }))) {
            mixin(enumMixinStr_NJS_UINT_SIZE);
        }
    }




    static if(!is(typeof(NJS_INT_SIZE))) {
        private enum enumMixinStr_NJS_INT_SIZE = `enum NJS_INT_SIZE = 4;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_INT_SIZE); }))) {
            mixin(enumMixinStr_NJS_INT_SIZE);
        }
    }




    static if(!is(typeof(NJS_GCC))) {
        private enum enumMixinStr_NJS_GCC = `enum NJS_GCC = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_GCC); }))) {
            mixin(enumMixinStr_NJS_GCC);
        }
    }




    static if(!is(typeof(NJS_LINUX))) {
        private enum enumMixinStr_NJS_LINUX = `enum NJS_LINUX = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_LINUX); }))) {
            mixin(enumMixinStr_NJS_LINUX);
        }
    }
    static if(!is(typeof(NJS_ARRAY_FLAT_MAX_LENGTH))) {
        private enum enumMixinStr_NJS_ARRAY_FLAT_MAX_LENGTH = `enum NJS_ARRAY_FLAT_MAX_LENGTH = ( 1048576 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ARRAY_FLAT_MAX_LENGTH); }))) {
            mixin(enumMixinStr_NJS_ARRAY_FLAT_MAX_LENGTH);
        }
    }




    static if(!is(typeof(NJS_ARRAY_LARGE_OBJECT_LENGTH))) {
        private enum enumMixinStr_NJS_ARRAY_LARGE_OBJECT_LENGTH = `enum NJS_ARRAY_LARGE_OBJECT_LENGTH = ( 32768 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ARRAY_LARGE_OBJECT_LENGTH); }))) {
            mixin(enumMixinStr_NJS_ARRAY_LARGE_OBJECT_LENGTH);
        }
    }




    static if(!is(typeof(NJS_ARRAY_FAST_OBJECT_LENGTH))) {
        private enum enumMixinStr_NJS_ARRAY_FAST_OBJECT_LENGTH = `enum NJS_ARRAY_FAST_OBJECT_LENGTH = ( 1024 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ARRAY_FAST_OBJECT_LENGTH); }))) {
            mixin(enumMixinStr_NJS_ARRAY_FAST_OBJECT_LENGTH);
        }
    }




    static if(!is(typeof(NJS_ARRAY_SPARE))) {
        private enum enumMixinStr_NJS_ARRAY_SPARE = `enum NJS_ARRAY_SPARE = 8;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ARRAY_SPARE); }))) {
            mixin(enumMixinStr_NJS_ARRAY_SPARE);
        }
    }




    static if(!is(typeof(NJS_ARRAY_INVALID_INDEX))) {
        private enum enumMixinStr_NJS_ARRAY_INVALID_INDEX = `enum NJS_ARRAY_INVALID_INDEX = NJS_ARRAY_MAX_INDEX;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ARRAY_INVALID_INDEX); }))) {
            mixin(enumMixinStr_NJS_ARRAY_INVALID_INDEX);
        }
    }




    static if(!is(typeof(NJS_ARRAY_MAX_INDEX))) {
        private enum enumMixinStr_NJS_ARRAY_MAX_INDEX = `enum NJS_ARRAY_MAX_INDEX = 0xffffffff;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_ARRAY_MAX_INDEX); }))) {
            mixin(enumMixinStr_NJS_ARRAY_MAX_INDEX);
        }
    }
    static if(!is(typeof(NJS_PROTO_ID_ANY))) {
        private enum enumMixinStr_NJS_PROTO_ID_ANY = `enum NJS_PROTO_ID_ANY = ( - 1 );`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_PROTO_ID_ANY); }))) {
            mixin(enumMixinStr_NJS_PROTO_ID_ANY);
        }
    }
    static if(!is(typeof(NJS_VM_OPT_UNHANDLED_REJECTION_THROW))) {
        private enum enumMixinStr_NJS_VM_OPT_UNHANDLED_REJECTION_THROW = `enum NJS_VM_OPT_UNHANDLED_REJECTION_THROW = 1;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_VM_OPT_UNHANDLED_REJECTION_THROW); }))) {
            mixin(enumMixinStr_NJS_VM_OPT_UNHANDLED_REJECTION_THROW);
        }
    }




    static if(!is(typeof(NJS_VM_OPT_UNHANDLED_REJECTION_IGNORE))) {
        private enum enumMixinStr_NJS_VM_OPT_UNHANDLED_REJECTION_IGNORE = `enum NJS_VM_OPT_UNHANDLED_REJECTION_IGNORE = 0;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_VM_OPT_UNHANDLED_REJECTION_IGNORE); }))) {
            mixin(enumMixinStr_NJS_VM_OPT_UNHANDLED_REJECTION_IGNORE);
        }
    }
    static if(!is(typeof(NJS_VERSION_NUMBER))) {
        private enum enumMixinStr_NJS_VERSION_NUMBER = `enum NJS_VERSION_NUMBER = 0x000708;`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_VERSION_NUMBER); }))) {
            mixin(enumMixinStr_NJS_VERSION_NUMBER);
        }
    }




    static if(!is(typeof(NJS_VERSION))) {
        private enum enumMixinStr_NJS_VERSION = `enum NJS_VERSION = "0.7.8";`;
        static if(is(typeof({ mixin(enumMixinStr_NJS_VERSION); }))) {
            mixin(enumMixinStr_NJS_VERSION);
        }
    }



}


/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */

import shaft.evaluator.engine.interface_ : JSEngine;
import shaft.exception : ExpressionFailed, FeatureUnsupported;
import dyaml : Node;
import shaft.runtime : Runtime;


//
// workaround for dpp
//
private alias u_char = ubyte;

///
class EmbeddedNJSEngine : JSEngine
{
    this() @trusted
    {
        import std.exception : enforce;
        import std.string : toStringz;

        njs_vm_opt_t vm_options;

        njs_vm_opt_init(&vm_options);

        enum Mode
        {
            command = "string",
            shell = "shell",
        }
        auto mode = Mode.command;

        vm_options.file.start = cast(u_char*)mode.toStringz;
        vm_options.file.length = mode.length;

        vm_options.init = 1;
        vm_options.interactive = 0;
        vm_options.backtrace = 1;
        vm_options.quiet = 0;
        vm_options.sandbox = 1;
        vm_options.unhandled_rejection = 0;

        vm = enforce!FeatureUnsupported(
            njs_vm_create(&vm_options),
            "Failed to initialize JavaScript engine"
        );

        vm.eval_(
            q"EOS
            "use strict";
            this.global = {};
            delete this.global;
            delete this.njs;
            delete this.process;
            if ("$262" in this)
            {
                delete this["$262"];
            }
EOS"
        );
    }

    ~this() @trusted
    {
        njs_vm_destroy(vm);
    }

    override string evaluate(scope string exp, Node inputs, Runtime runtime, Node self, in string[] libs)
    in(exp.length != 0)
    {
        import std : enforce, toStringz, format;

        auto to(T: string)(njs_str_t chars)
        {
            import std.conv : castFrom;
            return castFrom!(u_char[]).to!string(chars.start[0..chars.length]);
        }

        auto code = toJSCode(exp, inputs, runtime, self, libs);
        return vm.eval_(code);
    }

private:
    string toJSCode(string exp, Node inputs, Runtime runtime, Node self,
        in string[] libs) const
    {
        import shaft.type.common : toJSON;
        import std.array : join;
        import std.format : format;
        import std.range : chain;

        auto expBody = exp[1] == '('
            ? format!"(function() { return %s; })()"(exp[1..$])
            : format!"(function() { %s; })()"(exp[2..$-1]);
        auto toBeEvaled = chain(libs, [expBody]).join(";\n");

        return format!q"EOS
            (function() {
                var globalThis = {};
                try
                {
                    var runtime = %s;
                    var inputs = %s;
                    var self = %s;
                    return JSON.stringify(%s);
                }
                catch(e)
                {
                    return JSON.stringify({ 'class': 'exception', 'message': `${e.name}: ${e.message}`});
                }
            })();
EOS"(Node(runtime).toJSON, inputs.toJSON, self.toJSON, toBeEvaled);
    }

    njs_vm_t* vm;
}

private:

auto eval_(scope njs_vm_t* vm, scope string code)
{
    import std.exception : enforce;
    import std.format : format;
    import std.string : toStringz;

    auto to(T: string)(njs_str_t chars)
    {
        import std.conv : castFrom;
        return castFrom!(u_char[]).to!string(chars.start[0..chars.length]);
    }
    auto ccode = code.toStringz;

    auto start = cast(u_char*)(ccode);
    auto end = cast(u_char*)(ccode+code.length);
    auto ret1 = njs_vm_compile(vm, &start, end);

    enforce(ret1 == 0,
    {
        njs_str_t msg;
        njs_vm_retval_string(vm, &msg);
        throw new ExpressionFailed(format!"%s in the expression `%s`"(to!string(msg), code));
    });
    assert(start is end);
    auto ret2 = njs_vm_start(vm);
    enforce(ret2 == 0,
    {
        njs_str_t msg;
        njs_vm_retval_string(vm, &msg);
        throw new ExpressionFailed(format!"%s in the expression `%s`"(to!string(msg), code));
    });

    njs_str_t result;

    enforce!ExpressionFailed(
        njs_vm_value_dump(vm, &result, &vm.retval, 1, 1) == 0,
        "Failed to get return value from JavaScript engine"
    );
    return to!string(result);
}
