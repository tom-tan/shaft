/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 * See_Also: https://github.com/common-workflow-language/common-workflow-language/issues/915
 */
module shaft.exception;

import dyaml : Mark;

import std.exception : basicExceptionCtors;

abstract class ShaftException : Exception
{
    mixin basicExceptionCtors;

    int code() const @nogc nothrow pure @safe;
}

///
class TypeException : Exception
{
    mixin basicExceptionCtors;
}

/// There is an unsupported feature in the workflow
class FeatureUnsupported : ShaftException
{
    mixin basicExceptionCtors;

    override int code() const @nogc nothrow pure @safe
    {
        return 33;
    }
}

/// 
class NotYetImplemented : ShaftException
{
    mixin basicExceptionCtors;

    override int code() const @nogc nothrow pure @safe
    {
        return 33;
    }
}

/// User used Ctrl + C to interupt the workflow
class Interrupted : ShaftException
{
    mixin basicExceptionCtors;

    override int code() const @nogc nothrow pure @safe
    {
        return 130;
    }
}

/// The workflow input/output cannot be found
class InputFileNotFound : ShaftException
{
    mixin basicExceptionCtors;

    override int code() const @nogc nothrow pure @safe
    {
        return 250;
    }
}

/// The workflow input/output cannot be found
class OutputFileNotFound : ShaftException
{
    mixin basicExceptionCtors;

    override int code() const @nogc nothrow pure @safe
    {
        return 250;
    }
}

/// Fail to parse workflow
class InvalidDocument : ShaftException
{
    this(string msg, Mark mark, Throwable nextInChain = null) nothrow pure @trusted
    {
        super(msg, mark.name, mark.line+1, nextInChain);
        column = mark.column+1;
        this.mark = mark;
    }

    size_t column;
    Mark mark;

    override int code() const @nogc nothrow pure @safe
    {
        return 251;
    }
}

/// Fail to load workflow inputs
class InputCannotBeLoaded : ShaftException
{
    this(string msg, Mark mark, Throwable nextInChain = null) nothrow pure @trusted
    {
        super(msg, mark.name, mark.line+1, nextInChain);
        column = mark.column+1;
        this.mark = mark;
    }

    size_t column;
    Mark mark;

    override int code() const @nogc nothrow pure @safe
    {
        return 252;
    }
}

/// Fail to evaluate the expression in workflow
class ExpressionFailed : ShaftException
{
    mixin basicExceptionCtors;

    override int code() const @nogc nothrow pure @safe
    {
        return 253;
    }
}

/// Fail to capture the workflow/step output after the workflow/step is done
class CaptureFailed : ShaftException
{
    mixin basicExceptionCtors;

    override int code() const @nogc nothrow pure @safe
    {
        return 254;
    }
}

/// System exception. For example, command arguments are wrong; the CWL workflow description file cannot be found; bsub/bwait command cannot be found
class SystemException : ShaftException
{
    mixin basicExceptionCtors;

    override int code() const @nogc nothrow pure @safe
    {
        return 255;
    }
}
