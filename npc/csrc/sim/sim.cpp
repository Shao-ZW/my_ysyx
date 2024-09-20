#include <verilated.h>
#include "verilated_fst_c.h"
#include "Vtop.h"
#include "Vtop___024root.h"
#include "cpu.h"
#include "common.h"

VerilatedContext* contextp = nullptr;
VerilatedFstC* fst = nullptr;
Vtop* top = nullptr;
vluint64_t cur_time = 0;

void npc_eval() {
  cpu.pc = top->rootp->top__DOT__u_CPU__DOT__pc_wb;
  cpu.inst_val = top->rootp->top__DOT__u_CPU__DOT__inst_wb;

  top->clk = 0;
  top->eval();
  IFDEF(CONFIG_WAVE, fst->dump(cur_time));
  cur_time++;

  top->clk = 1;
  top->eval();
  IFDEF(CONFIG_WAVE, fst->dump(cur_time));
  cur_time++;

  while (!top->rootp->top__DOT__u_CPU__DOT__u_WB_SegReg__DOT__valid) {
    top->clk = 0;
    top->eval();
    IFDEF(CONFIG_WAVE, fst->dump(cur_time));
    cur_time++;

    top->clk = 1;
    top->eval();
    IFDEF(CONFIG_WAVE, fst->dump(cur_time));
    cur_time++;
  }

  cpu.npc = top->rootp->top__DOT__u_CPU__DOT__pc_wb;
}

void cpu_update() {
  for(int i = 0; i < RISCV_GPR_NUM; ++i) {
    cpu.gpr[i] = top->rootp->top__DOT__u_CPU__DOT__u_regfile__DOT__reg_array[i];
  }
  
  cpu.csr[MSTATUS] = top->rootp->top__DOT__u_CPU__DOT__u_CSR__DOT__mstatus;
  cpu.csr[MTVEC] = top->rootp->top__DOT__u_CPU__DOT__u_CSR__DOT__mtvec;
  cpu.csr[MEPC] = top->rootp->top__DOT__u_CPU__DOT__u_CSR__DOT__mepc;
  cpu.csr[MCAUSE] = top->rootp->top__DOT__u_CPU__DOT__u_CSR__DOT__mcause;
}

static void restart() {
  /* Synchronous reset */
  top->rst = 1;

  top->clk = 0;
  top->eval();
  IFDEF(CONFIG_WAVE, fst->dump(cur_time));
  cur_time++;

  top->clk = 1;
  top->eval();
  IFDEF(CONFIG_WAVE, fst->dump(cur_time));
  cur_time++;

  top->rst = 0;
  while (!top->rootp->top__DOT__u_CPU__DOT__u_WB_SegReg__DOT__valid) {
    top->clk = 0;
    top->eval();
    IFDEF(CONFIG_WAVE, fst->dump(cur_time));
    cur_time++;

    top->clk = 1;
    top->eval();
    IFDEF(CONFIG_WAVE, fst->dump(cur_time));
    cur_time++;
  }

  cpu.pc = top->rootp->top__DOT__u_CPU__DOT__pc_wb;
  cpu_update();
}

void init_sim() {
  contextp = new VerilatedContext;
  top = new Vtop{contextp};
  fst = new VerilatedFstC;

  #ifdef CONFIG_WAVE
  Verilated::traceEverOn(true);
  top->trace(fst, 0);
  fst->open("./build/wave.fst");
  #endif

  restart();
}

void finish_sim() {
  #ifdef CONFIG_FTRACE
  void ftrace_display();
  ftrace_display();
  #endif
  
  top->final();
  fst->close();
}

void set_sim_state(int state, vaddr_t pc, int halt_ret);

extern "C" void npc_trap() {
  cpu_update();
  set_sim_state(SIM_END, top->rootp->top__DOT__u_CPU__DOT__pc_mem, cpu.gpr[10]);
}
