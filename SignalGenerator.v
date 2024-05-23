`timescale 1ns / 1ps

module signal_generator (
    input rst,
    input clk,
    input [1:0] spare_struct,
   input test_end,
   input termination,
   input early_term_SVC2SG,

    output reg [7:0] DSSS,
    output reg [2:0] RLSS,
   output reg start_SVC,
   output reg opSG
);

localparam S1 = 2'b01;
localparam S2 = 2'b10;
localparam S3 = 2'b11;
reg [2:0] i, j, k, p;
reg [1:0] ri;
reg rlss_term;
reg gen_sig;
reg regtermination;
reg regtests_end;
reg regearly_term_SVC2SG;

always @ (posedge clk) begin
   if(rst) begin
   if(spare_struct != S3) begin
            DSSS <= 8'b0;
            RLSS <= 3'b0;
   end
   else begin
      DSSS <= 8'b0;
      RLSS <= 3'b0;
   end
      gen_sig <= 1;
      rlss_term <= 0;
      i <= 3'd7;
      j <= 3'd6;
      k <= 3'd5;

      p <= 3'd4;
      ri <= 2'd2;
      regtests_end <= 0;
      regtermination <= 0;
      regearly_term_SVC2SG <= 0;
      start_SVC <= 0;
   end
   else begin
      DSSS <= 8'b0;
      RLSS <= 3'b0;
      regtermination <= termination;
      regtests_end <= test_end;
      regearly_term_SVC2SG <= early_term_SVC2SG;


      if(((!termination == 0) && (regtermination == 0)) | ((!test_end == 0) && (regtests_end == 0)) | ((!early_term_SVC2SG == 0) && (regearly_term_SVC2SG == 0))) begin
         start_SVC <= 1;
         case (spare_struct)
         S1, S2 : begin
            if (gen_sig) begin
               DSSS[i] <= 1;
               DSSS[j] <= 1;
               DSSS[k] <= 1;
               DSSS[p] <= 1; 
               if (p > 0) begin
                  p <= p - 1;
               end 
               else if (k > 1) begin
                  k <= k - 1;
                  p <= k - 2;
               end 
               else if (j > 2) begin
                  j <= j - 1;
                  k <= j - 2;
                  p <= j - 3;
               end 
               else if (i > 3) begin
                  i <= i - 1;
                  j <= i - 2;
                  k <= i - 3; 
                  p <= i - 4;
               end 
               else begin
                  gen_sig <= 0; 
               end
            end
         end
         S3 : begin
            if (gen_sig) begin
               //DSSS[i] <= 1;
               DSSS[j] <= 1;
               DSSS[k] <= 1;
               DSSS[p] <= 1;
               RLSS[ri] <= 1;
               //RLSS[3] <= 0; // RLSS's MSB is always 0
               if (ri > 0) begin
                  ri <= ri - 1;
               end 
               else begin
                  ri <= 2'd2;
                  if (p > 0) begin
                     p <= p - 1;
                  end 
                  else if (k > 1) begin
                     k <= k - 1;
                     p <= k - 2;
                  end 
                  else if (j > 2) begin
                     j <= j - 1;
                     k <= j - 2;
                     p <= j - 3;
                  end 
                  /*               
                  else if (i > 3) begin
                     i <= i - 1;
                     j <= i - 2;
                     k <= i - 3; 
                     p <= i - 4;
                  end 
                  */
                  else begin
                     gen_sig <= 0; 
                  end
               end
            end
         end         
         endcase
      end
      else begin
         DSSS <= DSSS;
         RLSS <= RLSS;
         start_SVC <= 0;
      end
   end
end

endmodule