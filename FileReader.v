module FileReader;
  
  // ??? ??? ? ??? ???
  reg [7:0] data; // 8?? ???? ?? ??
  integer file;   // ?? ???

  initial begin
    // ??? ?? ??
    file = $fopen("input.txt", "r"); // "input.txt" ??? ?? ??? ??

    if (file == 0) begin
      $display("??? ? ? ????.");
      $finish; // ????? ??
    end else begin
      $display("??? ?????.");

      // ???? ??? ??
      while (!$feof(file)) begin
        $fscanf(file, "%h", data); // 16?? ??? ??? ??
        $display("?? ???: %h", data);
      end

      // ?? ??
      $fclose(file);
    end
  end

endmodule