#!/usr/bin/env bash

mkdir build
cd build

cmake -G "Unix Makefiles" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=${PREFIX} \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DBoost_USE_STATIC_LIBS=No \
      ..

cmake --build .

cmake --build . --target install
