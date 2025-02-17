#!/bin/bash  

# 查看基本硬件信息的shell脚本
echo "IP:"  
ifconfig |grep "inet addr"|grep -v 127.0.0.1|awk '{print $2}'|awk -F ':' '{print $2}'  
echo "Product Name:"  
dmidecode |grep Name  
echo "CPU Info:"  
dmidecode |grep -i cpu|grep -i version|awk -F ':' '{print $2}'  
echo "Disk Info:"  
parted -l|grep 'Disk /dev/sd'|awk -F ',' '{print "   ",$1}'  
echo "Network Info:"  
lspci |grep Ethernet  
echo "Memory Info:"  
dmidecode|grep -A5 "Memory Device"|grep Size|grep -v No  
echo "Memory number:"`dmidecode|grep -A5 "Memory Device"|grep Size|grep -v No|wc -l`