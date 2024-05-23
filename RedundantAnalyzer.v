`timescale 1ns / 1ps

module RedundantAnalyzer (
   // **************************** inputs ********************************************
   // from topmodule
   input clk,                  // clk signal 
   input rst,                  // reset signal
   input [1:0] spare_struct,    // spare structure
   
   // from signal generator
   input [7:0] DSSS,            // DSSS signal 
   input [2:0] RLSS,            // RLSS signal

   // from signal validity checker
   input signal_valid,               // whether generated signal is valid?
   input [7:0] unused_spare,            // 8-bit unused_spare
   input ra_start,            // if SVC is end?

   // from spare allocation analyzer
   // pivot addresses
   input cam_early_term,

   input [9:0] pivot_row_addr0,
   input [9:0] pivot_row_addr1,
   input [9:0] pivot_row_addr2,
   input [9:0] pivot_row_addr3,
   input [9:0] pivot_row_addr4,
   input [9:0] pivot_row_addr5,
   input [9:0] pivot_row_addr6,
   input [9:0] pivot_row_addr7,

   input [9:0] pivot_col_addr0,
   input [9:0] pivot_col_addr1,
   input [9:0] pivot_col_addr2,
   input [9:0] pivot_col_addr3,
   input [9:0] pivot_col_addr4,
   input [9:0] pivot_col_addr5,
   input [9:0] pivot_col_addr6,
   input [9:0] pivot_col_addr7,

   input [1:0] pivot_bnk_addr0,
   input [1:0] pivot_bnk_addr1,
   input [1:0] pivot_bnk_addr2,
   input [1:0] pivot_bnk_addr3,
   input [1:0] pivot_bnk_addr4,
   input [1:0] pivot_bnk_addr5,
   input [1:0] pivot_bnk_addr6,
   input [1:0] pivot_bnk_addr7,

   // en bit of non-pivot faults
   input [9:0] nonpivot_en,
   input [7:0] pivot_ren,
   input [7:0] pivot_en,

   // non-pivot addresses
   input [9:0] nonpivot_row_addr0,
   input [9:0] nonpivot_row_addr1,
   input [9:0] nonpivot_row_addr2,
   input [9:0] nonpivot_row_addr3,
   input [9:0] nonpivot_row_addr4,
   input [9:0] nonpivot_row_addr5,
   input [9:0] nonpivot_row_addr6,
   input [9:0] nonpivot_row_addr7,
   input [9:0] nonpivot_row_addr8,
   input [9:0] nonpivot_row_addr9,

   input [9:0] nonpivot_col_addr0,
   input [9:0] nonpivot_col_addr1,
   input [9:0] nonpivot_col_addr2,
   input [9:0] nonpivot_col_addr3,
   input [9:0] nonpivot_col_addr4,
   input [9:0] nonpivot_col_addr5,
   input [9:0] nonpivot_col_addr6,
   input [9:0] nonpivot_col_addr7,
   input [9:0] nonpivot_col_addr8,
   input [9:0] nonpivot_col_addr9,

   input [1:0] nonpivot_bnk_addr0,
   input [1:0] nonpivot_bnk_addr1,
   input [1:0] nonpivot_bnk_addr2,
   input [1:0] nonpivot_bnk_addr3,
   input [1:0] nonpivot_bnk_addr4,
   input [1:0] nonpivot_bnk_addr5,
   input [1:0] nonpivot_bnk_addr6,
   input [1:0] nonpivot_bnk_addr7,
   input [1:0] nonpivot_bnk_addr8,
   input [1:0] nonpivot_bnk_addr9,   

   // indicate that ith non-pivot fault is covered
   input [9:0] nonpivot_cover_info,  
   
   // ************ output *********************************************
   output [21:0] uncovered_addr,   // uncovered non-pivot address 
   output [15:0] solution,         // solution
   output reg repair,            // if faults can be repaired
   output reg termination,         // reanalsis is terminated -> next singal
   output reg reanalyze,            // reanalyze signal to CAM
   output reg ratest_end         // indicate CAM that sending np addresses is finish
);

// parameter
parameter ROW = 1;
parameter COL = 0;

// spare structure and types
parameter S1 = 2'd1;      // spare struct 1
parameter S2 = 2'd2;      // spare struct 2
parameter S3 = 2'd3;      // spare struct 3

// state of analyzer
localparam    IDLE = 0,
               REAN = 1,
               WAIT = 2,
              SOL = 3,
              TERM = 4;

// size of PCAM and NPCAM
parameter PCAM_SIZE = 8;
parameter NPCAM_SIZE = 10;

// non-pivot fault addresses
wire [9:0] np_row_addr [0:9];
wire [9:0] np_col_addr [0:9];
wire [1:0] np_bnk_addr [0:9];

// pivot fault addresses
wire [9:0] p_row_addr [0:7];
wire [9:0] p_col_addr [0:7];
wire [1:0] p_bnk_addr [0:7];

wire check;
wire remain;

// uncovered non-pivot fault address which is sended to CAM
reg [9:0] uncovered_row_addr;
reg [9:0] uncovered_col_addr;
reg [1:0] uncovered_bnk_addr;

// solution
reg flag;            // rc flaog of solution
reg [9:0] rc_addr;      // row or column address of solution
reg [2:0] spare_type;   // spare type of solution
reg [1:0] bnk_sel;      // bank of solution

// variable
reg [2:0]state;         // state
reg [2:0]next_state;      // next state

reg [3:0] zero_idx;   // find the number of uncovered nonpivot faults
reg [3:0] np_idx;   // last uncover nonpivot idx
reg [3:0] pcnt;
reg [3:0] uncover_num;   // remain number of  uncovered nonpivots
reg [3:0] uncover_idx;   // uncovered nonpivot idx
reg [9:0] uncover_nps;
reg [3:0] upper;
reg [3:0] lower;

reg [3:0]idx;         // for parallel access
reg [2:0]ridx;         // row cnt
reg [2:0]cidx;         // column cnt
reg bnk1C;      // use local spare in Bank2?
reg bnk2C;      // use local spare in Bank1?



// uncovered non-pivot address
assign solution = { spare_type, flag, bnk_sel, rc_addr };
assign uncovered_addr = { uncovered_bnk_addr, uncovered_row_addr, uncovered_col_addr };
assign check = ((~(nonpivot_cover_info[0] ^ nonpivot_en[0]) &
      ~(nonpivot_cover_info[1] ^ nonpivot_en[1])) &
      (~(nonpivot_cover_info[2] ^ nonpivot_en[2]) &
      ~(nonpivot_cover_info[3] ^ nonpivot_en[3]))) &
      ((~(nonpivot_cover_info[4] ^ nonpivot_en[4]) &
      ~(nonpivot_cover_info[5] ^ nonpivot_en[5])) &
      (~(nonpivot_cover_info[6] ^ nonpivot_en[6]) &
      ~(nonpivot_cover_info[7] ^ nonpivot_en[7]))) &
   (~(nonpivot_cover_info[8] ^ nonpivot_en[8]) &
   ~(nonpivot_cover_info[9] ^ nonpivot_en[9]));

assign remain = ((unused_spare[0] | unused_spare[1]) | (unused_spare[2] | unused_spare[3])) | ((unused_spare[4] | unused_spare[5]) | (unused_spare[6] | unused_spare[7]));

// port connection
generate
    assign p_row_addr[0] = pivot_row_addr0;
    assign p_row_addr[1] = pivot_row_addr1;
    assign p_row_addr[2] = pivot_row_addr2;
    assign p_row_addr[3] = pivot_row_addr3;
    assign p_row_addr[4] = pivot_row_addr4;
    assign p_row_addr[5] = pivot_row_addr5;
    assign p_row_addr[6] = pivot_row_addr6;
    assign p_row_addr[7] = pivot_row_addr7;

    assign p_col_addr[0] = pivot_col_addr0;
    assign p_col_addr[1] = pivot_col_addr1;
    assign p_col_addr[2] = pivot_col_addr2;
    assign p_col_addr[3] = pivot_col_addr3;
    assign p_col_addr[4] = pivot_col_addr4;
    assign p_col_addr[5] = pivot_col_addr5;
    assign p_col_addr[6] = pivot_col_addr6;
    assign p_col_addr[7] = pivot_col_addr7;

    assign p_bnk_addr[0] = pivot_bnk_addr0;
    assign p_bnk_addr[1] = pivot_bnk_addr1;
    assign p_bnk_addr[2] = pivot_bnk_addr2;
    assign p_bnk_addr[3] = pivot_bnk_addr3;
    assign p_bnk_addr[4] = pivot_bnk_addr4;
    assign p_bnk_addr[5] = pivot_bnk_addr5;
    assign p_bnk_addr[6] = pivot_bnk_addr6;
    assign p_bnk_addr[7] = pivot_bnk_addr7;
endgenerate


generate
    assign np_row_addr[0] = nonpivot_row_addr0;
    assign np_row_addr[1] = nonpivot_row_addr1;
    assign np_row_addr[2] = nonpivot_row_addr2;
    assign np_row_addr[3] = nonpivot_row_addr3;
    assign np_row_addr[4] = nonpivot_row_addr4;
    assign np_row_addr[5] = nonpivot_row_addr5;
    assign np_row_addr[6] = nonpivot_row_addr6;
    assign np_row_addr[7] = nonpivot_row_addr7;
    assign np_row_addr[8] = nonpivot_row_addr8;
    assign np_row_addr[9] = nonpivot_row_addr9;

    assign np_col_addr[0] = nonpivot_col_addr0;
    assign np_col_addr[1] = nonpivot_col_addr1;
    assign np_col_addr[2] = nonpivot_col_addr2;
    assign np_col_addr[3] = nonpivot_col_addr3;
    assign np_col_addr[4] = nonpivot_col_addr4;
    assign np_col_addr[5] = nonpivot_col_addr5;
    assign np_col_addr[6] = nonpivot_col_addr6;
    assign np_col_addr[7] = nonpivot_col_addr7;
    assign np_col_addr[8] = nonpivot_col_addr8;
    assign np_col_addr[9] = nonpivot_col_addr9;

    assign np_bnk_addr[0] = nonpivot_bnk_addr0;
    assign np_bnk_addr[1] = nonpivot_bnk_addr1;
    assign np_bnk_addr[2] = nonpivot_bnk_addr2;
    assign np_bnk_addr[3] = nonpivot_bnk_addr3;
    assign np_bnk_addr[4] = nonpivot_bnk_addr4;
    assign np_bnk_addr[5] = nonpivot_bnk_addr5;
    assign np_bnk_addr[6] = nonpivot_bnk_addr6;
    assign np_bnk_addr[7] = nonpivot_bnk_addr7;
    assign np_bnk_addr[8] = nonpivot_bnk_addr8;
    assign np_bnk_addr[9] = nonpivot_bnk_addr9;
endgenerate


// state transition
always@(posedge clk) begin
   state = next_state;
end

// outputs state
always@(posedge clk) begin
   case(state)
   IDLE : begin
      repair <= 0;
      reanalyze <= 0;
      termination <= 0;   
   end

   REAN : begin
      repair <= 0;
      reanalyze <= 1;
      termination <= 0;
   end

   SOL : begin
      repair <= 1;
      reanalyze <= 0;
      termination <= 0;
   end

   TERM : begin
      repair <= 0;
      reanalyze <= 0;
      termination <= 1;
   end
   endcase
end 



always@(posedge clk) begin
   case(state)
   IDLE, SOL, TERM : begin
   uncover_nps = nonpivot_cover_info;
      uncover_num = 0;
      for(zero_idx = 0; zero_idx < NPCAM_SIZE; zero_idx = zero_idx + 1) begin
         if(!uncover_nps[zero_idx] & nonpivot_en[zero_idx]) begin
            uncover_num = uncover_num + 1;
         end
      end

   pcnt = 0;
   for(zero_idx = 0; zero_idx < PCAM_SIZE; zero_idx = zero_idx + 1) begin
      if(pivot_en[zero_idx] | pivot_ren[zero_idx]) begin
         pcnt = pcnt + 1;
      end
   end
   end
   
   REAN : begin
	if(uncover_num > 0)
		uncover_num = uncover_num - 1;
      	/*
	for(zero_idx = 0; zero_idx < PCAM_SIZE; zero_idx = zero_idx + 1) begin
      		if(nonpivot_en[zero_idx] && !nonpivot_cover_info[zero_idx]) begin
         		uncover_num = uncover_num + 1;
      		end
   	end
	*/
   end
   endcase
end


// module output setting
always@(posedge clk) begin
   case(state)
   IDLE : begin
      flag = 0;   
      rc_addr = 0;   
      spare_type = 0;    
      bnk_sel = 0;
      ridx = 0;
      cidx = 0;
   bnk1C = 0;
   bnk2C = 0;

   end

   REAN : begin

   end

   SOL : begin
      if(idx <= pcnt && spare_struct == S3) begin
         flag = DSSS[idx-1];
         bnk_sel = p_bnk_addr[idx-1];

         // row_spare   
         if(flag == ROW) begin
            rc_addr = p_row_addr[idx-1];
            if(RLSS[ridx]) begin
               // global spare
               spare_type = 3'b100;
            end
            else begin
               // local spare
               spare_type = 3'b001;   
            end
            ridx = ridx + 1;
         end

         // col spare
         else begin
            rc_addr = p_col_addr[idx-1];
            if(spare_struct == S1) begin
               // local spare
               spare_type = 3'b001;
            end
            else begin
               // bank0
               if(p_bnk_addr[idx-1] == 2'b01) begin
                  if(~bnk1C) begin
                     bnk1C = 1'b1;
                     spare_type = 3'b001;
                  end
                  else begin
                     spare_type = 3'b010;
                  end
               end
               // bank1
               else begin
                  if(~bnk2C) begin
                     bnk2C = 1'b1;
                     spare_type = 3'b001;
                  end
                  else begin
                     spare_type = 3'b010;
                  end
               end
            end
         end
      end
      else if (idx < pcnt && spare_struct != S3) begin
         flag = DSSS[idx];
         bnk_sel = p_bnk_addr[idx];

         // row_spare   
         if(flag == ROW) begin
            rc_addr = p_row_addr[idx];
            if(RLSS[ridx]) begin
               // global spare
               spare_type = 3'b100;
            end
            else begin
               // local spare
               spare_type = 3'b001;   
            end
            ridx = ridx + 1;
         end
         // col spare
         else begin
            rc_addr = p_col_addr[idx];
            if(spare_struct == S1) begin
               // local spare
               spare_type = 3'b001;
            end
            else begin
               // bank0
               if(p_bnk_addr[idx] == 2'b01) begin
                  if(~bnk1C) begin
                     bnk1C = 1'b1;
                     spare_type = 3'b001;
                  end
                  else begin
                     spare_type = 3'b010;
                  end
               end
               // bank1
               else begin
                  if(~bnk2C) begin
                     bnk2C = 1'b1;
                     spare_type = 3'b001;
                  end
                  else begin
                     spare_type = 3'b010;
                  end
               end
            end
         end
      end
      else begin
         flag = 0;   
         rc_addr = 0;   
         spare_type = 0;    
         bnk_sel = 0;
      end
   end

   TERM : begin
      flag = 0;   
      rc_addr = 0;   
      spare_type = 0;    
      bnk_sel = 0;
      ridx = 0;
      cidx = 0;
   end
   endcase
end


always@(posedge clk) begin
   case(state)
   IDLE : begin
      uncover_idx = 0;
      upper = NPCAM_SIZE;
      np_idx = 0;
   end

   REAN : begin
      uncover_idx = NPCAM_SIZE;
      for(np_idx = 0; np_idx < NPCAM_SIZE; np_idx = np_idx + 1) begin
         if((!uncover_nps[np_idx] & nonpivot_en[np_idx]) && np_idx < upper) begin
			   uncover_idx = np_idx;
         end
      end
	   upper = uncover_idx;
   end

   SOL : begin
      uncover_idx = 0;
      np_idx = 0;
      upper = NPCAM_SIZE;

   end

   TERM : begin
      uncover_idx = 0;
      upper = NPCAM_SIZE;
      np_idx = 0;
   end
   endcase
end

always@(posedge clk) begin
   case(state)
   IDLE : begin
   if(spare_struct == S3)
            idx <= 1;
   else
      idx <= 0;
            uncovered_row_addr = 0;
      uncovered_col_addr = 0;
      uncovered_bnk_addr = 0;
   end

   REAN : begin
                  // there is nonpivot faults which is not sended to CAM
            if(uncover_idx < NPCAM_SIZE) begin
               uncovered_row_addr = np_row_addr[NPCAM_SIZE-1-uncover_idx];
               uncovered_col_addr = np_col_addr[NPCAM_SIZE-1-uncover_idx];
               uncovered_bnk_addr = np_bnk_addr[NPCAM_SIZE-1-uncover_idx];
           end
            // there is no nonpivot faults which is not sended to CAM
            else begin
               uncovered_row_addr = 0;
               uncovered_col_addr = 0;
               uncovered_bnk_addr = 0;
            end
   end

   SOL : begin
      idx <= idx + 1;

   end

   TERM : begin
      idx <= 0;
      uncovered_row_addr = 0;
      uncovered_col_addr = 0;
      uncovered_bnk_addr = 0;
   end
   endcase
end



// next state transition
always@(posedge clk or posedge rst or posedge check or posedge cam_early_term) begin
   if(rst) begin
      next_state <= IDLE;
   end
   else if(cam_early_term) begin
      next_state <= TERM;
   end
   else if(check) begin
      case(state)
      IDLE : begin
         if(ra_start) begin
            if(signal_valid) begin
               next_state <= SOL;
            end
            else begin
               next_state <= TERM;
            end
         end
         else begin
            next_state <= IDLE;
         end
         ratest_end <= 0;
      end
     
      REAN : begin
         if(uncover_num == 0) begin
            next_state <= IDLE;
            ratest_end <= 1;
         end
      end
   
      SOL : begin
         if(idx >= PCAM_SIZE - 1)
            next_state <= TERM;
         ratest_end <= 0;
      end
   
      TERM : begin
         next_state <= IDLE;
         ratest_end <= 0;
      end
      endcase
   end
   else begin
      case(state)
      IDLE : begin
         if(ra_start) begin
            if(signal_valid) begin
               if(check)
                  next_state <= SOL;
               else if(remain)
                  next_state <= REAN;
            else
               next_state <= TERM;
            end
            else begin
               next_state <= TERM;
            end
         end
         else begin
            next_state <= IDLE;
         end
         ratest_end <= 0;
      end
      
      REAN : begin
         if(uncover_num == 0) begin
            next_state <= IDLE;
            ratest_end <= 1;
         end
      end
   
      SOL : begin
         if(idx >= PCAM_SIZE - 1)
            next_state <= TERM;
         ratest_end <= 0;
      end
   
      TERM : begin
         next_state <= IDLE;
         ratest_end <= 0;
      end
      endcase
   end
end



endmodule
