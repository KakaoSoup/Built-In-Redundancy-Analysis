module Analyzer(
    input clk,
    input rst,
    input [7:0] DSSS,
    input [2:0] RLSS,
    input [11:0] PR0, //selected pivot row
    input [11:0] PR1,
    input [11:0] PR2,
    input [11:0] PR3,
    input [11:0] PC0, //selected pivot column
    input [11:0] PC1,
    input [11:0] PC2,
    input [11:0] PC3,
    input [9:0] NPr_addr,
    input [9:0] NPc_addr,
    input [1:0] NPr_bnk,
    input [1:0] NPc_bnk,
    output nonpivot_cover_info
    );

    wire [3:0] NR;   //calculated by RAC
    wire [3:0] NC;   //calculated by CAC    

    RAC R0(clk,PR0[11:2],NPr_addr,PR0[1:0],NPr_bnk,RLSS,rst,NR[0]);
    RAC R1(clk,PR1[11:2],NPr_addr,PR1[1:0],NPr_bnk,RLSS,rst,NR[1]);
    RAC R2(clk,PR2[11:2],NPr_addr,PR2[1:0],NPr_bnk,RLSS,rst,NR[2]);
    RAC R3(clk,PR3[11:2],NPr_addr,PR3[1:0],NPr_bnk,RLSS,rst,NR[3]);

    CAC C0(clk,PC0[11:2],NPc_addr,PC0[1:0],NPc_bnk,rst,NC[0]);
    CAC C1(clk,PC1[11:2],NPc_addr,PC1[1:0],NPc_bnk,rst,NC[1]);
    CAC C2(clk,PC2[11:2],NPc_addr,PC2[1:0],NPc_bnk,rst,NC[2]);
    CAC C3(clk,PC3[11:2],NPc_addr,PC3[1:0],NPc_bnk,rst,NC[3]);
    
    assign nonpivot_cover_info = (NR[0]|NR[1]|NR[2]|NR[3]) | (NC[0]|NC[1]|NC[2]|NC[3]);
endmodule