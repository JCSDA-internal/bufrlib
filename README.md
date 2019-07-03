# NCEP BUFRLIB

This is a copy of the public domain NCEP BUFRLIB software with a modern CMake build system.  This repository
will track the most recent release of NCEP BUFRLIB, applying build-system related modifications only.
 * Current upstream version tracked: [**11.3.0**](https://www.emc.ncep.noaa.gov/BUFRLIB/docs/versions/#v11.3.0)
 * [NCEP BUFRLIB detailed package description](https://www.emc.ncep.noaa.gov/?branch=BUFRLIB)
 * Distributed under the terms and conditions of the [disclaimer](https://www.weather.gov/disclaimer).

## Install
The [CMake build system](https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html) is used to configure, build, and install this library in shared and static
variants.  It is easily configurable enabling support for a wide range of computing environments and operating systems.

 * Manual installation
```
cmake -H. -B_build -DCMAKE_INSTALL_PREFIX=<prefix> -DCMAKE_BUILD_TYPE=Release <additional-cmake-args>
cd _build && make -j<num-procs> install
```
 * Automatic install script
```
./tools/build.sh <install-prefix> <additional-cmake-args>
```

### CMake options

The following CMake cache variables control the build.  They can be set as arguments to the cmake executable
via the `-D<var>=<val>` syntax:
 * `BUILD_STATIC_LIBS` - Build static libraries. [default=ON]
 * `BUILD_SHARED_LIBS` - Build shared libraries. [default=OFF]
 * `OPT_IPO` - Enable [interprocedural optimization](https://en.wikipedia.org/wiki/Interprocedural_optimization) if available. [default=ON] 

This package can build both static and shared libraries simultaneously.  At least one of `BUILD_STATIC_LIBS` or `BUILD_SHARED_LIBS` must be set.  If neither is set,
`BUILD_STATIC_LIBS` will be used.

### CMake package config

This package installs a modern [CMake package config file](https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#config-file-packages)
which provides [imported interface targets](https://cmake.org/cmake/help/latest/command/add_library.html#interface-libraries) using
CMake namespaces.

#### Components

The bufrlib package config file can identify the following components through `COMPONENTS` or `REQUIRED COMPONENTS` keywords to the 
`find_package()` command.
 * `SHARED` - Find shared libraries
 * `STATIC` - Find shared libraries
 
#### Provided imported interface libraries

 * `bufrlib::bufrlib_static` - Static libraries if available
 * `bufrlib::bufrlib_shared` - Shared libraries if available

#### Provided CMake variables

 * `bufrlib_LIBRARIES` - Defaults to `bufrlib::bufrlib_static` if available, or `bufrlib::bufrlib_shared` otherwise
 * `bufrlib_STATIC_LIBRARIES` - Set to `bufrlib::bufrlib_static` if available.
 * `bufrlib_SHARED_LIBRARIES` - Set to `bufrlib::bufrlib_shared` if available.
 * `bufrlib_BUILD_TYPES` - List of `CMAKE_BUILD_TYPE`s available.

### CMake build types

This package has the capability to install *Debug* and *Release* versions of both static and shared
libraries so that they can coexist under the same install prefix.  Using the generated CMake package config file, a downstream package
will use the 
[`IMPORTED_CONFIGURATIONS`](https://cmake.org/cmake/help/latest/prop_tgt/IMPORTED_CONFIGURATIONS.html)
property of the [imported interface targets](https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html#interface-libraries) to link to the correct *Debug* or *Release*
version of this library.

To build and install shared and static versions of *Debug* and *Release* build types to the
same install prefix, the build procedure can be repeated for each build-type.
```
./tools/build.sh <install-prefix> -DBUILD_STATIC_LIBS=1 -DBUILD_SHARED_LIBS=1 -DCMAKE_BUILD_TYPE=Release
./tools/build.sh <install-prefix> -DBUILD_STATIC_LIBS=1 -DBUILD_SHARED_LIBS=1 -DCMAKE_BUILD_TYPE=Debug
```

### Setting compilers and flags

The compiler executables as well as the compilation and linking flags used in the build can be controlled via:
 1) Setting normal **environment variables** before the CMake configure step, or by 
 2) Setting **CMake cache variables** on the `cmake` command line or through the [CMake GUI](https://cmake.org/cmake/help/latest/manual/cmake-gui.1.html).

#### Environment variables
Certain environment variables are respected by CMake when initially generating a build system in a
new build directory.  Each environment variable will append its value onto the default values of the appropriate
CMake cache variable(s).  To completely override any CMake defualt values for compiler flags, use the appropriate CMake cache variables instead.

 * [`FC`](https://cmake.org/cmake/help/latest/envvar/FC.html) - Fortran compiler (full path to executable or name of executable on PATH).
   * Sets: `CMAKE_Fortran_COMPILER`
 * [`CC`](https://cmake.org/cmake/help/latest/envvar/CC.html) - C compiler (full path to executable or name of executable on PATH).
   * Sets: `CMAKE_C_COMPILER`
 * [`FFLAGS`](https://cmake.org/cmake/help/latest/envvar/FFLAGS.html) - Fortran compiler flags 
   * Sets: `CMAKE_Fortran_FLAGS`
 * [`CFLAGS`](https://cmake.org/cmake/help/latest/envvar/CFLAGS.html) - C compiler flags 
   * Sets: `CMAKE_C_FLAGS`
 * [`LDFLAGS`](https://cmake.org/cmake/help/latest/envvar/LDFLAGS.html) - Universal linker flags.  Common flags for all linker operations.
   * Sets: `CMAKE_EXE_LINKER_FLAGS`, `CMAKE_SHARED_LINKER_FLAGS`, `CMAKE_STATIC_LINKER_FLAGS`, and `CMAKE_MODULE_LINKER_FLAGS`

Environment variables  only have an effect when creating a new build
directory for the first time.  Once CMake has generated the build system in a directory, subsequent re-generation
of the build system using `cmake` on the same directory will not take into account any changes to
environment variables because their effect has already been stored in the appropriate CMake cache variable.

#### CMake cache variables
Finer-grained control over the compilers and flags used can be achieved using CMake cache variables.  These variables can be configured directly by using the `-D<var>=<val>` arguments to the `cmake` command
when generating a new build directory.  After the initial build-system generation, cache variables
can be viewed and modified with the [CMake GUI](https://cmake.org/cmake/help/latest/manual/cmake-gui.1.html), which must be given the path to the build directory as input, *e.g.*:
```
cd <build-dir> && cmake-gui . &
```

The following CMake cache variables are useful for controlling the compilation and linking steps.  These variables define the base set of flags used for compilation and linking processes, but targets
may define additional flags which are appended to the list of flags to be used.  For this reason, the CMake targets
specified in this project only define flags that are strictly necessary for compilation and linking.
Optional or system-dependent flags should be set directly via these CMake cache variables:
 * **Compilers**
   * [`CMAKE_Fortran_COMPILER`](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER.html) - Full path to the Fortran compiler.
   * [`CMAKE_C_COMPILER`](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER.html) - Full path to the C compiler.
 * **Compiler flags**
   * [`CMAKE_Fortran_FLAGS`](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_FLAGS.html) - Common set of universal Fortran compiler flags.
   * [`CMAKE_Fortran_FLAGS_<BUILD-TYPE>`](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_FLAGS_CONFIG.html) - Fortran compiler flags specific to each CMake build type.
   * [`CMAKE_C_FLAGS`](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_FLAGS.html) - Common set of universal C compiler flags.
   * [`CMAKE_C_FLAGS_<BUILD-TYPE>`](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_FLAGS_CONFIG.html)  - C compiler flags specific to each CMake build type.
 * **Linker flags** 
   * [`CMAKE_EXE_LINKER_FLAGS`](https://cmake.org/cmake/help/latest/variable/CMAKE_EXE_LINKER_FLAGS.html) - Common set of linker flags used when creating an executable.
   * [`CMAKE_EXE_LINKER_FLAGS_<BUILD-TYPE>`](https://cmake.org/cmake/help/latest/variable/CMAKE_EXE_LINKER_FLAGS_CONFIG.html) - Linking flags for executables specific to each CMake build type.
   * [`CMAKE_SHARED_LINKER_FLAGS`](https://cmake.org/cmake/help/latest/variable/CMAKE_SHARED_LINKER_FLAGS.html) - Common set of linker flags used when creating a shared library target.
   * [`CMAKE_SHARED_LINKER_FLAGS_<BUILD-TYPE>`](https://cmake.org/cmake/help/latest/variable/CMAKE_SHARED_LINKER_FLAGS_CONFIG.html) - Linking flags for shared libraries specific to each CMake build type.
   * [`CMAKE_STATIC_LINKER_FLAGS`](https://cmake.org/cmake/help/latest/variable/CMAKE_STATIC_LINKER_FLAGS.html) - Common set of linker flags used when creating a static library target.
   * [`CMAKE_STATIC_LINKER_FLAGS_<BUILD-TYPE>`](https://cmake.org/cmake/help/latest/variable/CMAKE_STATIC_LINKER_FLAGS_CONFIG.html) - Linking flags for static libraries specific to each CMake build type.
   * [`CMAKE_MODULE_LINKER_FLAGS`](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_LINKER_FLAGS.html) - Common set of linker flags used when creating a Fortran module target.
   * [`CMAKE_MODULE_LINKER_FLAGS_<BUILD-TYPE>`](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_LINKER_FLAGS_CONFIG.html) - Linking flags for Fortran modules specific to each CMake build type.

For each compiler, CMake has pre-configured sets of compiler flags specified for each of the four default build types.   To override
these default values, the appropriate CMake cache variable should be set when generating the build directory.
The default build types and thier GCC flags are:
 * `Release` - Release build [GCC: `-O3 -DNDEBUG`]
 * `Debug` - Debugging build without optimization [GCC: `-g`]
 * `MinSizeRel` - Minimum size release [GCC: `-Os -DNDEBUG`]
 * `RelWithDebInfo` - Optimized release version with debugging info [GCC: `-O2 -g -DNDEBUG`]
### Debugging compilation/linking errors

To see the exact command line invocations CMake uses to build the project, set the [`VERBOSE`](https://cmake.org/cmake/help/latest/envvar/VERBOSE.html) environment variable.
```
cd <build-dir> && VERBOSE=1 make
```

## Using the BUFRLIB package in CMake projects.
The CMake package config file provided will allow downstream libraries
to find this library via the [`find_package()`](https://cmake.org/cmake/help/latest/command/find_package.html) command.  When linking a target against this library, we recommend using
the provided *imported interface targets* as arguments to the [`target_link_libraries()`](https://cmake.org/cmake/help/latest/command/target_link_libraries.html) command.  Using
the imported targets will cause all transitive dependencies as well as public linking and compiling flags
and even library and include directories to be automatically added to your target's compilation and linking
phases as appropriate.

### Example useage

 * Linking against the static libraries, in a dependent project's `CMakeLists.txt`:
```
find_package(bufrlib REQUIRED COMPONENTS STATIC)
target_link_libraries(${MY_STATIC_TARGET} <PUBLIC|PRIVATE|INTERFACE> bufrlib::bufrlib_static)
```

 * Linking against the shared libraries, in a dependent project's `CMakeLists.txt`:
```
find_package(bufrlib REQUIRED COMPONENTS SHARED)
target_link_libraries(${MY_SHARED_TARGET} <PUBLIC|PRIVATE|INTERFACE> bufrlib::bufrlib_shared)
```
As described in the [`target_link_libraries()` documentation](https://cmake.org/cmake/help/latest/command/target_link_libraries.html#libraries-for-a-target-and-or-its-dependents), the choice of `PUBLIC`, `PRIVATE`, or `INTERFACE` visibility will depend on the requirements of the target library and it's own link interface as required by further downstream dependencies.
