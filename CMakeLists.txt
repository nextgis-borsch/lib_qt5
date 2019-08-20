################################################################################
# Project:  Lib Qt 5
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2018-2019, NextGIS <info@nextgis.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################
cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(qt5)

if(NOT DEFINED PACKAGE_VENDOR)
    set(PACKAGE_VENDOR NextGIS)
endif()

if(NOT DEFINED PACKAGE_BUGREPORT)
    set(PACKAGE_BUGREPORT info@nextgis.com)
endif()

# some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

set(INSTALL_CMAKECONF_DIR CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)


set(PACKAGE_NAME ${PROJECT_NAME})
string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)

include(util)
check_version(QT_MAJOR_VERSION QT_MINOR_VERSION QT_REV_VERSION)
set(VERSION "${QT_MAJOR_VERSION}.${QT_MINOR_VERSION}.${QT_REV_VERSION}")
report_version(${PROJECT_NAME} ${VERSION})

set(SUBFOLDER "single/")
set(CONFIGURE_ARGS -opensource -confirm-license -nomake examples -nomake tests -silent ${QT_CONFIGURE_ARGS})

if(OSX_FRAMEWORK)
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -framework -no-rpath)
elseif(BUILD_SHARED_LIBS)
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -shared)
else()
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -static)
    # if(WIN32)   # Switch /MD to /MT
    #     set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -static-runtime)
    # endif()
endif()

if(WIN32)
    if(MSVC)
        # Visual Studio 2005	Whidbey	8.0	             1400
        # Visual Studio 2008	Orcas	9.0 	         1500
        # Visual Studio 2010	Dev10/Rosario	10.0     1600
        # Visual Studio 2012	Dev11	11.0             1700
        # Visual Studio 2013	Dev12	12.0             1800
        # Visual Studio 2015	Dev14	14.0             1900
        # Visual Studio 2017	Dev15	15.0             1910-1919
        if(MSVC_VERSION EQUAL 1400)
            set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -platform win32-msvc2005)
        elseif(MSVC_VERSION EQUAL 1500)
            set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -platform win32-msvc2008)
        elseif(MSVC_VERSION EQUAL 1600)
            set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -platform win32-msvc2010)
        elseif(MSVC_VERSION EQUAL 1700)
            set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -platform win32-msvc2012)
        elseif(MSVC_VERSION EQUAL 1800)
            set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -platform win32-msvc2013)
        elseif(MSVC_VERSION EQUAL 1900)
            set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -platform win32-msvc2015)
        elseif(MSVC_VERSION GREATER 1900)
            set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -platform win32-msvc2017)
        endif()
    endif()
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -debug)
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -debug-and-release)
else()
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -release -strip)
endif()

include(ProcessorCount)
ProcessorCount(CPU_COUNT)
if(NOT CPU_COUNT OR CPU_COUNT EQUAL 0)
    set(CPU_COUNT 1)
endif()

if(CPU_COUNT GREATER 1 AND WIN32)
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -mp)
endif()

if(WIN32)
    file(REMOVE_RECURSE "$ENV{USERPROFILE}\\source")
endif()

include(FindAnyProject)

file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/project_lib)

if(WIN32)
    find_anyproject(ZLIB DEFAULT ON)
    if(ZLIB_FOUND)
        add_dependency(ZLIB -system-zlib "${ZLIB_INCLUDE_DIRS}" "${ZLIB_LIBRARIES}")
    endif()
endif()

if(OSX_FRAMEWORK OR WIN32)
    find_anyproject(OpenSSL DEFAULT ON)
    if(OPENSSL_FOUND)
        add_dependency(OPENSSL -openssl-linked "${OPENSSL_INCLUDE_DIRS}" "${OPENSSL_LIBRARIES}")
    endif()
endif()

find_anyproject(Freetype DEFAULT ON)
if(FREETYPE_FOUND)
    add_dependency(FREETYPE -system-freetype "${FREETYPE_INCLUDE_DIRS}" "${FREETYPE_LIBRARIES}")
endif()

if(NOT APPLE)
    find_anyproject(HarfBuzz DEFAULT ON)
    if(HARFBUZZ_FOUND)
        add_dependency(HARFBUZZ -system-harfbuzz "${HARFBUZZ_INCLUDE_DIRS}" "${HARFBUZZ_LIBRARIES}")
        # file(MAKE_DIRECTORY ${HARFBUZZ_INCLUDE_DIRS}/harfbuzz)
        #execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${HARFBUZZ_INCLUDE_DIRS} ${HARFBUZZ_INCLUDE_DIRS}/harfbuzz)
    endif()
