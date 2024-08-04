-include $(NPC_HOME)/../Makefile
include $(NPC_HOME)/scripts/build.mk

include $(NPC_HOME)/tools/difftest.mk

override ARGS ?= --log=$(BUILD_DIR)/npc-log.txt
override ARGS += $(ARGS_DIFF)

# Command to execute NPC
IMG ?=
NPC_SIM := $(BIN) $(ARGS) $(IMG)

sim-env: $(BIN) $(DIFF_REF_SO)

sim: sim-env
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(NPC_SIM)

vcd: $(VCD_FILE)
	gtkwave $(VCD_FILE)

clean:
	rm -rf $(BUILD_DIR)
	
.PHONY: sim vcd clean
