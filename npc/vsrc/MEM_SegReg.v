module MEM_SegReg (
    input clk,
    input rst,

    input  wb_ready,
    output mem_ready,
    input  ex_valid,
    output mem_valid,

    input [31:0] pc_ex,
    input [31:0] inst_ex,
    input [31:0] alu_res_ex,
    input [31:0] csr_wdata_ex,
    input [7:0]  mem_type_ex,
    input        rf_wen_ex,
    input [2:0]  sel_rf_wdata_ex,
    input        csr_wen_ex,
    input        ecall_en_ex,
    input        mret_en_ex,
    input [31:0] csr_rdata_ex,
    input        dram_en_ex,
    input        dram_wen_ex,
    input [3:0]  dram_wmask_ex,
    input [31:0] dram_wdata_ex,
    input        ebreak_ex,

    output reg [31:0] pc_mem,
    output reg [31:0] inst_mem,
    output reg [31:0] alu_res_mem,
    output reg [31:0] csr_wdata_mem,
    output reg [7:0]  mem_type_mem,
    output reg        rf_wen_mem,
    output reg [2:0]  sel_rf_wdata_mem,
    output reg        csr_wen_mem,
    output reg        ecall_en_mem,
    output reg        mret_en_mem,
    output reg [31:0] csr_rdata_mem,
    output reg        dram_en_mem,
    output reg        dram_wen_mem,
    output reg [3:0]  dram_wmask_mem,
    output reg [31:0] dram_wdata_mem,
    output reg        ebreak_mem
);
    reg valid;
    wire ready_go;
    
    assign ready_go = 1'b1;  //  可以在一个周期完成，恒为1
    assign mem_ready = !valid || ready_go && wb_ready;
    assign mem_valid = valid && ready_go;

    always @(posedge clk) begin
        if (rst) begin
            valid <= 1'b0;
        end
        else if (mem_ready) begin
            valid <= ex_valid;
        end
    end

    always @(posedge clk) begin
        if (mem_ready && ex_valid) begin
            pc_mem           <= pc_ex;
            inst_mem         <= inst_ex;
            alu_res_mem      <= alu_res_ex;
            csr_wdata_mem    <= csr_wdata_ex;
            mem_type_mem     <= mem_type_ex;
            rf_wen_mem       <= rf_wen_ex;
            sel_rf_wdata_mem <= sel_rf_wdata_ex;
            csr_wen_mem      <= csr_wen_ex;
            ecall_en_mem     <= ecall_en_ex;
            mret_en_mem      <= mret_en_ex;
            csr_rdata_mem    <= csr_rdata_ex;
            dram_en_mem      <= dram_en_ex;
            dram_wen_mem     <= dram_wen_ex;
            dram_wmask_mem   <= dram_wmask_ex;
            dram_wdata_mem   <= dram_wdata_ex;
            ebreak_mem       <= ebreak_ex;
        end
    end
endmodule