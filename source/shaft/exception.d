/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 * See_Also: https://github.com/common-workflow-language/common-workflow-language/issues/915
 */
module shaft.exception;

import dyaml : Mark;

import std.exception : basicExceptionCtors;

///
class TypeException : Exception
{
    mixin basicExceptionCtors;
}

/// There is an unsupported feature in the workflow
class FeatureUnsupported : Exception
{
    mixin basicExceptionCtors;
}

/// 
class NotYetImplemented : Exception
{
    mixin basicExceptionCtors;
}

/// User used Ctrl + C to interupt the workflow
class Interrupted : Exception
{
    mixin basicExceptionCtors;
}

/// The workflow input/output cannot be found
class InputFileNotFound : Exception
{
    mixin basicExceptionCtors;
}

/// The workflow input/output cannot be found
class OutputFileNotFound : Exception
{
    mixin basicExceptionCtors;
}

/// Fail to parse workflow
class InvalidDocument : Exception
{
    this(string msg, Mark mark, Throwable nextInChain = null) nothrow pure @trusted
    {
        super(msg, mark.name, mark.line+1, nextInChain);
        column = mark.column+1;
        this.mark = mark;
    }

    size_t column;
    Mark mark;
}

/// Fail to load workflow inputs
class InputCannotBeLoaded : Exception
{
    this(string msg, Mark mark, Throwable nextInChain = null) nothrow pure @trusted
    {
        super(msg, mark.name, mark.line+1, nextInChain);
        column = mark.column+1;
        this.mark = mark;
    }

    size_t column;
    Mark mark;
}

/// Fail to evaluate the expression in workflow
class ExpressionFailed : Exception
{
    mixin basicExceptionCtors;
}

/// Fail to capture the workflow/step output after the workflow/step is done
class CaptureFailed : Exception
{
    mixin basicExceptionCtors;
}

/// System exception. For example, command arguments are wrong; the CWL workflow description file cannot be found; bsub/bwait command cannot be found
class SystemException : Exception
{
    mixin basicExceptionCtors;
}
