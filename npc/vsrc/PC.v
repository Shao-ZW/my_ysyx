module PC (
    input         clock,
    input         reset,
    input         wen,
    input  [31:0] next_pc,
    output [31:0] pc
);
    reg [31:0] pc_reg;

    always @(posedge clock) begin
        if (reset) begin
            pc_reg <= 32'h80000000;
        end
        else if (wen) begin
            pc_reg <= next_pc;
        end
    end

    assign pc = pc_reg;
endmodule
