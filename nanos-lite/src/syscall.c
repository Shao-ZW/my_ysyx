#include <common.h>
#include "syscall.h"

static int sys_write(int fd, void *buf, size_t count) {
  if(fd == 1 || fd == 2) {
    for(char *p = buf; p - (char*)buf < count; p++)
      putch(*p);

    return count;
  }

  return -1;
}

static int sys_brk(unsigned int addr) {

  return 0;
}

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;

  switch (a[0]) {
    case SYS_exit: halt(a[1]); break;
    case SYS_yield: yield(); c->GPRx = 0; break;
    case SYS_write: c->GPRx = sys_write((int)a[1], (void*)a[2], (size_t)a[3]); break;
    case SYS_brk: c->GPRx = sys_brk(a[1]); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }

  #ifdef STRACE
    printf("syscall: %s arguments: %d %d %d return value: %d\n", 
    syscall_name[a[0]], a[1], a[2], a[3], c->GPRx);
  #endif
}

