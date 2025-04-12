AArch64 Generic Timer Example
=============================

Introduction
============
This example demonstrates the use of the Generic Timer in a baremetal environment.


Notice
=======
Copyright (C) Arm Limited, 2019 All rights reserved.

The example code is provided to you as an aid to learning when working 
with Arm-based technology, including but not limited to programming tutorials. 
Arm hereby grants to you, subject to the terms and conditions of this License, 
a non-exclusive, non-transferable, non-sub-licensable, free-of-charge license, 
to use and copy the Software solely for the purpose of demonstration and 
evaluation.

You accept that the Software has not been tested by Arm therefore the Software 
is provided “as is”, without warranty of any kind, express or implied. In no 
event shall the authors or copyright holders be liable for any claim, damages 
or other liability, whether in action or contract, tort or otherwise, arising 
from, out of or in connection with the Software or the use of Software.


Requirements
============
* DS-5 Ultimate Edition (5.29 or later) or Arm Development Studio
* AEMv8 BasePlatform FVP


File list
=========
 <root>
  |-> headers
  |   |-> generic_timer.h
  |   |-> gicv3_basic.h
  |   |-> gicv3_registers.h  
  |   |-> system_counter.h
  |
  |-> src
  |   |-> el3_vectors.s      Minimal vector table
  |   |-> generic_timer.s    Helper functions for Generic Timer
  |   |-> gicv3_basic.c      Helper functions for GICv3
  |   |-> main.c             Example program using the Generic Timer
  |   |-> startup.s          Minimal reset handler
  |   |-> system_counter.s   Helper functions for System Counter
  |
  |-> ReadMe.txt             This file
  |-> scatter.txt            Memory layout for linker



Description
===========
This example configures the System Counter to generate a system count and two Timers to generate interrupts based off the system count:

* The Secure Physical Timer is configured using CVAL.
* The Non-secure EL1 Physical Timer is configured using TVAL.

On each Timer firing, the interrupt handler disables the associated Timer to clear the interrupt.


Building and running the example from the command line
=======================================================
To build the example:
- Open a DS-5 or Arm Developer Studio command prompt (<tools installation directory>\bin), then navigate to the location of the example
- Run "make"

To run the example:
- Open a command prompt, then navigate to the location of Base Platform FVP executable
- Run:

  FVP_Base_Cortex-A35x1 --application=<path_to_example>\image.axf
  
Note: FVP_Base_Cortex-A35x1 is not available in Arm Development Studio Bronze edition.

Or on DS-5 and Arm Development Studio Platinum edition, you can use one of the AEM based FVPs:

  FVP_Base_AEMv8A-AEMv8A -C cluster0.NUM_CORES=1 -C cluster1.NUM_CORES=0 --application=<path_to_example>\image.axf

Or:

  FVP_Base_AEMv8A -C cluster.NUM_CORES=1 --application=<path_to_example>\image.axf

Expected output:
  FIQ: Received INTID 29
  FIQ: Secure Physical Timer
  FIQ: Received INTID 30
  FIQ: Non-secure EL1 Physical Timer
  Main(): Test end
  
Debugging a image built outside of DS-5 with DS-5
=============================================
After building the image outside of Eclipse for DS-5, you can run the image in DS-5 by:
* In DS-5, go to File -> Import... .
* Select Run/Debug -> Launch Configurations, then click Next.
* Click Browse... and browse to the generic_timer project directory.
* Tick generic_timer, then click Finish.
* Select Run -> Debug Configurations... .
* In the Debug Configurations view, select DS-5 Debugger -> generic_timer_example.
* In the Files tab, set Target Configuration -> Application on host to download to the location of the built generic_timer image.
* Click Apply, then click Debug.


Debugging a image built outside of Arm Development Studio with Arm Development Studio
================================================================================
After building the image outside of Arm Development Studio, you can run the image in Arm Development Studio Silver edition and higher by:
* In Arm Development Studio, go to File -> Import... .
* Select Run/Debug -> Launch Configurations, then click Next.
* Click Browse... and browse to the generic_timer project directory.
* Tick generic_timer, then click Finish.
* Select Run -> Debug Configurations... .
* In the Debug Configurations view, select Generic Arm C/C++ Application -> generic_timer_example.
* If a Upgrading debug configuration dialog appears, click OK.
* In the Files tab, set Target Configuration -> Application on host to download to the location of the built generic_timer image.
* Click Apply, then click Debug.


Building and running the example using DS-5
===========================================
* In DS-5, go to File -> Import... .
* Select General -> "Existing Projects into Workspace". 
* Navigate to and select the generic_timer example, then click Finish.
* In the C/C++ perspective, select the "generic_timer" project and then Project -> "Build Project".
* Once the project has built, right-click generic_timer_example.launch and "Debug as".



Building and running the example using Arm Development Studio
=============================================================
* In Arm DS, go to File -> Import... .
* Select General -> "Existing Projects into Workspace".
* Navigate to and select the generic_timer_ArmDS example, then click Finish.
* In the Development Studio perspective, select the "generic_timer_ArmDS" project and then Project -> "Build Project".
* Once the project has built, right-click generic_timer_example.launch and "Debug as" -> generic_timer_example.