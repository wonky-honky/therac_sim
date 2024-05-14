#!/usr/bin/env zsh
cmake -GNinja -S . -B build -DCMAKE_BUILD_TYPE=Debug -DTHERAC_SIM_WARNING_AS_ERROR=OFF
cmake --build build --parallel 8
