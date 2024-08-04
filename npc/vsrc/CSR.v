module CSR(
    input         clk,
    input         rst,
    input         wen,
    input  [11:0] raddr,
    input  [11:0] waddr,
    input  [31:0] wdata,
    input         exception_en,
    input  [31:0] mepc_wdata,
    input  [31:0] mcause_wdata,
    output [31:0] mtvec_rdata, 
    output [31:0] mepc_rdata,
    output reg [31:0] rdata
);
    reg [31:0] mstatus;
    always @(posedge clk) begin
        if(rst) begin
            mstatus <= 32'h1800;
        end
        else if(waddr == 12'h300 && wen) begin
            mstatus <= wdata;
        end
    end

    reg [31:0] mtvec;
    always @(posedge clk) begin
        if(rst) begin
            mtvec <= 32'h0;
        end
        else if(waddr == 12'h305 && wen) begin
            mtvec <= wdata;
        end
    end

    reg [31:0] mepc;
    always @(posedge clk) begin
        if(rst) begin
            mepc <= 32'h0;
        end
        else if(exception_en) begin
            mepc <= mepc_wdata;
        end
        else if(waddr == 12'h341 && wen) begin
            mepc <= wdata;
        end
    end

    reg [31:0] mcause;
    always @(posedge clk) begin
        if(rst) begin
            mcause <= 32'h0;
        end
        else if(exception_en) begin
            mcause <= mcause_wdata;
        end
        else if(waddr == 12'h342 && wen) begin
            mcause <= wdata;
        end
    end

    always @(*) begin
        case(raddr)
            12'h300: rdata = mstatus;
            12'h305: rdata = mtvec;
            12'h341: rdata = mepc;
            12'h342: rdata = mcause;
            default: rdata = 32'h0;
        endcase
    end

    assign mtvec_rdata = mtvec;

    assign mepc_rdata = mepc;
endmodule
