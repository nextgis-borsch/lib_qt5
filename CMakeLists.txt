################################################################################
# Project:  Lib Qt 5
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2018, NextGIS <info@nextgis.com>
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

set(PACKAGE_NAME ${PROJECT_NAME})

include(util)
check_version(QT_MAJOR_VERSION QT_MINOR_VERSION QT_REV_VERSION)
set(VERSION "${QT_MAJOR_VERSION}.${QT_MINOR_VERSION}.${QT_REV_VERSION}")
report_version(${PROJECT_NAME} ${VERSION})

set(SUBFOLDER "single/")
set(CONFIGURE_ARGS -opensource -confirm-license -nomake examples -nomake tests ${QT_CONFIGURE_ARGS})

if(OSX_FRAMEWORK)
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -framework -no-rpath)
elseif(BUILD_SHARED_LIBS)
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -shared)
else()
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -static)
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

# http://download.qt.io/official_releases/qt/5.10/5.10.0/single/qt-everywhere-src-5.10.0.tar.xz
set(QT_INPUT_NAME "qt-everywhere-src-${VERSION}")
set(DOWNLOAD_URL "http://download.qt.io/official_releases/qt/${QT_MAJOR_VERSION}.${QT_MINOR_VERSION}/${VERSION}/${SUBFOLDER}${QT_INPUT_NAME}.tar.xz")
set(OUT_NAME "qt.tar.xz")

if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${OUT_NAME}")
    status_message("Download ${DOWNLOAD_URL}")
    file(DOWNLOAD "${DOWNLOAD_URL}" "${CMAKE_CURRENT_BINARY_DIR}/${OUT_NAME}"
         SHOW_PROGRESS
     )
endif()

include(ProcessorCount)
ProcessorCount(CPU_COUNT)
if(NOT CPU_COUNT OR CPU_COUNT EQUAL 0)
    set(CPU_COUNT 1)
endif()

if(CPU_COUNT GREATER 1 AND WIN32)
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -mp )
endif()

find_package(Git)
if(NOT GIT_FOUND)
  message(FATAL_ERROR "git is required")
endif()

include(FindAnyProject)

find_anyproject(ZLIB DEFAULT ON)
if(ZLIB_FOUND)
    set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${ZLIB_INCLUDE_DIRS})
    if(TARGET ${ZLIB_LIBRARIES})
        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -system-zlib)
        get_target_property(LINK_SEARCH_PATH ${ZLIB_LIBRARIES} IMPORTED_LOCATION_RELEASE)
        get_filename_component(PARENT_DIR ${LINK_SEARCH_PATH} DIRECTORY)

        set(CONFIGURE_ARGS_LINK_LIBS ${CONFIGURE_ARGS_LINK_LIBS} ${PARENT_DIR})

        create_symlink(${PARENT_DIR} "zlib")
        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} "LIBZ_LIBS=\"-lzlib\"")

        # Check if build needed
        build_if_needed(LINK_SEARCH_PATH "ZLIB" CPU_COUNT)
    endif()
endif()

find_anyproject(OpenSSL DEFAULT ON)
if(OPENSSL_FOUND)
    set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${OPENSSL_INCLUDE_DIRS})
    if(TARGET ${OPENSSL_LIBRARIES})
        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -openssl-linked)
        get_target_property(LINK_SEARCH_PATH ${OPENSSL_LIBRARIES} IMPORTED_LOCATION_RELEASE)
        get_filename_component(PARENT_DIR ${LINK_SEARCH_PATH} DIRECTORY)

        set(CONFIGURE_ARGS_LINK_LIBS ${CONFIGURE_ARGS_LINK_LIBS} ${PARENT_DIR})

        create_symlink(${PARENT_DIR} "openssl")
        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} "OPENSSL_LIBS=\"-lopenssl\"")

        # Check if build needed
        build_if_needed(${LINK_SEARCH_PATH} "OpenSSL" ${CPU_COUNT})
    endif()
endif()

