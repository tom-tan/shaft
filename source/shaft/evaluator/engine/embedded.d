/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.evaluator.engine.embedded;

import shaft.evaluator.engine.interface_ : JSEngine;
import shaft.exception : ExpressionFailed, FeatureUnsupported;
import dyaml : Node;
import shaft.runtime : Runtime;

import njs_d : njs_vm_t;

///
class EmbeddedNJSEngine : JSEngine
{
    this() @trusted
    {
        import njs_d : njs_vm_destroy;

        vm = create_vm();
        scope(failure) njs_vm_destroy(vm);

        vm.eval(
            q"EOS
            "use strict";
            this.global = {};
            delete this.global;
            delete this.njs;
            delete this.process;
EOS"
        );
    }

    ~this() @trusted
    {
        import njs_d : njs_vm_destroy;
        njs_vm_destroy(vm);
    }

    override string evaluate(scope string exp, Node inputs, Runtime runtime, Node self, in string[] libs)
    in(exp.length != 0)
    {
        import std : enforce, toStringz, format;

        auto to(T: string)(njs_str_t chars)
        {
            import std.conv : castFrom;
            import njs_d : u_char;
            return castFrom!(u_char[]).to!string(chars.start[0..chars.length]);
        }

        auto code = toJSCode(exp, inputs, runtime, self, libs);
        return vm.eval(code);
    }

private:
    string toJSCode(string exp, Node inputs, Runtime runtime, Node self,
        in string[] libs) const
    {
        import shaft.type.common : toJSONString;
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
                    return %s;
                }
                catch(e)
                {
                    return { 'class': 'exception', 'message': `${e.name}: ${e.message}`};
                }
            })();
EOS"(Node(runtime).toJSONString, inputs.toJSONString, self.toJSONString, toBeEvaled);
    }

    njs_vm_t* vm;
}

private:

auto create_vm()
{
        import std.exception : enforce;
        import std.string : toStringz;

        import njs_d : njs_vm_create, njs_vm_opt_init, njs_vm_opt_t, u_char;

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

        return enforce!FeatureUnsupported(
            njs_vm_create(&vm_options),
            "Failed to initialize JavaScript engine"
        );
}

auto eval(scope njs_vm_t* vm, scope string code)
{
    import std.exception : enforce;
    import std.format : format;
    import std.string : toStringz;

    import njs_d : NJS_OK, njs_vm_compile, njs_vm_exception_string, njs_str_t,
        njs_value_t, njs_vm_start, njs_vm_value_dump, u_char;

    auto to(T: string)(njs_str_t chars)
    {
        import std.conv : castFrom;
        return castFrom!(u_char[]).to!string(chars.start[0..chars.length]);
    }
    auto ccode = code.toStringz;

    auto start = cast(u_char*)(ccode);
    auto end = cast(u_char*)(ccode+code.length);
    auto ret1 = njs_vm_compile(vm, &start, end);

    enforce(ret1 == NJS_OK && start is end,
    {
        njs_str_t msg;
        njs_vm_exception_string(vm, &msg);
        throw new ExpressionFailed(format!"%s in the expression `%s`"(to!string(msg), code));
    });

    njs_value_t retval;
    auto ret2 = njs_vm_start(vm, &retval);
    enforce(ret2 == NJS_OK,
    {
        njs_str_t msg;
        njs_vm_exception_string(vm, &msg);
        throw new ExpressionFailed(format!"%s in the expression `%s`"(to!string(msg), code));
    });

    njs_str_t result;
    
    enforce!ExpressionFailed(
        njs_vm_value_dump(vm, &result, &retval, 0, 1) == NJS_OK,
        "Failed to get return value from JavaScript engine"
    );
    return to!string(result);
}

unittest
{
    auto vm = create_vm();
    auto ret = vm.eval("1+1");
    assert(ret == "2");
}

unittest
{
    auto vm = create_vm();
    auto ret = vm.eval("'foo'+'bar'");
    assert(ret == "'foobar'");
}
