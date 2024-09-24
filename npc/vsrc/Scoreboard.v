module Scoreboard(
    input       clock,
    input       reset,
    input       id_valid,
    input       ex_ready,
    input [4:0] wb_rd,
    input       wb_rf_wen,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input       rf_wen,
    output      id_stall,
    output      ex_flush
);
    reg pending[31:0];
    reg [2:0] result_pos[31:0];

    integer i;
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                result_pos[i] <= 3'b000;
            end
        end
        else begin
            if (wb_rf_wen && wb_rd != 5'b00000) begin
                result_pos[wb_rd] <= result_pos[wb_rd] - 1'b1;
            end

            if (id_valid && ex_ready && !ex_flush && rf_wen && rd != 5'b00000) begin
                result_pos[rd] <= result_pos[rd] + 1'b1;
            end
        end
    end

    always @(*) begin
        for (i = 0; i < 32; i = i + 1) begin
            pending[i] = |result_pos[i];
        end
    end

    assign id_stall = pending[rs1] || pending[rs2];
    assign ex_flush = id_valid & ex_ready & (pending[rs1] || pending[rs2]);

endmodule
