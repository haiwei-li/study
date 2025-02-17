#!/bin/bash

gdb ./vmlinux -ex "target remote localhost:1234"    \
              -ex "break start_kernel"              \
              -ex "continue"                        \
              -ex "disconnect"                      \
              -ex "set architecture i386:x86-64:intel" \
              -ex "target remote localhost:1234"