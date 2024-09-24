module mux2_1 #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input              sel,
    output [WIDTH-1:0] out
);
    assign out = sel ? in1 : in0;
    
endmodule

module mux3_1 #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [2:0]       sel,
    output [WIDTH-1:0] out
);
    assign out =  ({32{sel[0]}} & in0)
                | ({32{sel[1]}} & in1)
                | ({32{sel[2]}} & in2);
    
endmodule

module mux5_1 #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [WIDTH-1:0] in3,
    input  [WIDTH-1:0] in4,
    input  [4:0]       sel,
    output [WIDTH-1:0] out
);
    assign out =  ({32{sel[0]}} & in0)
                | ({32{sel[1]}} & in1)
                | ({32{sel[2]}} & in2)
                | ({32{sel[3]}} & in3)
                | ({32{sel[4]}} & in4);    
endmodule

module LFSR (
    input clock,
    input reset,
    output [7:0] lfsr_out
);
    reg [7:0] lfsr_reg;

    always @(posedge clock) begin
        if (reset) begin
            lfsr_reg <= 8'b00000001;
        end else begin
            lfsr_reg <= {lfsr_reg[4] ^ lfsr_reg[3] ^ lfsr_reg[2] ^ lfsr_reg[0], lfsr_reg[7:1]};
        end
    end

    assign lfsr_out = lfsr_reg;
endmodule
