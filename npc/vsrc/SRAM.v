module SRAM(
    input clock,
    input reset
);

endmodule

module SRAM_AXI(
    input clock,
    input reset,

    // AR
    input [31:0] araddr,
    input        arvalid,
    output reg   arready,

    // R
    output     [31:0] rdata,
    output reg [1:0]  rresp,
    output reg        rvalid,
    input             rready,

    // AW
    input [31:0] awaddr,
    input        awvalid,
    output reg   awready,

    // W
    input [31:0] wdata,
    input [3:0]  wstrb,
    input        wvalid,
    output reg   wready,

    // B
    output reg [1:0] bresp,
    output reg       bvalid,
    input            bready
);
    import "DPI-C" function int pmem_read(input int raddr);
    import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);

    reg        ram_ren;
    reg        ram_wen;
    reg [31:0] ram_addr;
    reg [31:0] ram_rdata;
    reg        ram_rvalid;
    reg [3:0]  ram_wmask;
    reg [31:0] ram_wdata;
    reg        ram_wvalid;

    reg [5:0] crt, nxt;

    always @(posedge clock) begin
        if(reset) begin
            crt <= 6'b000001;
        end else begin
            crt <= nxt;
        end
    end

    always @(*) begin
        case(crt)
        6'b000001: begin // IDLE
            nxt = arvalid ? 6'b000010 : awvalid ? 6'b001000 : 6'b000001;
        end
        6'b000010: begin // AR
            nxt = arready & arvalid ? 6'b000100 : 6'b000010; 
        end
        6'b000100: begin // R
            nxt = rready & rvalid ? 6'b000001 : 6'b000100; 
        end
        6'b001000: begin // AW
            nxt = awready & awvalid ? 6'b010000 : 6'b001000;
        end
        6'b010000: begin // W
            nxt = wready & wvalid ? 6'b100000 : 6'b010000;
        end
        6'b100000: begin // B
            nxt = bready & bvalid ? 6'b000001 : 6'b100000;
        end
        default: nxt = 6'b000001;    
        endcase
    end

    assign rdata = ram_rdata;

    always @(posedge clock) begin
        case (crt)
        6'b000010: begin // AR
            ram_addr  <= araddr;
            ram_wdata <= ram_wdata;
            ram_wmask <= ram_wmask;
            ram_ren   <= 1'b0;
            ram_wen   <= 1'b0;
        end
        6'b000100: begin // R
            ram_addr  <= ram_addr;
            ram_wdata <= ram_wdata;
            ram_wmask <= ram_wmask;
            ram_ren   <= 1'b1;
            ram_wen   <= 1'b0;
        end
        6'b001000: begin // AW
            ram_addr  <= awaddr;
            ram_wdata <= ram_wdata;
            ram_wmask <= ram_wmask;
            ram_ren   <= 1'b0;
            ram_wen   <= 1'b0;
        end
        6'b010000: begin // W
            ram_addr  <= ram_addr;
            ram_wdata <= wdata;
            ram_wmask <= wstrb;
            ram_ren   <= 1'b0;
            ram_wen   <= 1'b1;
        end
        default: begin
            ram_addr  <= ram_addr;
            ram_wdata <= ram_wdata;
            ram_wmask <= ram_wmask;
            ram_ren   <= 1'b0;
            ram_wen   <= 1'b0;
        end
        endcase
    end

    always @(*) begin
        case(crt)
        6'b000001: begin // IDLE
            arready = 1'b0;
            rresp   = 2'b00;
            rvalid  = 1'b0;
            awready = 1'b0;
            wready  = 1'b0;
            bresp   = 2'b00;
            bvalid  = 1'b0;
        end
        6'b000010: begin // AR
            arready = 1'b1;
            rresp   = 2'b00;
            rvalid  = 1'b0;
            awready = 1'b0;
            wready  = 1'b0;
            bresp   = 2'b00;
            bvalid  = 1'b0;
        end
        6'b000100: begin // R
            arready = 1'b0;
            rresp   = 2'b00;
            rvalid  = ram_rvalid;
            awready = 1'b0;
            wready  = 1'b0;
            bresp   = 2'b00;
            bvalid  = 1'b0;
        end
        6'b001000: begin // AW
            arready = 1'b0;
            rresp   = 2'b00;
            rvalid  = 1'b0;
            awready = 1'b1;
            wready  = 1'b0;
            bresp   = 2'b00;
            bvalid  = 1'b0;
        end
        6'b010000: begin // W
            arready = 1'b0;
            rresp   = 2'b00;
            rvalid  = 1'b0;
            awready = 1'b0;
            wready  = 1'b1;
            bresp   = 2'b00;
            bvalid  = 1'b0;
        end
        6'b100000: begin // B
            arready = 1'b0;
            rresp   = 2'b00;
            rvalid  = 1'b0;
            awready = 1'b0;
            wready  = 1'b0;
            bresp   = 2'b00;
            bvalid  = ram_wvalid;
        end
        default: begin
            arready = 1'b0;
            rresp   = 2'b00;
            rvalid  = 1'b0;
            awready = 1'b0;
            wready  = 1'b0;
            bresp   = 2'b00;
            bvalid  = 1'b0;
        end
        endcase
    end

    always @(*) begin
        if (ram_ren) begin 
            ram_rdata = pmem_read(ram_addr);
            ram_rvalid = 1'b1;
        end
        else begin
            ram_rdata = 0;
            ram_rvalid = 1'b0;
        end
    end

    always @(posedge clock) begin
        if(ram_wen) begin
            pmem_write(ram_addr, ram_wdata, {4'b0000, ram_wmask});
            ram_wvalid = 1'b1;
        end
        else begin
            ram_wvalid = 1'b0;
        end
    end

endmodule
