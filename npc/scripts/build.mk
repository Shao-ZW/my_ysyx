TOPNAME = top
VERILATOR = verilator
VERILATOR_CFLAGS += --build -cc --exe -x-assign fast --trace-fst #-Wall

WORK_DIR  = $(shell pwd)
BUILD_DIR = $(WORK_DIR)/build
OBJ_DIR = $(BUILD_DIR)/obj_dir
INC_PATH := $(WORK_DIR)/include $(INC_PATH)

BIN = $(BUILD_DIR)/$(TOPNAME)
FST_FILE = $(BUILD_DIR)/wave.fst

$(shell mkdir -p $(BUILD_DIR))

VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.cc" -or -name "*.cpp")
INCLUDES = $(addprefix -I, $(INC_PATH))
CFLAGS  += $(INCLUDES)
LIBS += -lreadline $(shell llvm-config --libs)
LDFLAGS += $(LIBS)

$(BIN): $(VSRCS) $(CSRCS) 
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
	$^ -CFLAGS "$(CFLAGS)" -LDFLAGS "$(LDFLAGS)" \
	--top-module $(TOPNAME) \
	--Mdir $(OBJ_DIR) -o $(abspath $(BIN))

