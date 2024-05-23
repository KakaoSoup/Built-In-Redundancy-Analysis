module SpareAllocationAnalyzer(
   input clk, 
   input [7:0] DSSS,
   input [2:0] RLSS,
   
   input rst,
   input termination,
   input repair,
   input reanalyze,
   input test_end,
   input start_SVC,

   input [26:0] pivot_fault_addr0,     //pivot fault address
   input [26:0] pivot_fault_addr1,
   input [26:0] pivot_fault_addr2,
   input [26:0] pivot_fault_addr3,
   input [26:0] pivot_fault_addr4,
   input [26:0] pivot_fault_addr5,
   input [26:0] pivot_fault_addr6,
   input [26:0] pivot_fault_addr7,
   
   input [16:0] nonpivot_fault_addr0,  //nonpivot fualt address
   input [16:0] nonpivot_fault_addr1,
   input [16:0] nonpivot_fault_addr2,
   input [16:0] nonpivot_fault_addr3,
   input [16:0] nonpivot_fault_addr4,
   input [16:0] nonpivot_fault_addr5,
   input [16:0] nonpivot_fault_addr6,
   input [16:0] nonpivot_fault_addr7,
   input [16:0] nonpivot_fault_addr8,
   input [16:0] nonpivot_fault_addr9,

   output [9:0] nonpivot_cover_info,  //nonpivot cover infomation
   
   output [9:0] nonpivot_row_addr0,    //nonpivot row address
   output [9:0] nonpivot_row_addr1,
   output [9:0] nonpivot_row_addr2,
   output [9:0] nonpivot_row_addr3,
   output [9:0] nonpivot_row_addr4,
   output [9:0] nonpivot_row_addr5,
   output [9:0] nonpivot_row_addr6,
   output [9:0] nonpivot_row_addr7,
   output [9:0] nonpivot_row_addr8,
   output [9:0] nonpivot_row_addr9,

   output [9:0] nonpivot_col_addr0,    //nonpivot column address
   output [9:0] nonpivot_col_addr1,
   output [9:0] nonpivot_col_addr2,
   output [9:0] nonpivot_col_addr3,
   output [9:0] nonpivot_col_addr4,
   output [9:0] nonpivot_col_addr5,
   output [9:0] nonpivot_col_addr6,
   output [9:0] nonpivot_col_addr7,
   output [9:0] nonpivot_col_addr8,
   output [9:0] nonpivot_col_addr9,

   output [1:0] nonpivot_bnk_addr0,    //nonpivot bank address
   output [1:0] nonpivot_bnk_addr1,
   output [1:0] nonpivot_bnk_addr2,
   output [1:0] nonpivot_bnk_addr3,
   output [1:0] nonpivot_bnk_addr4,
   output [1:0] nonpivot_bnk_addr5,
   output [1:0] nonpivot_bnk_addr6,
   output [1:0] nonpivot_bnk_addr7,
   output [1:0] nonpivot_bnk_addr8,
   output [1:0] nonpivot_bnk_addr9,

   output [9:0] nonpivot_en,

   output [9:0] pivot_row_addr0,      //pivot row addresss
   output [9:0] pivot_row_addr1,
   output [9:0] pivot_row_addr2,
   output [9:0] pivot_row_addr3,
   output [9:0] pivot_row_addr4,
   output [9:0] pivot_row_addr5,
   output [9:0] pivot_row_addr6,
   output [9:0] pivot_row_addr7,

   output [9:0] pivot_col_addr0,      //pivot column address
   output [9:0] pivot_col_addr1,
   output [9:0] pivot_col_addr2,
   output [9:0] pivot_col_addr3,
   output [9:0] pivot_col_addr4,
   output [9:0] pivot_col_addr5,
   output [9:0] pivot_col_addr6,
   output [9:0] pivot_col_addr7,
    
   output [1:0] pivot_bnk_addr0,      //pivot bank address
   output [1:0] pivot_bnk_addr1,
   output [1:0] pivot_bnk_addr2,
   output [1:0] pivot_bnk_addr3,
   output [1:0] pivot_bnk_addr4,
   output [1:0] pivot_bnk_addr5,
   output [1:0] pivot_bnk_addr6,
   output [1:0] pivot_bnk_addr7,

   output [7:0] pivot_ren,
   output [7:0] pivot_en,
   output reg opSAA
);
//   pivot_fault_addr
//   ren + en + row_addr + col_addr + bnk_addr + must_flag;

