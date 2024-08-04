#include "memory/pmem.h"
#include "trace/mtrace.h"
#include "difftest.h"
#include "common.h"

static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

static const uint32_t img [] = {
  0x00000297,  // auipc t0,0
  0x00028823,  // sb  zero,16(t0)
  0x0102c503,  // lbu a0,16(t0)
  0x00100073,  // ebreak (used as nemu_trap)
  0xdeadbeef,  // some data 
};  // built-in image

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }

extern "C" uint32_t pmem_read(paddr_t raddr) {
  // 总是读取地址为`raddr & ~0x3u`的4字节返回
  #ifdef CONFIG_HAS_TIMER
  static uint64_t nowtime;
  if(raddr == CONFIG_RTC_MMIO) {
    difftest_skip_ref();
    return (uint32_t)nowtime;
  }
  if(raddr == CONFIG_RTC_MMIO + 4) {
    difftest_skip_ref();
    nowtime = get_time();
    return nowtime >> 32;
  }
  
  // Prevent out-of-bounds access
  if(raddr > CONFIG_MBASE + CONFIG_MSIZE) {
    return 0;
  }
  #endif

  uint32_t rdata = *(uint32_t*)guest_to_host(raddr & ~0x3u);
  IFDEF(CONFIG_MTRACE, mtrace_read(raddr, rdata));
  return rdata;
}

extern "C" void pmem_write(paddr_t waddr, uint32_t wdata, char wmask) {
  // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
  #ifdef CONFIG_HAS_SERIAL
  if(waddr == CONFIG_SERIAL_MMIO) {
    difftest_skip_ref();
    putchar(wdata & 0xFF);
    return;
  }
  #endif

  IFDEF(CONFIG_MTRACE, mtrace_write(waddr, wdata, wmask));
  uint8_t* p = guest_to_host(waddr & ~0x3u);

  for (int i = 0; i < 4; i++) {
    if (wmask & 1) {
      *p = (uint8_t)(wdata & 0xFF);
    }
    wdata >>= 8;
    wmask >>= 1;
    p++;
  }
}

void init_mem() {
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

long load_img(const char *img_file) {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

