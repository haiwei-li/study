#!/bin/bash
# A script to hide/unhide PCI/PCIe device for KVM  (using 'vfio-pci')
#set -x
hide_dev=0
unhide_dev=0
driver=0

# check if the device exists
function dev_exist()
{
        local line_num=$(lspci -s "$1" 2>/dev/null | wc -l)
        if [ $line_num = 0 ]; then
                echo "Device $pcidev doesn't exists. Please check your system or your command line."
                exit 1
        else
                return 0
        fi
}

# output a format "<domain>:<bus>:<slot>.<func>" (e.g. 0000:01:10.0) of device
function canon() 
{
        f=`expr "$1" : '.*\.\(.\)'`
        d=`expr "$1" : ".*:\(.*\).$f"`
        b=`expr "$1" : "\(.*\):$d\.$f"`
        
        if [ `expr "$d" : '..'` == 0 ]
        then
                d=0$d
        fi
        if [ `expr "$b" : '.*:'` != 0 ]
        then
                p=`expr "$b" : '\(.*\):'`
                b=`expr "$b" : '.*:\(.*\)'`
        else
                p=0000
        fi
        if [ `expr "$b" : '..'` == 0 ]
        then
                b=0$b
        fi
        echo $p:$b:$d.$f
}

# output the device ID and vendor ID
function show_id() 
{
        lspci -Dn -s "$1" | awk '{print $3}' | sed "s/:/ /" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
                lspci -Dn -s "$1" | awk '{print $3}' | sed "s/:/ /"
        else
                echo "Can't find device id and vendor id for device $1"
                exit 1
        fi
}

# hide a device using 'vfio-pci' driver/module
function hide_pci()
{
        local pre_driver=NULL
        local pcidev=$(canon $1)
        local pciid=$(show_id $pcidev)

        dev_exist $pcidev

        if [ -e /sys/bus/pci/drivers/vfio-pci ]; then
                pre_driver=$(basename $(readlink /sys/bus/pci/devices/"$pcidev"/driver))

                echo "Unbinding $pcidev from $pre_driver"
                echo -n "$pciid" > /sys/bus/pci/drivers/vfio-pci/remove_id
                echo -n "$pcidev" > /sys/bus/pci/devices/"$pcidev"/driver/unbind

                echo "Binding $pcidev to vfio-pci"
                echo -n "$pciid" > /sys/bus/pci/drivers/vfio-pci/new_id
                echo -n "$pcidev" > /sys/bus/pci/drivers/vfio-pci/bind
                return $?
        fi

        echo "There's no 'vfio-pci' module? Please check your kernel config."
        exit 1
}

function unhide_pci() {
        local driver=$2
        local pcidev=$(canon $1)
        local pciid=$(show_id $pcidev)

        if [ $driver != 0 -a ! -d /sys/bus/pci/drivers/$driver ]; then
                echo "No $driver interface under sys, return fail"
                exit 1
        fi

        if [ -h /sys/bus/pci/devices/"$pcidev"/driver ]; then
                local pre_driver=$(basename $(readlink /sys/bus/pci/devices/"$pcidev"/driver))
                if [ "$pre_driver" = "$driver" ]; then
                        echo "$1 has been already bind with $driver, no need to unhide"
                        exit 1
                elif [ "$pre_driver" != "vfio-pci" ]; then
                        echo "$1 is not bind with vfio-pci, it is bind with $pre_driver, no need to unhide"
                        exit 1
                else
                        echo "Unbinding $pcidev from" $pre_driver
                        echo -n "$pciid" > /sys/bus/pci/drivers/vfio-pci/remove_id
                        echo -n "$pcidev" > /sys/bus/pci/drivers/vfio-pci/unbind

                        if [ $? -ne 0 ]; then
                                return $?
                        fi
                fi
        fi

        if [ $driver != 0 ]; then
                echo "Binding $pcidev to $driver"
                echo -n "$pciid" > /sys/bus/pci/drivers/$driver/new_id
                echo -n "$pcidev" > /sys/bus/pci/drivers/$driver/bind
        fi

        return $?
}

function usage()
{
        echo "Usage: vfio_pci.sh -h pcidev "
        echo " -h pcidev: <pcidev> is BDF number of the device you want to hide"
        echo " -u pcidev: Optional. <pcidev> is BDF number of the device you want to unhide."
        echo " -d driver: Optional. When unhiding the device, bind the device with <driver>. The option should be used together with '-u' option"
        echo ""
        echo "Example1: sh vfio_pci.sh -h 06:10.0          Hide device 06:10.0 to 'vfio-pci' driver"
        echo "Example2: sh vfio_pci.sh -u 08:00.0 -d e1000e   Unhide device 08:00.0 and bind the device with 'e1000e' driver"
        exit 1
}

if [ $# -eq 0 ] ; then
        usage
fi

# parse the options in the command line
OPTIND=1
while getopts ":h:u:d:" Option
do
        case $Option in
                h ) hide_dev=$OPTARG;;
                u ) unhide_dev=$OPTARG;;
                d ) driver=$OPTARG;;
                * ) usage ;;
        esac
done

if [ ! -d /sys/bus/pci/drivers/vfio-pci ]; then
        modprobe vfio_pci
        echo 0
        if [ ! -d /sys/bus/pci/drivers/vfio-pci ]; then
                echo "There's no 'vfio-pci' module? Please check your kernel config."
                exit 1
        fi
fi

if [ $hide_dev != 0 -a $unhide_dev != 0 ]; then
        echo "Do not use -h and -u option together."
        exit 1
fi

if [ $unhide_dev = 0 -a $driver != 0 ]; then
        echo "You should set -u option if you want to use -d option to unhide a device and bind it with a specific driver"
        exit 1
fi

if [ $hide_dev != 0 ]; then
        hide_pci $hide_dev
elif [ $unhide_dev != 0 ]; then
        unhide_pci $unhide_dev $driver
fi
exit $?

# set +x