module EX_SegReg (
    input clk,
    input rst,

    input flush,

    input  mem_ready,
    output ex_ready,
    input  id_valid,
    output ex_valid,

    input [31:0] pc_id,
    input [31:0] inst_id,
    input [31:0] imm_id,
    input [31:0] zimm_id,
    input [9:0]  alu_op_id,
    input [7:0]  jump_type_id,    // {inst_bgeu, inst_bltu, inst_bge, inst_blt, inst_bne, inst_beq, inst_jalr, inst_jal}
    input [7:0]  mem_type_id,     // {inst_lhu, inst_lbu, inst_lw, inst_lh, inst_lb, inst_sw, inst_sh, inst_sb}
    input [2:0]  sel_alu_src1_id, // 001 rf_rdata1 010 pc  100 0
    input [2:0]  sel_alu_src2_id, // 001 rf_rdata2 010 imm 100 4
    input        rf_wen_id,
    input [2:0]  sel_rf_wdata_id, // 001 alu_res 010 dram 100 csr_data
    input [5:0]  csr_op_id,       // {inst_csrrci, inst_csrrsi, inst_csrrwi, inst_csrrc, inst_csrrs, inst_csrrw}
    input        csr_wen_id,
    input        ecall_en_id,
    input        mret_en_id,
    input [31:0] rf_rdata1_id,
    input [31:0] rf_rdata2_id,
    input [31:0] csr_rdata_id,
    input        dram_en_id,  // save for a while
    input        dram_wen_id, // save for a while
    input        ebreak_id,

    output reg [31:0] pc_ex,
    output reg [31:0] inst_ex,
    output reg [31:0] imm_ex,
    output reg [31:0] zimm_ex,
    output reg [9:0]  alu_op_ex,
    output reg [7:0]  jump_type_ex,    // {inst_bgeu, inst_bltu, inst_bge, inst_blt, inst_bne, inst_beq, inst_jalr, inst_jal}
    output reg [7:0]  mem_type_ex,     // {inst_lhu, inst_lbu, inst_lw, inst_lh, inst_lb, inst_sw, inst_sh, inst_sb}
    output reg [2:0]  sel_alu_src1_ex, // 001 rf_rdata1 010 pc  100 0
    output reg [2:0]  sel_alu_src2_ex, // 001 rf_rdata2 010 imm 100 4
    output reg        rf_wen_ex,
    output reg [2:0]  sel_rf_wdata_ex, // 001 alu_res 010 dram 100 csr_data
    output reg [5:0]  csr_op_ex,       // {inst_csrrci, inst_csrrsi, inst_csrrwi, inst_csrrc, inst_csrrs, inst_csrrw}
    output reg        csr_wen_ex,
    output reg        ecall_en_ex,
    output reg        mret_en_ex,
    output reg [31:0] rf_rdata1_ex,
    output reg [31:0] rf_rdata2_ex,
    output reg [31:0] csr_rdata_ex,
    output reg        dram_en_ex,  // save for a while
    output reg        dram_wen_ex, // save for a while
    output reg        ebreak_ex
);
    reg valid;
    wire ready_go;
    
    assign ready_go = 1'b1;  //  可以在一个周期完成，恒为1
    assign ex_ready = !valid || ready_go && mem_ready;
    assign ex_valid = valid && ready_go;

    always @(posedge clk) begin
        if (rst || flush) begin
            valid <= 1'b0;
        end
        else if (ex_ready) begin
            valid <= id_valid;
        end
    end

    always @(posedge clk) begin
        if (ex_ready && id_valid) begin
            pc_ex           <= pc_id;
            inst_ex         <= inst_id;
            imm_ex          <= imm_id;
            zimm_ex         <= zimm_id;
            alu_op_ex       <= alu_op_id;
            jump_type_ex    <= jump_type_id;
            mem_type_ex     <= mem_type_id;
            sel_alu_src1_ex <= sel_alu_src1_id;
            sel_alu_src2_ex <= sel_alu_src2_id;
            rf_wen_ex       <= rf_wen_id;
            sel_rf_wdata_ex <= sel_rf_wdata_id;
            csr_op_ex       <= csr_op_id;
            csr_wen_ex      <= csr_wen_id;
            ecall_en_ex     <= ecall_en_id;
            mret_en_ex      <= mret_en_id;
            rf_rdata1_ex    <= rf_rdata1_id;
            rf_rdata2_ex    <= rf_rdata2_id;
            csr_rdata_ex    <= csr_rdata_id;
            dram_en_ex      <= dram_en_id;
            dram_wen_ex     <= dram_wen_id;
            ebreak_ex       <= ebreak_id;
        end
    end

endmodule