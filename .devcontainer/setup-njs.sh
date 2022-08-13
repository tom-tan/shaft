#!/bin/sh
# build and setup directories for njs

set -e

if [ $# != 2 ]; then
    echo "Usage: $0 <version> <dest>"
    exit 1
fi

version=$1
dest=$2

git clone --depth 1 https://github.com/nginx/njs.git -b $version njs-repo

cd njs-repo

./configure --test262=NO --no-openssl
make -j libnjs
cd ..

install -d $dest/include $dest/lib $dest/doc
install -m 644 njs-repo/build/libnjs.a $dest/lib
install -m 644 njs-repo/src/*.h $dest/include
install -m 644 njs-repo/build/njs_auto_config.h $dest/include
install -m 644 njs-repo/LICENSE $dest/doc

rm -rf njs-repo
