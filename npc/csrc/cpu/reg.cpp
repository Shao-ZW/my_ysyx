#include "common.h"
#include "cpu.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

word_t reg_str2val(const char *s) {
  for(int i = 0; i < RISCV_GPR_NUM; ++i) {
    if(strcmp(regs[i], s) == 0) {
      return cpu.gpr[i];
    }
  }
  return -1;
}

void reg_display() {
  for(int i = 0; i < RISCV_GPR_NUM; ++i) {
    word_t val = reg_str2val(regs[i]);
    printf("%-5s " FMT_WORD "   " FMT_UNSIGN "\n", regs[i], val, val);
  }

  printf("%-9s " FMT_WORD "   " FMT_UNSIGN "\n", "mstatus", cpu.csr[MSTATUS], cpu.csr[MSTATUS]);
  printf("%-9s " FMT_WORD "   " FMT_UNSIGN "\n", "mtvec", cpu.csr[MTVEC], cpu.csr[MTVEC]);
  printf("%-9s " FMT_WORD "   " FMT_UNSIGN "\n", "mepc", cpu.csr[MEPC], cpu.csr[MEPC]);
  printf("%-9s " FMT_WORD "   " FMT_UNSIGN "\n", "mcause", cpu.csr[MCAUSE], cpu.csr[MCAUSE]);
}

