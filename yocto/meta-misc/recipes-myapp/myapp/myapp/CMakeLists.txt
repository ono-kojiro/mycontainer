cmake_minimum_required(VERSION 3.19)

project(myapp)

add_executable(myapp myapp.c)

target_include_directories(myapp
  PUBLIC ../libmylib-cmake)

target_link_directories(myapp
  PUBLIC ../libmylib-cmake)

target_link_libraries(myapp
  PUBLIC mylib)

install(TARGETS myapp ARCHIVE DESTINATION ${INSTALL_LIB_DIR})