//   nonpivot_fault_addr
//   enable = nonpivot_fault_addr[16];
//   pivot_pointer = nonpivot_fault_addr[15:13];
//   row_column_descriptor = nonpivot_fault_addr[12]; //row=1, column=0
//   address = nonpivot_fault_addr[11:2];
//   block = nonpivot_fault_addr[1:0];

//always@(DSSS) begin
   

wire [9:0] p_row_addr [0:7];      //2nd array of pivot fault address
wire [9:0] p_col_addr [0:7];
wire [1:0] p_bnk_addr [0:7];

wire [9:0] np_row_addr [0:9];      //2nd array of nonpivot fault address
wire [9:0] np_col_addr [0:9];
wire [1:0] np_bnk_addr [0:9];

// pivot address 2nd array
    assign p_row_addr[0] = pivot_fault_addr0[24:15];
    assign p_row_addr[1] = pivot_fault_addr1[24:15];
    assign p_row_addr[2] = pivot_fault_addr2[24:15];
    assign p_row_addr[3] = pivot_fault_addr3[24:15];
    assign p_row_addr[4] = pivot_fault_addr4[24:15];
    assign p_row_addr[5] = pivot_fault_addr5[24:15];
    assign p_row_addr[6] = pivot_fault_addr6[24:15];
    assign p_row_addr[7] = pivot_fault_addr7[24:15];

    assign p_col_addr[0] = pivot_fault_addr0[14:5];
    assign p_col_addr[1] = pivot_fault_addr1[14:5];
    assign p_col_addr[2] = pivot_fault_addr2[14:5];
    assign p_col_addr[3] = pivot_fault_addr3[14:5];
    assign p_col_addr[4] = pivot_fault_addr4[14:5];
    assign p_col_addr[5] = pivot_fault_addr5[14:5];
    assign p_col_addr[6] = pivot_fault_addr6[14:5];
    assign p_col_addr[7] = pivot_fault_addr7[14:5];

    assign p_bnk_addr[0] = pivot_fault_addr0[4:3];
    assign p_bnk_addr[1] = pivot_fault_addr1[4:3];
    assign p_bnk_addr[2] = pivot_fault_addr2[4:3];
    assign p_bnk_addr[3] = pivot_fault_addr3[4:3];
    assign p_bnk_addr[4] = pivot_fault_addr4[4:3];
    assign p_bnk_addr[5] = pivot_fault_addr5[4:3];
    assign p_bnk_addr[6] = pivot_fault_addr6[4:3];
    assign p_bnk_addr[7] = pivot_fault_addr7[4:3];

    assign pivot_ren = {pivot_fault_addr0[26],pivot_fault_addr1[26],pivot_fault_addr2[26],pivot_fault_addr3[26],pivot_fault_addr4[26],pivot_fault_addr5[26],pivot_fault_addr6[26],pivot_fault_addr7[26]};
    assign pivot_en = {pivot_fault_addr0[25],pivot_fault_addr1[25],pivot_fault_addr2[25],pivot_fault_addr3[25],pivot_fault_addr4[25],pivot_fault_addr5[25],pivot_fault_addr6[25],pivot_fault_addr7[25]};

