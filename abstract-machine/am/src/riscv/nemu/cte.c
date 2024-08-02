#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      #ifdef __riscv_e
        case 11: ev.event =  c->gpr[15] == -1 ? EVENT_YIELD: EVENT_SYSCALL; c->mepc += 4; break;
      #else
        case 11: ev.event =  c->gpr[17] == -1 ? EVENT_YIELD: EVENT_SYSCALL; c->mepc += 4; break;
      #endif
      default: ev.event = EVENT_ERROR; break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  Context *cp = (Context*)kstack.end - 1;
  cp->gpr[10] = (uintptr_t)arg;
  cp->mepc = (uintptr_t)entry;
#if defined(CONFIG_RV64)
  cp->mstatus = 0xa00001800;
#else
  cp->mstatus = 0x1800;
#endif
  return cp;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else
  asm volatile("li a7, -1; ecall");
#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
