#!/usr/bin/python

import sys,mmap

with open(sys.argv[1],"rw") as f:
	map=mmap.mmap(f.fileno(), 0)

	print map.readline()

	map.close()
