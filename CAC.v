   module CAC(
    input clk,
    input wire [9:0] RCx_addr,
    input wire [9:0] NPcy_addr,
    input wire [1:0] RCx_bnk,
    input wire [1:0] NPcy_bnk,
    input rst,
    output reg result
);



//always@(rst) begin
//   result <= 0;
//end

always@(*) begin
   if(rst) 
      result <= 1'b0; //(rst == 1'b1) ? 1'b0 : ((((RCx_bnk[1] || RCx_bnk[0]) == 1'b1) && ((NPcy_bnk[1] || NPcy_bnk[0]) == 1'b1)) ? ((RCx_addr == NPcy_addr) ? ((RCx_bnk == NPcy_bnk) ?  1'b1 : 1'b0) : 1'b0) : 1'b0);
   else begin
      if((|RCx_bnk[1:0] == 1'b1) && (|NPcy_bnk[1:0] == 1'b1)) begin
      result <= (RCx_addr == NPcy_addr) ? ((RCx_bnk == NPcy_bnk) ?  1'b1 : 1'b0) : 1'b0;
      end else
      result <= 1'b0;
   end
end


endmodule