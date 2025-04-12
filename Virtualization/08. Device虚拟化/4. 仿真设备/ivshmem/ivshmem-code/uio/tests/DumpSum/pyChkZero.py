#!/usr/bin/python
from __future__ import with_statement;
import sys,mmap,os,stat,hashlib

if len(sys.argv)!=3:
	print "usage: mmap.py filename length"
	sys.exit(-1)

filestats=os.stat(sys.argv[1])
length=int(sys.argv[2]);

print 'file is',sys.argv[1]
with open(sys.argv[1],"r+") as f:
	# memory-map the file, size 0 means whole file
	map = mmap.mmap(f.fileno(), length, offset=mmap.PAGESIZE)
	# read content via standard file methods
	#print map.read(filesize),  # prints "Hello Python!"
	# read content via slice notation
	#print map[:5]  # prints "Hello"
	for i in range(length):
		if (map[i] == '\0'):
			print 'It\'s NULL'
		else:
			print 'not NULL'
	map.close()
