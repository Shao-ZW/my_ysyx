#include <fs.h>

size_t ramdisk_read(void *buf, size_t offset, size_t len);
size_t ramdisk_write(const void *buf, size_t offset, size_t len);
size_t serial_write(const void *buf, size_t offset, size_t len);
size_t events_read(void *buf, size_t offset, size_t len);
size_t dispinfo_read(void *buf, size_t offset, size_t len);
size_t fb_write(const void *buf, size_t offset, size_t len);

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

/* This is the information about all files in disk. */
Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, invalid_read, serial_write},
  [FD_STDERR] = {"stderr", 0, 0, invalid_read, serial_write},
  [FD_EVENT]  = {"/dev/events", 0, 0, events_read, invalid_write},
  [FD_FB]     = {"/dev/fb", 0, 0, invalid_read, fb_write},
  {"/proc/dispinfo", 0, 0, dispinfo_read, invalid_write},
#include "files.h"
};

void init_fs() {
  AM_GPU_CONFIG_T config = io_read(AM_GPU_CONFIG);
  file_table[FD_FB].size = config.vmemsz;
}

int fs_open(const char *pathname, int flags, int mode) {
  size_t ftbsize = sizeof(file_table) / sizeof(file_table[0]);

  for(int i = 0; i < ftbsize; ++i) {
    if(strcmp(pathname, file_table[i].name) == 0)
      return i;
  }

  return -1;
}

int fs_close(int fd) {
  file_table[fd].open_offset = 0;
  return 0;
}

size_t fs_read(int fd, void *buf, size_t len) {
  if(file_table[fd].read == NULL) {
    if(file_table[fd].open_offset + len > file_table[fd].size)
      len = file_table[fd].size - file_table[fd].open_offset;
    size_t offset = file_table[fd].disk_offset + file_table[fd].open_offset;
    file_table[fd].open_offset += len;
    return ramdisk_read(buf, offset, len);
  }

  return file_table[fd].read(buf, -1, len);
}

size_t fs_write(int fd, const void *buf, size_t len) {
  size_t offset = file_table[fd].disk_offset + file_table[fd].open_offset;
  file_table[fd].open_offset += len;

  if(file_table[fd].write == NULL) {
    assert(file_table[fd].open_offset + len <= file_table[fd].size);
    return ramdisk_write(buf, offset, len);
  }

  return file_table[fd].write(buf, offset, len);
}

size_t fs_lseek(int fd, size_t offset, int whence) {
  switch (whence) {
    case SEEK_SET: assert(offset <= file_table[fd].size); file_table[fd].open_offset = offset; break;
    case SEEK_CUR: assert(file_table[fd].open_offset + offset <= file_table[fd].size); file_table[fd].open_offset += offset; break;
    case SEEK_END: assert(offset <= file_table[fd].size); file_table[fd].open_offset = file_table[fd].size - offset; break;
  }
  
  return file_table[fd].open_offset;
}


