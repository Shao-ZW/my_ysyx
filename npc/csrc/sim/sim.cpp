#include <verilated.h>
#include "verilated_vcd_c.h"
#include "Vtop.h"
#include "Vtop___024root.h"
#include "cpu.h"
#include "common.h"

VerilatedContext* contextp = nullptr;
VerilatedVcdC* vcd = nullptr;
Vtop* top = nullptr;
vluint64_t cur_time = 0;

void npc_eval(int clk, int rst = 0) {
  top->rst = rst;
  top->clk = clk;
  top->eval();
  IFDEF(CONFIG_WAVE, vcd->dump(cur_time));
  cur_time++;
}

void cpu_update() {
  cpu.pc  = top->rootp->top__DOT__u_CPU__DOT__u_PC__DOT__pc_reg;
  cpu.npc = top->rootp->top__DOT__u_CPU__DOT__next_pc;

  cpu.gpr[0] = 0;
  for(int i = 1; i < RISCV_GPR_NUM; ++i) {
    cpu.gpr[i] = top->rootp->top__DOT__u_CPU__DOT__u_regfile__DOT__reg_array[i];
  }
  cpu.inst_val = top->rootp->top__DOT__inst;

  cpu.csr[MSTATUS] = top->rootp->top__DOT__u_CPU__DOT__u_CSR__DOT__mstatus;
  cpu.csr[MTVEC] = top->rootp->top__DOT__u_CPU__DOT__u_CSR__DOT__mtvec;
  cpu.csr[MEPC] = top->rootp->top__DOT__u_CPU__DOT__u_CSR__DOT__mcause;
  cpu.csr[MCAUSE] = top->rootp->top__DOT__u_CPU__DOT__u_CSR__DOT__mepc;
}

static void restart() {
  /* Synchronous reset */
  npc_eval(0, 1);
  npc_eval(1, 1);
  cpu_update();
}

void init_sim() {
  contextp = new VerilatedContext;
  top = new Vtop{contextp};
  vcd = new VerilatedVcdC;

  #ifdef CONFIG_WAVE
  Verilated::traceEverOn(true);
  top->trace(vcd, 0);
  vcd->open("./build/wave.vcd");
  #endif

  restart();
}

void finish_sim() {
  #ifdef CONFIG_FTRACE
  void ftrace_display();
  ftrace_display();
  #endif
  
  top->final();
  vcd->close();
}

