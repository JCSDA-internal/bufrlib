# bufrlib

This is a CMake enabled fork of NCEP BUFRLIB software, which is
described in detail at https://www.emc.ncep.noaa.gov/?branch=BUFRLIB
and whose usage is governed by the terms and conditions of the disclaimer
https://www.weather.gov/disclaimer.

## Install

 * Manual installation
```
cmake -H. -B_build -DCMAKE_INSTALL_PREFIX=<prefix> -DCMAKE_BUILD_TYPE=Release
cd _build && make -j8 install
```
 * Automatic install script
```
./build.sh <install-prefix> <optional-cmake-args>
```

## CMake options

This package can build both static and shared libraries simultaneously, as specified by the CMake
variables:

 * `BUILD_STATIC_LIBS` - Build static libraries [default=ON]
 * `BUILD_SHARED_LIBS` - Build static libraries [default=OFF]

At least one of `BUILD_STATIC_LIBS` or `BUILD_SHARED_LIBS` must be set.

## CMake Package Config

This package installs a modern [CMake package config file](https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#config-file-packages)
which provides [imported interface targets](https://cmake.org/cmake/help/latest/command/add_library.html#interface-libraries) using
CMake namespaces.

### Availible imported interface libraries

 * `bufrlib::bufrlib_static` - static libraries if available
 * `bufrlib::bufrlib_shared` - shared libraries if available

### Package config variables

 * `bufrlib_LIBRARIES` - Defaults to `bufrlib::bufrlib_static` if available, or `bufrlib::bufrlib_shared` otherwise
 * `bufrlib_STATIC_LIBRARIES` - Set to `bufrlib::bufrlib_static` if available.
 * `bufrlib_SHARED_LIBRARIES` - Set to `bufrlib::bufrlib_shared` if available.
 * `bufrlib_BUILD_TYPES` - List of `CMAKE_BUILD_TYPE`s available.
 
## Using the BUFRLIB CMake package in CMakeLists.txt

```
find_package(bufrlib REQUIRED)
target_link_libraries(${MY_TARGET} PRIVATE bufrlib::bufrlib_static)
```
