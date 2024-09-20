module BRU (
    input  [7:0]  jump_type,
    input  [31:0] src1, 
    input  [31:0] src2,
    input  [31:0] pc,
    input  [31:0] imm,
    output [31:0] jump_target,
    output        jump_taken
);
    wire inst_jal;
    wire inst_jalr;
    wire inst_beq;
    wire inst_bne;
    wire inst_blt;
    wire inst_bge;
    wire inst_bltu;
    wire inst_bgeu;

    wire [31:0] jalr_target;
    wire [31:0] other_target;

    wire [31:0] adder_a;
    wire [31:0] adder_b;
    wire [31:0] adder_res;
    wire [32:0] adder_tmp;
    wire        adder_cin;
    wire        adder_cout;
    
    wire lt;
    wire ltu;
    wire zero;

    wire beq;
    wire bne;
    wire blt;
    wire bge;
    wire bltu;
    wire bgeu;

    wire taken;

    assign inst_jal  = jump_type[0];
    assign inst_jalr = jump_type[1];
    assign inst_beq  = jump_type[2];
    assign inst_bne  = jump_type[3];
    assign inst_blt  = jump_type[4];
    assign inst_bge  = jump_type[5];
    assign inst_bltu = jump_type[6];
    assign inst_bgeu = jump_type[7];

    assign jalr_target  = src1 + imm;
    assign other_target = pc + imm;
    
    assign adder_a   = src1;
    assign adder_b   = ~src2;
    assign adder_cin = 1'b1;

    assign adder_tmp  = {1'b0, adder_a} + {1'b0, adder_b} + {32'b0, adder_cin};
    assign adder_res  = adder_tmp[31:0];
    assign adder_cout = adder_tmp[32];

    assign lt   = (src1[31] & ~src2[31]) | (~(src1[31] ^ src2[31]) & adder_res[31]);
    assign ltu  = ~adder_cout;
    assign zero = ~(| adder_res);

    assign beq  = zero;
    assign bne  = ~zero;
    assign blt  = lt;
    assign bge  = ~lt;
    assign bltu = ltu;
    assign bgeu = ~ltu;

    assign taken =  ((inst_jal | inst_jalr) & 1'b1)
                    | (inst_beq & beq)
                    | (inst_bne & bne)
                    | (inst_blt & blt)
                    | (inst_bge & bge)
                    | (inst_bltu & bltu)
                    | (inst_bgeu & bgeu);

    assign jump_target = inst_jalr ? jalr_target : taken ? other_target : pc + 4;

    assign jump_taken = |jump_type;

endmodule
