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
  skip_dut_nr_inst = 0;
}

// this is used to deal with instruction packing in QEMU.
// Sometimes letting QEMU step once will execute multiple instructions.
// We should skip checking until NEMU's pc catches up with QEMU's pc.
// The semantic is
//   Let REF run `nr_ref` instructions first.
//   We expect that DUT will catch up with REF within `nr_dut` instructions.
void difftest_skip_dut(int nr_ref, int nr_dut) {
  skip_dut_nr_inst += nr_dut;

  while (nr_ref -- > 0) {
    ref_difftest_exec(1);
  }
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

static void checkregs(vaddr_t pc) {
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
    sim_state.halt_pc = pc;
    reg_display();
  }
}

void difftest_step(vaddr_t pc, vaddr_t npc) {
  if (skip_dut_nr_inst > 0) {
    ref_difftest_regcpy(&ref, DIFFTEST_TO_DUT);
    if (ref.pc == npc) {
      skip_dut_nr_inst = 0;
      checkregs(npc);
      return;
    }
    skip_dut_nr_inst --;
    if (skip_dut_nr_inst == 0)
      panic("can not catch up with ref.pc = " FMT_WORD " at pc = " FMT_WORD, ref.pc, pc);
    return;
  }

  if (is_skip_ref) {
    is_skip_ref = false;
    just_skip_ref = true;
    return;
  }

  if(just_skip_ref) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    just_skip_ref = false;
  }

  // changed for synchronous writes
  ref_difftest_regcpy(&ref, DIFFTEST_TO_DUT);
  checkregs(pc);

  ref_difftest_exec(1);
}
#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
#endif
