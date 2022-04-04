#!/bin/sh

apk --no-cache add dub ldc gcc musl-dev git llvm-libunwind-static

dub build -b release-static || exit 1
strip bin/shaft
