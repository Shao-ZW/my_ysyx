module ID_SegReg (
    input clk,
    input rst,
    input stall,
    input flush,

    input  if_valid,
    output id_ready,
    input  ex_ready,
    output id_valid,

    input [31:0] pc_if,
    input [31:0] inst_if,

    output reg [31:0] pc_id,
    output reg [31:0] inst_id
);    
    reg valid;
    wire ready_go;

    assign ready_go = 1'b1 && !stall;
    assign id_ready = !valid || ready_go && ex_ready;
    assign id_valid = valid && ready_go;

    always @(posedge clk) begin
        if (rst || flush) begin
            valid <= 1'b0;
        end
        else if (id_ready) begin
            valid <= if_valid;
        end
    end

    always @(posedge clk) begin
        if (id_ready && if_valid) begin
            pc_id   <= pc_if;
            inst_id <= inst_if;
        end
    end

endmodule