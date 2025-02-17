#!/usr/bin/env python

import os
import commands

save_dir = '/data/coredump/'
user_id_file = 'echo "1" > /proc/sys/kernel/core_uses_pid'
ulimit_command = 'ulimit -c unlimited'
sysctl_context = 'kernel.core_pattern = /data/coredump/core.%e.%p'
sysctl_p = 'sysctl -p'
 
def is_con_exists(str_, file_path):
    with open(file_path, 'r') as file_obj:
        for line in file_obj: 
            if str_ in line:
                return True
    return False

if __name__ == '__main__':
    
    if(not os.path.exists(save_dir)):
        os.makedirs(save_dir)

    status,out = commands.getstatusoutput(user_id_file)
    if(status != 0):
         print 'commands(%s) error.' % user_id_file
         os._exit(0)

    status,out = commands.getstatusoutput(ulimit_command)
    if(status != 0):
         print 'commands(%s) error.' % ulimit_command
         os._exit(0)         

    if not is_con_exists(ulimit_command, '/etc/profile'):
        with open('/etc/profile', 'a') as file_obj:
            file_obj.write('\n' + ulimit_command)

    if not is_con_exists(sysctl_context, '/etc/sysctl.conf'):
        with open('/etc/sysctl.conf', 'a') as file_obj:
            file_obj.write('\n' + sysctl_context)
    
    status,out = commands.getstatusoutput(sysctl_p)
    if(status != 0):
         print 'commands(%s) error.' % sysctl_p 
         os._exit(0)
