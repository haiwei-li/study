#!/bin/bash

## Usage: ./traceprocess.sh ls

DPATH="/sys/kernel/debug/tracing"

## shell pid
PID=$$
## Quick basic checks
[ `id -u` -ne 0 ] && { echo "needs to be root" ; exit 1; } # check for root permissions
[ -z $1 ] && { echo "needs process name as argument" ; exit 1; } # check for args to this function
mount | grep -i debugfs &> /dev/null
[ $? -ne 0 ] && { echo "debugfs not mounted, mount it first"; exit 1; } #checks for debugfs mount

# flush existing trace data
echo nop > $DPATH/current_tracer

# write current process id to set_ftrace_pid file
echo $PID > $DPATH/set_ftrace_pid

# set function tracer
echo function > $DPATH/current_tracer

# start the tracing
echo 1 > $DPATH/tracing_on

# execute the process
# $* all parameter list
exec $*

# stop the tracing
echo 0 > tracing_on