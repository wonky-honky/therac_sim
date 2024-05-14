# SPDX-License-Identifier: Unlicense

target_sources( ${PROJECT_NAME}
    PRIVATE
        GDExtensionTemplate.h
        GDExtensionTemplate.cpp
        RegisterExtension.cpp
        Toot.h
        Toot.cpp
        PianoParasite.hpp
        PianoParasite.cpp
)

target_include_directories( ${PROJECT_NAME}
    PRIVATE
        "src"
)
