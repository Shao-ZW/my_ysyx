module top(
    input clk,
    input rst
);
    wire        iram_en;
    wire [31:0] iram_rdata;
    wire [31:0] iram_addr;

    wire        dram_en;
    wire        dram_wen;
    wire [31:0] dram_rdata;
    wire [31:0] dram_addr;
    wire [31:0] dram_wdata;
    wire [3:0]  dram_wmask;
    
    CPU u_CPU(
        .clk(clk),
        .rst(rst),
        .iram_rdata(iram_rdata),
        .iram_en(iram_en),
        .iram_addr(iram_addr),
        .dram_rdata(dram_rdata),
        .dram_en(dram_en),
        .dram_wen(dram_wen),
        .dram_addr(dram_addr),
        .dram_wdata(dram_wdata),
        .dram_wmask(dram_wmask)
    );

    DRAM u_DRAM(
        .clk(clk),
        .dram_en(dram_en),
        .dram_wen(dram_wen),
        .dram_addr(dram_addr),
        .dram_wdata(dram_wdata),
        .dram_wmask(dram_wmask),
        .dram_rdata(dram_rdata)
    );

    IRAM u_IRAM(
        .clk(clk),
        .iram_en(iram_en),
        .iram_addr(iram_addr),
        .iram_rdata(iram_rdata)
    );

endmodule

// module IRAM_AXI_Slave (
//     input             clk,
//     input             rst,
    
//     // AXI-Lite Slave Interface
//     input             i_arvalid,
//     output reg        i_arready,
//     input      [31:0] i_araddr,
    
//     output reg        i_rvalid,
//     input             i_rready,
//     output reg [31:0] i_rdata,

//     // IRAM 内部接口
//     output reg        iram_en,
//     output reg [31:0] iram_addr,
//     input      [31:0] iram_rdata
// );

//     // 状态机定义
//     typedef enum logic [1:0] {
//         IDLE = 2'b00,
//         ADDR_PHASE = 2'b01,
//         DATA_PHASE = 2'b10
//     } state_t;

//     state_t crt_state, nxt_state;

//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             crt_state <= IDLE;
//         end
//         else begin
//             crt_state <= nxt_state;
//         end
//     end

//     always @(*) begin
//         nxt_state = crt_state;
//         i_arready = 1'b0;
//         i_rvalid  = 1'b0;
//         iram_en   = 1'b0;
        
//         case (crt_state)
//             IDLE: begin
//                 if (i_arvalid) begin
//                     i_arready = 1'b1;    // 准备接收地址
//                     nxt_state = ADDR_PHASE;
//                 end
//             end
            
//             ADDR_PHASE: begin
//                 if (i_arvalid && i_arready) begin
//                     iram_en   = 1'b1;    // 使能 IRAM
//                     iram_addr = i_araddr; // 传递地址给 IRAM
//                     nxt_state = DATA_PHASE;
//                 end
//             end

//             DATA_PHASE: begin
//                 if (iram_rdata) begin
//                     i_rdata  = iram_rdata; // 读取数据
//                     i_rvalid = 1'b1;       // 有效的读数据

//                     if (i_rvalid && i_rready) begin
//                         nxt_state = IDLE;   // 返回 IDLE 状态
//                     end
//                 end
//             end
//         endcase
//     end
// endmodule

