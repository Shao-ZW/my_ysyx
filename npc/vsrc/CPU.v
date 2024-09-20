module CPU(
    input         clk,
    input         rst,

    // output [31:0] i_araddr,
    // output        i_arvalid,
    // input         i_arready,

    // input  [31:0] i_rdata,
    // input  [1:0]  i_rresp,
    // input         i_rvalid,
    // output        i_rready,

    output        iram_en,
    output [31:0] iram_addr,
    input  [31:0] iram_rdata,

    output        dram_en,
    output        dram_wen,
    output [31:0] dram_addr,
    output [31:0] dram_wdata,
    output [3:0]  dram_wmask,
    input  [31:0] dram_rdata
);

    wire [31:0] mtvec_rdata_global;
    wire [31:0] mepc_rdata_global;

    // IF
    wire if_stall;
    wire if_flush;
    wire if_valid;
    
    // ID
    wire id_flush;
    wire id_stall;

    wire id_ready;
    wire id_valid;

    wire [31:0] pc_id;
    wire [31:0] inst_id;
    wire [31:0] imm_id;
    wire [9:0]  alu_op_id;
    wire [7:0]  jump_type_id;
    wire [7:0]  mem_type_id;
    wire [2:0]  sel_alu_src1_id;
    wire [2:0]  sel_alu_src2_id;
    wire        rf_wen_id;
    wire [2:0]  sel_rf_wdata_id;
    wire        dram_en_id;
    wire        dram_wen_id;
    wire        csr_wen_id;
    wire [5:0]  csr_op_id;
    wire [31:0] zimm_id;
    wire        ecall_en_id;
    wire        mret_en_id;
    wire [31:0] rf_rdata1_id;
    wire [31:0] rf_rdata2_id;
    wire [31:0] csr_rdata_id;
    wire        dram_en_id;
    wire        dram_wen_id;
    wire        ebreak_id;

    // EX
    wire ex_ready;
    wire ex_valid;
    
    wire ex_flush;

    wire [31:0] pc_ex;
    wire [31:0] inst_ex;
    wire [31:0] imm_ex;
    wire [31:0] zimm_ex;
    wire [9:0]  alu_op_ex;
    wire [7:0]  jump_type_ex;
    wire [7:0]  mem_type_ex;
    wire [2:0]  sel_alu_src1_ex;
    wire [2:0]  sel_alu_src2_ex;
    wire        rf_wen_ex;
    wire [2:0]  sel_rf_wdata_ex;
    wire [5:0]  csr_op_ex;
    wire        csr_wen_ex;
    wire        ecall_en_ex;
    wire        mret_en_ex;
    wire [31:0] rf_rdata1_ex;
    wire [31:0] rf_rdata2_ex;
    wire [31:0] csr_rdata_ex;
    wire        dram_en_ex;
    wire        dram_wen_ex;
    wire [31:0] alu_res_ex;
    wire [31:0] jump_target_ex;
    wire        jump_taken_ex;
    wire [31:0] csr_wdata_ex;
    wire [31:0] dram_wdata_ex;
    wire [3:0]  dram_wmask_ex;
    wire        ebreak_ex;

    // MEM
    wire mem_ready;
    wire mem_valid;

    wire [31:0] pc_mem;
    wire [31:0] inst_mem;
    wire [31:0] alu_res_mem;
    wire [31:0] csr_wdata_mem;
    wire [7:0]  mem_type_mem;
    wire        rf_wen_mem;
    wire [2:0]  sel_rf_wdata_mem;
    wire        csr_wen_mem;
    wire        ecall_en_mem;
    wire        mret_en_mem;
    wire [31:0] csr_rdata_mem;
    wire        dram_en_mem;
    wire        dram_wen_mem;
    wire [3:0]  dram_wmask_mem;
    wire [31:0] dram_wdata_mem;
    wire [31:0] load_data_mem;
    wire        ebreak_mem;

    // WB
    wire wb_ready;

    wire [31:0] pc_wb;
    wire [31:0] inst_wb;
    wire [31:0] load_data_wb;
    wire [31:0] alu_res_wb;
    wire [31:0] csr_rdata_wb;
    wire [2:0]  sel_rf_wdata_wb;
    wire        ecall_en_wb;
    wire [31:0] mcause_wdata_wb;
    wire        exception_en_wb;
    wire        mret_en_wb;
    wire [31:0] rf_wdata_wb;
    wire        rf_wen_wb;
    wire        csr_wen_wb;
    wire [31:0] csr_wdata_wb;
    wire        ebreak_wb;

    // IF
    wire [31:0] pc;
    wire [31:0] next_pc;

    NPC u_NPC(
        .pc(pc),
        .mtvec_rdata(mtvec_rdata_global),
        .mepc_rdata(mepc_rdata_global),
        .jump_target(jump_target_ex),   // bypass
        .exception_en(ecall_en_ex & ex_valid),     // bypass
        .mret_en(mret_en_ex & ex_valid),           // bypass
        .jump_taken(jump_taken_ex & ex_valid),     // bypass
        .next_pc(next_pc)
    );

    PC u_PC(
        .clk(clk),
        .rst(rst),
        .wen(id_ready),
        .next_pc(next_pc),
        .pc(pc)
    );

    assign iram_addr = pc;
    assign iram_en = !rst;

    reg if_valid;

    always @(posedge clk) begin
        if (rst || if_flush) begin
            if_valid <= 1'b0;
        end
        else begin
            if_valid <= 1'b1;
        end
    end

    // ID
    ID_SegReg u_ID_SegReg(
        .clk(clk),
        .rst(rst),
        
        .stall(id_stall),
        .flush(id_flush),

        .if_valid(if_valid),
        .id_ready(id_ready),
        .ex_ready(ex_ready),
        .id_valid(id_valid),

        .pc_if(pc),
        .inst_if(iram_rdata),
        .pc_id(pc_id),
        .inst_id(inst_id)
    );

    IDU u_IDU(
        .inst(inst_id),
        .imm(imm_id),
        .zimm(zimm_id),
        .alu_op(alu_op_id),
        .jump_type(jump_type_id),
        .mem_type(mem_type_id),
        .sel_alu_src1(sel_alu_src1_id),
        .sel_alu_src2(sel_alu_src2_id),
        .rf_wen(rf_wen_id),
        .sel_rf_wdata(sel_rf_wdata_id),
        .dram_en(dram_en_id),
        .dram_wen(dram_wen_id),
        .csr_op(csr_op_id),
        .csr_wen(csr_wen_id),
        .ecall_en(ecall_en_id),
        .mret_en(mret_en_id),
        .ebreak_en(ebreak_id)
    );

    regfile u_regfile(
        .clk(clk),
        .wen(rf_wen_wb),
        .raddr1(inst_id[19:15]),
        .raddr2(inst_id[24:20]),
        .waddr(inst_wb[11:7]),
        .wdata(rf_wdata_wb),
        .rdata1(rf_rdata1_id),
        .rdata2(rf_rdata2_id)
    );

    CSR u_CSR(
        .clk(clk),
        .rst(rst),
        .wen(csr_wen_wb),
        .raddr(inst_id[31:20]),
        .waddr(inst_wb[31:20]),
        .wdata(csr_wdata_wb),
        .rdata(csr_rdata_id),
        .mepc_wdata(pc_wb),
        .exception_en(exception_en_wb),
        .mepc_rdata(mepc_rdata_global),
        .mcause_wdata(mcause_wdata_wb),
        .mtvec_rdata(mtvec_rdata_global)
    );

    assign id_flush = id_valid & (|jump_type_id || mret_en_id || ecall_en_id); 
    assign if_flush = id_valid & (|jump_type_id || mret_en_id || ecall_en_id); 

    // Scoreboard only handle data hazard right now
    Scoreboard u_Scoreboard(
        .clk(clk),
        .rst(rst),
        .id_valid(id_valid),
        .ex_ready(ex_ready),
        .rs1(inst_id[19:15]),
        .rs2(inst_id[24:20]),
        .rd(inst_id[11:7]),
        .rf_wen(rf_wen_id),
        .id_stall(id_stall),
        .ex_flush(ex_flush)
    );

    // EX
    EX_SegReg u_EX_SegReg(
        .clk(clk),
        .rst(rst),
        .flush(ex_flush),

        .mem_ready(mem_ready),
        .ex_ready(ex_ready),
        .id_valid(id_valid),
        .ex_valid(ex_valid),

        .pc_id(pc_id),
        .inst_id(inst_id),
        .imm_id(imm_id),
        .zimm_id(zimm_id),
        .alu_op_id(alu_op_id),
        .jump_type_id(jump_type_id),
        .mem_type_id(mem_type_id),
        .sel_alu_src1_id(sel_alu_src1_id),
        .sel_alu_src2_id(sel_alu_src2_id),
        .rf_wen_id(rf_wen_id),
        .sel_rf_wdata_id(sel_rf_wdata_id),
        .csr_op_id(csr_op_id),
        .csr_wen_id(csr_wen_id),
        .ecall_en_id(ecall_en_id),
        .mret_en_id(mret_en_id),
        .rf_rdata1_id(rf_rdata1_id),
        .rf_rdata2_id(rf_rdata2_id),
        .csr_rdata_id(csr_rdata_id),
        .dram_en_id(dram_en_id),
        .dram_wen_id(dram_wen_id),
        .ebreak_id(ebreak_id),

        .pc_ex(pc_ex),
        .inst_ex(inst_ex),
        .imm_ex(imm_ex),
        .zimm_ex(zimm_ex),
        .alu_op_ex(alu_op_ex),
        .jump_type_ex(jump_type_ex),
        .mem_type_ex(mem_type_ex),
        .sel_alu_src1_ex(sel_alu_src1_ex),
        .sel_alu_src2_ex(sel_alu_src2_ex),
        .rf_wen_ex(rf_wen_ex),
        .sel_rf_wdata_ex(sel_rf_wdata_ex),
        .csr_op_ex(csr_op_ex),
        .csr_wen_ex(csr_wen_ex),
        .ecall_en_ex(ecall_en_ex),
        .mret_en_ex(mret_en_ex),
        .rf_rdata1_ex(rf_rdata1_ex),
        .rf_rdata2_ex(rf_rdata2_ex),
        .csr_rdata_ex(csr_rdata_ex),
        .dram_en_ex(dram_en_ex),
        .dram_wen_ex(dram_wen_ex),
        .ebreak_ex(ebreak_ex) 
    );
 
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;

    mux3_1 #(.WIDTH(32)) mux_alu_src1(
        .in0(rf_rdata1_ex),
        .in1(pc_ex),
        .in2(32'd0),
        .sel(sel_alu_src1_ex),
        .out(alu_src1)
    );

    mux3_1 #(.WIDTH(32)) mux_alu_src2(
        .in0(rf_rdata2_ex),
        .in1(imm_ex),
        .in2(32'd4),
        .sel(sel_alu_src2_ex),
        .out(alu_src2)
    );

    ALU u_ALU(
        .src1(alu_src1),
        .src2(alu_src2),
        .op(alu_op_ex),
        .res(alu_res_ex)
    );

    BRU u_BRU(
        .src1(rf_rdata1_ex),
        .src2(rf_rdata2_ex),
        .jump_type(jump_type_ex),
        .pc(pc_ex),
        .imm(imm_ex),
        .jump_target(jump_target_ex),
        .jump_taken(jump_taken_ex)
    );

    PriU u_PriU(
        .csr_op(csr_op_ex),
        .csr_rdata(csr_rdata_ex),
        .rf_rdata(rf_rdata1_ex),
        .zimm(zimm_ex),
        .csr_wdata(csr_wdata_ex)
    );

    DRAM_write_ctrl u_DRAM_write_ctrl(
        .wdata(rf_rdata2_ex),
        .dram_waddr(alu_res_ex),
        .store_type(mem_type_ex[2:0]),
        .dram_wmask(dram_wmask_ex),
        .dram_wdata(dram_wdata_ex)
    );

    // MEM
    MEM_SegReg u_MEM_SegReg(
        .clk(clk),
        .rst(rst),

        .wb_ready(wb_ready),
        .mem_ready(mem_ready),
        .ex_valid(ex_valid),
        .mem_valid(mem_valid),

        .pc_ex(pc_ex),
        .inst_ex(inst_ex),
        .alu_res_ex(alu_res_ex),
        .csr_wdata_ex(csr_wdata_ex),
        .mem_type_ex(mem_type_ex),
        .rf_wen_ex(rf_wen_ex),
        .sel_rf_wdata_ex(sel_rf_wdata_ex),
        .csr_wen_ex(csr_wen_ex),
        .ecall_en_ex(ecall_en_ex),
        .mret_en_ex(mret_en_ex),
        .csr_rdata_ex(csr_rdata_ex),
        .dram_en_ex(dram_en_ex),
        .dram_wen_ex(dram_wen_ex),
        .dram_wmask_ex(dram_wmask_ex),
        .dram_wdata_ex(dram_wdata_ex),
        .ebreak_ex(ebreak_ex),

        .pc_mem(pc_mem),
        .inst_mem(inst_mem),
        .alu_res_mem(alu_res_mem),
        .csr_wdata_mem(csr_wdata_mem),
        .mem_type_mem(mem_type_mem),
        .rf_wen_mem(rf_wen_mem),
        .sel_rf_wdata_mem(sel_rf_wdata_mem),
        .csr_wen_mem(csr_wen_mem),
        .ecall_en_mem(ecall_en_mem),
        .mret_en_mem(mret_en_mem),
        .csr_rdata_mem(csr_rdata_mem),
        .dram_en_mem(dram_en_mem),
        .dram_wen_mem(dram_wen_mem),
        .dram_wmask_mem(dram_wmask_mem),
        .dram_wdata_mem(dram_wdata_mem),
        .ebreak_mem(ebreak_mem)
    );

    assign dram_addr  = alu_res_mem;
    assign dram_en    = dram_en_mem & mem_valid;
    assign dram_wen   = dram_wen_mem & mem_valid;
    assign dram_wmask = dram_wmask_mem;
    assign dram_wdata = dram_wdata_mem;

    DRAM_read_ctrl u_DRAM_read_ctrl(
        .dram_rdata(dram_rdata),
        .dram_raddr(alu_res_mem),
        .load_type(mem_type_mem[7:3]),
        .load_data(load_data_mem)
    );

    
    // WB
    WB_SegReg u_WB_SegReg(
        .clk(clk),
        .rst(rst),

        .mem_valid(mem_valid),
        .wb_ready(wb_ready),

        .pc_mem(pc_mem),
        .inst_mem(inst_mem),
        .load_data_mem(load_data_mem),
        .alu_res_mem(alu_res_mem),
        .csr_rdata_mem(csr_rdata_mem),
        .sel_rf_wdata_mem(sel_rf_wdata_mem),
        .ecall_en_mem(ecall_en_mem),
        .mret_en_mem(mret_en_mem),
        .rf_wen_mem(rf_wen_mem),
        .csr_wen_mem(csr_wen_mem),
        .csr_wdata_mem(csr_wdata_mem),
        .ebreak_mem(ebreak_mem),

        .pc_wb(pc_wb),
        .inst_wb(inst_wb),
        .load_data_wb(load_data_wb),
        .alu_res_wb(alu_res_wb),
        .csr_rdata_wb(csr_rdata_wb),
        .sel_rf_wdata_wb(sel_rf_wdata_wb),
        .ecall_en_wb(ecall_en_wb),
        .mret_en_wb(mret_en_wb),
        .rf_wen_wb(rf_wen_wb),
        .csr_wen_wb(csr_wen_wb),
        .csr_wdata_wb(csr_wdata_wb),
        .ebreak_wb(ebreak_wb)
    );

    mux3_1 #(.WIDTH(32)) mux_rf_wdata(
        .in0(alu_res_wb),
        .in1(load_data_wb),
        .in2(csr_rdata_wb),
        .sel(sel_rf_wdata_wb),
        .out(rf_wdata_wb)
    );

    Exp_Commit u_Exp_Commit(
        .ecall_en(ecall_en_wb),
        .mcause_wdata(mcause_wdata_wb),
        .exception_en(exception_en_wb)
    );

    import "DPI-C" function void npc_trap();
    always @(*) begin
        if(ebreak_wb)
            npc_trap();
    end

endmodule