// nonpivot address 2nd array
    assign np_row_addr[0] = nonpivot_fault_addr0[12] ? nonpivot_fault_addr0[11:2] : nonpivot_fault_addr0[16] ? p_row_addr[nonpivot_fault_addr0[15:13]] : 10'b00000_00000;
    assign np_row_addr[1] = nonpivot_fault_addr1[12] ? nonpivot_fault_addr1[11:2] : nonpivot_fault_addr1[16] ? p_row_addr[nonpivot_fault_addr1[15:13]] : 10'b00000_00000;
    assign np_row_addr[2] = nonpivot_fault_addr2[12] ? nonpivot_fault_addr2[11:2] : nonpivot_fault_addr2[16] ? p_row_addr[nonpivot_fault_addr2[15:13]] : 10'b00000_00000;
    assign np_row_addr[3] = nonpivot_fault_addr3[12] ? nonpivot_fault_addr3[11:2] : nonpivot_fault_addr3[16] ? p_row_addr[nonpivot_fault_addr3[15:13]] : 10'b00000_00000;
    assign np_row_addr[4] = nonpivot_fault_addr4[12] ? nonpivot_fault_addr4[11:2] : nonpivot_fault_addr4[16] ? p_row_addr[nonpivot_fault_addr4[15:13]] : 10'b00000_00000;
    assign np_row_addr[5] = nonpivot_fault_addr5[12] ? nonpivot_fault_addr5[11:2] : nonpivot_fault_addr5[16] ? p_row_addr[nonpivot_fault_addr5[15:13]] : 10'b00000_00000;
    assign np_row_addr[6] = nonpivot_fault_addr6[12] ? nonpivot_fault_addr6[11:2] : nonpivot_fault_addr6[16] ? p_row_addr[nonpivot_fault_addr6[15:13]] : 10'b00000_00000;
    assign np_row_addr[7] = nonpivot_fault_addr7[12] ? nonpivot_fault_addr7[11:2] : nonpivot_fault_addr7[16] ? p_row_addr[nonpivot_fault_addr7[15:13]] : 10'b00000_00000;
    assign np_row_addr[8] = nonpivot_fault_addr8[12] ? nonpivot_fault_addr8[11:2] : nonpivot_fault_addr8[16] ? p_row_addr[nonpivot_fault_addr8[15:13]] : 10'b00000_00000;
    assign np_row_addr[9] = nonpivot_fault_addr9[12] ? nonpivot_fault_addr9[11:2] : nonpivot_fault_addr9[16] ? p_row_addr[nonpivot_fault_addr9[15:13]] : 10'b00000_00000;

    assign np_col_addr[0] = nonpivot_fault_addr0[12] ? p_col_addr[nonpivot_fault_addr0[15:13]] : nonpivot_fault_addr0[11:2];
    assign np_col_addr[1] = nonpivot_fault_addr1[12] ? p_col_addr[nonpivot_fault_addr1[15:13]] : nonpivot_fault_addr1[11:2];
    assign np_col_addr[2] = nonpivot_fault_addr2[12] ? p_col_addr[nonpivot_fault_addr2[15:13]] : nonpivot_fault_addr2[11:2];
    assign np_col_addr[3] = nonpivot_fault_addr3[12] ? p_col_addr[nonpivot_fault_addr3[15:13]] : nonpivot_fault_addr3[11:2];
    assign np_col_addr[4] = nonpivot_fault_addr4[12] ? p_col_addr[nonpivot_fault_addr4[15:13]] : nonpivot_fault_addr4[11:2];
    assign np_col_addr[5] = nonpivot_fault_addr5[12] ? p_col_addr[nonpivot_fault_addr5[15:13]] : nonpivot_fault_addr5[11:2];
    assign np_col_addr[6] = nonpivot_fault_addr6[12] ? p_col_addr[nonpivot_fault_addr6[15:13]] : nonpivot_fault_addr6[11:2];
    assign np_col_addr[7] = nonpivot_fault_addr7[12] ? p_col_addr[nonpivot_fault_addr7[15:13]] : nonpivot_fault_addr7[11:2];
    assign np_col_addr[8] = nonpivot_fault_addr8[12] ? p_col_addr[nonpivot_fault_addr8[15:13]] : nonpivot_fault_addr8[11:2];
    assign np_col_addr[9] = nonpivot_fault_addr9[12] ? p_col_addr[nonpivot_fault_addr9[15:13]] : nonpivot_fault_addr9[11:2];

    assign np_bnk_addr[0] = nonpivot_fault_addr0[1:0];
    assign np_bnk_addr[1] = nonpivot_fault_addr1[1:0];
    assign np_bnk_addr[2] = nonpivot_fault_addr2[1:0];
    assign np_bnk_addr[3] = nonpivot_fault_addr3[1:0];
    assign np_bnk_addr[4] = nonpivot_fault_addr4[1:0];
    assign np_bnk_addr[5] = nonpivot_fault_addr5[1:0];
    assign np_bnk_addr[6] = nonpivot_fault_addr6[1:0];
    assign np_bnk_addr[7] = nonpivot_fault_addr7[1:0];
    assign np_bnk_addr[8] = nonpivot_fault_addr8[1:0];
    assign np_bnk_addr[9] = nonpivot_fault_addr9[1:0];

