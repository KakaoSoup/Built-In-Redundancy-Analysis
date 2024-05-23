module RAC(
    input clk,
    input wire [9:0] RRx_addr,
    input wire [9:0] NPry_addr,
    input wire [1:0] RRx_bnk,
    input wire [1:0] NPry_bnk,
    input wire [2:0] RLSS,
    input rst,
    output reg result
);
    

//always@(rst) begin
//   result <= 0;
//end

always@(*) begin
   if(rst)
      result <= 1'b0;//(rst == 1'b1) ? 1'b0 : ((((RRx_bnk[1] || RRx_bnk[0]) == 1'b1) && ((NPry_bnk[1] || NPry_bnk[0]) == 1'b1)) ? ((RRx_addr == NPry_addr) ? ((RLSS[2] || (RRx_bnk == NPry_bnk)) ?  1'b1 : 1'b0) : 1'b0) : 1'b0);
   else begin
      if((|RRx_bnk[1:0] == 1'b1) && (|NPry_bnk[1:0] == 1'b1)) begin
      result <= (RRx_addr == NPry_addr) ? (|(RLSS[2:0] || (RRx_bnk == NPry_bnk)) ?  1'b1 : 1'b0) : 1'b0;
      end else
      result <= 1'b0;
    end
end

endmodule 