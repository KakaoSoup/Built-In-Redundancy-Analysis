`timescale  1ns/1ps

module cam
#(parameter PCAM = 8,
  parameter NPCAM = 10)
(
    input clk,
    input rst,
    input test_end,             // from BIST

    input fault_detect,
    input [9:0] row_addr,
    input [9:0] col_addr,
    input [1:0] bank_addr,
    input [9:0] uncovered_row_addr,
    input [9:0] uncovered_col_addr,
    input [1:0] uncovered_bank_addr,
    input [7:0] col_flag,
    input [1:0] STRUCT_TYPE,

    ///////////////////////////////
    input early_term_SVC2SG,

    input reanalyze,
    input termination,
    input ra_test_end,
    
    output [1:0] pivot_bnk0,
    output [1:0] pivot_bnk1,
    output [1:0] pivot_bnk2,
    output [1:0] pivot_bnk3,
    output [1:0] pivot_bnk4,
    output [1:0] pivot_bnk5,
    output [1:0] pivot_bnk6,
    output [1:0] pivot_bnk7,

    output [2:0] must_repair0,
    output [2:0] must_repair1,
    output [2:0] must_repair2,
    output [2:0] must_repair3,
    output [2:0] must_repair4,
    output [2:0] must_repair5,
    output [2:0] must_repair6,
    output [2:0] must_repair7,

    output [26:0] pivot_fault_addr0,
    output [26:0] pivot_fault_addr1,
    output [26:0] pivot_fault_addr2,
    output [26:0] pivot_fault_addr3,
    output [26:0] pivot_fault_addr4,
    output [26:0] pivot_fault_addr5,
    output [26:0] pivot_fault_addr6,
    output [26:0] pivot_fault_addr7,

    output [16:0] nonpivot_fault_addr0,
    output [16:0] nonpivot_fault_addr1,
    output [16:0] nonpivot_fault_addr2,
    output [16:0] nonpivot_fault_addr3,
    output [16:0] nonpivot_fault_addr4,
    output [16:0] nonpivot_fault_addr5,
    output [16:0] nonpivot_fault_addr6,
    output [16:0] nonpivot_fault_addr7,
    output [16:0] nonpivot_fault_addr8,
    output [16:0] nonpivot_fault_addr9,

    output reg test_signal,
    output cam_early_term,
    output reg early_term1,
    output reg opCAM
);
// pcam structure
reg pcam_ren [0:PCAM-1];
reg pcam_en [0:PCAM-1];
reg [9:0] pcam_row_addr [0:PCAM-1];
reg [9:0] pcam_col_addr [0:PCAM-1];
reg [1:0] pcam_bnk_addr [0:PCAM-1];
reg [2:0] pcam_must_flag [0:PCAM-1];

// npcam structure
reg npcam_en [0:NPCAM-1];
reg [2:0] npcam_ptr [0:NPCAM-1];
reg npcam_dscrpt [0:NPCAM-1];
reg [9:0] npcam_addr [0:NPCAM-1];
reg [1:0] npcam_bnk_addr [0:NPCAM-1];

// to RA
reg cam_early_term_reg;

// XXX_XX_XXX : row, col, adj (must flag)
reg [7:0] cnt [0:PCAM-1];

reg find;

integer p_idx;
integer np_idx;
integer idx;
integer col_cnt;

integer pidx1;
integer pidx2;
reg first;

integer idx1;
integer idx2;
integer idx3;
//integer idx5;
//integer idx6;
integer idx7;
integer idx8;
integer idx9;


// storing values on the register
always @ (posedge clk or posedge rst) begin
    if (rst) begin // reset values
        find = 0;
        first = 0;
        p_idx = 0;
          pidx1 = 0;
          pidx2 = 0;
        np_idx = 0;
        test_signal <= 0;
        early_term1 <= 0;
        cam_early_term_reg = 0;
        for (idx = 0; idx < PCAM; idx = idx + 1) begin // PCAM reset
            pcam_ren[idx] <= 1'b0;
            pcam_en[idx] <= 1'b0;
            pcam_row_addr[idx] <= 10'b0;
            pcam_col_addr[idx] <= 10'b0;
            pcam_bnk_addr[idx] <= 2'b0;
            pcam_must_flag[idx] <= 3'b0;
            cnt[idx] = 8'b0;
        end
        for (idx = 0; idx < NPCAM; idx = idx + 1) begin // NPCAM reset
            npcam_en[idx] <= 1'b0;
            npcam_ptr[idx] <= 3'b0;
            npcam_dscrpt[idx] <= 1'b0;
            npcam_addr[idx] <= 10'b0;
            npcam_bnk_addr[idx] <= 2'b0;
        end
    end
    else begin
        if (fault_detect) begin // storing CAM
            find = 0;
            first = 0;      // first pivot fault
            for (idx = 0; idx < PCAM; idx = idx + 1) begin
                //if (STRUCT_TYPE == 2'b11) begin // spare struct 3           
                    // set npcam shares row adress with pcam    
                    if ((pcam_row_addr[idx] == row_addr) && (((STRUCT_TYPE == 2'b10 || STRUCT_TYPE == 2'b01) && bank_addr == pcam_bnk_addr[idx] || STRUCT_TYPE == 2'b11)) && pcam_en[idx] && !find) begin
                        //for (idx5 = 7; idx5 >= 0; idx5 = idx5 - 1) begin // search col_flag == 1
                            if (col_flag[7]==1) begin
                    npcam_en[np_idx] <= 1;
                    npcam_ptr[np_idx] <= idx;
                    npcam_dscrpt[np_idx] <= 0; //ROW          // SAA? ??
                    npcam_addr[np_idx] <= (col_addr | (0));
                    npcam_bnk_addr[np_idx] <= bank_addr;
                    find = 1;
                    np_idx = np_idx + 1;
                    // count faults
                    if((bank_addr == pcam_bnk_addr[idx])) begin
                        cnt[idx] = cnt[idx] + 8'b001_00_000; // share the row addr
                    end
                    else begin
                        cnt[idx] = cnt[idx] + 8'b000_00_001; // share the row addr but different bank
                    end
                    // STRUCT_TYPE //
                    case (STRUCT_TYPE)
                        2'b01 : begin // STRUCT 1
                            if (cnt[idx] == 8'b010_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                        end
                        2'b10 : begin // STRUCT 2
                            if (cnt[idx] == 8'b011_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        2'b11 : begin // STRUCT 3
                            if (cnt[idx] == 8'b100_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        default : pcam_must_flag[idx] <= 3'b0;
                    endcase
                    end
                    /////////////
                    else if (col_flag[6]==1) begin
                    npcam_en[np_idx] <= 1;
                    npcam_ptr[np_idx] <= idx;
                    npcam_dscrpt[np_idx] <= 0; //ROW          // SAA? ??
                    npcam_addr[np_idx] <= (col_addr | (1));
                    npcam_bnk_addr[np_idx] <= bank_addr;
                    find = 1;
                    np_idx = np_idx + 1;
                    // count faults
                    if((bank_addr == pcam_bnk_addr[idx])) begin
                        cnt[idx] = cnt[idx] + 8'b001_00_000; // share the row addr
                    end
                    else begin
                        cnt[idx] = cnt[idx] + 8'b000_00_001; // share the row addr but different bank
                    end
                    // STRUCT_TYPE //
                    case (STRUCT_TYPE)
                        2'b01 : begin // STRUCT 1
                            if (cnt[idx] == 8'b010_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                        end
                        2'b10 : begin // STRUCT 2
                            if (cnt[idx] == 8'b011_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        2'b11 : begin // STRUCT 3
                            if (cnt[idx] == 8'b100_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        default : pcam_must_flag[idx] <= 3'b0;
                    endcase
                    end
                    ///////////
                    else if (col_flag[5]==1) begin
                    npcam_en[np_idx] <= 1;
                    npcam_ptr[np_idx] <= idx;
                    npcam_dscrpt[np_idx] <= 0; //ROW          // SAA? ??
                    npcam_addr[np_idx] <= (col_addr | (2));
                    npcam_bnk_addr[np_idx] <= bank_addr;
                    find = 1;
                    np_idx = np_idx + 1;
                    // count faults
                    if((bank_addr == pcam_bnk_addr[idx])) begin
                        cnt[idx] = cnt[idx] + 8'b001_00_000; // share the row addr
                    end
                    else begin
                        cnt[idx] = cnt[idx] + 8'b000_00_001; // share the row addr but different bank
                    end
                    // STRUCT_TYPE //
                    case (STRUCT_TYPE)
                        2'b01 : begin // STRUCT 1
                            if (cnt[idx] == 8'b010_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                        end
                        2'b10 : begin // STRUCT 2
                            if (cnt[idx] == 8'b011_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        2'b11 : begin // STRUCT 3
                            if (cnt[idx] == 8'b100_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        default : pcam_must_flag[idx] <= 3'b0;
                    endcase
                    end
                    ////////////////
                    else if (col_flag[4]==1) begin
                    npcam_en[np_idx] <= 1;
                    npcam_ptr[np_idx] <= idx;
                    npcam_dscrpt[np_idx] <= 0; //ROW          // SAA? ??
                    npcam_addr[np_idx] <= (col_addr | (3));
                    npcam_bnk_addr[np_idx] <= bank_addr;
                    find = 1;
                    np_idx = np_idx + 1;
                    // count faults
                    if((bank_addr == pcam_bnk_addr[idx])) begin
                        cnt[idx] = cnt[idx] + 8'b001_00_000; // share the row addr
                    end
                    else begin
                        cnt[idx] = cnt[idx] + 8'b000_00_001; // share the row addr but different bank
                    end
                    // STRUCT_TYPE //
                    case (STRUCT_TYPE)
                        2'b01 : begin // STRUCT 1
                            if (cnt[idx] == 8'b010_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                        end
                        2'b10 : begin // STRUCT 2
                            if (cnt[idx] == 8'b011_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        2'b11 : begin // STRUCT 3
                            if (cnt[idx] == 8'b100_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        default : pcam_must_flag[idx] <= 3'b0;
                    endcase
                    end
                    /////////////////////
                    else if (col_flag[3]==1) begin
                    npcam_en[np_idx] <= 1;
                    npcam_ptr[np_idx] <= idx;
                    npcam_dscrpt[np_idx] <= 0; //ROW          // SAA? ??
                    npcam_addr[np_idx] <= (col_addr | (4));
                    npcam_bnk_addr[np_idx] <= bank_addr;
                    find = 1;
                    np_idx = np_idx + 1;
                    // count faults
                    if((bank_addr == pcam_bnk_addr[idx])) begin
                        cnt[idx] = cnt[idx] + 8'b001_00_000; // share the row addr
                    end
                    else begin
                        cnt[idx] = cnt[idx] + 8'b000_00_001; // share the row addr but different bank
                    end
                    // STRUCT_TYPE //
                    case (STRUCT_TYPE)
                        2'b01 : begin // STRUCT 1
                            if (cnt[idx] == 8'b010_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                        end
                        2'b10 : begin // STRUCT 2
                            if (cnt[idx] == 8'b011_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        2'b11 : begin // STRUCT 3
                            if (cnt[idx] == 8'b100_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        default : pcam_must_flag[idx] <= 3'b0;
                    endcase
                    end
                    /////////////////
                    else if (col_flag[2]==1) begin
                    npcam_en[np_idx] <= 1;
                    npcam_ptr[np_idx] <= idx;
                    npcam_dscrpt[np_idx] <= 0; //ROW          // SAA? ??
                    npcam_addr[np_idx] <= (col_addr | (5));
                    npcam_bnk_addr[np_idx] <= bank_addr;
                    find = 1;
                    np_idx = np_idx + 1;
                    // count faults
                    if((bank_addr == pcam_bnk_addr[idx])) begin
                        cnt[idx] = cnt[idx] + 8'b001_00_000; // share the row addr
                    end
                    else begin
                        cnt[idx] = cnt[idx] + 8'b000_00_001; // share the row addr but different bank
                    end
                    // STRUCT_TYPE //
                    case (STRUCT_TYPE)
                        2'b01 : begin // STRUCT 1
                            if (cnt[idx] == 8'b010_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                        end
                        2'b10 : begin // STRUCT 2
                            if (cnt[idx] == 8'b011_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        2'b11 : begin // STRUCT 3
                            if (cnt[idx] == 8'b100_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        default : pcam_must_flag[idx] <= 3'b0;
                    endcase
                    end
                    /////////////////
                    else if (col_flag[1]==1) begin
                    npcam_en[np_idx] <= 1;
                    npcam_ptr[np_idx] <= idx;
                    npcam_dscrpt[np_idx] <= 0; //ROW          // SAA? ??
                    npcam_addr[np_idx] <= (col_addr | (6));
                    npcam_bnk_addr[np_idx] <= bank_addr;
                    find = 1;
                    np_idx = np_idx + 1;
                    // count faults
                    if((bank_addr == pcam_bnk_addr[idx])) begin
                        cnt[idx] = cnt[idx] + 8'b001_00_000; // share the row addr
                    end
                    else begin
                        cnt[idx] = cnt[idx] + 8'b000_00_001; // share the row addr but different bank
                    end
                    // STRUCT_TYPE //
                    case (STRUCT_TYPE)
                        2'b01 : begin // STRUCT 1
                            if (cnt[idx] == 8'b010_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                        end
                        2'b10 : begin // STRUCT 2
                            if (cnt[idx] == 8'b011_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        2'b11 : begin // STRUCT 3
                            if (cnt[idx] == 8'b100_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        default : pcam_must_flag[idx] <= 3'b0;
                    endcase
                    end
                    /////////////////////
                    else if (col_flag[0]==1) begin
                    npcam_en[np_idx] <= 1;
                    npcam_ptr[np_idx] <= idx;
                    npcam_dscrpt[np_idx] <= 0; //ROW          // SAA? ??
                    npcam_addr[np_idx] <= (col_addr | (7));
                    npcam_bnk_addr[np_idx] <= bank_addr;
                    find = 1;
                    np_idx = np_idx + 1;
                    // count faults
                    if((bank_addr == pcam_bnk_addr[idx])) begin
                        cnt[idx] = cnt[idx] + 8'b001_00_000; // share the row addr
                    end
                    else begin
                        cnt[idx] = cnt[idx] + 8'b000_00_001; // share the row addr but different bank
                    end
                    // STRUCT_TYPE //
                    case (STRUCT_TYPE)
                        2'b01 : begin // STRUCT 1
                            if (cnt[idx] == 8'b010_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                        end
                        2'b10 : begin // STRUCT 2
                            if (cnt[idx] == 8'b011_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        2'b11 : begin // STRUCT 3
                            if (cnt[idx] == 8'b100_00_000) begin
                                pcam_must_flag[idx] <= 3'b100;
                            end
                            else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                pcam_must_flag[idx] <= 3'b001;
                            end
                        end
                        default : pcam_must_flag[idx] <= 3'b0;
                    endcase
                    end
                end
                    //end
                    // set npcam shares col address with pcam
                    else if ((pcam_col_addr[idx] == col_addr + MUX(col_flag)) && pcam_en[idx] && !find) begin
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= idx;
                        npcam_dscrpt[np_idx] <= 1;//COL
                        npcam_addr[np_idx] <= row_addr;
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        find = 1;
                        np_idx = np_idx + 1;
                        // count faults
                        cnt[idx] = cnt[idx] + 8'b000_01_000;
                        if ((cnt[idx] & 8'b000_11_000) == 8'b000_11_000) begin
                            pcam_must_flag[idx] <= 3'b010;
                        end
                    end
                //end
/*
              // spare type == 1, 2
                else if (STRUCT_TYPE == 2'b01 || STRUCT_TYPE == 2'b10) begin           
                    // set npcam shares row address with pcam
                    if ((pcam_row_addr[idx] == row_addr) && (pcam_bnk_addr[idx] == bank_addr)&& pcam_en[idx] && !find) begin
                        for (idx5 = 7; idx5 >= 0; idx5 = idx5 - 1) begin
                            if (col_flag[idx5] == 1) begin
                                // set npcam
                                npcam_en[np_idx] <= 1;
                                npcam_ptr[np_idx] <= idx;
                                npcam_dscrpt[np_idx] <= 0; //ROW
                                //$display("%d = idx5",idx5);
                                npcam_addr[np_idx] <= (col_addr | (7-idx5));
                                npcam_bnk_addr[np_idx] <= bank_addr;
                                find = 1;
                                np_idx = np_idx + 1;
                                // count faults
                                if((bank_addr == pcam_bnk_addr[idx])) begin
                                    cnt[idx] = cnt[idx] + 8'b001_00_000; // share the row addr
                                end
                                else begin
                                    cnt[idx] = cnt[idx] + 8'b000_00_001; // share the row addr but different bank
                                end
                                // STRUCT_TYPE //
                                case (STRUCT_TYPE)
                                    2'b01 : begin // STRUCT 1
                                        if (cnt[idx] == 8'b010_00_000) begin
                                            pcam_must_flag[idx] <= 3'b100;
                                        end
                                    end
                                    2'b10 : begin // STRUCT 2
                                        if (cnt[idx] == 8'b011_00_000) begin
                                            pcam_must_flag[idx] <= 3'b100;
                                        end
                                        else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                            pcam_must_flag[idx] <= 3'b001;
                                        end
                                    end
                                    2'b11 : begin // STRUCT 3
                                        if (cnt[idx] == 8'b100_00_000) begin
                                            pcam_must_flag[idx] <= 3'b100;
                                        end
                                        else if (((cnt[idx] & 8'b111_00_000) >> 5) + (cnt[idx] & 8'b000_00_111) >= 4'b100) begin
                                            pcam_must_flag[idx] <= 3'b001;
                                        end
                                    end
                                    default : pcam_must_flag[idx] <= 3'b0;
                                endcase
                            end
                        end
                    end
                    // set npcam share col address with pcam
                    else if ((pcam_col_addr[idx] == col_addr+MUX(col_flag)) && pcam_en[idx] && !find) begin
                        // set npcam
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= idx;
                        npcam_dscrpt[np_idx] <= 1;//COL
                        npcam_addr[np_idx] <= row_addr;
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        find = 1;

                        np_idx = np_idx + 1;

                        // count faults
                        cnt[idx] = cnt[idx] + 8'b000_01_000;
                        if ((cnt[idx] & 8'b000_11_000) == 8'b000_11_000) begin
                            pcam_must_flag[idx] <= 3'b010;
                        end

 
                    end
                end
                */
            end
        end

        if (!find && fault_detect) begin         // pcam set
            col_cnt = 0;
            //for (idx6 = 7; idx6 >= 0; idx6 = idx6 - 1) begin
                if (col_flag[7] == 1 && col_cnt == 0) begin
                    if(bank_addr == 2'b01 && !first) begin
                        pidx1 = pidx1 + 1;
                    end
                    else if(bank_addr == 2'b10 && !first) begin
                        pidx2 = pidx2 + 1;
                    end
                    pcam_ren[p_idx] <= 0;
                    pcam_en[p_idx] <= 1;
                    pcam_row_addr[p_idx] <= row_addr;
                    pcam_col_addr[p_idx] <= (col_addr | (0));
                    pcam_bnk_addr[p_idx] <= bank_addr;
                    p_idx = p_idx + 1;
                    first = 1;
                    col_cnt = col_cnt + 1;
                    end
                else if (col_flag[7] == 1 && col_cnt >= 1) begin
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= p_idx-1;
                        npcam_dscrpt[np_idx] <= 0; //ROW
                        npcam_addr[np_idx] <= (col_addr | (0));
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        np_idx = np_idx + 1;
                end
                ////////////////////////////
                if (col_flag[6] == 1 && col_cnt == 0) begin
                    if(bank_addr == 2'b01 && !first) begin
                        pidx1 = pidx1 + 1;
                    end
                    else if(bank_addr == 2'b10 && !first) begin
                        pidx2 = pidx2 + 1;
                    end
                    pcam_ren[p_idx] <= 0;
                    pcam_en[p_idx] <= 1;
                    pcam_row_addr[p_idx] <= row_addr;
                    pcam_col_addr[p_idx] <= (col_addr | (1));
                    pcam_bnk_addr[p_idx] <= bank_addr;
                    p_idx = p_idx + 1;
                    first = 1;
                    col_cnt = col_cnt + 1;
                    end
                else if (col_flag[6] == 1 && col_cnt >= 1) begin
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= p_idx-1;
                        npcam_dscrpt[np_idx] <= 0; //ROW
                        npcam_addr[np_idx] <= (col_addr | (1));
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        np_idx = np_idx + 1;
                end
                ///////////////////////////////
                if (col_flag[5] == 1 && col_cnt == 0) begin
                    if(bank_addr == 2'b01 && !first) begin
                        pidx1 = pidx1 + 1;
                    end
                    else if(bank_addr == 2'b10 && !first) begin
                        pidx2 = pidx2 + 1;
                    end
                    pcam_ren[p_idx] <= 0;
                    pcam_en[p_idx] <= 1;
                    pcam_row_addr[p_idx] <= row_addr;
                    pcam_col_addr[p_idx] <= (col_addr | (2));
                    pcam_bnk_addr[p_idx] <= bank_addr;
                    p_idx = p_idx + 1;
                    first = 1;
                    col_cnt = col_cnt + 1;
                    end
                else if (col_flag[5] == 1 && col_cnt >= 1) begin
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= p_idx-1;
                        npcam_dscrpt[np_idx] <= 0; //ROW
                        npcam_addr[np_idx] <= (col_addr | (2));
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        np_idx = np_idx + 1;
                end
                //////////////////////////////
                if (col_flag[4] == 1 && col_cnt == 0) begin
                    if(bank_addr == 2'b01 && !first) begin
                        pidx1 = pidx1 + 1;
                    end
                    else if(bank_addr == 2'b10 && !first) begin
                        pidx2 = pidx2 + 1;
                    end
                    pcam_ren[p_idx] <= 0;
                    pcam_en[p_idx] <= 1;
                    pcam_row_addr[p_idx] <= row_addr;
                    pcam_col_addr[p_idx] <= (col_addr | (3));
                    pcam_bnk_addr[p_idx] <= bank_addr;
                    p_idx = p_idx + 1;
                    first = 1;
                    col_cnt = col_cnt + 1;
                    end
                else if (col_flag[4] == 1 && col_cnt >= 1) begin
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= p_idx-1;
                        npcam_dscrpt[np_idx] <= 0; //ROW
                        npcam_addr[np_idx] <= (col_addr | (3));
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        np_idx = np_idx + 1;
                end
                ////////////////////////////
                if (col_flag[3] == 1 && col_cnt == 0) begin
                    if(bank_addr == 2'b01 && !first) begin
                        pidx1 = pidx1 + 1;
                    end
                    else if(bank_addr == 2'b10 && !first) begin
                        pidx2 = pidx2 + 1;
                    end
                    pcam_ren[p_idx] <= 0;
                    pcam_en[p_idx] <= 1;
                    pcam_row_addr[p_idx] <= row_addr;
                    pcam_col_addr[p_idx] <= (col_addr | (4));
                    pcam_bnk_addr[p_idx] <= bank_addr;
                    p_idx = p_idx + 1;
                    first = 1;
                    col_cnt = col_cnt + 1;
                    end
                else if (col_flag[3] == 1 && col_cnt >= 1) begin
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= p_idx-1;
                        npcam_dscrpt[np_idx] <= 0; //ROW
                        npcam_addr[np_idx] <= (col_addr | (4));
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        np_idx = np_idx + 1;
                end
                /////////////////////////
                if (col_flag[2] == 1 && col_cnt == 0) begin
                    if(bank_addr == 2'b01 && !first) begin
                        pidx1 = pidx1 + 1;
                    end
                    else if(bank_addr == 2'b10 && !first) begin
                        pidx2 = pidx2 + 1;
                    end
                    pcam_ren[p_idx] <= 0;
                    pcam_en[p_idx] <= 1;
                    pcam_row_addr[p_idx] <= row_addr;
                    pcam_col_addr[p_idx] <= (col_addr | (5));
                    pcam_bnk_addr[p_idx] <= bank_addr;
                    p_idx = p_idx + 1;
                    first = 1;
                    col_cnt = col_cnt + 1;
                    end
                else if (col_flag[2] == 1 && col_cnt >= 1) begin
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= p_idx-1;
                        npcam_dscrpt[np_idx] <= 0; //ROW
                        npcam_addr[np_idx] <= (col_addr | (5));
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        np_idx = np_idx + 1;
                end
                /////////////////////////
                if (col_flag[1] == 1 && col_cnt == 0) begin
                    if(bank_addr == 2'b01 && !first) begin
                        pidx1 = pidx1 + 1;
                    end
                    else if(bank_addr == 2'b10 && !first) begin
                        pidx2 = pidx2 + 1;
                    end
                    pcam_ren[p_idx] <= 0;
                    pcam_en[p_idx] <= 1;
                    pcam_row_addr[p_idx] <= row_addr;
                    pcam_col_addr[p_idx] <= (col_addr | (6));
                    pcam_bnk_addr[p_idx] <= bank_addr;
                    p_idx = p_idx + 1;
                    first = 1;
                    col_cnt = col_cnt + 1;
                    end
                else if (col_flag[1] == 1 && col_cnt >= 1) begin
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= p_idx-1;
                        npcam_dscrpt[np_idx] <= 0; //ROW
                        npcam_addr[np_idx] <= (col_addr | (6));
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        np_idx = np_idx + 1;
                end
                //////////////////////////
                if (col_flag[0] == 1 && col_cnt == 0) begin
                    if(bank_addr == 2'b01 && !first) begin
                        pidx1 = pidx1 + 1;
                    end
                    else if(bank_addr == 2'b10 && !first) begin
                        pidx2 = pidx2 + 1;
                    end
                    pcam_ren[p_idx] <= 0;
                    pcam_en[p_idx] <= 1;
                    pcam_row_addr[p_idx] <= row_addr;
                    pcam_col_addr[p_idx] <= (col_addr | (7));
                    pcam_bnk_addr[p_idx] <= bank_addr;
                    p_idx = p_idx + 1;
                    first = 1;
                    col_cnt = col_cnt + 1;
                    end
                else if (col_flag[0] == 1 && col_cnt >= 1) begin
                        npcam_en[np_idx] <= 1;
                        npcam_ptr[np_idx] <= p_idx-1;
                        npcam_dscrpt[np_idx] <= 0; //ROW
                        npcam_addr[np_idx] <= (col_addr | (7));
                        npcam_bnk_addr[np_idx] <= bank_addr;
                        np_idx = np_idx + 1;
                end
            //end
        end
        if ((STRUCT_TYPE == 2'b01) && ((pidx1 > 4 || pidx2 > 4) || (p_idx > 8) || (np_idx > 10))) early_term1 <= 1;
        if ((STRUCT_TYPE == 2'b10) && ((pidx1 > 5 || pidx2 > 5) || (p_idx > 8) || (np_idx > 10))) early_term1 <= 1;
        if ((STRUCT_TYPE == 2'b11) && ((pidx1 > 5 || pidx2 > 5) || (p_idx > 7) || (np_idx > 10))) early_term1 <= 1;

        if (termination || early_term_SVC2SG) begin       // if termination signal is '1' --> pcam_ren[]? 1? row reset
           test_signal <= 0;
           cam_early_term_reg = 0;
            for (idx1 = 0; idx1 < PCAM; idx1 = idx1 + 1) begin
                if (pcam_ren[idx1] == 1) begin
                    pcam_ren[idx1] <= 0;
                    pcam_en[idx1] <= 0;
                    pcam_row_addr[idx1] <= 0;
                    pcam_col_addr[idx1] <= 0;
                    pcam_bnk_addr[idx1] <= 0;
                    pcam_must_flag[idx1] <= 0;
                end
            end
        end

        if (reanalyze && !(uncovered_bank_addr == 2'b00)) begin // reanalyze
            idx2 = 0;
            idx7 = 0;
            test_signal <= 0;
            for (idx3 = 0; idx3 < PCAM && !idx2; idx3 = idx3 + 1) begin
                if (!pcam_en[idx3] && idx2 == 0) begin
                    pcam_ren[idx3] <= 1; 
                    pcam_en[idx3] <= 1;
                    pcam_row_addr[idx3] <= uncovered_row_addr;
                    pcam_col_addr[idx3] <= uncovered_col_addr;
                    pcam_bnk_addr[idx3] <= uncovered_bank_addr;
                    idx2 = 1;
                end
                if (STRUCT_TYPE == 2'b01) begin            // cam_early_term (reanalyze)
                  idx7 = 0; idx9 = 0;
                  for (idx8 = 0; idx8 < PCAM; idx8 = idx8 + 1) begin
                      if (pcam_bnk_addr[idx8] == 2'b01) begin
                            idx7 = idx7 + 1;
                         if (idx7 >= 5) cam_early_term_reg = 1;
                          end
                        else if (pcam_bnk_addr[idx8] == 2'b10) begin
                            idx9 = idx9 + 1;
                            if (idx9 >= 5) cam_early_term_reg = 1;
                        end
                  end
                end
                else if (STRUCT_TYPE == 2'b10) begin            // cam_early_term (reanalyze)
                  idx7 = 0; idx9 = 0;
                  for (idx8 = 0; idx8 < PCAM; idx8 = idx8 + 1) begin
                      if (pcam_bnk_addr[idx8] == 2'b01) begin
                            idx7 = idx7 + 1;
                         if (idx7 >= 6) cam_early_term_reg = 1;
                          end
                        else if (pcam_bnk_addr[idx8] == 2'b10) begin
                            idx9 = idx9 + 1;
                            if (idx9 >= 6) cam_early_term_reg = 1;
                        end
                  end
                end
                else if (STRUCT_TYPE == 2'b11) begin            // cam_early_term (reanalyze)
                  idx7 = 0; idx9 = 0;
                  for (idx8 = 0; idx8 < PCAM; idx8 = idx8 + 1) begin
                      if (pcam_bnk_addr[idx8] == 2'b01) begin
                            idx7 = idx7 + 1;
                         if (idx7 >= 5) cam_early_term_reg = 1;
                          end
                        else if (pcam_bnk_addr[idx8] == 2'b10) begin
                            idx9 = idx9 + 1;
                            if (idx9 >= 5) cam_early_term_reg = 1;
                        end
                  end
                end
            end
        end

        if ((test_end || ra_test_end) && !reanalyze) test_signal <= 1;

        
    end
end

// for output
assign cam_early_term = cam_early_term_reg;

assign pivot_bnk0 = pcam_bnk_addr[0];
assign must_repair0 = pcam_must_flag[0];
assign pivot_fault_addr0 = { pcam_ren[0], pcam_en[0], pcam_row_addr[0], pcam_col_addr[0], pcam_bnk_addr[0], pcam_must_flag[0] };

assign pivot_bnk1 = pcam_bnk_addr[1];
assign must_repair1 = pcam_must_flag[1];
assign pivot_fault_addr1 = { pcam_ren[1], pcam_en[1], pcam_row_addr[1], pcam_col_addr[1], pcam_bnk_addr[1], pcam_must_flag[1] };

assign pivot_bnk2 = pcam_bnk_addr[2];
assign must_repair2 = pcam_must_flag[2];
assign pivot_fault_addr2 = { pcam_ren[2], pcam_en[2], pcam_row_addr[2], pcam_col_addr[2], pcam_bnk_addr[2], pcam_must_flag[2] };

assign pivot_bnk3 = pcam_bnk_addr[3];
assign must_repair3 = pcam_must_flag[3];
assign pivot_fault_addr3 = { pcam_ren[3], pcam_en[3], pcam_row_addr[3], pcam_col_addr[3], pcam_bnk_addr[3], pcam_must_flag[3] };

assign pivot_bnk4 = pcam_bnk_addr[4];
assign must_repair4 = pcam_must_flag[4];
assign pivot_fault_addr4 = { pcam_ren[4], pcam_en[4], pcam_row_addr[4], pcam_col_addr[4], pcam_bnk_addr[4], pcam_must_flag[4] };

assign pivot_bnk5 = pcam_bnk_addr[5];
assign must_repair5 = pcam_must_flag[5];
assign pivot_fault_addr5 = { pcam_ren[5], pcam_en[5], pcam_row_addr[5], pcam_col_addr[5], pcam_bnk_addr[5], pcam_must_flag[5] };

assign pivot_bnk6 = pcam_bnk_addr[6];
assign must_repair6 = pcam_must_flag[6];
assign pivot_fault_addr6 = { pcam_ren[6], pcam_en[6], pcam_row_addr[6], pcam_col_addr[6], pcam_bnk_addr[6], pcam_must_flag[6] };

assign pivot_bnk7 = pcam_bnk_addr[7];
assign must_repair7 = pcam_must_flag[7];
assign pivot_fault_addr7 = { pcam_ren[7], pcam_en[7], pcam_row_addr[7], pcam_col_addr[7], pcam_bnk_addr[7], pcam_must_flag[7] };

assign nonpivot_fault_addr0 = { npcam_en[0], npcam_ptr[0], npcam_dscrpt[0], npcam_addr[0], npcam_bnk_addr[0] };
assign nonpivot_fault_addr1 = { npcam_en[1], npcam_ptr[1], npcam_dscrpt[1], npcam_addr[1], npcam_bnk_addr[1] };
assign nonpivot_fault_addr2 = { npcam_en[2], npcam_ptr[2], npcam_dscrpt[2], npcam_addr[2], npcam_bnk_addr[2] };
assign nonpivot_fault_addr3 = { npcam_en[3], npcam_ptr[3], npcam_dscrpt[3], npcam_addr[3], npcam_bnk_addr[3] };
assign nonpivot_fault_addr4 = { npcam_en[4], npcam_ptr[4], npcam_dscrpt[4], npcam_addr[4], npcam_bnk_addr[4] };
assign nonpivot_fault_addr5 = { npcam_en[5], npcam_ptr[5], npcam_dscrpt[5], npcam_addr[5], npcam_bnk_addr[5] };
assign nonpivot_fault_addr6 = { npcam_en[6], npcam_ptr[6], npcam_dscrpt[6], npcam_addr[6], npcam_bnk_addr[6] };
assign nonpivot_fault_addr7 = { npcam_en[7], npcam_ptr[7], npcam_dscrpt[7], npcam_addr[7], npcam_bnk_addr[7] };
assign nonpivot_fault_addr8 = { npcam_en[8], npcam_ptr[8], npcam_dscrpt[8], npcam_addr[8], npcam_bnk_addr[8] };
assign nonpivot_fault_addr9 = { npcam_en[9], npcam_ptr[9], npcam_dscrpt[9], npcam_addr[9], npcam_bnk_addr[9] };

function [2:0] MUX;
    input [7:0] input_bits;
        begin
            MUX = (input_bits == 8'b1000_0000) ? 3'd0 :           // 00000_00111
                (input_bits == 8'b0100_0000) ? 3'd1 :           // 00000_00110
                (input_bits == 8'b0010_0000) ? 3'd2 :           // 00000_00101
                (input_bits == 8'b0001_0000) ? 3'd3 :           // 00000_00100
                (input_bits == 8'b0000_1000) ? 3'd4 :           // 00000_00011
                (input_bits == 8'b0000_0100) ? 3'd5 :           // 00000_00010
                (input_bits == 8'b0000_0010) ? 3'd6 : 3'd7;     // 00000_00001 : 00000_00000
        end
endfunction


endmodule