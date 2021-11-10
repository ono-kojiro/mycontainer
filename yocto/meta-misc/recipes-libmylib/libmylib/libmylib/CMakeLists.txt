cmake_minimum_required(VERSION 3.19)

project(mylib)

add_library(mylib mylib.c)

install(TARGETS mylib ARCHIVE DESTINATION ${INSTALL_LIB_DIR})
install(FILES mylib.h DESTINATION include)

