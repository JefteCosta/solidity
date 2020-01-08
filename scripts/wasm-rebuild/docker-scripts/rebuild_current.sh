#!/bin/bash -e

# This script is expected to be run inside the docker image trzeci/emscripten:sdk-tag-1.39.3-64bit and
# be called by ./rebuild_tags.sh.

echo "========== STAGE 1: PREPARE ========== ($(date))"
git rev-parse --short=8 HEAD > commit_hash.txt
echo -e "" > prerelease.txt
sed -i -e 's/-Wl,--gc-sections//' cmake/EthCompilerSettings.cmake
sed -i -e 's/-Werror/-Wno-error/' cmake/EthCompilerSettings.cmake
echo "set(CMAKE_CXX_FLAGS \"\${CMAKE_CXX_FLAGS} -s EXTRA_EXPORTED_RUNTIME_METHODS=['cwrap','addFunction','removeFunction','UTF8ToString','lengthBytesUTF8','_malloc','stringToUTF8','setValue'] -s WASM=1 -s WASM_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -Wno-almost-asm\")" >> cmake/EthCompilerSettings.cmake

echo "========== STAGE 2: BUILD ========== ($(date))"
scripts/travis-emscripten/install_deps.sh
scripts/travis-emscripten/build_emscripten.sh

echo "========== SUCCESS ========== ($(date))"
