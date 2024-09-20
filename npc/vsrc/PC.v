module PC (
    input         clk,
    input         rst,
    input         wen,
    input  [31:0] next_pc,
    output [31:0] pc
);
    reg [31:0] pc_reg;
    reg rst_done;

    always @(posedge clk) begin
        if (rst) begin
            pc_reg <= 32'h80000000;
            rst_done <= 1'b0;
        end
        else begin
            rst_done <= 1'b1;
            if (wen && rst_done) begin
                pc_reg <= next_pc;
            end
        end
    end

    assign pc = pc_reg;
endmodule
