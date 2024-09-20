#include <locale.h>
#include "difftest.h"
#include "cpu.h"
#include "sim.h"
#include "trace/itrace.h"
#include "trace/ftrace.h"
#include "common.h"

/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
 */

#define MAX_INST_TO_PRINT 10

uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static bool g_print_step = false;
SIMState sim_state = { .state = SIM_STOP };
CPU_state cpu;

void device_update();
void check_wp();

static void trace_and_difftest() {
#ifdef CONFIG_ITRACE_COND
  log_write("%s\n", cpu.logbuf);
#endif
  if (g_print_step) { IFDEF(CONFIG_ITRACE, puts(cpu.logbuf)); }
  IFDEF(CONFIG_DIFFTEST, difftest_step());

  IFDEF(CONFIG_WATCHPOINT, check_wp());
}

static void exec_once() {
  npc_eval();
  cpu_update();
  IFDEF(CONFIG_ITRACE, itrace());
  cpu.pc = cpu.npc;
}

static void execute(uint64_t n) {
  for (;n > 0; n --) {
    exec_once();
    g_nr_guest_inst ++;
    trace_and_difftest();
    if (sim_state.state != SIM_RUNNING) break;
    IFDEF(CONFIG_DEVICE, device_update());
  }
}

static void statistic() {
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}

void assert_fail_msg() {
  reg_display();
  IFDEF(CONFIG_ITRACE, iringbuffer_display());
  IFDEF(CONFIG_FTRACE, ftrace_display());
  statistic();
}

void cpu_exec(uint64_t n) {
  g_print_step = (n < MAX_INST_TO_PRINT);
  switch (sim_state.state) {
    case SIM_END: case SIM_ABORT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: sim_state.state = SIM_RUNNING;
  }

  uint64_t timer_start = get_time();

  execute(n);

  uint64_t timer_end = get_time();
  g_timer += timer_end - timer_start;

  switch (sim_state.state) {
    case SIM_RUNNING: sim_state.state = SIM_STOP; break;

    case SIM_END: case SIM_ABORT:
      Log("nemu: %s at pc = " FMT_WORD,
          (sim_state.state == SIM_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (sim_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          sim_state.halt_pc);
      // fall through
    case SIM_QUIT: statistic();
  }
}

void set_sim_state(int state, vaddr_t pc, int halt_ret) {
  difftest_skip_ref();
  sim_state.state = state;
  sim_state.halt_pc = pc;
  sim_state.halt_ret = halt_ret;
}