endif()

find_anyproject(JPEG DEFAULT ON)
if(JPEG_FOUND)
    add_dependency(LIBJPEG -system-libjpeg "${JPEG_INCLUDE_DIRS}" "${JPEG_LIBRARIES}")
endif()

find_anyproject(PNG DEFAULT ON)
if(PNG_FOUND)
    add_dependency(LIBPNG -system-libpng "${PNG_INCLUDE_DIRS}" "${PNG_LIBRARIES}")
endif()

find_anyproject(TIFF DEFAULT ON)
if(TIFF_FOUND)
    add_dependency(TIFF -system-tiff "${TIFF_INCLUDE_DIRS}" "${TIFF_LIBRARIES}")
endif()

find_anyproject(WEBP DEFAULT ON)
find_anyproject(WEBPDEMUX DEFAULT ON)
find_anyproject(WEBPMUX DEFAULT ON)
if(WEBP_FOUND AND WEBPDEMUX_FOUND AND WEBPMUX_FOUND)
    set(W_INC_DIRS ${WEBP_INCLUDE_DIRS} ${WEBPDEMUX_INCLUDE_DIRS} ${WEBPMUX_INCLUDE_DIRS})
    set(W_LIBRARIES ${WEBP_LIBRARIES} ${WEBPDEMUX_LIBRARIES} ${WEBPMUX_LIBRARIES})
    add_dependency(WEBP -system-webp "${W_INC_DIRS}" "${W_LIBRARIES}")
endif()

# find_anyproject(GIF DEFAULT ON)
# if(GIF_FOUND)
#     add_dependency(${GIF_INCLUDE_DIRS} ${GIF_LIBRARIES} -system-gif)
# endif()

find_anyproject(SQLite3 DEFAULT ON)
if(SQLITE3_FOUND)
    add_dependency(SQLITE "-system-sqlite;-sql-sqlite" "${SQLITE3_INCLUDE_DIRS}" "${SQLITE3_LIBRARIES}")
endif()

find_anyproject(PostgreSQL DEFAULT ON NAMES PQ pq libpq)
if(POSTGRESQL_FOUND)
    add_dependency(PSQL -sql-psql "${POSTGRESQL_INCLUDE_DIRS}" "${POSTGRESQL_LIBRARIES}")
endif()

foreach(CONF_INC_DIR ${CONFIGURE_ARGS_INCLUDE_DIRS})
    list(APPEND CONFIGURE_ARGS -I${CONF_INC_DIR})
endforeach()

if(OSX_FRAMEWORK)
    list(APPEND CONFIGURE_ARGS -L${PROJECT_BINARY_DIR}/project_lib)
else()
    foreach(CONF_LINK_LIB ${CONFIGURE_ARGS_LINK_LIBS})
        list(APPEND CONFIGURE_ARGS -L${CONF_LINK_LIB})
    endforeach()
endif()

if(WIN32)
    set(CONFIGURE_CMD_NAME configure.bat)
else()
    set(CONFIGURE_CMD_NAME configure)
endif()

# http://download.qt.io/official_releases/qt/5.10/5.10.0/single/qt-everywhere-src-5.10.0.tar.xz
# http://download.qt.io/official_releases/qt/5.9/5.9.4/single/qt-everywhere-opensource-src-5.9.4.tar.xz

if(VERSION VERSION_LESS "5.10.0")
    set(QT_INPUT_NAME "qt-everywhere-opensource-src-${VERSION}")
else()
    set(QT_INPUT_NAME "qt-everywhere-src-${VERSION}")
endif()

if(WIN32)
    if(CMAKE_CL_64)
        set(ARCH_OUT_DIR "C:/t64")
    else()
        set(ARCH_OUT_DIR "C:/t32")
    endif()
    file(MAKE_DIRECTORY ${ARCH_OUT_DIR})
