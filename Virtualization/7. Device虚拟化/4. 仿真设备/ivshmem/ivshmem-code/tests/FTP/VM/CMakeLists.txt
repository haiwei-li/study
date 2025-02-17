cmake_minimum_required(VERSION 2.6)
project(campino)

add_executable(ftp_recv ftp_recv)
add_executable(ftp_send ftp_send)
add_library(ivshmem ivshmem)

set(CMAKE_C_FLAGS_DEBUG "-DDEBUG")
set(CMAKE_C_FLAGS "-std=c99 -g -Wall -D_GNU_SOURCE")
target_link_libraries(ftp_recv ivshmem rt crypto pthread)
target_link_libraries(ftp_send ivshmem rt crypto pthread)

