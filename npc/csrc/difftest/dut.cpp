#include <dlfcn.h>
#include "utils.h"
#include "memory/pmem.h"
#include "difftest.h"
#include "cpu.h"
#include "common.h"

typedef void (*difftest_memcpy_t)(unsigned int, void*, unsigned long, bool);
typedef void (*difftest_regcpy_t)(void*, bool);
typedef void (*difftest_exec_t)(uint64_t);
typedef void (*difftest_raise_intr_t)(uint64_t);
typedef void (*difftest_init_t)(int);

difftest_memcpy_t ref_difftest_memcpy = NULL;
difftest_regcpy_t ref_difftest_regcpy = NULL;
difftest_exec_t ref_difftest_exec = NULL;
difftest_raise_intr_t ref_difftest_raise_intr = NULL;
difftest_init_t ref_difftest_init = NULL;

#ifdef CONFIG_DIFFTEST

static bool is_skip_ref = false;
static int skip_dut_nr_inst = 0;
static bool just_skip_ref = false;
CPU_state ref;

// this is used to let ref skip instructions which
// can not produce consistent behavior with NEMU
void difftest_skip_ref() {
  is_skip_ref = true;
  // If such an instruction is one of the instruction packing in QEMU
  // (see below), we end the process of catching up with QEMU's pc to
  // keep the consistent behavior in our best.
  // Note that this is still not perfect: if the packed instructions
  // already write some memory, and the incoming instruction in NEMU
  // will load that memory, we will encounter false negative. But such
  // situation is infrequent.

  skip_dut_nr_inst = 2; // !!! this is buggy but i have not find a good way !!!
}

void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (difftest_memcpy_t)dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (difftest_regcpy_t)dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (difftest_exec_t)dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (difftest_raise_intr_t)dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = (difftest_init_t )dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

static void checkregs() {
  bool flag = true;
  
  if(ref.pc != cpu.pc) {
    printf("\ndut-pc : " FMT_PADDR "  ref-pc : " FMT_PADDR "\n", cpu.pc, ref.pc);
    flag = false; 
  }
  
  for(int i = 0; i < RISCV_GPR_NUM; ++i) {
    if(ref.gpr[i] != cpu.gpr[i]) {
      printf("dut-%-3s: " FMT_WORD "  ref-%-3s: " FMT_WORD "\n", reg_name(i), cpu.gpr[i], reg_name(i), ref.gpr[i]);
      flag = false;
    }
  }

  if (!flag) {
    sim_state.state = SIM_ABORT;
    sim_state.halt_pc = cpu.pc;
    reg_display();
  }
}

void difftest_step() {
  if (skip_dut_nr_inst > 0) {
    ref_difftest_regcpy(&ref, DIFFTEST_TO_DUT);
    skip_dut_nr_inst --;
    return;
  }

  if (is_skip_ref) {
    ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    is_skip_ref = false;
    return;
  }

  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref, DIFFTEST_TO_DUT);

  checkregs();
}
#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
#endif
