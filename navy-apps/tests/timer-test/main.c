#include <stdio.h>
#include <assert.h>
#include <NDL.h>

int main() {
    uint32_t start, current;
    uint32_t elapsed_time;

    NDL_Init(0);
    start = NDL_GetTicks();
    while (1) {
        current = NDL_GetTicks();
        elapsed_time = current - start;
        if (elapsed_time >= 500) {
            printf("This message is printed every 0.5 seconds.\n");
            start = current;
        }
    }

    return 0;
}
