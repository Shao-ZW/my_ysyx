#include <proc.h>
#include <elf.h>

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

size_t ramdisk_read(void *buf, size_t offset, size_t len);

static uintptr_t loader(PCB *pcb, const char *filename) {
  Elf_Ehdr elf_header;

  ramdisk_read(&elf_header, 0, sizeof(elf_header));
  
  // check elf magic
  assert(strncmp((char*)elf_header.e_ident, expected_e_ident, EI_NIDENT) == 0);

  // read program header
  for (int i = 0, offset = elf_header.e_phoff; i < elf_header.e_phnum; i++) {
        Elf_Phdr program_header;
        offset += ramdisk_read(&program_header, offset, sizeof(Elf_Phdr));

        if(program_header.p_type == PT_LOAD) {
          ramdisk_read((void*)program_header.p_vaddr, program_header.p_offset, program_header.p_filesz);
          memset((void*)program_header.p_vaddr + program_header.p_filesz, 0, program_header.p_memsz - program_header.p_filesz);
        }
    }

  return elf_header.e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", entry);
  ((void(*)())entry) ();
}