find_anyproject(Freetype DEFAULT ON)
if(FREETYPE_FOUND)
    set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${FREETYPE_INCLUDE_DIRS})
    if(TARGET ${FREETYPE_LIBRARIES})
        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -system-freetype)
        get_target_property(LINK_SEARCH_PATH ${OPENSSL_LIBRARIES} IMPORTED_LOCATION_RELEASE)
        get_filename_component(PARENT_DIR ${LINK_SEARCH_PATH} DIRECTORY)

        set(CONFIGURE_ARGS_LINK_LIBS ${CONFIGURE_ARGS_LINK_LIBS} ${PARENT_DIR})

        create_symlink(${PARENT_DIR} "freetype")

        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} "FREETYPE_LIBS=\"-lfreetype\"")

        # Check if build needed
        build_if_needed(${LINK_SEARCH_PATH} "Freetype" ${CPU_COUNT})
    endif()
endif()

# TODO: -harfbuzz ............ Select used HarfBuzz-NG [system/qt/no]

find_anyproject(JPEG DEFAULT ON)
if(JPEG_FOUND)
    set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${JPEG_INCLUDE_DIRS})
    if(TARGET ${JPEG_LIBRARIES})
        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -system-libjpeg)
        get_target_property(LINK_SEARCH_PATH ${OPENSSL_LIBRARIES} IMPORTED_LOCATION_RELEASE)
        get_filename_component(PARENT_DIR ${LINK_SEARCH_PATH} DIRECTORY)

        set(CONFIGURE_ARGS_LINK_LIBS ${CONFIGURE_ARGS_LINK_LIBS} ${PARENT_DIR})

        create_symlink(${PARENT_DIR} "jpeg")

        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} "LIBJPEG_LIBS=\"-ljpeg\"")

        # Check if build needed
        build_if_needed(${LINK_SEARCH_PATH} "JPEG" ${CPU_COUNT})
    endif()
endif()

find_anyproject(PNG DEFAULT ON)
if(PNG_FOUND)
    set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${PNG_INCLUDE_DIRS})
    if(TARGET ${PNG_LIBRARIES})
        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -system-libpng)
        get_target_property(LINK_SEARCH_PATH ${OPENSSL_LIBRARIES} IMPORTED_LOCATION_RELEASE)
        get_filename_component(PARENT_DIR ${LINK_SEARCH_PATH} DIRECTORY)

        set(CONFIGURE_ARGS_LINK_LIBS ${CONFIGURE_ARGS_LINK_LIBS} ${PARENT_DIR})

        create_symlink(${PARENT_DIR} "png")

        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} "LIBPNG_LIBS=\"-lpng\"")

        # Check if build needed
        build_if_needed(${LINK_SEARCH_PATH} "PNG" ${CPU_COUNT})
    endif()
endif()

# find_anyproject(TIFF DEFAULT ON)
# if(TIFF_FOUND)
#     set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${TIFF_INCLUDE_DIRS})
#     if(TARGET ${TIFF_LIBRARIES})
#         if(WIN32)
#             get_target_property(LINK_SEARCH_PATH ${TIFF_LIBRARIES} IMPORTED_IMPLIB_RELEASE)
#         else()
#             get_target_property(LINK_SEARCH_PATH ${TIFF_LIBRARIES} LOCATION)
#         endif()
#         get_filename_component(PARENT_DIR ${LINK_SEARCH_PATH} DIRECTORY)
#         set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -L ${PARENT_DIR})
#
#         if(WIN32)
#             warning_message("Copy ${LINK_SEARCH_PATH}")
#             execute_process(COMMAND ${CMAKE_COMMAND} -E copy ${LINK_SEARCH_PATH} ${PARENT_DIR}/libtiff.lib)
#         endif()
#
#         create_symlink(${PARENT_DIR} "tiff")
#     endif()
# endif()
#
# find_anyproject(GIF DEFAULT ON)
# if(GIF_FOUND)
#     set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${GIF_INCLUDE_DIRS})
#     if(TARGET ${GIF_LIBRARIES})
#         set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -system-gif)
#         if(WIN32)
#             get_target_property(LINK_SEARCH_PATH ${GIF_LIBRARIES} IMPORTED_IMPLIB_RELEASE)
#         else()
#             get_target_property(LINK_SEARCH_PATH ${GIF_LIBRARIES} LOCATION)
#         endif()
#         get_filename_component(PARENT_DIR ${LINK_SEARCH_PATH} DIRECTORY)
#         if(OSX_FRAMEWORK)
#             set(CONFIGURE_ARGS_LINK_LIBS ${CONFIGURE_ARGS_LINK_LIBS} ${PARENT_DIR})
#         endif()
#     endif()
# endif()

