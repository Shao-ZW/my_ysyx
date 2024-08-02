#include <stdint.h>
#include <stdlib.h>
#include <assert.h>

int main(int argc, char *argv[], char *envp[]);
extern char **environ;
void call_main(uintptr_t *args) {
  int argc = *(int*)args;
  char **argv = (char**)((void*)args + sizeof(int));
  char **envp = (char**)((void*)args + sizeof(int) + (argc + 1) * sizeof(char*));
  environ = envp;
  exit(main(argc, argv, envp));
  assert(0);
}