else()
    set(ARCH_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
endif()

set(DOWNLOAD_URL "http://download.qt.io/official_releases/qt/${QT_MAJOR_VERSION}.${QT_MINOR_VERSION}/${VERSION}/${SUBFOLDER}${QT_INPUT_NAME}.tar.xz")
set(OUT_NAME "qt.tar.xz")

message(STATUS "Configure args: ${CONFIGURE_ARGS}")
status_message("Configure in ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}")

if(NOT EXISTS "${ARCH_OUT_DIR}/${OUT_NAME}")
    status_message("Download ${DOWNLOAD_URL}")
    file(DOWNLOAD "${DOWNLOAD_URL}" "${ARCH_OUT_DIR}/${OUT_NAME}"
         SHOW_PROGRESS
    )
    status_message("Downloaded ...")
endif()

# Make path shorter: https://forum.qt.io/topic/86079/qtwebengine-build-failed-on-gn-bootstrap-py/4
set(QT_INPUT_NAME_NEW q)
if(NOT EXISTS ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW})
    status_message("Extract ${ARCH_OUT_DIR}/${OUT_NAME}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf ${ARCH_OUT_DIR}/${OUT_NAME}
        WORKING_DIRECTORY ${ARCH_OUT_DIR}
    )
    status_message("Extract finished ...")
    file(RENAME ${ARCH_OUT_DIR}/${QT_INPUT_NAME} ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW})
endif()

# Copy zlib1.dll to make  moc.exe, rcc.exe, etc. working
if(WIN32 AND ZLIB_FOUND)
    warning_message("Copy ${ZLIB_LIB_PATH} to ${ARCH_OUT_DIR}\\${QT_INPUT_NAME_NEW}\\qtbase\\bin")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E make_directory "${ARCH_OUT_DIR}\\${QT_INPUT_NAME_NEW}\\qtbase\\bin"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ZLIB_LIB_PATH} "${ARCH_OUT_DIR}\\${QT_INPUT_NAME_NEW}\\qtbase\\bin\\zlib1.dll"
    )
    if(NOT EXISTS ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}/qtbase/bin/zlib1.dll)
        message(FATAL_ERROR "${ARCH_OUT_DIR}\\${QT_INPUT_NAME_NEW}\\qtbase\\bin\\zlib1.dll not exists!")
    endif()

    warning_message("Copy ${ZLIB_LIB_PATH} to $ENV{USERPROFILE}\\source\\qtbase\\bin\\")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E make_directory "$ENV{USERPROFILE}\\source" "$ENV{USERPROFILE}\\source\\qtbase" "$ENV{USERPROFILE}\\source\\qtbase\\bin"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ZLIB_LIB_PATH} "$ENV{USERPROFILE}\\source\\qtbase\\bin\\zlib1.dll"
    )
    if(NOT EXISTS $ENV{USERPROFILE}/source/qtbase/bin/zlib1.dll)
        message(FATAL_ERROR "$ENV{USERPROFILE}\\source\\qtbase\\bin\\zlib1.dll not exists!")
    endif()
endif()

find_package(Git)
if(NOT GIT_FOUND)
  message(FATAL_ERROR "git is required")
endif()

if(OPENSSL_FOUND AND OPENSSL_VERSION VERSION_GREATER "1.0.2" AND QT_MINOR_VERSION LESS 10)
    # Apply patch for 1.1
    status_message("Apply patch ${CMAKE_CURRENT_SOURCE_DIR}/patch/openssl11.patch")
    execute_process(COMMAND ${GIT_EXECUTABLE} apply --ignore-whitespace -v ${CMAKE_CURRENT_SOURCE_DIR}/patch/openssl11.patch
        WORKING_DIRECTORY ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}
        OUTPUT_QUIET ERROR_QUIET
    )
endif()

set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}/inst)