find_anyproject(SQLite3 DEFAULT ON)
if(SQLITE3_FOUND)
    set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${SQLITE3_INCLUDE_DIRS})
    if(TARGET ${SQLITE3_LIBRARIES})
        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -system-sqlite)
        get_target_property(LINK_SEARCH_PATH ${OPENSSL_LIBRARIES} IMPORTED_LOCATION_RELEASE)
        get_filename_component(PARENT_DIR ${LINK_SEARCH_PATH} DIRECTORY)

        set(CONFIGURE_ARGS_LINK_LIBS ${CONFIGURE_ARGS_LINK_LIBS} ${PARENT_DIR})

        create_symlink(${PARENT_DIR} "sqlite3")

        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} "SQLITE_LIBS=\"-lsqlite3\"")

        # Check if build needed
        build_if_needed(${LINK_SEARCH_PATH} "SQLite3" ${CPU_COUNT})
    endif()
endif()

find_anyproject(PostgreSQL DEFAULT ON)
if(POSTGRESQL_FOUND)
    set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${POSTGRESQL_INCLUDE_DIRS})
    if(TARGET ${POSTGRESQL_LIBRARIES})
        # set(CONFIGURE_ARGS ${CONFIGURE_ARGS} -feature-psql)
        get_target_property(LINK_SEARCH_PATH ${OPENSSL_LIBRARIES} IMPORTED_LOCATION_RELEASE)
        get_filename_component(PARENT_DIR ${LINK_SEARCH_PATH} DIRECTORY)

        set(CONFIGURE_ARGS_LINK_LIBS ${CONFIGURE_ARGS_LINK_LIBS} ${PARENT_DIR})

        create_symlink(${PARENT_DIR} "pq")

        set(CONFIGURE_ARGS ${CONFIGURE_ARGS} "PSQL_LIBS=\"-lpq\"")

        # Check if build needed
        build_if_needed(${LINK_SEARCH_PATH} "PostgreSQL" ${CPU_COUNT})
    endif()
endif()

foreach(CONF_INC_DIR ${CONFIGURE_ARGS_INCLUDE_DIRS})
    list(APPEND CONFIGURE_ARGS -I${CONF_INC_DIR})
endforeach()

foreach(CONF_LINK_LIB ${CONFIGURE_ARGS_LINK_LIBS})
    # if(OSX_FRAMEWORK)
        # list(APPEND CONFIGURE_ARGS -F${CONF_LINK_LIB})
    # else()
        list(APPEND CONFIGURE_ARGS -L${CONF_LINK_LIB})
    # endif()
endforeach()

if(WIN32)
    set(CONFIGURE_CMD_NAME configure.bat)
else()
    set(CONFIGURE_CMD_NAME configure)
endif()

message(STATUS "Configure args: ${CONFIGURE_ARGS}")

if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME})
    status_message("Extract ${CMAKE_CURRENT_BINARY_DIR}/${OUT_NAME}")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_CURRENT_BINARY_DIR}/${OUT_NAME})
endif()

if(APPLE)
    # https://bugreports.qt.io/browse/QTBUG-65075
    status_message("Apply patch ${CMAKE_CURRENT_SOURCE_DIR}/patch/mac3.patch")
    execute_process(COMMAND ${GIT_EXECUTABLE} apply -v ${CMAKE_CURRENT_SOURCE_DIR}/patch/mac3.patch
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}
    )
endif()

status_message("Configure in ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}")

