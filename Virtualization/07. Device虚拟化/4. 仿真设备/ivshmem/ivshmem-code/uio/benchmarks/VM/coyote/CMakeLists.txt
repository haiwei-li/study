cmake_minimum_required(VERSION 2.6)
project(nahanni)

add_executable(server server)
add_executable(client client)
add_executable(getident getident)
add_library(ivshmem ivshmem)

set(CMAKE_C_FLAGS_DEBUG "-DDEBUG")
set(CMAKE_C_FLAGS "-std=c99 -g -Wall -D_BSD_SOURCE")

target_link_libraries(client ivshmem rt crypto)
target_link_libraries(server ivshmem rt crypto pthread)

