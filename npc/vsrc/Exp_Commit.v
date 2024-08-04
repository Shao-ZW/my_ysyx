module Exp_Commit(
    input         ecall_en,
    output        exception_en,
    output [31:0] mcause_wdata
);
    assign exception_en = ecall_en;
    assign mcause_wdata = ecall_en ? 32'd11 : 32'd0;

endmodule
