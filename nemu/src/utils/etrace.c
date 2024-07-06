#include <stdio.h>
#include <common.h>

void etrace(word_t NO, vaddr_t epc) {
    printf("Trigger an interrupt/exception! Exception Code: " FMT_WORD "  Program Counter: " FMT_PADDR "\n", NO, epc);
}