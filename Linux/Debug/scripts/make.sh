#!/bin/bash - 
#===============================================================================
#
#          FILE:  make.sh
# 
#         USAGE:  ./make.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: YOUR NAME (), 
#       COMPANY: 
#       CREATED: 2015年06月09日 16时35分42秒 CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

sudo rmmod kvm-intel
sudo rmmod kvm
rm `pwd`/arch/x86/kvm/*.o
sudo make -j8 CONFIG_KVM=m CONFIG_KVM_INTEL=m -C `pwd` M=`pwd`/arch/x86/kvm modules
#sudo make -j8 CONFIG_KVM=m CONFIG_KVM_INTEL=m -C /lib/modules/`uname -r`/build M=`pwd`/arch/x86/kvm/ modules
sudo insmod `pwd`/arch/x86/kvm/kvm.ko 
sudo insmod `pwd`/arch/x86/kvm/kvm-intel.ko