if(WIN32)
    get_filename_component(VC_COMPILER_DIR ${CMAKE_CXX_COMPILER} DIRECTORY)
    find_file(VCVARSALL_BAT
        NAMES vsdevcmd.bat vcvarsall.bat
        PATHS "${VC_COMPILER_DIR}/.." "${VC_COMPILER_DIR}/../.." "${VC_COMPILER_DIR}/../../../../../../../.." "${VC_COMPILER_DIR}/../../../../../../.."
        PATH_SUFFIXES "Common7/Tools" "Tools"
    )

    if(DEFINED CMAKE_GENERATOR)
        # TODO: Need different arguments for vsdevcmd.bat and vcvarsall.bat. Now support only VC2017
        string(FIND ${CMAKE_GENERATOR} "Win64" POS)
        if(POS GREATER -1)
            set(VCVARSALL_BAT_ARG -arch=amd64)
        else()
            set(VCVARSALL_BAT_ARG -arch=x86)
        endif()
    endif()

    message(STATUS "VCVARSALL_BAT: ${VCVARSALL_BAT} ${VCVARSALL_BAT_ARG}")

    set(CONFIGURE_CMD ${VCVARSALL_BAT} ${VCVARSALL_BAT_ARG} && ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}/${CONFIGURE_CMD_NAME} ${CONFIGURE_ARGS})

    execute_process(
        COMMAND ${CONFIGURE_CMD} -prefix ${CMAKE_INSTALL_PREFIX}
        WORKING_DIRECTORY ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}
    )

    add_custom_target(build_qt ALL
        COMMAND ${VCVARSALL_BAT} ${VCVARSALL_BAT_ARG} && nmake
        WORKING_DIRECTORY ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}
        COMMENT "${VCVARSALL_BAT} ${VCVARSALL_BAT_ARG} && nmake"
        VERBATIM
    )
else()
    set(CONFIGURE_CMD ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}/${CONFIGURE_CMD_NAME} ${CONFIGURE_ARGS})

    execute_process(
        COMMAND ${CONFIGURE_CMD} -prefix ${CMAKE_INSTALL_PREFIX}
        WORKING_DIRECTORY ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}
    )

    add_custom_target(build_qt ALL
        COMMAND make -j ${CPU_COUNT}
        WORKING_DIRECTORY ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}
        COMMENT "${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}/make -j ${CPU_COUNT}"
        VERBATIM
    )
endif()

# Get cpack archive name
get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)

if(WIN32)
    set(MAKE_CMD ${VCVARSALL_BAT} ${VCVARSALL_BAT_ARG} && nmake install)
else()
    set(MAKE_CMD make install)
endif()

add_custom_target(preinstall_qt ALL
    COMMAND ${MAKE_CMD}
    DEPENDS build_qt
    WORKING_DIRECTORY ${ARCH_OUT_DIR}/${QT_INPUT_NAME_NEW}
)

if(OSX_FRAMEWORK)
    find_package(PythonInterp REQUIRED)
    # FIXME: Uncomment fix path for zlib if WITH_ZLIB_EXTERNAL=ON
    install(CODE "execute_process(COMMAND ${PYTHON_EXECUTABLE} ${CMAKE_SOURCE_DIR}/cmake/mac_rpath_fix.py
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        )"
    )
endif()


if(REGISTER_PACKAGE)
    # Export the package for use from the build-tree
    # (this registers the build-tree with a global CMake-registry)
    export(PACKAGE ${PACKAGE_UPPER_NAME})
endif()


# Create the <Package>Config.cmake file
configure_file(cmake/PackageConfigCurrent.cmake.in
    ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake @ONLY)
configure_file(cmake/PackageConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/inst/CMake/${PACKAGE_UPPER_NAME}Config.cmake @ONLY)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL )
    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/inst/ DESTINATION "." USE_SOURCE_PERMISSIONS)
endif()

# Hack for qt make routine
if(CREATE_CPACK_LIGHT)
    add_custom_target(create_light_pack ALL
        COMMAND ${CMAKE_COMMAND} -E tar "cfv" "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_CPACK_FILENAME}.zip" --format=zip "${CMAKE_CURRENT_BINARY_DIR}/inst/bin"
        DEPENDS preinstall_qt
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
endif()

# Archiving ====================================================================

if(NOT CREATE_CPACK_LIGHT)
    set(CPACK_PACKAGE_NAME "${PACKAGE_NAME}")
    set(CPACK_PACKAGE_VENDOR "${PACKAGE_VENDOR}")
    set(CPACK_PACKAGE_VERSION "${VERSION}")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PACKAGE_NAME} Installation")
    set(CPACK_PACKAGE_RELOCATABLE TRUE)
    set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
    set(CPACK_GENERATOR "ZIP")
    set(CPACK_MONOLITHIC_INSTALL ON)
    set(CPACK_STRIP_FILES TRUE)

    set(CPACK_PACKAGE_FILE_NAME ${PROJECT_CPACK_FILENAME})

    include (CPack)
endif()
