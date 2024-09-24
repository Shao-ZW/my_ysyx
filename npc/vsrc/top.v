module top(
    input clock,
    input reset
);
    // AXI-Lite Interface

    // AR
    wire [31:0] araddr;
    wire        arvalid;
    wire        arready;

    // R
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    wire        rready;

    // AW
    wire [31:0] awaddr;
    wire        awvalid;
    wire        awready;

    // W
    wire [31:0] wdata;
    wire [3:0]  wstrb;
    wire        wvalid;
    wire        wready;

    // B
    wire [ 1:0] bresp;
    wire        bvalid;
    wire        bready;

    CPU u_CPU(
        .clock(clock),
        .reset(reset),

        .araddr(araddr),
        .arvalid(arvalid),
        .arready(arready),

        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready),

        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),

        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wready(wready),

        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready)
    );

    SRAM_AXI u_SRAM_AXI(
        .clock(clock),
        .reset(reset),
        
        .araddr(araddr),
        .arvalid(arvalid),
        .arready(arready),

        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready),

        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),

        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wready(wready),

        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready)
    );

endmodule