if(WIN32)
    get_filename_component(VC_COMPILER_DIR ${CMAKE_CXX_COMPILER} DIRECTORY)
    message(STATUS "VC_COMPILER_DIR: ${VC_COMPILER_DIR}")
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

    set(CONFIGURE_CMD ${VCVARSALL_BAT} ${VCVARSALL_BAT_ARG} && ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/${CONFIGURE_CMD_NAME} ${CONFIGURE_ARGS})

    execute_process(
        COMMAND ${CONFIGURE_CMD} -prefix ${CMAKE_INSTALL_PREFIX}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}
    )

    add_custom_target(build_qt ALL
        COMMAND ${VCVARSALL_BAT} ${VCVARSALL_BAT_ARG} && nmake
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}
        COMMENT "${VCVARSALL_BAT} ${VCVARSALL_BAT_ARG} && nmake"
        VERBATIM
    )
    install(CODE "execute_process(
        COMMAND ${VCVARSALL_BAT} ${VCVARSALL_BAT_ARG} && nmake install
        WORKING_DIRECTORY  ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}
        )"
    )
else()
    set(CONFIGURE_CMD ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/${CONFIGURE_CMD_NAME} ${CONFIGURE_ARGS})

    execute_process(
        COMMAND ${CONFIGURE_CMD} -prefix ${CMAKE_INSTALL_PREFIX}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}
    )

    add_custom_target(build_qt ALL
        COMMAND make -j ${CPU_COUNT}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}
        COMMENT "${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/make -j ${CPU_COUNT}"
        VERBATIM
    )
    install(CODE "execute_process(
        COMMAND make install
        WORKING_DIRECTORY  ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}
        )"
    )
endif()

# Get cpack zip archive name
get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)

# Hack for qt make routine
if(CREATE_CPACK_LIGHT)
    if(WIN32)
        set(EXT ".exe")
    endif()
    set(PACK_FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qttools/bin/lconvert${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qttools/bin/lrelease${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qttools/bin/lupdate${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qttools/bin/qtplugininfo${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qttools/bin/qtdiag${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qttools/bin/qtpaths${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qtbase/bin/qmake${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qtbase/bin/moc${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qtbase/bin/qlalr${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qtbase/bin/qvkgen${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qtbase/bin/rcc${EXT}
        ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qtbase/bin/uic${EXT}
    )

    add_custom_target(create_light_pack ALL
        COMMAND ${CMAKE_COMMAND} -E tar "cfv" "${PROJECT_CPACK_FILENAME}.zip" --format=zip
        DEPENDS build_qt
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )

endif()

if(OSX_FRAMEWORK)
    # TODO: Fix hardcoded to real install path
    find_package(PythonInterp REQUIRED)
    install(CODE "execute_process(COMMAND ${PYTHON_EXECUTABLE} ${CMAKE_SOURCE_DIR}/cmake/mac_rpath_fix.py
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )"
    )
endif()

if (REGISTER_PACKAGE)
    # Export the package for use from the build-tree
    # (this registers the build-tree with a global CMake-registry)

    set(PACKAGE_NAME Qt5)
    string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)
    set(PACKAGE_PREFIX ${CMAKE_CURRENT_BINARY_DIR}/${QT_INPUT_NAME}/qtbase)

    export(PACKAGE ${PACKAGE_NAME})

    include(CMakePackageConfigHelpers)
    configure_package_config_file(
        ${CMAKE_SOURCE_DIR}/cmake/PackageConfig.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake
        INSTALL_DESTINATION ${CMAKE_CURRENT_BINARY_DIR} )
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake
        VERSION ${VERSION}
        COMPATIBILITY AnyNewerVersion )
endif()

# Archiving ====================================================================

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

if(NOT CREATE_CPACK)
    # Reconfig qt to new install path in CPack. Reconfig need make clean?
    configure_file("${PROJECT_SOURCE_DIR}/cmake/qt_conf.cmake.in" "${CMAKE_CURRENT_BINARY_DIR}/qt_conf.cmake" @ONLY)
    set(CPACK_INSTALL_SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/qt_conf.cmake)
endif()

include (CPack)
