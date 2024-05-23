`timescale 1ns/1ps
module test_bench();

reg clk;
reg rst;
reg test;
reg [1:0] spare_struct;
	
wire repair;
wire early_term;
wire [15:0] solution;

wire test_end_for_time;
   
top_module dut(
	.clk(clk),
	.rst(rst),
	.test(test),
	.repair(repair),
	.spare_struct(spare_struct),

	.early_term(early_term),
	.solution(solution),
	.test_end_for_time(test_end_for_time)
);
/*
always@(posedge early_term) begin
	$finish;
end

always@(negedge repair) begin
	if(~rst)
		$finish;
end
*/
initial 
begin
	spare_struct = 2'b01;
    	clk = 1'b0;
	rst = 1;

	forever begin
    		#1 clk = ~clk;
	end
end


initial begin
	$display("---------------simulation start-----------------");
	repeat(1) begin
		#20;
		// read memory
		rst = 1'b0;
    		test = 1'b1;
		$display("test pattern %d : test is start", i);
		#550000;
		// test end
		test = 1'b0;
		rst = 1'b1;
    	#100;
	end
	
	$display("---------------simulation end-----------------");
 	$stop;
end

// change it!!!
integer i = 0;

realtime t1;
realtime t2;

always @ (negedge repair) begin
	t2 = $time;
	if (!rst) begin
		$display("repair %d : repair_time = %d", i-1, (t2-t1)*5);
	end
	rst = 1;
end

always@(posedge early_term) begin
	$display("early_term %d : ealry termination occurs", i-1);
end

always @ (posedge test_end_for_time) begin
	t1 = $time;
end

always @ (posedge early_term) begin
	#10;
	rst = 1;
end

always @ (negedge rst) begin
	i = i + 1;
end
	
endmodule