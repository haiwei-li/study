#!/usr/bin/python
from __future__ import with_statement;
import sys,mmap,os,stat,hashlib

if len(sys.argv)!=2:
	print "usage: mmap.py filename"
	sys.exit(-1)

filestats=os.stat(sys.argv[1])
filesize=filestats[stat.ST_SIZE]

with open(sys.argv[1],"r+") as f:
	# memory-map the file, size 0 means whole file
	map = mmap.mmap(f.fileno(), 0)
	# read content via standard file methods
	#print map.read(filesize),  # prints "Hello Python!"
	# read content via slice notation
	#print map[:5]  # prints "Hello"
	h=hashlib.sha1()
	h.update(map)
	print "digest of " + sys.argv[1]
	print h.hexdigest()
	map.close()
