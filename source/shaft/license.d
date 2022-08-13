/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.license;

import std.algorithm : map;
import std.format : format;
import std.string : chomp, join;

enum thirdPartiesBase = [
    LicenseInfo(
        "njs",
        "https://github.com/nginx/njs",
        import("license-njs.txt").chomp,
    ),
];

static if (import("license-musl.txt").length == 0)
{
    // dynamic link
    enum thirdParties = thirdPartiesBase;
}
else
{
    // static link
    enum thirdParties = [
        LicenseInfo(
            "musl libc",
            "https://musl.libc.org/",
            import("license-musl.txt").chomp,
        ),
    ] ~ thirdPartiesBase;
}

enum licenseString = format!q"EOS
# NOTICES AND INFORMATION
This software is licensed under the following Apache-2.0 License.

```
%s
```

# THIRD-PARTY SOFTWARE NOTICES AND INFORMATION
This software incorporates material from the following third parties.

%s
EOS"(
    import("license-shaft.txt").chomp,
    thirdParties.map!(a => a.toString).join("\n"),
);

struct LicenseInfo
{
    string name;
    string link;
    string license;

    auto toString() const pure scope
    {
        import std.format : format;

        return format!q"EOS
## %s

Link: %s

### License
```
%s
```
EOS"(name, link, license);
    }
}
