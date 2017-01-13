#!/usr/local/bin/bash
export PRJROOT=`realpath ~/work/w64`
export TARGET=x86_64-w64-mingw32
export PREFIX=${PRJROOT}/tools
export BUILD=${PRJROOT}/build-tools
export TARGET_PREFIX=${PREFIX}/${TARGET}

