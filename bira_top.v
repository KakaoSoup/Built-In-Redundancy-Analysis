`timescale 1ns / 1ps

module bira_top(
	input clk,			// 100MHz clk signal from top module
	input rst, 			// reset signal from top module
	input [1:0] spare_struct,	// types of spare structure from top module
	input test_end,			// Test End signal from BIST
	input fault_detect,		// fault alertion from BIST
	
    	input [9:0] row_add_in,		// fault row address from BIST
    	input [9:0] col_add_in,		// fault col address from BIST
	input [7:0] col_flag,		// fault col flag from BIST
	input [1:0] bank_in,		// fault bank address from BIST
	
    	output early_term,		// if # of pivot fault > total # of spares, stop BIST
    	output repair,			// repair possible?
	output [15:0] solution		// 16 bits = 3 bits(spare types) + 1 bit(row:0 or col:1 flag) + 2 bits(bank addr) + 10 bits(row or col solution)
);

///////////////////////////
wire change_signal;
wire [7:0] DSSS;
wire [2:0] RLSS;
wire start_SVC;
wire SGEN;

////////// SVC output wire ///////////////
wire [7:0] unused_spare;
wire signal_valid;
wire ra_start;
// CAM input wire //////
wire [1:0] bnk_addr;
wire [9:0] row_addr;
wire [9:0] col_addr;

////////// CAM output wire //////////////
wire [1:0] pivot_bnk0;
wire [1:0] pivot_bnk1;
wire [1:0] pivot_bnk2;
wire [1:0] pivot_bnk3;
wire [1:0] pivot_bnk4;
wire [1:0] pivot_bnk5;
wire [1:0] pivot_bnk6;
wire [1:0] pivot_bnk7;

wire [2:0] must_repair0;
wire [2:0] must_repair1;
wire [2:0] must_repair2;
wire [2:0] must_repair3;
wire [2:0] must_repair4;
wire [2:0] must_repair5;
wire [2:0] must_repair6;
wire [2:0] must_repair7;

wire [26:0] pivot_fault_addr0;
wire [26:0] pivot_fault_addr1;
wire [26:0] pivot_fault_addr2;
wire [26:0] pivot_fault_addr3;
wire [26:0] pivot_fault_addr4;
wire [26:0] pivot_fault_addr5;
wire [26:0] pivot_fault_addr6;
wire [26:0] pivot_fault_addr7;

wire [16:0] nonpivot_fault_addr0;
wire [16:0] nonpivot_fault_addr1;
wire [16:0] nonpivot_fault_addr2;
wire [16:0] nonpivot_fault_addr3;
wire [16:0] nonpivot_fault_addr4;
wire [16:0] nonpivot_fault_addr5;
wire [16:0] nonpivot_fault_addr6;
wire [16:0] nonpivot_fault_addr7;
wire [16:0] nonpivot_fault_addr8;
wire [16:0] nonpivot_fault_addr9;

wire test_signal;
wire cam_early_term;
wire early_term_SVC2SG;

////// RA outputs //////////////////////////////
wire [21:0] uncovered_addr;
wire reanalyze;
wire termination;
wire ratest_end;
/////////////////////////////////////////////


///////////// SAA output wire /////////////////////
//nonpivot cover infomation
wire [9:0] nonpivot_cover_info;

//nonpivot row address
wire [9:0] nonpivot_row_addr0;    
wire [9:0] nonpivot_row_addr1;
wire [9:0] nonpivot_row_addr2;
wire [9:0] nonpivot_row_addr3;
wire [9:0] nonpivot_row_addr4;
wire [9:0] nonpivot_row_addr5;
wire [9:0] nonpivot_row_addr6;
wire [9:0] nonpivot_row_addr7;
wire [9:0] nonpivot_row_addr8;
wire [9:0] nonpivot_row_addr9;

//nonpivot column address
wire [9:0] nonpivot_col_addr0;    
wire [9:0] nonpivot_col_addr1;
wire [9:0] nonpivot_col_addr2;
wire [9:0] nonpivot_col_addr3;
wire [9:0] nonpivot_col_addr4;
wire [9:0] nonpivot_col_addr5;
wire [9:0] nonpivot_col_addr6;
wire [9:0] nonpivot_col_addr7;
wire [9:0] nonpivot_col_addr8;
wire [9:0] nonpivot_col_addr9;

//nonpivot bank address
wire [1:0] nonpivot_bnk_addr0;    
wire [1:0] nonpivot_bnk_addr1;
wire [1:0] nonpivot_bnk_addr2;
wire [1:0] nonpivot_bnk_addr3;
wire [1:0] nonpivot_bnk_addr4;
wire [1:0] nonpivot_bnk_addr5;
wire [1:0] nonpivot_bnk_addr6;
wire [1:0] nonpivot_bnk_addr7;
wire [1:0] nonpivot_bnk_addr8;
wire [1:0] nonpivot_bnk_addr9;

//nonpivot en signal
wire [9:0] nonpivot_en;						

//pivot row address
wire [9:0] pivot_row_addr0;				
wire [9:0] pivot_row_addr1;
wire [9:0] pivot_row_addr2;
wire [9:0] pivot_row_addr3;
wire [9:0] pivot_row_addr4;
wire [9:0] pivot_row_addr5;
wire [9:0] pivot_row_addr6;
wire [9:0] pivot_row_addr7;

//pivot column address
wire [9:0] pivot_col_addr0;				
wire [9:0] pivot_col_addr1;
wire [9:0] pivot_col_addr2;
wire [9:0] pivot_col_addr3;
wire [9:0] pivot_col_addr4;
wire [9:0] pivot_col_addr5;
wire [9:0] pivot_col_addr6;
wire [9:0] pivot_col_addr7;

//pivot bank address
wire [1:0] pivot_bnk_addr0;				
wire [1:0] pivot_bnk_addr1;
wire [1:0] pivot_bnk_addr2;
wire [1:0] pivot_bnk_addr3;
wire [1:0] pivot_bnk_addr4;
wire [1:0] pivot_bnk_addr5;
wire [1:0] pivot_bnk_addr6;
wire [1:0] pivot_bnk_addr7;

//pivot ren signal
wire [7:0] pivot_ren;
wire [7:0] pivot_en;						

/////////////////////////////////////////////////////////////////////

cam cam0(.clk(clk),                 	// okay
         .rst(rst),                 	// okay
         .test_end(test_end),       	// okay

	 .fault_detect(fault_detect),
         .row_addr(row_add_in),       	// okay
         .col_addr(col_add_in),       	// okay
         .bank_addr(bank_in),      	// okay
         .col_flag(col_flag),       	// okay

         .uncovered_row_addr(uncovered_addr[19:10]),       	// okay
         .uncovered_col_addr(uncovered_addr[9:0]),       	// okay
         .uncovered_bank_addr(uncovered_addr[21:20]),      	// okay

         .STRUCT_TYPE(spare_struct), 	// okay
         .early_term_SVC2SG(early_term_SVC2SG),
         .reanalyze(reanalyze),      	// okay
         .termination(termination),  	// okay
         .ra_test_end(ratest_end),  	// okay

         .pivot_bnk0(pivot_bnk0),
         .pivot_bnk1(pivot_bnk1),
         .pivot_bnk2(pivot_bnk2),
         .pivot_bnk3(pivot_bnk3),
         .pivot_bnk4(pivot_bnk4),
         .pivot_bnk5(pivot_bnk5),
         .pivot_bnk6(pivot_bnk6),
         .pivot_bnk7(pivot_bnk7),
              
         .must_repair0(must_repair0),
         .must_repair1(must_repair1),
         .must_repair2(must_repair2),
         .must_repair3(must_repair3),
		.must_repair4(must_repair4),
        .must_repair5(must_repair5),
        .must_repair6(must_repair6),
         .must_repair7(must_repair7),

         .pivot_fault_addr0(pivot_fault_addr0),
         .pivot_fault_addr1(pivot_fault_addr1),
         .pivot_fault_addr2(pivot_fault_addr2),
         .pivot_fault_addr3(pivot_fault_addr3),
         .pivot_fault_addr4(pivot_fault_addr4),
         .pivot_fault_addr5(pivot_fault_addr5),
         .pivot_fault_addr6(pivot_fault_addr6),
         .pivot_fault_addr7(pivot_fault_addr7),

         .nonpivot_fault_addr0(nonpivot_fault_addr0),
         .nonpivot_fault_addr1(nonpivot_fault_addr1),
         .nonpivot_fault_addr2(nonpivot_fault_addr2),
         .nonpivot_fault_addr3(nonpivot_fault_addr3),
         .nonpivot_fault_addr4(nonpivot_fault_addr4),
         .nonpivot_fault_addr5(nonpivot_fault_addr5),
         .nonpivot_fault_addr6(nonpivot_fault_addr6),
         .nonpivot_fault_addr7(nonpivot_fault_addr7),
         .nonpivot_fault_addr8(nonpivot_fault_addr8),
         .nonpivot_fault_addr9(nonpivot_fault_addr9),
            
         .test_signal(test_signal),
         .cam_early_term(cam_early_term),
         .early_term1(early_term)
);


signal_generator SG(
		.rst(rst),
		.clk(clk),
		.spare_struct(spare_struct),
		.test_end(test_end),
		.termination(termination),
		.early_term_SVC2SG(early_term_SVC2SG),
		.DSSS(DSSS),
		.RLSS(RLSS),
		.start_SVC(start_SVC)
);


signal_validity_checker SVC(.clk(clk),
    .rst(rst),
    .test_signal(test_signal),
    .reanalyze(reanalyze),
    .termination(termination),
    .spare_struct(spare_struct),
    .DSSS(DSSS),
    .RLSS(RLSS),
    .start_SVC(start_SVC),
    .pivot_bank0(pivot_bnk0),
    .pivot_bank1(pivot_bnk1),
    .pivot_bank2(pivot_bnk2),
    .pivot_bank3(pivot_bnk3),
    .pivot_bank4(pivot_bnk4),
    .pivot_bank5(pivot_bnk5),
    .pivot_bank6(pivot_bnk6),
    .pivot_bank7(pivot_bnk7),
    .must_repair0(must_repair0),
    .must_repair1(must_repair1),
    .must_repair2(must_repair2),
    .must_repair3(must_repair3),
    .must_repair4(must_repair4),
    .must_repair5(must_repair5),
    .must_repair6(must_repair6),
    .must_repair7(must_repair7),
    .unused_spare(unused_spare),
    .signal_valid(signal_valid),
                        
    .early_term(early_term_SVC2SG),
    .ra_start(ra_start)
);          

SpareAllocationAnalyzer SAA(
    .clk(clk),
    .DSSS(DSSS),
    .RLSS(RLSS),
    .rst(rst),
    .termination(termination),
    .repair(repair),
    .reanalyze(reanalyze),
    //.test_end(test_end),
    
    .pivot_fault_addr0(pivot_fault_addr0),
    .pivot_fault_addr1(pivot_fault_addr1),
    .pivot_fault_addr2(pivot_fault_addr2),
    .pivot_fault_addr3(pivot_fault_addr3),
    .pivot_fault_addr4(pivot_fault_addr4),
    .pivot_fault_addr5(pivot_fault_addr5),
    .pivot_fault_addr6(pivot_fault_addr6),
    .pivot_fault_addr7(pivot_fault_addr7),
    
    .nonpivot_fault_addr0(nonpivot_fault_addr0),
    .nonpivot_fault_addr1(nonpivot_fault_addr1),
    .nonpivot_fault_addr2(nonpivot_fault_addr2),
    .nonpivot_fault_addr3(nonpivot_fault_addr3),
    .nonpivot_fault_addr4(nonpivot_fault_addr4),
    .nonpivot_fault_addr5(nonpivot_fault_addr5),
    .nonpivot_fault_addr6(nonpivot_fault_addr6),
    .nonpivot_fault_addr7(nonpivot_fault_addr7),
    .nonpivot_fault_addr8(nonpivot_fault_addr8),
    .nonpivot_fault_addr9(nonpivot_fault_addr9),
    
    .nonpivot_cover_info(nonpivot_cover_info),
    
    .nonpivot_row_addr0(nonpivot_row_addr0),
    .nonpivot_row_addr1(nonpivot_row_addr1),
    .nonpivot_row_addr2(nonpivot_row_addr2),
    .nonpivot_row_addr3(nonpivot_row_addr3),
    .nonpivot_row_addr4(nonpivot_row_addr4),
    .nonpivot_row_addr5(nonpivot_row_addr5),
    .nonpivot_row_addr6(nonpivot_row_addr6),
    .nonpivot_row_addr7(nonpivot_row_addr7),
    .nonpivot_row_addr8(nonpivot_row_addr8),
    .nonpivot_row_addr9(nonpivot_row_addr9),
    
    .nonpivot_col_addr0(nonpivot_col_addr0),
    .nonpivot_col_addr1(nonpivot_col_addr1),
    .nonpivot_col_addr2(nonpivot_col_addr2),
    .nonpivot_col_addr3(nonpivot_col_addr3),
    .nonpivot_col_addr4(nonpivot_col_addr4),
    .nonpivot_col_addr5(nonpivot_col_addr5),
    .nonpivot_col_addr6(nonpivot_col_addr6),
    .nonpivot_col_addr7(nonpivot_col_addr7),
    .nonpivot_col_addr8(nonpivot_col_addr8),
    .nonpivot_col_addr9(nonpivot_col_addr9),
    
    .nonpivot_bnk_addr0(nonpivot_bnk_addr0),
    .nonpivot_bnk_addr1(nonpivot_bnk_addr1),
    .nonpivot_bnk_addr2(nonpivot_bnk_addr2),
    .nonpivot_bnk_addr3(nonpivot_bnk_addr3),
    .nonpivot_bnk_addr4(nonpivot_bnk_addr4),
    .nonpivot_bnk_addr5(nonpivot_bnk_addr5),
    .nonpivot_bnk_addr6(nonpivot_bnk_addr6),
    .nonpivot_bnk_addr7(nonpivot_bnk_addr7),
    .nonpivot_bnk_addr8(nonpivot_bnk_addr8),
    .nonpivot_bnk_addr9(nonpivot_bnk_addr9),
    
    .nonpivot_en(nonpivot_en),
    
    .pivot_row_addr0(pivot_row_addr0),
    .pivot_row_addr1(pivot_row_addr1),
    .pivot_row_addr2(pivot_row_addr2),
    .pivot_row_addr3(pivot_row_addr3),
    .pivot_row_addr4(pivot_row_addr4),
    .pivot_row_addr5(pivot_row_addr5),
    .pivot_row_addr6(pivot_row_addr6),
    .pivot_row_addr7(pivot_row_addr7),
    
    .pivot_col_addr0(pivot_col_addr0),
    .pivot_col_addr1(pivot_col_addr1),
    .pivot_col_addr2(pivot_col_addr2),
    .pivot_col_addr3(pivot_col_addr3),
    .pivot_col_addr4(pivot_col_addr4),
    .pivot_col_addr5(pivot_col_addr5),
    .pivot_col_addr6(pivot_col_addr6),
    .pivot_col_addr7(pivot_col_addr7),
    
    .pivot_bnk_addr0(pivot_bnk_addr0),
    .pivot_bnk_addr1(pivot_bnk_addr1),
    .pivot_bnk_addr2(pivot_bnk_addr2),
    .pivot_bnk_addr3(pivot_bnk_addr3),
    .pivot_bnk_addr4(pivot_bnk_addr4),
    .pivot_bnk_addr5(pivot_bnk_addr5),
    .pivot_bnk_addr6(pivot_bnk_addr6),
    .pivot_bnk_addr7(pivot_bnk_addr7),
    
    .pivot_ren(pivot_ren),
    .pivot_en(pivot_en),

    .start_SVC(start_SVC),
    .test_end(test_end)
);

RedundantAnalyzer RA (
   //////// inputs /////////////////////////////////////////////////////
   // from Top Module
   .clk(clk),
   .rst(rst),
   .spare_struct(spare_struct),
   // from CAM   
   .cam_early_term(cam_early_term),

   // from Signal Generator
   .DSSS(DSSS),
   .RLSS(RLSS),

   // from Signal Validity Checker
   .signal_valid(signal_valid),
   .unused_spare(unused_spare),
   .ra_start(ra_start),

   // from Spare Allocation Analyzer
   .pivot_row_addr0(pivot_row_addr0),
   .pivot_row_addr1(pivot_row_addr1),
   .pivot_row_addr2(pivot_row_addr2),
   .pivot_row_addr3(pivot_row_addr3),
   .pivot_row_addr4(pivot_row_addr4),
   .pivot_row_addr5(pivot_row_addr5),
   .pivot_row_addr6(pivot_row_addr6),
   .pivot_row_addr7(pivot_row_addr7),

   .pivot_col_addr0(pivot_col_addr0),
   .pivot_col_addr1(pivot_col_addr1),
   .pivot_col_addr2(pivot_col_addr2),
   .pivot_col_addr3(pivot_col_addr3),
   .pivot_col_addr4(pivot_col_addr4),
   .pivot_col_addr5(pivot_col_addr5),
   .pivot_col_addr6(pivot_col_addr6),
   .pivot_col_addr7(pivot_col_addr7),

   .pivot_bnk_addr0(pivot_bnk_addr0),
   .pivot_bnk_addr1(pivot_bnk_addr1),
   .pivot_bnk_addr2(pivot_bnk_addr2),
   .pivot_bnk_addr3(pivot_bnk_addr3),
   .pivot_bnk_addr4(pivot_bnk_addr4),
   .pivot_bnk_addr5(pivot_bnk_addr5),
   .pivot_bnk_addr6(pivot_bnk_addr6),
   .pivot_bnk_addr7(pivot_bnk_addr7),
   
   // nonpivot_addr
   .nonpivot_en(nonpivot_en),
   .pivot_ren(pivot_ren),
   .pivot_en(pivot_en),
 
   .nonpivot_row_addr0(nonpivot_row_addr0),
   .nonpivot_row_addr1(nonpivot_row_addr1),
   .nonpivot_row_addr2(nonpivot_row_addr2),
   .nonpivot_row_addr3(nonpivot_row_addr3),
   .nonpivot_row_addr4(nonpivot_row_addr4),
   .nonpivot_row_addr5(nonpivot_row_addr5),
   .nonpivot_row_addr6(nonpivot_row_addr6),
   .nonpivot_row_addr7(nonpivot_row_addr7),
   .nonpivot_row_addr8(nonpivot_row_addr8),
   .nonpivot_row_addr9(nonpivot_row_addr9),

   .nonpivot_col_addr0(nonpivot_col_addr0),
   .nonpivot_col_addr1(nonpivot_col_addr1),
   .nonpivot_col_addr2(nonpivot_col_addr2),
   .nonpivot_col_addr3(nonpivot_col_addr3),
   .nonpivot_col_addr4(nonpivot_col_addr4),
   .nonpivot_col_addr5(nonpivot_col_addr5),
   .nonpivot_col_addr6(nonpivot_col_addr6),
   .nonpivot_col_addr7(nonpivot_col_addr7),
   .nonpivot_col_addr8(nonpivot_col_addr8),
   .nonpivot_col_addr9(nonpivot_col_addr9),

   .nonpivot_bnk_addr0(nonpivot_bnk_addr0),
   .nonpivot_bnk_addr1(nonpivot_bnk_addr1),
   .nonpivot_bnk_addr2(nonpivot_bnk_addr2),
   .nonpivot_bnk_addr3(nonpivot_bnk_addr3),
   .nonpivot_bnk_addr4(nonpivot_bnk_addr4),
   .nonpivot_bnk_addr5(nonpivot_bnk_addr5),
   .nonpivot_bnk_addr6(nonpivot_bnk_addr6),
   .nonpivot_bnk_addr7(nonpivot_bnk_addr7),
   .nonpivot_bnk_addr8(nonpivot_bnk_addr8),
   .nonpivot_bnk_addr9(nonpivot_bnk_addr9),

   .nonpivot_cover_info(nonpivot_cover_info),

	////// outputs /////////////////////////////////////////////////////////
   .uncovered_addr(uncovered_addr),
   .solution(solution),      // solution
   .repair(repair),      // if faults can be repaired
   .termination(termination),   // reanalsis is terminated -> next singal
   .reanalyze(reanalyze),      // reanalyze signal to CAM
   .ratest_end(ratest_end)   
);

endmodule