// Extract Nonpivot Row/Column/Bank address
assign nonpivot_row_addr0 = np_row_addr[0];
assign nonpivot_row_addr1 = np_row_addr[1];
assign nonpivot_row_addr2 = np_row_addr[2];
assign nonpivot_row_addr3 = np_row_addr[3];
assign nonpivot_row_addr4 = np_row_addr[4];
assign nonpivot_row_addr5 = np_row_addr[5];
assign nonpivot_row_addr6 = np_row_addr[6];
assign nonpivot_row_addr7 = np_row_addr[7];
assign nonpivot_row_addr8 = np_row_addr[8];
assign nonpivot_row_addr9 = np_row_addr[9];

assign nonpivot_col_addr0 = np_col_addr[0];
assign nonpivot_col_addr1 = np_col_addr[1];
assign nonpivot_col_addr2 = np_col_addr[2];
assign nonpivot_col_addr3 = np_col_addr[3];
assign nonpivot_col_addr4 = np_col_addr[4];
assign nonpivot_col_addr5 = np_col_addr[5];
assign nonpivot_col_addr6 = np_col_addr[6];
assign nonpivot_col_addr7 = np_col_addr[7];
assign nonpivot_col_addr8 = np_col_addr[8];
assign nonpivot_col_addr9 = np_col_addr[9];

assign nonpivot_bnk_addr0 = np_bnk_addr[0];
assign nonpivot_bnk_addr1 = np_bnk_addr[1];
assign nonpivot_bnk_addr2 = np_bnk_addr[2];
assign nonpivot_bnk_addr3 = np_bnk_addr[3];
assign nonpivot_bnk_addr4 = np_bnk_addr[4];
assign nonpivot_bnk_addr5 = np_bnk_addr[5];
assign nonpivot_bnk_addr6 = np_bnk_addr[6];
assign nonpivot_bnk_addr7 = np_bnk_addr[7];
assign nonpivot_bnk_addr8 = np_bnk_addr[8];
assign nonpivot_bnk_addr9 = np_bnk_addr[9];

assign nonpivot_en = {nonpivot_fault_addr0[16],nonpivot_fault_addr1[16],nonpivot_fault_addr2[16],nonpivot_fault_addr3[16],nonpivot_fault_addr4[16],nonpivot_fault_addr5[16],
   nonpivot_fault_addr6[16],nonpivot_fault_addr7[16],nonpivot_fault_addr8[16],nonpivot_fault_addr9[16]};

// Extract Pivot Row/Column/Bank address
assign pivot_row_addr0 = pivot_fault_addr0[24:15];
assign pivot_row_addr1 = pivot_fault_addr1[24:15];
assign pivot_row_addr2 = pivot_fault_addr2[24:15];
assign pivot_row_addr3 = pivot_fault_addr3[24:15];
assign pivot_row_addr4 = pivot_fault_addr4[24:15];
assign pivot_row_addr5 = pivot_fault_addr5[24:15];
assign pivot_row_addr6 = pivot_fault_addr6[24:15];
assign pivot_row_addr7 = pivot_fault_addr7[24:15];

