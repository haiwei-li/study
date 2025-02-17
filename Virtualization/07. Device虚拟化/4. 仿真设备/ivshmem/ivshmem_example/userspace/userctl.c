#include <stdio.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <poll.h>

#include "../ivshmem_common.h"

typedef enum user_options {
  option_read_shmem,
  option_read_vmid,
  option_send_irq,
  option_poll,
  option_wait,
  option_commu
} user_options;


int get_sharemem(int fd){
  int value;
  if (ioctl(fd, CMD_READ_SHMEM, &value) == -1)
  {
    perror("failed to get sharemem \n");
    return -1;
  }
  else
  {
    printf("Received message from shared memory, %d\n", value);
    return value;
  }
}

int get_vmid(int fd){
  int vmid;
  if (ioctl(fd, CMD_READ_VMID, &vmid) == -1)
  {
    perror("failed to get vmid\n");
    return -1;
  }
  else
  {
    printf("Status : vmid is %d\n", vmid);
    return vmid;
  }
}

void send_interrupt(int fd, int dest_vm, int msg){
  irq_arg arg;
  arg.dest_id = dest_vm;
  arg.msg = msg;

  if (ioctl(fd, CMD_INTERRUPT, &arg) != 0)
  {
    perror("failed to write to doorbell\n");
  }
  else
  {
    printf("Interrupt sent to vm %d, msg: %d \n", dest_vm, msg);
  }
}

void wait_for_irq(int fd){
   struct pollfd fds[1];
   int ret = 0;

   fds[0].fd = fd;
   fds[0].events = POLLIN;
   printf("Waiting for message from other vm .... \n");
   while (!ret){
      ret = poll(fds, 1, -1);
   }
   printf("Message is ready. \n");
}

void wait_and_reply(int fd){
  int dest_vm = -1;
  wait_for_irq(fd);
  dest_vm = get_sharemem(fd);

  if (dest_vm > -1){
    printf("message received from vm_id: %d\n", dest_vm);
    // reply
    send_interrupt(fd, dest_vm, 6666);
  }
}

void send_and_wait(int fd, int dest_vm){
  // send self vmid to dest
  int msg = get_vmid(fd);
  send_interrupt(fd, dest_vm, msg);
  wait_for_irq(fd);
  get_sharemem(fd);
}

int main(int argc, char *argv[])
{

  // print something to understand
  printf("command %ld, %ld, %ld\n",CMD_READ_SHMEM, CMD_READ_VMID, CMD_INTERRUPT);

  char *file_name = "/dev/ivshmem";
  int fd, msg;
  user_options option;
  int dest_vm = 0;

  // parsing arguments
  if (argc == 1){
    option = option_read_shmem;
  }
  else{
    if (strcmp(argv[1], "-m") == 0){
      option = option_read_shmem;
    }
    else if (strcmp(argv[1], "-d") == 0){
      option = option_read_vmid;
    }
    else if (strcmp(argv[1], "-p") == 0){
      option = option_poll;
    }
    else if (strcmp(argv[1], "-w") == 0){
      option = option_wait;
    }
    else if ((strcmp(argv[1], "-i") == 0) && (argc == 4)){
      option = option_send_irq;
      dest_vm = atoi(argv[2]);
      msg = atoi(argv[3]);
      printf("destination vm id is %d \n", dest_vm);
    }
    else if ((strcmp(argv[1], "-c") == 0) && (argc == 3)){
      option = option_commu;
      dest_vm = atoi(argv[2]);
      printf("destination vm id is %d \n", dest_vm);
    }
    else {
      printf("Usage: \n");
      printf("sudo ./userctl -m                     // get shmem content\n");
      printf("sudo ./userctl -d                     // get self vm id\n");
      printf("sudo ./userctl -p                     // wait for interrupt and reply\n");
      printf("sudo ./userctl -w                     // wait for interrupt\n");
      printf("sudo ./userctl -i <dest_vm> <msg>     // trigger interrupt to dest_vm\n");
      printf("sudo ./userctl -c <dest_vm>           // send selfid to dest_vm and wait for reply\n");
    }
  }

  fd = open(file_name, O_RDWR);
  if (fd == -1)
  {
    perror("open file failed\n");
    return 2;
  }

  switch (option)
  {
    case option_read_shmem:
      get_sharemem(fd);
      break;
    case option_read_vmid:
      get_vmid(fd);
      break;
    case option_send_irq:
      send_interrupt(fd, dest_vm, msg);
      break;
    case option_poll:
      wait_and_reply(fd);
      break;
    case option_wait:
      wait_for_irq(fd);
      break;
    case option_commu:
      send_and_wait(fd, dest_vm);
      break;
    default:
      break;
  }

  close(fd);

}
