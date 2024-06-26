# SPDX-License-Identifier: Unlicense

cmake_minimum_required( VERSION 3.22 )

message( STATUS "Using CMake ${CMAKE_VERSION}" )
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_EXTENSIONS OFF)

# Require out-of-source builds
file( TO_CMAKE_PATH "${PROJECT_BINARY_DIR}/CMakeLists.txt" LOC_PATH )

if ( EXISTS "${LOC_PATH}" )
    message( FATAL_ERROR "You cannot build in the source directory. Please use a build subdirectory." )
endif()

# Add paths to modules
list( APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/" )

# Turn on link time optimization for everything
set( CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON )
#set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
if(CMAKE_EXPORT_COMPILE_COMMANDS)
  set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES 
      ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
endif()
add_compile_options("-fexperimental-library")
add_link_options("-fuse-ld=lld")
# Build universal lib on macOS
# Note that CMAKE_OSX_ARCHITECTURES must be set before project().
if ( APPLE )
    set( CMAKE_OSX_ARCHITECTURES "x86_64;arm64" CACHE STRING "" )
endif()

# Main project information
project( therac_sim
    LANGUAGES
        CXX
    VERSION
        0.1.0
)

# Create our library
add_library( ${PROJECT_NAME} SHARED )

target_compile_features( ${PROJECT_NAME}
    PRIVATE
        cxx_std_23
)

add_subdirectory(extern/rustex)
add_subdirectory(extern/GSL)
# LIB_ARCH is the architecture being built. It is set to the build system's architecture.
# For macOS, we build a universal library (both arm64 and x86_64).
set( LIB_ARCH ${CMAKE_SYSTEM_PROCESSOR} )
if ( APPLE )
    set( LIB_ARCH "universal" )
endif()



# LIB_DIR is where the actual library ends up. This is used in both the build directory and the
# install directory and needs to be consistent with the paths in the gdextension file.
#   e.g. linux.release.x86_64 = "lib/Linux-x86_64/libGDExtensionTemplate.so"
set( LIB_DIR "lib/${CMAKE_SYSTEM_NAME}-${LIB_ARCH}" )

message( STATUS "Building ${PROJECT_NAME} for ${LIB_ARCH} on ${CMAKE_SYSTEM_NAME}")

# BUILD_OUTPUT_DIR is where we put the resulting library (in the build directory)
set( BUILD_OUTPUT_DIR "${PROJECT_BINARY_DIR}/${PROJECT_NAME}/" )

set_target_properties( ${PROJECT_NAME}
    PROPERTIES
        CXX_VISIBILITY_PRESET hidden
        VISIBILITY_INLINES_HIDDEN true
        RUNTIME_OUTPUT_DIRECTORY "${BUILD_OUTPUT_DIR}/${LIB_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${BUILD_OUTPUT_DIR}/${LIB_DIR}"
)

if( NOT DEFINED CMAKE_DEBUG_POSTFIX )
    set_target_properties( ${PROJECT_NAME}
        PROPERTIES
            DEBUG_POSTFIX "-d"
    )
endif()

# Copy over additional files from the support_files directory
add_custom_command(
    TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/support_files"
            ${BUILD_OUTPUT_DIR}
)

# Warnings
include( CompilerWarnings )

# Create and include version info file from git
include( GitVersionInfo )

# haskell stuff
set(ghc_version 9.8.2)
set(ghc_rts_ver 1.0.2)
set(therac_sim_ver 0.1.0.0)
set(HSTHERACROOT extern/hstherac25)
if ( LINUX )
  set(HSPLATFORM x86_64-linux)
  set(HSSOSUFFIX .so)
  set(GHCUPHOME ~/.ghcup)
elseif ( WIN32 )
  set(HSPLATFORM x86_64-windows)
  set(HSSOSUFFIX .dll.a)
  set(GHCUPHOME C:/GHCUP)
endif()
set(GHCEXTRAPATHS ${GHCUPHOME}/ghc/${ghc_version}/)
find_path(HSINCLUDES NAMES "HsFFI.h" PATH_SUFFIXES "lib/ghc-${ghc_version}/lib/${HSPLATFORM}-ghc-${ghc_version}/rts-${ghc_rts_ver}/include" "include/" HINTS ${GHCEXTRAPATHS})

if ( WIN32 )
  set(HSTHERAC ${PROJECT_SOURCE_DIR}/${HSTHERACROOT}/dist-newstyle/build/${HSPLATFORM}/ghc-${ghc_version}/hstherac25-${therac_sim_ver}/f/hstherac25/build/hstherac25/hstherac25${HSSOSUFFIX})
  set(HSTHERACDLL ${PROJECT_SOURCE_DIR}/${HSTHERACROOT}/dist-newstyle/build/${HSPLATFORM}/ghc-${ghc_version}/hstherac25-${therac_sim_ver}/f/hstherac25/build/hstherac25/hstherac25.dll)
  set(HSTHERACARCHIVE ${PROJECT_SOURCE_DIR}/${HSTHERACROOT}/dist-newstyle/build/${HSPLATFORM}/ghc-${ghc_version}/hstherac25-${therac_sim_ver}/build/libHShstherac25-${therac_sim_ver}-inplace-ghc${ghc_version}.lib)
  set(HSRTS "")
  add_library(DLLHSTHERAC SHARED IMPORTED GLOBAL)
  set_target_properties(DLLHSTHERAC PROPERTIES
  IMPORTED_LOCATION ${HSTHERACDLL}
  IMPORTED_IMPLIB ${HSTHERAC}
  INTERFACE_INCLUDE_DIRECTORIES ${PROJECT_SOURCE_DIR}/${HSTHERACROOT}/dist-newstyle/build/${HSPLATFORM}/ghc-${ghc_version}/hstherac25-${therac_sim_ver}/build
)
elseif ( LINUX )

  #  set(HSTHERAC ${PROJECT_SOURCE_DIR}/${HSTHERACROOT}/dist-newstyle/build/${HSPLATFORM}/ghc-${ghc_version}/hstherac25-${therac_sim_ver}/build/libHShstherac25-${therac_sim_ver}-inplace-ghc${ghc_version}${HSSOSUFFIX})
  set(HSTHERAC ${PROJECT_SOURCE_DIR}/${HSTHERACROOT}/dist-newstyle/build/${HSPLATFORM}/ghc-${ghc_version}/hstherac25-${therac_sim_ver}/f/hstherac25/build/hstherac25/libhstherac25.so)
  set(HSRTS HSrts-${ghc_rts_ver}_thr-ghc${ghc_version})
  find_path(HSLDPATH NAMES "lib${HSRTS}${HSSOSUFFIX}" "${HSRTS}${HSSOSUFFIX}" PATH_SUFFIXES "lib/ghc-${ghc_version}/lib/${HSPLATFORM}-ghc-${ghc_version}/" "lib/ghc-${ghc_version}/lib/x86_64-mingw32-ghc-${ghc_version}/" "lib/ghc-${ghc_version}/lib/x86_64-mingw64-ghc-${ghc_version}/" HINTS ${GHCEXTRAPATHS})
  set(HSLDFLAGS "-L${HSLDPATH}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${HSLDFLAGS}")
  add_library (SOHSTHERAC SHARED IMPORTED GLOBAL)
  set_target_properties(SOHSTHERAC PROPERTIES
    IMPORTED_LOCATION ${HSTHERAC}
#    IMPORTED_IMPLIB ${HSTHERAC}
  )
  add_library (SOHSRTS SHARED IMPORTED GLOBAL)
  set_target_properties(SOHSRTS PROPERTIES
    IMPORTED_LOCATION "${HSLDPATH}/lib${HSRTS}${HSSOSUFFIX}"
#    IMPORTED_IMPLIB ${HSRTS}
  )
endif()
#configure_file(${PROJECT_SOURCE_DIR}/src/TheracSimulatorAdapter.hpp.in ${PROJECT_SOURCE_DIR}/src/TheracSimulatorAdapter.hpp)
include_directories(${PROJECT_NAME} ${PROJECT_SOURCE_DIR}/extern ${PROJECT_SOURCE_DIR}/extern/furnace/extern/fmt/include ${PROJECT_SOURCE_DIR}/extern/ctre/include ${PROJECT_SOURCE_DIR}/extern/frozen/include ${PROJECT_SOURCE_DIR}/extern/GSL/include ${HSINCLUDES} ${PROJECT_SOURCE_DIR}/${HSTHERACROOT}/dist-newstyle/build/${HSPLATFORM}/ghc-${ghc_version}/hstherac25-${therac_sim_ver}/build ${PROJECT_SOURCE_DIR}/extern/GSL/include ${PROJECT_SOURCE_DIR}/${HSTHERACROOT}/csrc)
add_subdirectory( src )

# Install library, extension file, and support files in ${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}
set( INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/" )

message( STATUS "Install directory: ${INSTALL_DIR}")

if ( WIN32 )
install(IMPORTED_RUNTIME_ARTIFACTS DLLHSTHERAC DESTINATION ${INSTALL_DIR}/${LIB_DIR})
install( TARGETS ${PROJECT_NAME}
    LIBRARY
        DESTINATION ${INSTALL_DIR}/${LIB_DIR}
    RUNTIME
        DESTINATION ${INSTALL_DIR}/${LIB_DIR}
)
elseif (LINUX)
install(IMPORTED_RUNTIME_ARTIFACTS SOHSTHERAC SOHSRTS DESTINATION usr/lib)
set_target_properties(${PROJECT_NAME}
       PROPERTIES
       LINK_FLAGS "-Wl,-rpath,\\\$ORIGIN/../../../usr/lib:\\\$ORIGIN"
)
install( TARGETS ${PROJECT_NAME}
    LIBRARY
        DESTINATION ${INSTALL_DIR}/${LIB_DIR}
    RUNTIME
        DESTINATION ${INSTALL_DIR}/${LIB_DIR}
)
endif ()
# Copy over support files
install( DIRECTORY "${CMAKE_SOURCE_DIR}/support_files/"
    DESTINATION ${INSTALL_DIR}
    PATTERN ".*" EXCLUDE
)

add_subdirectory( templates )

# ccache
# Turns on ccache if found
include( ccache )

# Formatting
# Adds a custom target to format all the code at once
include( ClangFormat )

# godot-cpp
# From here: https://github.com/godotengine/godot-cpp
if ( NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/extern/godot-cpp/Makefile" )
    message(
        FATAL_ERROR
            "[${PROJECT_NAME}] The godot-cpp submodule was not downloaded. Please update submodules: git submodule update --init --recursive."
    )
endif()

set( GODOT_CPP_SYSTEM_HEADERS ON CACHE BOOL "" FORCE )




add_subdirectory( extern/godot-cpp )

set_target_properties( godot-cpp
    PROPERTIES
        CXX_VISIBILITY_PRESET hidden    # visibility needs to be the same as the main library
)

if (WIN32)
  file(COPY ${HSTHERACDLL} DESTINATION ${CMAKE_BINARY_DIR})
#  link_directories(  ${PROJECT_SOURCE_DIR}/${HSTHERACROOT}/dist-newstyle/build/${HSPLATFORM}/ghc-${ghc_version}/hstherac25-${therac_sim_ver}/f/hstherac25/build/hstherac25/)
  target_link_libraries( ${PROJECT_NAME}
    PRIVATE
        godot-cpp
        rustex
        Microsoft.GSL::GSL
#        ${HSTHERACARCHIVE}
        DLLHSTHERAC
#        ${HSRTS}
)

else()
file(COPY ${HSTHERAC} DESTINATION ${CMAKE_BINARY_DIR})
target_link_libraries( ${PROJECT_NAME}
    PRIVATE
        godot-cpp
        rustex
        Microsoft.GSL::GSL
        SOHSTHERAC
        SOHSRTS
)
endif()
