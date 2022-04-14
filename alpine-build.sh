#!/bin/sh

apk --no-cache add dub ldc gcc musl-dev git llvm-libunwind-static

git config --add safe.directory $PWD

dub --cache=local build -b release-static || exit 1
strip bin/shaft
