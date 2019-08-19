################################################################################
# Project:  borsch
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

function(check_version major minor rev)

    set(CHECK_FILE ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt)
    set(MAJOR_VERSION 5)
    set(MINOR_VERSION 13)
    set(REV_VERSION 0)

    set(${major} ${MAJOR_VERSION} PARENT_SCOPE)
    set(${minor} ${MINOR_VERSION} PARENT_SCOPE)
    set(${rev} ${REV_VERSION} PARENT_SCOPE)

    # Store version string in file for installer needs
    file(TIMESTAMP ${CHECK_FILE} VERSION_DATETIME "%Y-%m-%d %H:%M:%S" UTC)
    set(VERSION ${MAJOR_VERSION}.${MINOR_VERSION}.${REV_VERSION})
    get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
    file(WRITE ${CMAKE_BINARY_DIR}/version.str "${VERSION}\n${VERSION_DATETIME}\n${PROJECT_CPACK_FILENAME}")

endfunction(check_version)


function(report_version name ver)

    string(ASCII 27 Esc)
    set(BoldYellow  "${Esc}[1;33m")
    set(ColourReset "${Esc}[m")

    message("${BoldYellow}${name} version ${ver}${ColourReset}")

endfunction()


function(status_message text)

    string(ASCII 27 Esc)
    set(BoldGreen   "${Esc}[1;32m")
    set(ColourReset "${Esc}[m")

    message("${BoldGreen}${text}${ColourReset}")

endfunction()

function(warning_message text)

    string(ASCII 27 Esc)
    set(BoldBlue   "${Esc}[1;34m")
    set(ColourReset "${Esc}[m")

    message(STATUS "${BoldGreen}${text}${ColourReset}")

endfunction()

macro(create_symlink PATH_TO_LIB LIB_NAME)
    if(OSX_FRAMEWORK)
        warning_message("Create symlink lib${LIB_NAME}.dylib")
        execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${PATH_TO_LIB} ${PROJECT_BINARY_DIR}/project_lib/lib${LIB_NAME}.dylib)
    endif()
endmacro()

macro(build_if_needed PATH NAME CPU_COUNT)
    if(NOT EXISTS ${PATH})
        if(UNIX)
            set(OPTIONAL_ARGS "--" "-j${CPU_COUNT}")
        endif()

        if(EXISTS ${CMAKE_BINARY_DIR}/third-party/build/${NAME}_EP-build)
			set(WD ${CMAKE_BINARY_DIR}/third-party/build/${NAME}_EP-build)
		elseif(EXISTS ${CMAKE_BINARY_DIR}/../${NAME}_EP-build)
			set(WD ${CMAKE_BINARY_DIR}/../${NAME}_EP-build)
        else()
            message(FATAL_ERROR "Not found working directory ${${NAME}_EP-build}")
		endif()

        execute_process(COMMAND ${CMAKE_COMMAND} --build . --config Release ${OPTIONAL_ARGS}
            WORKING_DIRECTORY ${WD}
            RESULT_VARIABLE EXECUTE_RESULT_CODE
        )

        if(NOT ${EXECUTE_RESULT_CODE} EQUAL 0)
            message(FATAL_ERROR "Build ${NAME} failed")
        endif()
    endif()
endmacro()

