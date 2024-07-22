#include <common.h>
#include <sys/time.h>
#include "syscall.h"
#include <fs.h>

// #define STRACE

extern Finfo file_table[];

void strace(uintptr_t a[], int ret) {
  switch (a[0]) {
    case SYS_exit: 
      printf("exit(%d) = %d\n", a[1], ret); 
      break;
    case SYS_yield: 
      printf("yiled() = %d\n", ret); 
      break;
    case SYS_brk: 
      printf("brk(%u) = %d\n", a[1], ret); 
      break;
    case SYS_open: 
      printf("open(\"%s\", %d, %d) = %d\n", a[1], a[2], a[3], ret); 
      break;
    case SYS_close: 
      printf("close(\"%s\") = %d\n", file_table[a[1]].name, ret); 
      break;
    case SYS_read: 
      printf("read(\"%s\", %p, %u) = %d\n", file_table[a[1]].name, a[2], a[3], ret); 
      break;
    case SYS_write: 
      printf("write(\"%s\", %p, %u) = %d\n", file_table[a[1]].name, a[2], a[3], ret); 
      break;
    case SYS_lseek: 
      printf("lseek(\"%s\", %u, %d) = %d\n", file_table[a[1]].name, a[2], a[3], ret); 
      break;
    case SYS_gettimeofday:
      printf("gettimeofday(%p, %p) = %d\n", a[1], a[2], ret); 
      break;
  }
}

static int sys_exit(int status) {
  halt(status); 
}

static int sys_yield() {
  yield(); 
  return 0;
}

static int sys_brk(unsigned int addr) {

  return 0;
}

static int sys_open(const char *pathname, int flags, int mode) {
  return fs_open(pathname, flags, mode);
}

static int sys_close(int fd) {
  return fs_close(fd);
}

static int sys_read(int fd, void *buf, size_t len) {
  return fs_read(fd, buf, len);
}

static int sys_write(int fd, const void *buf, size_t len) {
  return fs_write(fd, buf, len);
}

static int sys_lseek(int fd, size_t offset, int whence) {
  return fs_lseek(fd, offset, whence);
}

static int sys_gettimeofday(struct timeval *tv, struct timezone *tz) {
  uint64_t us;
  ioe_read(AM_TIMER_UPTIME, &us);
  tv->tv_sec = us / 1000000;
  tv->tv_usec = us % 1000000;
  return 0;
}

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;

  switch (a[0]) {
    case SYS_exit: sys_exit(a[1]); break;
    case SYS_yield: c->GPRx = sys_yield(); break;
    case SYS_brk: c->GPRx = sys_brk(a[1]); break;
    case SYS_open: c->GPRx = sys_open((char*)a[1], a[2], a[3]); break;
    case SYS_close: c->GPRx = sys_close(a[1]); break;
    case SYS_read: c->GPRx = sys_read(a[1], (void*)a[2], a[3]); break;
    case SYS_write: c->GPRx = sys_write(a[1], (void*)a[2], a[3]); break;
    case SYS_lseek: c->GPRx = sys_lseek(a[1], a[2], a[3]); break;
    case SYS_gettimeofday: c->GPRx = sys_gettimeofday((void*)a[1], (void*)a[2]); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }

  #ifdef STRACE
    strace(a, c->GPRx);
  #endif
}

