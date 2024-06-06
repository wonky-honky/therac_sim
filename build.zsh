#!/usr/bin/env zsh
cmake -GNinja -S . -B build -DCMAKE_BUILD_TYPE=Debug -DTHERAC_SIM_WARNING_AS_ERROR=OFF -DFLOAT_PRECISION=double -DCMAKE_INSTALL_PREFIX=install-test
cmake --build build --parallel 8
