# SPDX-License-Identifier: Unlicense

target_sources( ${PROJECT_NAME}
    PRIVATE
        RegisterExtension.cpp
        TheracSimulatorAdapter.hpp
        TheracSimulatorAdapter.cpp
)

target_include_directories( ${PROJECT_NAME}
    PRIVATE
        "src"
)
