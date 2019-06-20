# bufrlib

This is a CMake enabled fork of NCEP BUFRLIB software, which is
described in detail at https://www.emc.ncep.noaa.gov/?branch=BUFRLIB
and whose usage is governed by the terms and conditions of the disclaimer
https://www.weather.gov/disclaimer.

## Install

 * Manual installation
```
cmake -H. -B_build -DCMAKE_INSTALL_PREFIX=<prefix> -DCMAKE_BUILD_TYPE=Release
cd _build && make -j<num-procs> install
```
 * Automatic install script
```
./tools/build.sh <install-prefix> <optional-cmake-args>
```

### CMake options

The following CMake variables control the build:
 * `BUILD_STATIC_LIBS` - Build static libraries. [default=ON]
 * `BUILD_SHARED_LIBS` - Build shared libraries. [default=OFF]
 * `OPT_IPO` - Enable [interprocedural optimization](https://en.wikipedia.org/wiki/Interprocedural_optimization) if available. [default=ON] 

This package can build both static and shared libraries simultaneously, as specified by the CMake
options.  At least one of `BUILD_STATIC_LIBS` or `BUILD_SHARED_LIBS` must be set.  If neither is set,
`BUILD_STATIC_LIBS` will be used.

### CMake Package Config

This package installs a modern [CMake package config file](https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#config-file-packages)
which provides [imported interface targets](https://cmake.org/cmake/help/latest/command/add_library.html#interface-libraries) using
CMake namespaces.

#### Available imported interface libraries

 * `bufrlib::bufrlib_static` - static libraries if available
 * `bufrlib::bufrlib_shared` - shared libraries if available

#### Package config variables provided

 * `bufrlib_LIBRARIES` - Defaults to `bufrlib::bufrlib_static` if available, or `bufrlib::bufrlib_shared` otherwise
 * `bufrlib_STATIC_LIBRARIES` - Set to `bufrlib::bufrlib_static` if available.
 * `bufrlib_SHARED_LIBRARIES` - Set to `bufrlib::bufrlib_shared` if available.
 * `bufrlib_BUILD_TYPES` - List of `CMAKE_BUILD_TYPE`s available.

### CMake Build types

This package has the capability to install debug and release versions of both static and shared
libraries so that they can coexist in the same install prefix.  The CMake package config file provides
targets for both debug and release versions if both are installed to the same prefix, via the
[`IMPORTED_CONFIGURATIONS`](https://cmake.org/cmake/help/latest/prop_tgt/IMPORTED_CONFIGURATIONS.html)
property of imported interface targets.

For example, to build shared and static versions of debug and release build types, one can invoke CMake
for each build type, and build and install to the same prefix, or using the `build.sh` script:
```
./tools/build.sh <install-prefix> -DBUILD_STATIC_LIBS=1 -DBUILD_SHARED_LIBS=1 -DCMAKE_BUILD_TYPE=Release
./tools/build.sh <install-prefix> -DBUILD_STATIC_LIBS=1 -DBUILD_SHARED_LIBS=1 -DCMAKE_BUILD_TYPE=Debug
```

## Using the BUFRLIB CMake package in CMakeLists.txt

```
find_package(bufrlib REQUIRED)
target_link_libraries(${MY_TARGET} PRIVATE bufrlib::bufrlib_static)
```
