#
# libbufr/CMakeLists.txt
#

cmake_minimum_required( VERSION 3.12 )
project(bufr VERSION 11.3.2 LANGUAGES C Fortran)
include(GNUInstallDirs)
### Configuration options
option(BUILD_STATIC_LIBS "Build static libraries" OFF)
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(OPT_IPO "Enable inter-procedural optimization if available." ON)

#Ensure at least one of BUILD_SHARED_LIBS and BUILD_STATIC_LIBS is set
if(NOT (BUILD_STATIC_LIBS OR BUILD_SHARED_LIBS))
    if(OPT_IPO)
        message(WARNING "Niether BUILD_STATIC_LIBS nor BUILD_SHARED_LIBS is set.  Defaulting to BUILD_SHARED_LIBS=ON")
        set(BUILD_SHARED_LIBS ON CACHE BOOL "[FORCE ENABLED] Build shared libraries" FORCE)
        set(BUILD_SHARED_LIBS ON)
    else()
        set(BUILD_STATIC_LIBS ON CACHE BOOL "[FORCE ENABLED] Build static libraries" FORCE)
        set(BUILD_STATIC_LIBS ON)
    endif()
endif()
if(OPT_IPO AND BUILD_STATIC_LIBS)
    message(WARNING "BUILD_STATIC_LIBS and OPT_IPO are currently incompatible.  Disabling OPT_IPO.")
    set(OPT_IPO OFF CACHE BOOL "[DISABLED] Conflicts with BUILD_STATIC_LIBS." FORCE)
endif()

message(STATUS "Option: BUILD_STATIC_LIBS: ${BUILD_STATIC_LIBS}")
message(STATUS "Option: BUILD_SHARED_LIBS: ${BUILD_SHARED_LIBS}")
message(STATUS "Option: OPT_IPO: ${OPT_IPO}")

#Set default build type to Release if not specified
if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    message(STATUS "Setting default build type to 'Release'.  Set CMAKE_BUILD_TYPE variable to change build types.")
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY VALUE "Release")
endif()

#Postfix for debug libraries so they can live alongside release libraries
set(CMAKE_DEBUG_POSTFIX ".debug" CACHE STRING "Debug file extension")

### Compilation flags
## Package compiler flags
#Public flags are necessary to build the library and to build code that links against the library
#Private flags are necessary only when building the library
set(PUBLIC_DEFS DYNAMIC_ALLOCATION)

set(BUFRLIB_PRM src/bufrlib.prm)
file(READ ${BUFRLIB_PRM} BUFRLIB_PRM_STR)
foreach(_var IN ITEMS MAXNC MXNAF)
    if(BUFRLIB_PRM_STR MATCHES "${_var} = ([0-9]+)")
        list(APPEND PRIVATE_DEFS $<$<OR:$<COMPILE_LANGUAGE:C>,$<COMPILE_LANGUAGE:CXX>>:${_var}=${CMAKE_MATCH_1}>)
    else()
        message(FATAL_ERROR "Unable to parse variable ${_var} value from file: ${BUFRLIB_PRM}")
    endif()
endforeach()

include(TestBigEndian)
test_big_endian(IS_BIG_ENDIAN)
if(IS_BIG_ENDIAN)
    list(APPEND PRIVATE_DEFS $<$<COMPILE_LANGUAGE:Fortran>:BIG_ENDIAN>)
else()
    list(APPEND PRIVATE_DEFS $<$<COMPILE_LANGUAGE:Fortran>:LITTLE_ENDIAN>)
endif()

include(FortranCInterface)
if(FortranCInterface_GLOBAL_FOUND AND FortranCInterface_GLOBAL_SUFFIX STREQUAL "_")
    list(APPEND PUBLIC_DEFS $<$<OR:$<COMPILE_LANGUAGE:C>,$<COMPILE_LANGUAGE:CXX>>:UNDERSCORE>)
endif()

# Compiler specific fixes
if( CMAKE_Fortran_COMPILER_ID STREQUAL GNU AND CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 10)
    list(APPEND PRIVATE_OPTS $<$<COMPILE_LANGUAGE:Fortran>:-fallow-argument-mismatch>) #Required for gfortan-10+.  Convert errors to warnings
endif()


### Global compilation properties
set(INCLUDE_DIR ${PROJECT_NAME}) #path relative to <prefix>/include/ to install headers/modules
set(CMAKE_Fortran_MODULE_DIRECTORY ${INCLUDE_DIR})
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

