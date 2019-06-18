#
# libbufr/CMakeLists.txt
#

cmake_minimum_required( VERSION 3.9 )
project(bufrlib VERSION 11.3 LANGUAGES C Fortran)

### Configuration options

option(BUILD_STATIC_LIBS "Build static libarary" ON)
option(BUILD_SHARED_LIBS "Build shared libarary" OFF)

#Ensure at least one of BUILD_SHARED_LIBS and BUILD_STATIC_LIBS is set
if(NOT (BUILD_STATIC_LIBS OR BUILD_SHARED_LIBS))
    message(STATUS "Niether BUILD_STATIC_LIBS nor BUILD_SHARED_LIBS is set.  Defaulting to BUILD_STATIC_LIBS=ON")
    set(BUILD_STATIC_LIBS ON CACHE BOOL "Build static library" FORCE)
    set(BUILD_STATIC_LIBS ON)
endif()

message(STATUS "Option: BUILD_STATIC_LIBS: ${BUILD_STATIC_LIBS}")
message(STATUS "Option: BUILD_SHARED_LIBS: ${BUILD_SHARED_LIBS}")

#Set default build type to debug if not specified
if(NOT CMAKE_CONFIGURATION_TYPES)
  if(NOT CMAKE_BUILD_TYPE)
    # Encourage user to specify build type.
    message(STATUS "Setting default build type to 'Release'.  Set CMAKE_BUILD_TYPE variable to change build types.")
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY VALUE "Release")
  endif()
endif()

### Compilation flags

#Public flags are necessary to build the library and to build code that links against the library
set(BUFRLIB_PUBLIC_FLAGS DYNAMIC_ALLOCATION)

#Private flags are necessary only when building the library
set(BUFRLIB_PRM bufrlib.prm)
file(READ ${BUFRLIB_PRM} BUFRLIB_PRM_STR)
foreach(_var IN ITEMS MAXNC MXNAF)
    if(BUFRLIB_PRM_STR MATCHES "${_var} = ([0-9]+)")
        list(APPEND BUFRLIB_PRIVATE_FLAGS $<$<COMPILE_LANGUAGE:C>:${_var}=${CMAKE_MATCH_1}>)
    else()
        message(FATAL_ERROR "Unable to parse variable ${_var} value from file: ${BUFRLIB_PRM}")
    endif()
endforeach()

include(TestBigEndian)
TEST_BIG_ENDIAN(IS_BIG_ENDIAN)
if(IS_BIG_ENDIAN)
    list(APPEND BUFRLIB_PRIVATE_FLAGS $<$<COMPILE_LANGUAGE:Fortran>:BIG_ENDIAN>)
else()
    list(APPEND BUFRLIB_PRIVATE_FLAGS $<$<COMPILE_LANGUAGE:Fortran>:LITTLE_ENDIAN>)
endif()

### Global compilation properties
set(BUFRLIB_INCLUDE_DIR bufrlib)
set(CMAKE_Fortran_MODULE_DIRECTORY ${BUFRLIB_INCLUDE_DIR})
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

#Enable interproceedural optimization if abvailible
include(CheckIPOSupported)
check_ipo_supported(RESULT _result OUTPUT _output)
if(_result)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
    message(STATUS "Enabling interproceedural optimization.")
endif()

### Define Library Targets
file(GLOB C_SRC *.c)
file(GLOB C_HDRS *.h)
file(GLOB F_SRC modv*.F moda*.F *.f *.F) #Order of compilation is important

#Add static lib target
add_library(${PROJECT_NAME}_static STATIC ${C_SRC} ${F_SRC})
set(LIB_TARGETS ${PROJECT_NAME}_static)

#Add shared lib target
if(BUILD_SHARED_LIBS)
    add_library(${PROJECT_NAME}_shared SHARED ${C_SRC} ${F_SRC})
    list(APPEND LIB_TARGETS ${PROJECT_NAME}_shared)
endif()

#Set common lib target properties
foreach(_lib IN LISTS LIB_TARGETS)
    target_compile_definitions(${_lib} PUBLIC ${BUFRLIB_PUBLIC_FLAGS} 
                                       PRIVATE ${BUFRLIB_PRIVATE_FLAGS})
endforeach()

### Install
install(TARGETS ${LIB_TARGETS} EXPORT ${PROJECT_NAME}Exports 
        INCLUDES DESTINATION include/${BUFRLIB_INCLUDE_DIR})
install(FILES ${C_HDRS} DESTINATION ${BUFRLIB_INCLUDE_DIR})
install(DIRECTORY ${CMAKE_BINARY_DIR}/${BUFRLIB_INCLUDE_DIR}/ 
        DESTINATION include/${BUFR_INCLUDE_DIR})

### Package config
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion)

export(EXPORT ${PROJECT_NAME}Exports NAMESPACE ${PROJECT_NAME}:: FILE ${PROJECT_NAME}-targets.cmake)

set(CONFIG_INSTALL_DESTINATION share/${PROJECT_NAME}/cmake)

configure_package_config_file(cmake/PackageConfig.cmake.in ${PROJECT_NAME}-config.cmake
                              INSTALL_DESTINATION ${CONFIG_INSTALL_DESTINATION})

install(EXPORT ${PROJECT_NAME}Exports NAMESPACE ${PROJECT_NAME}::
        FILE ${PROJECT_NAME}-targets.cmake
        DESTINATION ${CONFIG_INSTALL_DESTINATION})