assign pivot_col_addr0 = pivot_fault_addr0[14:5];
assign pivot_col_addr1 = pivot_fault_addr1[14:5];
assign pivot_col_addr2 = pivot_fault_addr2[14:5];
assign pivot_col_addr3 = pivot_fault_addr3[14:5];
assign pivot_col_addr4 = pivot_fault_addr4[14:5];
assign pivot_col_addr5 = pivot_fault_addr5[14:5];
assign pivot_col_addr6 = pivot_fault_addr6[14:5];
assign pivot_col_addr7 = pivot_fault_addr7[14:5];

assign pivot_bnk_addr0 = pivot_fault_addr0[4:3];
assign pivot_bnk_addr1 = pivot_fault_addr1[4:3];
assign pivot_bnk_addr2 = pivot_fault_addr2[4:3];
assign pivot_bnk_addr3 = pivot_fault_addr3[4:3];
assign pivot_bnk_addr4 = pivot_fault_addr4[4:3];
assign pivot_bnk_addr5 = pivot_fault_addr5[4:3];
assign pivot_bnk_addr6 = pivot_fault_addr6[4:3];
assign pivot_bnk_addr7 = pivot_fault_addr7[4:3];
    

wire [11:0] PR0;   //selected pivot row
wire [11:0] PR1;
wire [11:0] PR2;
wire [11:0] PR3;
wire [11:0] PC0;   //selected pivot column
wire [11:0] PC1;
wire [11:0] PC2;
wire [11:0] PC3;

// MUX by DSSS
//always@(negedge termination or negedge repair) begin
//   if(!termination) begin
//   PR0 <= 12'b0;
//   PR1 <= 12'b0;
//   PR2 <= 12'b0;
//   PR3 <= 12'b0;
//   PC0 <= 12'b0;
//   PC1 <= 12'b0;
///   PC2 <= 12'b0;
//   PC3 <= 12'b0;
//   end
//   else begin
//   PR0 <= 12'b0;
///   PR1 <= 12'b0;
//   PR2 <= 12'b0;
//   PR3 <= 12'b0;
//   PC0 <= 12'b0;
//   PC1 <= 12'b0;
//   PC2 <= 12'b0;
///   PC3 <= 12'b0;
//   end
//end

   reg [2:0] idx_row[0:3];
   reg [2:0] idx_col[0:3];
   integer i;
   integer cnt_row;
   integer cnt_col;
