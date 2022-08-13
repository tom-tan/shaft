/**
 * Authors: Tomoya Tanjo
 * Copyright: © 2022 Tomoya Tanjo
 * License: Apache-2.0
 */
module shaft.license;

import std.format : format;
import std.string : chomp;

enum licenseString = format!q"EOS
# NOTICES AND INFORMATION
This software is licensed under Apache-2.0 License.

```
%s
```

# THIRD-PARTY SOFTWARE NOTICES AND INFORMATION
This software incorporates material from the following third party.

## njs

Link: https://github.com/nginx/njs

### License
```
%s
```
EOS"(
    import("license-shaft.txt").chomp,
    import("license-njs.txt").chomp
);
