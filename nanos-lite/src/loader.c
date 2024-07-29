#include <proc.h>
#include <elf.h>
#include <fs.h>

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

int naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  if(entry != -1) {
    Log("Jump to entry = %p", entry);
    ((void(*)())entry) ();
  }
  return -1;
}

