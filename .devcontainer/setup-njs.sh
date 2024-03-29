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

./configure --no-openssl
sed -e 's/^#define NJS_HAVE_UNSIGNED_INT128  1//' build/njs_auto_config.h > njs_auto_config_tmp1.h
sed -e 's/^#define NJS_HAVE_DENORMALS_CONTROL  1//' njs_auto_config_tmp1.h > njs_auto_config_tmp2.h
sed -e 's/^#define NJS_HAVE_BUILTIN_CLZLL  1//' njs_auto_config_tmp2.h > njs_auto_config_tmp3.h
mv njs_auto_config_tmp3.h build/njs_auto_config.h
make -j libnjs
cd ..

install -d $dest/include $dest/lib $dest/doc
echo "$version" > $dest/version
install -m 644 njs-repo/build/libnjs.a $dest/lib
install -m 644 njs-repo/src/*.h $dest/include
install -m 644 njs-repo/build/njs_auto_config.h $dest/include
install -m 644 njs-repo/LICENSE $dest/doc

rm -rf njs-repo
