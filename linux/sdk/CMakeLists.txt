cmake_minimum_required(VERSION 3.0.0)

set(CMAKE_CXX_STANDARD 11)
add_compile_options(-std=c++11)

include_directories(../driver/)
add_library(file_intf SHARED file_intf.cpp)
add_library(file_intf_static STATIC file_intf.cpp)
add_executable(demo demo.cpp)
target_link_libraries(demo file_intf_static)

install(TARGETS demo file_intf file_intf_static
    RUNTIME DESTINATION ./out
    LIBRARY DESTINATION ./out
    ARCHIVE DESTINATION ./out
)
install(FILES file_intf.hpp DESTINATION ./out)