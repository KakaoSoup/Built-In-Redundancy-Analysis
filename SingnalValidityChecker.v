`timescale 1ns / 1ps

// 1. are spares in block over?
// 2. are must-repair lines covered?

module signal_validity_checker (
   input clk,
   input rst,
   input test_signal,
   input reanalyze,
   input termination,
   input [1:0] spare_struct,   
   input [7:0] DSSS,            // 8bits DSSS signal
   input [2:0] RLSS,            // 4bits RLSS signal
   input start_SVC,

   // 1. PCAM?? ??? input?? ??
   input [1:0] pivot_bank0,           // 2bits bank_addr
   input [2:0] must_repair0,           // 3bits must flag

   input [1:0] pivot_bank1,           // 2bits bank_addr
   input [2:0] must_repair1,           // 3bits must flag
   
   input [1:0] pivot_bank2,           // 2bits bank_addr
   input [2:0] must_repair2,           // 3bits must flag

   input [1:0] pivot_bank3,           // 2bits bank_addr
   input [2:0] must_repair3,           // 3bits must flag

   input [1:0] pivot_bank4,           // 2bits bank_addr
   input [2:0] must_repair4,           // 3bits must flag

   input [1:0] pivot_bank5,           // 2bits bank_addr
   input [2:0] must_repair5,           // 3bits must flag

   input [1:0] pivot_bank6,           // 2bits bank_addr
   input [2:0] must_repair6,           // 3bits must flag

   input [1:0] pivot_bank7,           // 2bits bank_addr
   input [2:0] must_repair7,           // 3bits must flag

   output reg [7:0] unused_spare,
   output signal_valid,
   output reg early_term,

   output reg ra_start,
   output reg opSVC
);

// state types
reg[2:0] reg_RLSS;
reg[7:0] check_must;
localparam S1 = 2'b01;
localparam S2 = 2'b10;
localparam S3 = 2'b11;

reg v_signal;
assign signal_valid = v_signal;

reg [1:0] state;
localparam IDLE = 0;
localparam CAL = 1;
localparam PRINT = 2;
localparam INVALID = 3;

reg regtest_signal;


always @ (posedge clk) begin
   if(rst) begin
      state <= IDLE;
   end
   else begin
      regtest_signal <= test_signal;
   case(state)
   IDLE: begin
      if(((!test_signal == 0) && (regtest_signal == 0)) | start_SVC) state <= CAL;
//      if((test_signal | start_SVC)) state <= CAL;
      else state <= IDLE;
   end
   CAL : begin
      state <= PRINT;
   end
   PRINT : begin
      if(v_signal == 0) state <= INVALID;
      else if(reanalyze | termination) state <= IDLE;
      else state <= PRINT;
   end
   INVALID: begin
      state <= IDLE;
   end
   endcase
   end
end

always@(posedge clk or posedge reanalyze) begin
   if(rst) begin
      ra_start <= 1'b0;
   end
   else if(termination == 1) ra_start <= 1'b0;
   else begin
      case (state)
      IDLE : begin
         ra_start <= 1'b0;
      end
      PRINT : begin
         if(v_signal == 0 || reanalyze == 1) ra_start <= 1'b0;
         else ra_start <= 1'b1;
      end
      endcase
   end
end

always @ (posedge clk) begin : signal_validity_check
   if(rst) begin
      unused_spare = 8'b1111_1111;
      v_signal = 1'b1;
      reg_RLSS = 3'b100;
      early_term = 1'b0;
   end
   else begin
      case (state)
      IDLE : begin
         unused_spare = 8'b1111_1111;
         v_signal = 1'b1;
         reg_RLSS = 3'b100;
         early_term = 1'b0;
      end
      PRINT : begin
         unused_spare = unused_spare;
         v_signal = v_signal;
      end
      INVALID : begin
         early_term = 1'b1;
      end
      CAL : begin
      // For PCAM 0.
      if(pivot_bank0 == 2'b01) begin
         if(DSSS[0] == 1'b1) begin
            /*
            if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
            else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
            else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
            else reg_RLSS = 3'b000;
            */
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else if (unused_spare[2] == 1'b1) unused_spare[2] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if (reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         else if(DSSS[0] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      else if(pivot_bank0 == 2'b10) begin
         if(DSSS[0] == 1'b1) begin
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else if (unused_spare[3] == 1'b1) unused_spare[3] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         if(DSSS[0] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      
      // For PCAM 1.
      if(pivot_bank1 == 2'b01) begin
         if(DSSS[1] == 1'b1) begin
            /*
            if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
            else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
            else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
            else reg_RLSS = 3'b000;
            */
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else if (unused_spare[2] == 1'b1) unused_spare[2] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         else if(DSSS[1] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      else if(pivot_bank1 == 2'b10) begin
         if(DSSS[1] == 1'b1) begin
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else if (unused_spare[3] == 1'b1) unused_spare[3] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         if(DSSS[1] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end

      // For PCAM 2.
      if(pivot_bank2 == 2'b01) begin
         if(DSSS[2] == 1'b1) begin
            /*
            if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
            else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
            else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
            else reg_RLSS = 3'b000;
            */
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else if (unused_spare[2] == 1'b1) unused_spare[2] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         else if(DSSS[2] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      else if(pivot_bank2 == 2'b10) begin
         if(DSSS[2] == 1'b1) begin
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else if (unused_spare[3] == 1'b1) unused_spare[3] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         if(DSSS[2] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end

      // For PCAM 3.
      if(pivot_bank3 == 2'b01) begin
         if(DSSS[3] == 1'b1) begin
            /*
            if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
            else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
            else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
            else reg_RLSS = 3'b000;
            */
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else if (unused_spare[2] == 1'b1) unused_spare[2] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         else if(DSSS[3] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      else if(pivot_bank3 == 2'b10) begin
         if(DSSS[3] == 1'b1) begin
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else if (unused_spare[3] == 1'b1) unused_spare[3] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         if(DSSS[3] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end

      // For PCAM 4.
      if(pivot_bank4 == 2'b01) begin
         if(DSSS[4] == 1'b1) begin
            /*
            if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
            else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
            else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
            else reg_RLSS = 3'b000;
            */
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else if (unused_spare[2] == 1'b1) unused_spare[2] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         else if(DSSS[4] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      else if(pivot_bank4 == 2'b10) begin
         if(DSSS[4] == 1'b1) begin
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else if (unused_spare[3] == 1'b1) unused_spare[3] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         if(DSSS[4] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end

      // For PCAM 5.
      if(pivot_bank5 == 2'b01) begin
         if(DSSS[5] == 1'b1) begin
            /*
            if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
            else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
            else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
            else reg_RLSS = 3'b000;
            */
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else if (unused_spare[2] == 1'b1) unused_spare[2] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         else if(DSSS[5] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      else if(pivot_bank5 == 2'b10) begin
         if(DSSS[5] == 1'b1) begin
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else if (unused_spare[3] == 1'b1) unused_spare[3] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         if(DSSS[5] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end

      // For PCAM 6.
      if(pivot_bank6 == 2'b01) begin
         if(DSSS[6] == 1'b1) begin
            /*
            if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
            else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
            else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
            else reg_RLSS = 3'b000;
            */
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else if (unused_spare[2] == 1'b1) unused_spare[2] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         else if(DSSS[6] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      else if(pivot_bank6 == 2'b10) begin
         if(DSSS[6] == 1'b1) begin
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else if (unused_spare[3] == 1'b1) unused_spare[3] = 1'b0;
                  else v_signal = 1'b0;
               end
               S3 : begin
                  if(reg_RLSS == 3'b100) reg_RLSS = 3'b001;
                  else if(reg_RLSS == 3'b001) reg_RLSS = 3'b010;
                  else if(reg_RLSS == 3'b010) reg_RLSS = 3'b100;
                  if(reg_RLSS == RLSS) unused_spare[3:2] = 2'b00;
                  else if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         if(DSSS[6] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2, S3 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end

      // For PCAM 7. no S3
      if(pivot_bank7 == 2'b01) begin
         if(DSSS[7] == 1'b1) begin
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[0] == 1'b1) unused_spare[0] = 1'b0;
                  else if (unused_spare[2] == 1'b1) unused_spare[2] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         else if(DSSS[7] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2 : begin
                  if (unused_spare[4] == 1'b1) unused_spare[4] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      else if(pivot_bank7 == 2'b10) begin
         if(DSSS[7] == 1'b1) begin
            case (spare_struct)
               S1, S2 : begin
                  if (unused_spare[1] == 1'b1) unused_spare[1] = 1'b0;
                  else if (unused_spare[3] == 1'b1) unused_spare[3] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
         if(DSSS[7] == 1'b0) begin
            case (spare_struct)
               S1 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
               S2 : begin
                  if (unused_spare[5] == 1'b1) unused_spare[5] = 1'b0;
                  else if (unused_spare[6] == 1'b1) unused_spare[6] = 1'b0;
                  else if (unused_spare[7] == 1'b1) unused_spare[7] = 1'b0;
                  else v_signal = 1'b0;
               end
            endcase
         end
      end
      end
      endcase
   end
/*
         // For must flag control
         check_must = unused_spare;
         if(must_repair0[0] == 1) begin
            if(DSSS[0] == 0) begin
               if(pivot_bank0 == 2'b00) begin
                  if(check_must[0] == 1) check_must[0] = 1
                  else if(check_must[2] == 1) check_must[2] =1
                  else v_signal = 0;
               end
               else if(pivot_bank0 == 2'b01) begin
                  if(check_must[1] == 1) check_must[1] = 1
                  else if(check_must[3] == 1) check_must[3] =1
                  else v_signal = 0;
               end
            end
         end
         if(must_repair0[1] == 1) begin
             if(DSSS[0] == 1) begin
               if(pivot_bank0 == 2'b00) begin
                  if(check_must[4] == 1) check_must[4] = 1
                  else if(check_must[6] == 1) check_must[6] =1
                  else v_signal = 0;
               end
               else if(pivot_bank0 == 2'b01) begin
                  if(check_must[5] == 1) check_must[5] = 1
                  else if(check_must[7] == 1) check_must[7] =1
                  else v_signal = 0;
               end
            end
         end
         if(must_repair0[2] == 1) begin
            //if(DSSS[0] == 1) begin
               if(pivot_bank0 == 2'b00) begin
                  if(check_must[1] == 1) check_must[1] = 1
                  else if(check_must[3] == 1) check_must[3] =1
                  else v_signal = 0;
               end
               else if(pivot_bank0 == 2'b01) begin
                  if(check_must[0] == 1) check_must[0] = 1
                  else if(check_must[2] == 1) check_must[2] =1
                  else v_signal = 0;
               end
            //end
         end
*/



   
end
/*
      // For must flag control
      case (state)
         // spare structure 1
         S1 : begin
               // bank1
               if(bank_addr == 2'b01) begin   
                  if(must_flag[2]) begin
                     if(|(unused_spare & 8'b1010_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[1]) begin
                     if(|(unused_spare & 8'b0000_1010)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[0]) begin
                     if(|(unused_spare & 8'b0101_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
               end
               // bank2
               else begin         
                  if(must_flag[2]) begin
                     if(|(unused_spare & 8'b0101_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[1]) begin
                     if(|(unused_spare & 8'b0000_0101)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[0]) begin
                     if(|(unused_spare & 8'b1010_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
               end
         end
         // spare structure 2
         S2 : begin
            // bank0
               if(bank_addr == 2'b01) begin   
                  if(must_flag[2]) begin      // row must
                     if(|(unused_spare & 8'b1010_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[1]) begin   // col must
                     if(|(unused_spare & 8'b0000_1011)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[0]) begin   // adj row must
                     if(|(unused_spare & 8'b0101_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
               end
               // bank1
               else begin         
                  if(must_flag[2]) begin      // row must
                     if(|(unused_spare & 8'b0101_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[1]) begin   // col must
                     if(|(unused_spare & 8'b0000_0111)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[0]) begin   // adj row must
                     if(|(unused_spare & 8'b1010_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
               end
         end
         
         // spare structure 3
         S3: begin
            // bank0
               if(bank_addr == 2'b01) begin   
                  if(must_flag[2]) begin      // row must
                     if(|(unused_spare & 8'b1010_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[1]) begin   // col must
                     if(|(unused_spare & 8'b0000_1011)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[0]) begin   // adj row must
                     if(|(unused_spare & 8'b0110_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
               end
               // bank1
               else begin         
                  if(must_flag[2]) begin      // row must
                     if(|(unused_spare & 8'b0110_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[1]) begin   // col must
                     if(|(unused_spare & 8'b0000_0111)) begin
                        v_signal <= 1;
                      end
                     else begin
                        v_signal <= 0;
                     end
                  end
                  else if(must_flag[0]) begin   // adj row must
                     if(|(unused_spare & 8'b1010_0000)) begin
                        v_signal <= 1;
                     end else begin
                        v_signal <= 0;
                     end
                  end
               end
         end
      endcase
   end
end
*/
endmodule