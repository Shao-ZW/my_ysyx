#ifndef __CPU_H__
#define __CPU_H__

#define RISCV_GPR_TYPE MUXDEF(CONFIG_RV64, uint64_t, uint32_t)
#define RISCV_GPR_NUM  MUXDEF(CONFIG_RVE , 16, 32)
#define DIFFTEST_REG_SIZE (sizeof(RISCV_GPR_TYPE) * (RISCV_GPR_NUM + 1)) // GPRs + pc

#include "common.h"

#define MSTATUS 0x300
#define MTVEC   0x305
#define MEPC    0x341
#define MCAUSE  0x342

typedef struct {
  word_t gpr[RISCV_GPR_NUM];
  vaddr_t pc;
  word_t csr[4096];
  vaddr_t npc;
  word_t inst_val;
  IFDEF(CONFIG_ITRACE, char logbuf[128]);
} CPU_state;

extern CPU_state cpu;

void reg_display();
void cpu_exec(uint64_t n);

static inline const char* reg_name(int idx) {
  extern const char* regs[];
  return regs[idx];
}

#endif
