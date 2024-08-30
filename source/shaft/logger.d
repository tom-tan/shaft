/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.logger;

import std.logger : LogLevel, FileLogger;
import std.datetime.timezone : TimeZone;

///
alias JSONLogger = FormatLogger!toJSONLogEntry;

/**
 * This Logger implementation writes log messages, that is formatted with Formatter, to the associated file.
 */
@safe class FormatLogger(alias Formatter) : FileLogger
{
    ///
    this(const string fn, const LogLevel lv = LogLevel.all) @trusted
    {
        super(fn, lv);
        tz = getTimeZone();
    }

    ///
    this(File file, const LogLevel lv = LogLevel.all)
    {
        super(file, lv);
        tz = getTimeZone();
    }

    override void writeLogMsg(ref LogEntry payload)
    {
        auto log = Formatter(payload, tz);
        file.writeln(log);
        file.flush;
    }

protected:
    import std.stdio : File;
    immutable TimeZone tz;
}

immutable(TimeZone) getTimeZone() @safe
{
    import std : exists, UTC;

    if ("/etc/localtime".exists)
    {
        // Note: /etc/timezone is not available on macOS
        import std : findSplitAfter, PosixTimeZone, readLink, stripLeft;

        // A linked file difers in platforms
        // e.g., Ubuntu 22.04: /usr/share/zoneinfo/Asia/Tokyo, macOS 14.4.1: /var/db/timezone/zoneinfo/Asia/Tokyo,
        //       Ubuntu 22.04 in mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04: /usr/share/zoneinfo//UTC
        auto zone = "/etc/localtime".readLink.findSplitAfter("zoneinfo/")[1].stripLeft("/");
        return zone == "UTC" ? UTC() : PosixTimeZone.getTimeZone(zone);
    }
    else
    {
        return UTC();
    }
}

/// A structured log entry
struct SLogEntry
{
    import std : JSONValue;

    ///
    typeof(this) add(T)(string key, T value)
    {
        log[key] = JSONValue(value);
        return this;
    }

    ///
    string toString() const @safe
    {
        return log.toString;
    }

    JSONValue log;
}

/// Convert a LogEntry to a JSON string
auto toJSONLogEntry(LogEntry)(in LogEntry payload, immutable TimeZone tz) @safe
{
    import std.conv : to;
    import std.json : JSONException, JSONValue, JSONType, parseJSON;

    auto log = JSONValue.emptyObject;
    log["time"] = payload.timestamp.toOtherTZ(tz).toISOExtString;
    log["level"] = payload.logLevel.to!string;
    try
    {
        auto json = parseJSON(payload.msg);
        if (json.type == JSONType.object)
        {
            () @trusted {
                foreach (string k, v; json)
                {
                    if (k in log)
                    {
                        import std : format;

                        auto wmsg = format!"duplicated log entry `%s`"(k);

                        log[k ~ "_"] = v;

                        if ("warnings" in log)
                        {
                            log["warnings"] = log["warnings"].array ~ JSONValue(wmsg);
                        }
                        else
                        {
                            log["warnings"] = [wmsg];
                        }
                    }
                    else
                    {
                        log[k] = v;
                    }
                }
            }();
        }
        else
        {
            log["payload"] = json;
        }
    }
    catch (JSONException _)
    {
        log["message"] = payload.msg;
    }
    return log.toString;
}
