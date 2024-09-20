module IRAM (
    input             clk,
    input             iram_en,
    input      [31:0] iram_addr,
    output reg [31:0] iram_rdata
);
    import "DPI-C" function int pmem_read(input int raddr);

    always @(*) begin
        if (iram_en) begin 
            iram_rdata = pmem_read(iram_addr);
        end
        else begin
            iram_rdata = 32'b0;
        end
    end

endmodule
