module IDU (
    input  [31:0] inst,
    output [31:0] imm,
    output [9:0]  alu_op,
    output [7:0]  jump_type,
    output [7:0]  mem_type,
    output [2:0]  sel_alu_src1, // 001 rf_rdata1 010 pc  100 0
    output [2:0]  sel_alu_src2, // 001 rf_rdata2 010 imm 100 4
    output        rf_wen,
    output [2:0]  sel_rf_wdata, // 001 alu_res 010 dram 100 csr_data
    output        dram_en,
    output        dram_wen,
    output        csr_wen,
    output [5:0]  csr_op,
    output [31:0] zimm,
    output        ecall_en,
    output        mret_en
);

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] immI, immU, immS, immB, immJ;

    wire R_type;
    wire I_type, I_type_load, I_type_jump, I_type_al, I_type_priv;
    wire U_type, U_type_lui, U_type_auipc;
    wire S_type;
    wire B_type;
    wire J_type;

    wire inst_jal;
    wire inst_jalr;
    wire inst_beq;
    wire inst_bne;
    wire inst_blt;
    wire inst_bge;
    wire inst_bltu;
    wire inst_bgeu;
    wire inst_lb;
    wire inst_lh;
    wire inst_lw;
    wire inst_lbu;
    wire inst_lhu;
    wire inst_sb;
    wire inst_sh;
    wire inst_sw;
    wire inst_addi;
    wire inst_slti;
    wire inst_sltiu;
    wire inst_xori;
    wire inst_ori;
    wire inst_andi;
    wire inst_slli;
    wire inst_srli;
    wire inst_srai;
    wire inst_add;
    wire inst_sub;
    wire inst_sll;
    wire inst_slt;
    wire inst_sltu;
    wire inst_xor;
    wire inst_srl;
    wire inst_sra;
    wire inst_or;
    wire inst_and;
    
    wire inst_csrrw;
    wire inst_csrrs;
    wire inst_csrrc;
    wire inst_csrrwi;
    wire inst_csrrsi;
    wire inst_csrrci;
    wire inst_ecall;
    wire inst_mret;

    wire inst_ebreak;


    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];

    assign R_type       = opcode == 7'b0110011;
    assign I_type_load  = opcode == 7'b0000011;
    assign I_type_jump  = opcode == 7'b1100111;
    assign I_type_al    = opcode == 7'b0010011;
    assign I_type_priv  = opcode == 7'b1110011;
    assign I_type       = I_type_load | I_type_jump | I_type_al | I_type_priv;
    assign U_type_lui   = opcode == 7'b0110111;
    assign U_type_auipc = opcode == 7'b0010111;
    assign U_type       = U_type_lui | U_type_auipc;
    assign S_type       = opcode == 7'b0100011;
    assign B_type       = opcode == 7'b1100011;
    assign J_type       = opcode == 7'b1101111;

    assign inst_jal   = J_type;
    assign inst_jalr  = I_type_jump;
    assign inst_beq   = B_type & (funct3 == 3'b000);
    assign inst_bne   = B_type & (funct3 == 3'b001);
    assign inst_blt   = B_type & (funct3 == 3'b100);
    assign inst_bge   = B_type & (funct3 == 3'b101);
    assign inst_bltu  = B_type & (funct3 == 3'b110);
    assign inst_bgeu  = B_type & (funct3 == 3'b111);
    assign inst_lb    = I_type_load & (funct3 == 3'b000);
    assign inst_lh    = I_type_load & (funct3 == 3'b001);
    assign inst_lw    = I_type_load & (funct3 == 3'b010);
    assign inst_lbu   = I_type_load & (funct3 == 3'b100);
    assign inst_lhu   = I_type_load & (funct3 == 3'b101);
    assign inst_sb    = S_type & (funct3 == 3'b000);
    assign inst_sh    = S_type & (funct3 == 3'b001);
    assign inst_sw    = S_type & (funct3 == 3'b010);
    assign inst_addi  = I_type_al & (funct3 == 3'b000);
    assign inst_slti  = I_type_al & (funct3 == 3'b010);
    assign inst_sltiu = I_type_al & (funct3 == 3'b011);
    assign inst_xori  = I_type_al & (funct3 == 3'b100);
    assign inst_ori   = I_type_al & (funct3 == 3'b110);
    assign inst_andi  = I_type_al & (funct3 == 3'b111);
    assign inst_slli  = I_type_al & (funct3 == 3'b001);
    assign inst_srli  = I_type_al & (funct3 == 3'b101) & (~funct7[5]);
    assign inst_srai  = I_type_al & (funct3 == 3'b101) & (funct7[5]);
    assign inst_add   = R_type & (funct3 == 3'b000) & (~funct7[5]);
    assign inst_sub   = R_type & (funct3 == 3'b000) & (funct7[5]);
    assign inst_sll   = R_type & (funct3 == 3'b001);
    assign inst_slt   = R_type & (funct3 == 3'b010);
    assign inst_sltu  = R_type & (funct3 == 3'b011);
    assign inst_xor   = R_type & (funct3 == 3'b100);
    assign inst_srl   = R_type & (funct3 == 3'b101) & (~funct7[5]);
    assign inst_sra   = R_type & (funct3 == 3'b101) & (funct7[5]);
    assign inst_or    = R_type & (funct3 == 3'b110);
    assign inst_and   = R_type & (funct3 == 3'b111);

    assign inst_csrrw  = I_type_priv & (funct3 == 3'b001);
    assign inst_csrrs  = I_type_priv & (funct3 == 3'b010);
    assign inst_csrrc  = I_type_priv & (funct3 == 3'b011);
    assign inst_csrrwi = I_type_priv & (funct3 == 3'b101);
    assign inst_csrrsi = I_type_priv & (funct3 == 3'b110);
    assign inst_csrrci = I_type_priv & (funct3 == 3'b111);
    assign inst_ecall  = inst == 32'b00000000000000000000000001110011;
    assign inst_mret   = inst == 32'b00110000001000000000000001110011;

    assign inst_ebreak = inst == 32'b00000000000100000000000001110011;

    import "DPI-C" function void npc_trap();
    always @(*) begin
        if(inst_ebreak)
            npc_trap();
    end

    assign immI = {{20{inst[31]}}, inst[31:20]};
    assign immU = {inst[31:12], 12'b0};
    assign immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign immB = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    assign immJ = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

    assign zimm = {27'b0, inst[19:15]};

    mux5_1 u_mux5_1(
        .in0(immI),
        .in1(immU),
        .in2(immS),
        .in3(immB),
        .in4(immJ),
        .sel({J_type, B_type, S_type, U_type, I_type}),
        .out(imm)
    );

    assign alu_op[0] = U_type | J_type | I_type_jump | B_type | I_type_load | S_type | inst_addi | inst_add;    
    assign alu_op[1] = inst_sub;
    assign alu_op[2] = inst_slti | inst_slt;
    assign alu_op[3] = inst_sltiu | inst_sltu;
    assign alu_op[4] = inst_andi | inst_and;
    assign alu_op[5] = inst_ori | inst_or;
    assign alu_op[6] = inst_xori | inst_xor;
    assign alu_op[7] = inst_slli | inst_sll;
    assign alu_op[8] = inst_srli | inst_srl;
    assign alu_op[9] = inst_srai | inst_sra;

    assign csr_op = {inst_csrrci, inst_csrrsi, inst_csrrwi, inst_csrrc, inst_csrrs, inst_csrrw};

    assign jump_type = {inst_bgeu, inst_bltu, inst_bge, inst_blt, inst_bne, inst_beq, inst_jalr, inst_jal};
    
    assign mem_type = {inst_lhu, inst_lbu, inst_lw, inst_lh, inst_lb, inst_sw, inst_sh, inst_sb};

    assign sel_alu_src1[0] = I_type_load | S_type | I_type_al | R_type;
    assign sel_alu_src1[1] = U_type_auipc | J_type | I_type_jump;
    assign sel_alu_src1[2] = U_type_lui;

    assign sel_alu_src2[0] = R_type;
    assign sel_alu_src2[1] = U_type | I_type_load | S_type | I_type_al;
    assign sel_alu_src2[2] = J_type | I_type_jump;

    assign sel_rf_wdata[0] = U_type | J_type | R_type | I_type_al | I_type_jump;
    assign sel_rf_wdata[1] = I_type_load;
    assign sel_rf_wdata[2] = I_type_priv;

    assign rf_wen = U_type | J_type | I_type | R_type;

    assign dram_en = I_type_load | S_type;

    assign dram_wen = S_type;
    
    assign csr_wen = I_type_priv;

    assign ecall_en = inst_ecall;

    assign mret_en = inst_mret;

endmodule
