#!/bin/sh
# generate version string

if [ -n "$GITHUB_REF" ] && $(echo $GITHUB_REF | grep '^refs/tags/' > /dev/null 2>&1); then
    echo ${GITHUB_REF#refs/tags/}
elif [ -d .git ] && $(which git > /dev/null 2>&1); then
    git describe --always --dirty
else
    cat VERSION
fi
