module CPU(
    input         clk,
    input         rst,
    input  [31:0] inst,
    input  [31:0] dram_rdata,
    output        iram_en,
    output [31:0] iram_addr,
    output        dram_en,
    output        dram_wen,
    output [31:0] dram_addr,
    output [31:0] dram_wdata,
    output [3:0]  dram_wmask
);

    wire [31:0] pc;
    wire [31:0] next_pc;
    wire        rst_done;

    wire [31:0] rf_rdata1;
    wire [31:0] rf_rdata2;
    wire [31:0] rf_wdata;

    wire [31:0] csr_rdata;
    wire [31:0] csr_wdata;
    wire [31:0] mcause_wdata;
    wire [31:0] mtvec_rdata;
    wire [31:0] mepc_rdata;

    wire [31:0] imm;
    wire [9:0]  alu_op;
    wire [2:0]  sel_alu_src1; // 001 rf_rdata1 010 pc  100 0
    wire [2:0]  sel_alu_src2; // 001 rf_rdata2 010 imm 100 4
    wire [7:0]  jump_type;
    wire [7:0]  mem_type;
    wire [2:0]  sel_rf_wdata; // 001 alu_res 010 dram 100 csr_data
    wire        rf_wen;
    wire [5:0]  csr_op;
    wire [31:0] zimm;
    wire        csr_wen;
    wire        ecall_en;
    wire        mret_en;

    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire [31:0] alu_res;

    wire [31:0] jump_target;
    wire        jump_taken;

    wire [31:0] load_data;

    wire exception_en;


    // IF
    assign iram_en   = rst_done;
    assign iram_addr = pc;

    NPC u_NPC(
        .pc(pc),
        .mtvec_rdata(mtvec_rdata),
        .mepc_rdata(mepc_rdata),
        .jump_target(jump_target),
        .exception_en(exception_en),
        .mret_en(mret_en),
        .jump_taken(jump_taken),
        .next_pc(next_pc)
    );

    PC u_PC(
        .clk(clk),
        .rst(rst),
        .wen(1'b1),
        .next_pc(next_pc),
        .rst_done(rst_done),
        .pc(pc)
    );


    // ID
    IDU u_IDU(
        .inst(inst),
        .imm(imm),
        .zimm(zimm),
        .alu_op(alu_op),
        .jump_type(jump_type),
        .mem_type(mem_type),
        .sel_alu_src1(sel_alu_src1),
        .sel_alu_src2(sel_alu_src2),
        .rf_wen(rf_wen),
        .sel_rf_wdata(sel_rf_wdata),
        .dram_en(dram_en),
        .dram_wen(dram_wen),
        .csr_op(csr_op),
        .csr_wen(csr_wen),
        .ecall_en(ecall_en),
        .mret_en(mret_en)
    );

    regfile u_regfile(
        .clk(clk),
        .wen(rf_wen),
        .raddr1(inst[19:15]),
        .raddr2(inst[24:20]),
        .waddr(inst[11:7]),
        .wdata(rf_wdata),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2)
    );

    CSR u_CSR(
        .clk(clk),
        .rst(rst),
        .wen(csr_wen),
        .raddr(imm[11:0]),
        .waddr(imm[11:0]),
        .wdata(csr_wdata),
        .rdata(csr_rdata),
        .mepc_wdata(pc),
        .exception_en(exception_en),
        .mepc_rdata(mepc_rdata),
        .mcause_wdata(mcause_wdata),
        .mtvec_rdata(mtvec_rdata)
    );

    // EXE
    mux3_1 #(.WIDTH(32)) mux_alu_src1(
        .in0(rf_rdata1),
        .in1(pc),
        .in2(32'd0),
        .sel(sel_alu_src1),
        .out(alu_src1)
    );

    mux3_1 #(.WIDTH(32)) mux_alu_src2(
        .in0(rf_rdata2),
        .in1(imm),
        .in2(32'd4),
        .sel(sel_alu_src2),
        .out(alu_src2)
    );

    ALU u_ALU(
        .src1(alu_src1),
        .src2(alu_src2),
        .op(alu_op),
        .res(alu_res)
    );

    BRU u_BRU(
        .src1(rf_rdata1),
        .src2(rf_rdata2),
        .jump_type(jump_type),
        .pc(pc),
        .imm(imm),
        .target(jump_target),
        .taken(jump_taken)
    );

    PriU u_PriU(
        .csr_op(csr_op),
        .csr_rdata(csr_rdata),
        .rf_rdata(rf_rdata1),
        .zimm(zimm),
        .csr_wdata(csr_wdata)
    );

    // MEM
    assign dram_addr = alu_res;

    DRAM_read_ctrl u_DRAM_read_ctrl(
        .dram_rdata(dram_rdata),
        .dram_raddr(dram_addr),
        .load_type(mem_type[7:3]),
        .load_data(load_data)
    );

    DRAM_write_ctrl u_DRAM_write_ctrl(
        .wdata(rf_rdata2),
        .dram_waddr(dram_addr),
        .store_type(mem_type[2:0]),
        .dram_wmask(dram_wmask),
        .dram_wdata(dram_wdata)
    );

    // WB
    mux3_1 #(.WIDTH(32)) mux_rf_wdata(
        .in0(alu_res),
        .in1(load_data),
        .in2(csr_rdata),
        .sel(sel_rf_wdata),
        .out(rf_wdata)
    );

    Exp_Commit u_Exp_Commit(
        .ecall_en(ecall_en),
        .mcause_wdata(mcause_wdata),
        .exception_en(exception_en)
    );

endmodule