#Enable interprocedural optimization if available
include(CheckIPOSupported)
check_ipo_supported(RESULT _result OUTPUT _output)
if(_result)
    if(OPT_IPO)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
        message(STATUS "Interprocedural optimization: Enabled")
    else()
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION OFF)
        message(STATUS "Interprocedural optimization: Disabled")
    endif()
else()
    message(STATUS "Interprocedural optimization: Not available")
endif()

### Define Library Targets
file(GLOB C_SRC src/*.c)
file(GLOB C_HDRS src/*.h)
file(GLOB F_SRC src/modv*.F src/moda*.F src/*.f src/*.F) #Order of compilation is important

#Use a common object library for building shared and static targets
add_library(${PROJECT_NAME}_objects OBJECT ${C_SRC} ${F_SRC})
target_compile_definitions(${PROJECT_NAME}_objects PUBLIC ${PUBLIC_DEFS}
                                                      PRIVATE ${PRIVATE_DEFS})
target_compile_options(${PROJECT_NAME}_objects PRIVATE ${PRIVATE_OPTS})

#Add static lib target
if(BUILD_STATIC_LIBS)
    add_library(${PROJECT_NAME}_static STATIC $<TARGET_OBJECTS:${PROJECT_NAME}_objects>)
    list(APPEND LIB_TARGETS ${PROJECT_NAME}_static)
endif()

#Add shared lib target
if(BUILD_SHARED_LIBS)
    add_library(${PROJECT_NAME}_shared SHARED $<TARGET_OBJECTS:${PROJECT_NAME}_objects>)
    list(APPEND LIB_TARGETS ${PROJECT_NAME}_shared)
endif()

### Set common lib target properties

#Include Fortran module output directory
set(MODULE_DIR ${CMAKE_INSTALL_LIBDIR}/${PROJECT_NAME}/module/${CMAKE_Fortran_COMPILER_ID}/${CMAKE_Fortran_COMPILER_VERSION})
set_target_properties(${PROJECT_NAME}_objects PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/${MODULE_DIR})
install(DIRECTORY ${CMAKE_BINARY_DIR}/${MODULE_DIR}/ DESTINATION ${MODULE_DIR})

foreach(_tgt IN LISTS LIB_TARGETS)
    #PUBLIC target_compile_definitions are not correctly propagated from object libraries
    target_compile_definitions(${_tgt} PUBLIC "${PUBLIC_DEFS}")

    #Don't warn about type mismatches on LTO for non Debug builds
    if( CMAKE_Fortran_COMPILER_ID STREQUAL GNU OR CMAKE_C_COMPILER_ID STREQUAL GNU)
        target_link_libraries(${_tgt} PUBLIC $<$<NOT:$<CONFIG:Debug>>:-Wno-lto-type-mismatch>)
    endif()

    #Include Fortran module output directory for build and install interfaces
    target_include_directories(${_tgt} INTERFACE
                                    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/${MODULE_DIR}>
                                    $<INSTALL_INTERFACE:${MODULE_DIR}>)
endforeach()

### Install
install(TARGETS ${LIB_TARGETS} EXPORT ${PROJECT_NAME}Exports
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${INCLUDE_DIR})
install(FILES ${C_HDRS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${INCLUDE_DIR})
install(DIRECTORY ${CMAKE_BINARY_DIR}/${INCLUDE_DIR}/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${INCLUDE_DIR})

### Package config
include(CMakePackageConfigHelpers)

export(EXPORT ${PROJECT_NAME}Exports NAMESPACE ${PROJECT_NAME}:: FILE ${PROJECT_NAME}-targets.cmake)

set(CONFIG_INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})

# package-config.cmake
configure_package_config_file(cmake/PackageConfig.cmake.in ${PROJECT_NAME}-config.cmake
                              INSTALL_DESTINATION ${CONFIG_INSTALL_DESTINATION})
install(FILES ${CMAKE_BINARY_DIR}/${PROJECT_NAME}-config.cmake 
        DESTINATION ${CONFIG_INSTALL_DESTINATION})

# package-config-version.cmake
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion)
install(FILES ${CMAKE_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake 
        DESTINATION ${CONFIG_INSTALL_DESTINATION})

# package-targets.cmake and package-targets-<build-type>.cmake
install(EXPORT ${PROJECT_NAME}Exports NAMESPACE ${PROJECT_NAME}::
        FILE ${PROJECT_NAME}-targets.cmake
        DESTINATION ${CONFIG_INSTALL_DESTINATION})
