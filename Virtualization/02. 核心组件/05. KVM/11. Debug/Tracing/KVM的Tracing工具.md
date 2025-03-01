

Tracing is done by means of kernel tracepoints, the ftrace infrastructure, and trace-cmd.

Installing trace-cmd

Install the udis86 and udis86-devel packages

download trace-cmd:
```
 $ git clone git://git.kernel.org/pub/scm/linux/kernel/git/rostedt/trace-cmd.git trace-cmd
 $ cd trace-cmd
```

build and install:

```
 $ make && sudo make install
```
Tracing

```
 # trace-cmd record -b 20000 -e kvm
```

(trace-cmd will wait)

run your workload, then stop trace-cmd with ctrl-C. trace-cmd will write a trace.dat file.

Analyzing the trace

```
trace-cmd report
```
will format and display the contents of the trace.

https://www.linux-kvm.org/page/Tracing