macro(add_dependency PREFIX ARGS DEPENDENCY_INCLUDE_DIRS DEPENDENCY_LIBRARIES)
    # DEBUG: message("PREFIX ${PREFIX}\nARGS ${ARGS}\nDEPENDENCY_INCLUDE_DIRS ${DEPENDENCY_INCLUDE_DIRS}\nDEPENDENCY_LIBRARIES ${DEPENDENCY_LIBRARIES}")
    set(CONFIGURE_ARGS_INCLUDE_DIRS ${CONFIGURE_ARGS_INCLUDE_DIRS} ${DEPENDENCY_INCLUDE_DIRS})
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} ${ARGS})
    set(_LIBS)   
    
    foreach(DEPENDENCY_LIBRARY ${DEPENDENCY_LIBRARIES})
        get_target_property(LINK_SEARCH_PATH ${DEPENDENCY_LIBRARY} IMPORTED_LOCATION_RELEASE)

        # DEBUG: message("LINK_SEARCH_PATH ${LINK_SEARCH_PATH}")

        set(${PREFIX}_LIB_PATH ${LINK_SEARCH_PATH})
        if(OSX_FRAMEWORK)
            create_symlink(${LINK_SEARCH_PATH} "${DEPENDENCY_LIBRARY}")
            set(_LIBS "${_LIBS}-l${DEPENDENCY_LIBRARY} ")
        elseif(WIN32)
            get_target_property(LINK_L_PATH ${DEPENDENCY_LIBRARY} IMPORTED_IMPLIB_RELEASE)
            get_filename_component(LINK_NAME ${LINK_L_PATH} NAME_WE)
            get_filename_component(LINK_LIBS_DIR ${LINK_L_PATH} PATH)

            # DEBUG: message("LINK_L_PATH ${LINK_L_PATH}; LINK_NAME ${LINK_NAME}; LINK_LIBS_DIR ${LINK_LIBS_DIR}")

            set(CONFIGURE_ARGS_LINK_LIBS ${CONFIGURE_ARGS_LINK_LIBS} ${LINK_LIBS_DIR})
            
            message("Check ${LINK_LIBS_DIR}/${LINK_NAME}.lib")
            if(EXISTS "${LINK_LIBS_DIR}/${LINK_NAME}.lib")
                set(_LIBS "${_LIBS}-l${LINK_NAME} ")
            endif()
        endif()
    endforeach()    
    set(CONFIGURE_ARGS ${CONFIGURE_ARGS} "${PREFIX}_LIBS=${_LIBS}")
endmacro()


# macro to find packages on the host OS
macro( find_exthost_package )
    if(CMAKE_CROSSCOMPILING)
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )

        find_package( ${ARGN} )

        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
    else()
        find_package( ${ARGN} )
    endif()
endmacro()

# macro to find programs on the host OS
macro( find_exthost_program )
    if(CMAKE_CROSSCOMPILING)
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )

        find_program( ${ARGN} )

        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
    else()
        find_program( ${ARGN} )
    endif()
endmacro()

function(get_prefix prefix IS_STATIC)
  if(IS_STATIC)
    set(STATIC_PREFIX "static-")
      if(ANDROID)
        set(STATIC_PREFIX "${STATIC_PREFIX}android-${ANDROID_ABI}-")
      elseif(IOS)
        set(STATIC_PREFIX "${STATIC_PREFIX}ios-${IOS_ARCH}-")
      endif()
    endif()
  set(${prefix} ${STATIC_PREFIX} PARENT_SCOPE)
endfunction()


function(get_cpack_filename ver name)
    get_compiler_version(COMPILER)

    if(NOT DEFINED BUILD_STATIC_LIBS)
      set(BUILD_STATIC_LIBS OFF)
    endif()

    get_prefix(STATIC_PREFIX ${BUILD_STATIC_LIBS})

    set(${name} ${PACKAGE_NAME}-${ver}-${STATIC_PREFIX}${COMPILER} PARENT_SCOPE)
endfunction()

function(get_compiler_version ver)
    ## Limit compiler version to 2 or 1 digits
    string(REPLACE "." ";" VERSION_LIST ${CMAKE_C_COMPILER_VERSION})
    list(LENGTH VERSION_LIST VERSION_LIST_LEN)
    if(VERSION_LIST_LEN GREATER 2 OR VERSION_LIST_LEN EQUAL 2)
        list(GET VERSION_LIST 0 COMPILER_VERSION_MAJOR)
        list(GET VERSION_LIST 1 COMPILER_VERSION_MINOR)
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${COMPILER_VERSION_MAJOR}.${COMPILER_VERSION_MINOR})
    else()
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${CMAKE_C_COMPILER_VERSION})
    endif()

    if(WIN32)
        if(CMAKE_CL_64)
            set(COMPILER "${COMPILER}-64bit")
        endif()
    endif()
    
    set(${ver} ${COMPILER} PARENT_SCOPE)
endfunction()
