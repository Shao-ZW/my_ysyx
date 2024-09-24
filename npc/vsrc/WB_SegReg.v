module WB_SegReg (
    input clock,
    input reset,

    input  mem_valid,
    output wb_ready,

    input [31:0] pc_mem,
    input [31:0] inst_mem,
    input [31:0] load_data_mem,
    input [31:0] alu_res_mem,
    input [31:0] csr_rdata_mem,
    input [2:0]  sel_rf_wdata_mem,
    input        ecall_en_mem,
    input        mret_en_mem,
    input        rf_wen_mem,
    input        csr_wen_mem,
    input [31:0] csr_wdata_mem,
    input        ebreak_mem,

    output reg [31:0] pc_wb,
    output reg [31:0] inst_wb,
    output reg [31:0] load_data_wb,
    output reg [31:0] alu_res_wb,
    output reg [31:0] csr_rdata_wb,
    output reg [2:0]  sel_rf_wdata_wb,
    output reg        ecall_en_wb,
    output reg        mret_en_wb,
    output reg        rf_wen_wb,
    output reg        csr_wen_wb,
    output reg [31:0] csr_wdata_wb,
    output reg        ebreak_wb
);
    reg valid;
    wire ready_go;

    assign ready_go = 1'b1;  //  可以在一个周期完成，恒为1
    assign wb_ready = !valid || ready_go;

    always @(posedge clock) begin
        if (reset) begin
            valid <= 1'b0;
        end
        else if (wb_ready) begin
            valid <= mem_valid;
        end
    end

    always @(posedge clock) begin
        if (wb_ready && mem_valid) begin
            pc_wb           <= pc_mem;
            inst_wb         <= inst_mem;
            load_data_wb    <= load_data_mem;
            alu_res_wb      <= alu_res_mem;
            csr_rdata_wb    <= csr_rdata_mem;
            sel_rf_wdata_wb <= sel_rf_wdata_mem;
            ecall_en_wb     <= ecall_en_mem;
            mret_en_wb      <= mret_en_mem;
            rf_wen_wb       <= rf_wen_mem;
            csr_wen_wb      <= csr_wen_mem;
            csr_wdata_wb    <= csr_wdata_mem;
            ebreak_wb       <= ebreak_mem;
        end
        else if (wb_ready && !mem_valid) begin
            rf_wen_wb       <= 1'b0;
            csr_wen_wb      <= 1'b0;
            ecall_en_wb     <= 1'b0;
            mret_en_wb      <= 1'b0;
            ebreak_wb       <= 1'b0;
        end
    end
endmodule