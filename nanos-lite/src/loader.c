#include <proc.h>
#include <elf.h>
#include <fs.h>

#define ENV_MAX 128
#define ARG_MAX 128

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif

const static char expected_e_ident[EI_NIDENT] = {
    0x7f, 'E', 'L', 'F', // 魔术字节和文件类型
    0x01,                // 文件类（32位）
    0x01,                // 数据编码（小端）
    0x01,                // 文件版本
    0x00,                // OS/ABI（无特定操作系统）
    0x00,                // ABI版本
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // 剩余的未使用字节
};


static uintptr_t loader(PCB *pcb, const char *filename) {
  Elf_Ehdr elf_header;
  int fd = fs_open(filename, 0, 0);
  
  if(fd == -1)
    return -1;

  // check elf magic
  fs_read(fd, &elf_header, sizeof(elf_header));
  assert(strncmp((char*)elf_header.e_ident, expected_e_ident, EI_NIDENT) == 0);

  // read program header
  fs_lseek(fd, elf_header.e_phoff, SEEK_SET);
  for (int i = 0; i < elf_header.e_phnum; i++) {
        Elf_Phdr program_header;
        fs_read(fd, &program_header, sizeof(Elf_Phdr));
        if(program_header.p_type == PT_LOAD) {
          size_t original_offset = fs_lseek(fd, 0, SEEK_CUR);
          fs_lseek(fd, program_header.p_offset, SEEK_SET);
          fs_read(fd, (void*)program_header.p_vaddr, program_header.p_filesz);
          fs_lseek(fd, original_offset, SEEK_SET);
          memset((void*)program_header.p_vaddr + program_header.p_filesz, 0, program_header.p_memsz - program_header.p_filesz);
        }
    }

  fs_close(fd);
  return elf_header.e_entry;
}

Context* context_kload(PCB *pcb, void (*entry)(void *), void *arg) {
  return kcontext((Area){&pcb->stack[0], &pcb->stack[STACK_SIZE]}, entry, arg);
}

/*
+---------------+ <---- ustack.end
|  Unspecified  |
+---------------+
|               | <----------+
|    string     | <--------+ |
|     area      | <------+ | |
|               | <----+ | | |
|               | <--+ | | | |
+---------------+    | | | | |
|  Unspecified  |    | | | | |
+---------------+    | | | | |
|     NULL      |    | | | | |
+---------------+    | | | | |
|    ......     |    | | | | |
+---------------+    | | | | |
|    envp[1]    | ---+ | | | |
+---------------+      | | | |
|    envp[0]    | -----+ | | |
+---------------+        | | |
|     NULL      |        | | |
+---------------+        | | |
| argv[argc-1]  | -------+ | |
+---------------+          | |
|    ......     |          | |
+---------------+          | |
|    argv[1]    | ---------+ |
+---------------+            |
|    argv[0]    | -----------+
+---------------+
|      argc     |
+---------------+ <---- cp->GPRx
*/

int context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]) {
  if(fs_open(filename, 0, 0) == -1)
    return -1;

  uintptr_t sp = (uintptr_t)new_page(STACK_SIZE / PGSIZE) + STACK_SIZE;
  char *argv_t[ARG_MAX] = {NULL};
  char *envp_t[ENV_MAX] = {NULL};
  int argc = 0;
  int envc = 0;

  while (argv && argv[argc] != NULL) argc++;
  while (envp && envp[envc] != NULL) envc++;

  for (int i = argc - 1; i >= 0; i--) {
    sp -= (strlen(argv[i]) + 1);
    strcpy((char*)sp, argv[i]);
    argv_t[i] = (char*)sp;
  }

  for (int i = envc - 1; i >= 0; i--) {
    sp -= (strlen(envp[i]) + 1);
    strcpy((char*)sp, envp[i]);
    envp_t[i] = (char*)sp;
  }

  sp &= ~0xF;

  sp -= (envc + 1) * sizeof(char*);
  memcpy((void*)sp, envp_t, (envc + 1) * sizeof(char*));

  sp -= (argc + 1) * sizeof(char*);
  memcpy((void*)sp, argv_t, (argc + 1) * sizeof(char*));

  sp -= sizeof(int);
  *(int*)sp = argc;

  // avoid envp be covered
  void *entry = (void*)loader(pcb, filename);
  pcb->cp = ucontext(NULL, (Area){&pcb->stack[0], &pcb->stack[STACK_SIZE]}, entry);
  pcb->cp->GPRx = sp;

  return 0;
}

int naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  if(entry != -1) {
    Log("Jump to entry = %p", entry);
    ((void(*)())entry) ();
  }
  return -1;
}