/*
// Row&Column MUX
// Row&Column MUX
always @(posedge start_SVC or posedge clk) begin
    if (!rst) begin
        cnt_row <= 0;
        cnt_col <= 0;
        for (i = 0; i < 8; i = i + 1) begin
            if (DSSS[7-i] == 1'b1) begin
                idx_row[cnt_row] <= i;
                cnt_row <= cnt_row + 1;
            end
            else begin
                idx_col[cnt_col] <= i;
                cnt_col <= cnt_col + 1;
            end
        end
    end
    else begin 
        cnt_row <= 0;
        cnt_col <= 0;
    end
end
*/
// Row&Column MUX
always@(posedge clk) begin
   cnt_row = 1'b0;
   cnt_col = 1'b0;
   for(i = 0; i < 8; i = i + 1) begin      
           if(DSSS[7-i] == 1'b1) begin
      idx_row[cnt_row] = i;
      cnt_row = cnt_row + 1;
           end
      else begin
      idx_col[cnt_col] = i;
      cnt_col = cnt_col + 1;
      end
   end
end


assign PR0 = test_end ? {p_row_addr[idx_row[0]],p_bnk_addr[idx_row[0]]} : 12'b0;
assign PR1 = test_end ? {p_row_addr[idx_row[1]],p_bnk_addr[idx_row[1]]} : 12'b0;
assign PR2 = test_end ? {p_row_addr[idx_row[2]],p_bnk_addr[idx_row[2]]} : 12'b0;
assign PR3 = test_end ? {p_row_addr[idx_row[3]],p_bnk_addr[idx_row[3]]} : 12'b0;
assign PC0 = test_end ? {p_col_addr[idx_col[0]],p_bnk_addr[idx_col[0]]} : 12'b0;
assign PC1 = test_end ? {p_col_addr[idx_col[1]],p_bnk_addr[idx_col[1]]} : 12'b0;
assign PC2 = test_end ? {p_col_addr[idx_col[2]],p_bnk_addr[idx_col[2]]} : 12'b0;
assign PC3 = test_end ? {p_col_addr[idx_col[3]],p_bnk_addr[idx_col[3]]} : 12'b0;

/*always@(posedge clk) begin
   if(rst) begin
      PR0 <= 0;
      PR1 <= 0;
      PR2 <= 0;
      PR3 <= 0;
      PC0 <= 0;
      PC1 <= 0;
      PC2 <= 0;
      PC3 <= 0;
   end
   else begin
      PR0 <= {p_row_addr[idx_row[0]],p_bnk_addr[idx_row[0]]};
      PR1 <= {p_row_addr[idx_row[1]],p_bnk_addr[idx_row[1]]};
      PR2 <= {p_row_addr[idx_row[2]],p_bnk_addr[idx_row[2]]};
      PR3 <= {p_row_addr[idx_row[3]],p_bnk_addr[idx_row[3]]};
      PC0 <= {p_col_addr[idx_col[0]],p_bnk_addr[idx_col[0]]};
      PC1 <= {p_col_addr[idx_col[1]],p_bnk_addr[idx_col[1]]};
      PC2 <= {p_col_addr[idx_col[2]],p_bnk_addr[idx_col[2]]};
      PC3 <= {p_col_addr[idx_col[3]],p_bnk_addr[idx_col[3]]};
   end
end*/

        
// nonpivot_cover_info by Analyzer module
   Analyzer A0(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
      nonpivot_row_addr0,nonpivot_col_addr0,nonpivot_bnk_addr0,nonpivot_bnk_addr0,nonpivot_cover_info[9]);
            
        Analyzer A1(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
            nonpivot_row_addr1,nonpivot_col_addr1,nonpivot_bnk_addr1,nonpivot_bnk_addr1,nonpivot_cover_info[8]);

        Analyzer A2(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
            nonpivot_row_addr2,nonpivot_col_addr2,nonpivot_bnk_addr2,nonpivot_bnk_addr2,nonpivot_cover_info[7]);
            
        Analyzer A3(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
            nonpivot_row_addr3,nonpivot_col_addr3,nonpivot_bnk_addr3,nonpivot_bnk_addr3,nonpivot_cover_info[6]);
            
        Analyzer A4(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
            nonpivot_row_addr4,nonpivot_col_addr4,nonpivot_bnk_addr4,nonpivot_bnk_addr4,nonpivot_cover_info[5]);
            
        Analyzer A5(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
            nonpivot_row_addr5,nonpivot_col_addr5,nonpivot_bnk_addr5,nonpivot_bnk_addr5,nonpivot_cover_info[4]);
            
        Analyzer A6(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
            nonpivot_row_addr6,nonpivot_col_addr6,nonpivot_bnk_addr6,nonpivot_bnk_addr6,nonpivot_cover_info[3]);
            
        Analyzer A7(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
            nonpivot_row_addr7,nonpivot_col_addr7,nonpivot_bnk_addr7,nonpivot_bnk_addr7,nonpivot_cover_info[2]);
           
        Analyzer A8(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
            nonpivot_row_addr8,nonpivot_col_addr8,nonpivot_bnk_addr8,nonpivot_bnk_addr8,nonpivot_cover_info[1]);
            
        Analyzer A9(clk, rst, DSSS, RLSS, PR0, PR1, PR2, PR3, PC0, PC1, PC2, PC3,
            nonpivot_row_addr9,nonpivot_col_addr9,nonpivot_bnk_addr9,nonpivot_bnk_addr9,nonpivot_cover_info[0]);

                        
endmodule