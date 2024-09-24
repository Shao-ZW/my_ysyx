module AXI_arbiter(
    input         clock,
    input         reset,

    // IFU
    input         i_rvalid,
    output reg    i_rready,
    input  [31:0] i_raddr,
    output [31:0] i_rdata,

    // LSU
    input         d_rvalid,
    output reg    d_rready,
    input  [31:0] d_raddr,
    output [31:0] d_rdata,

    input         d_wvalid,
    output reg    d_wready,
    input  [31:0] d_waddr,
    input  [31:0] d_wdata,
    input  [3:0]  d_wstrb,

    // AR
    output reg [31:0] araddr,
    output reg        arvalid,
    input             arready,

    // R
    input [31:0] rdata,
    input [1:0]  rresp,
    input        rvalid,
    output reg   rready,

    // AW
    output [31:0] awaddr,
    output reg    awvalid,
    input         awready,

    // W
    output [31:0] wdata,
    output [3:0]  wstrb,
    output reg    wvalid,
    input         wready,

    // B
    input [1:0] bresp,
    input       bvalid,
    output reg  bready
);

    // read part
    reg [4:0] r_crt, r_nxt;

    always @(posedge clock) begin
        if(reset) begin
            r_crt <= 5'b00001;
        end else begin
            r_crt <= r_nxt;
        end
    end

    always @(*) begin
        case(r_crt)
        5'b00001: begin // R_IDLE
            r_nxt = d_rvalid ? 5'b01000 : i_rvalid ? 5'b00010 : 5'b00001; 
        end
        5'b00010: begin // I_AR
            r_nxt = arready & arvalid ? 5'b00100 : 5'b00010; 
        end
        5'b00100: begin // I_R
            r_nxt = rready & rvalid ? 5'b00001 : 5'b00100; 
        end
        5'b01000: begin // D_AR
            r_nxt = arready & arvalid ? 5'b10000 : 5'b01000; 
        end
        5'b10000: begin // D_R
            r_nxt = rready & rvalid ? 5'b00001 : 5'b10000; 
        end
        default: r_nxt = 5'b00001;    
        endcase
    end
    
    assign i_rdata = rdata;
    assign d_rdata = rdata;

    always @(*) begin
        case(r_crt) 
        5'b00001: begin // R_IDLE
            i_rready = 1'b0;
            d_rready = 1'b0;
            arvalid  = 1'b0;
            araddr   = 32'b0;
            rready   = 1'b0;
        end
        5'b00010: begin // I_AR
            i_rready = 1'b0;
            d_rready = 1'b0;
            arvalid  = 1'b1;
            araddr   = i_raddr;
            rready   = 1'b0;
        end
        5'b00100: begin // I_R
            i_rready = rvalid;
            d_rready = 1'b0;
            arvalid  = 1'b0;
            araddr   = 32'b0;
            rready   = 1'b1;
        end
        5'b01000: begin // D_AR
            i_rready = 1'b0;
            d_rready = 1'b0;
            arvalid  = 1'b1;
            araddr   = d_raddr;
            rready   = 1'b0;
        end
        5'b10000: begin // D_R
            i_rready = 1'b0;
            d_rready = rvalid;
            arvalid  = 1'b0;
            araddr   = 32'b0;
            rready   = 1'b1;
        end
        default: begin
            i_rready = 1'b0;
            d_rready = 1'b0;
            arvalid  = 1'b0;
            araddr   = 32'b0;
            rready   = 1'b0;
        end   
        endcase
    end

    // write part
    reg [3:0] w_crt, w_nxt;

    always @(posedge clock) begin
        if(reset) begin
            w_crt <= 4'b0001;
        end else begin
            w_crt <= w_nxt;
        end
    end

    always @(*) begin
        case(w_crt)
        4'b0001: begin // W_IDLE
            w_nxt = d_wvalid ? 4'b0010 : 4'b0001;
        end
        4'b0010: begin // D_AW
            w_nxt = awready & awvalid ? 4'b0100 : 4'b0010;
        end
        4'b0100: begin // D_W
            w_nxt = wready & wvalid ? 4'b1000 : 4'b0100;
        end
        4'b1000: begin // D_B
            w_nxt = bready & bvalid ? 4'b0001 : 4'b1000;
        end
        default: w_nxt = 4'b0001;    
        endcase
    end

    assign awaddr   = d_waddr;
    assign wdata    = d_wdata;
    assign wstrb    = d_wstrb;

    always @(*) begin
        case(w_crt)
        4'b0001: begin // W_IDLE
            d_wready    = 1'b0;
            bready      = 1'b0;
            awvalid     = 1'b0;
            wvalid      = 1'b0;
        end
        4'b0010: begin // D_AW
            d_wready    = 1'b0;
            bready      = 1'b0;
            awvalid     = 1'b1;
            wvalid      = 1'b0;
        end
        4'b0100: begin // D_W
            d_wready    = 1'b0;
            bready      = 1'b0;
            awvalid     = 1'b0;
            wvalid      = 1'b1;
        end
        4'b1000: begin // D_B
            d_wready    = bvalid;
            bready      = 1'b1;
            awvalid     = 1'b0;
            wvalid      = 1'b0;
        end
        default: begin
            d_wready    = 1'b0;
            bready      = 1'b0;
            awvalid     = 1'b0;
            wvalid      = 1'b0;
        end
        endcase
    end

endmodule
