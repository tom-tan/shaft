#!/bin/sh

apk --no-cache add dub ldc gcc musl-dev git llvm-libunwind-static

dub --cache=local build -b release-static || exit 1
strip bin/shaft
