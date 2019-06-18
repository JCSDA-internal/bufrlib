#!/bin/bash
# Build a release version
# useage:
# ./build.sh <install-prefix> <cmake args>

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`
if [ -z $1 ]; then
    INSTALL_PREFIX=/usr/local
else
    INSTALL_PREFIX=$1
fi
BUILD_DIR=${SCRIPT_DIR}/_build

set -ex
rm -rf ${BUILD_DIR}
cmake -H${SCRIPT_DIR} -B${BUILD_DIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} ${@:2}
cmake --build ${BUILD_DIR} --target install -- -j${NUM_PROCS}
