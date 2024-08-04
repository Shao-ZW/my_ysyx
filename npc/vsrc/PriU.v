module PriU(
    input  [5:0]  csr_op,
    input  [31:0] csr_rdata,
    input  [31:0] rf_rdata,
    input  [31:0] zimm,
    output [31:0] csr_wdata
);
    wire [31:0] csrrw_res;
    wire [31:0] csrrs_res;
    wire [31:0] csrrc_res;
    wire [31:0] csrrwi_res;
    wire [31:0] csrrsi_res;
    wire [31:0] csrrci_res;

    assign csrrw_res = rf_rdata;
    assign csrrs_res = csr_rdata | rf_rdata;
    assign csrrc_res = csr_rdata & ~rf_rdata;
    assign csrrwi_res = zimm;
    assign csrrsi_res = csr_rdata | zimm;
    assign csrrci_res = csr_rdata & ~zimm;

    assign csr_wdata = ({32{csr_op[0]}} & csrrw_res)
                        | ({32{csr_op[1]}} & csrrs_res)
                        | ({32{csr_op[2]}} & csrrc_res)
                        | ({32{csr_op[3]}} & csrrwi_res)
                        | ({32{csr_op[4]}} & csrrsi_res)
                        | ({32{csr_op[5]}} & csrrci_res);
 
endmodule
