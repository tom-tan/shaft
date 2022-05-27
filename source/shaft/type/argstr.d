/**
 * This module defines string types to construct command line arguments.
 *
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.type.argstr;

/// string type that is escaped string
struct EscapedString // @suppress(dscanner.suspicious.incomplete_operator_overloading)
{
    /// `arg` is escaped internally
    this(NonEscapedString arg) nothrow pure @safe
    {
        import std.process : escapeShellFileName;
        arg_ = arg.escapeShellFileName;
    }

    this(EscapedString arg) @nogc nothrow pure @safe
    {
        arg_ = arg.arg_;
    }

    EscapedString opBinary(string op: "~")(EscapedString rhs) const nothrow pure @safe
    {
        typeof(return) ret;
        ret.arg_ = arg_[0..$-1]~rhs.arg_[1..$];
        return ret;
    }

    EscapedString opBinary(string op: "~")(NonEscapedString rhs) const nothrow pure @safe
    {
        typeof(return) ret;
        ret.arg_ = arg_[0..$-1]~rhs~"'";
        return ret;
    }

    EscapedString opBinaryRight(string op: "~")(NonEscapedString lhs) const nothrow pure @safe
    {
        auto escapedLhs = typeof(this)(lhs);
        return escapedLhs~this;
    }

    bool opEquals(in string other) const @nogc nothrow pure @safe
    {
        return arg_ == other;
    }

    string toString() const @nogc nothrow pure @safe
    {
        return arg_;
    }

    invariant(arg_.startsWith("'"));
    invariant(arg_.endsWith("'"));

private:
    import std.algorithm : endsWith, startsWith;
    string arg_;
}

///
alias NonEscapedString = string;

nothrow pure @safe unittest
{
    auto es = EscapedString("foo bar.txt");
    assert(es.arg_ == "'foo bar.txt'");

    assert("-p"~es == "'-pfoo bar.txt'");
    assert(es~".bak" == "'foo bar.txt.bak'");
}
