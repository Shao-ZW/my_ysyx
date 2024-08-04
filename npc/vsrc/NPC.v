module NPC(
    input  [31:0] pc,
    input  [31:0] jump_target,
    input  [31:0] mtvec_rdata,
    input  [31:0] mepc_rdata,
    input         jump_taken,
    input         exception_en,
    input         mret_en,
    output [31:0] next_pc
);
    assign next_pc = exception_en ? mtvec_rdata : 
                    mret_en ? mepc_rdata : 
                    jump_taken ? jump_target : 
                    pc + 32'd4;
endmodule
