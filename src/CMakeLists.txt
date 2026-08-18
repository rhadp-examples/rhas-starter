cmake_minimum_required(VERSION 3.14)
project(auto-app VERSION 0.1.0 LANGUAGES CXX)

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT DEFINED APP_VERSION)
    set(APP_VERSION "${PROJECT_VERSION}")
endif()

if(NOT DEFINED APP_GIT_REV)
    execute_process(
        COMMAND git rev-parse --short HEAD
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE APP_GIT_REV
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    if(NOT APP_GIT_REV)
        set(APP_GIT_REV "unknown")
    endif()
endif()

add_executable(auto-app main.cpp)

target_compile_definitions(auto-app PRIVATE
    APP_VERSION="${APP_VERSION}"
    APP_GIT_REV="${APP_GIT_REV}"
)

install(
    TARGETS auto-app
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT bin
)
