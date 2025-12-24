// ALU & Arithmetic Logic Design
// You will design and implement the Arithmetic Logic Unit (ALU), which must
// support:
// • add, sub,
// • and, or, xor,
// • sll, srl ….etc

// Your responsibilities:
// • Derive ALU operation codes
// • Implement ALU behavior in Verilog
// • Ensure correct outputs for all R-type and shift operations
// • Provide an individual testbench that proves correct ALU operation

// ALU & Arithmetic Logic Design
// Task 1 - Mohamed Ibrahim - 231002063

//=============================================================================
// ALU Module - Complete Implementation
//=============================================================================
module ALU(
  input [63:0] a,               // First operand (64-bit)
  input [63:0] b,               // Second operand (64-bit)
  input [3:0] ALUControl,       // ALU operation control signal
  output reg [63:0] result,     // ALU result (64-bit)
  output reg carryOut,          // Carry out flag
  output reg zero               // Zero flag (1 if result is 0)
);

  always @(*) begin
    // Default: clear carry out
    carryOut = 0;
    
    // Perform operation based on ALUControl
    case (ALUControl)
      
      // 0000: AND operation
      4'b0000: begin
        result = a & b;
      end
      
      // 0001: OR operation
      4'b0001: begin
        result = a | b;
      end
      
      // 0010: ADD operation
      4'b0010: begin
        {carryOut, result} = a + b;
      end
      
      // 0011: XOR operation
      4'b0011: begin
        result = a ^ b;
      end
      
      // 0100: SLL (Shift Left Logical)
      4'b0100: begin
        // Shift 'a' left by the amount specified in lower 6 bits of 'b'
        // In RISC-V, only lower 6 bits of shift amount are used for 64-bit
        result = a << b[5:0];
      end
      
      // 0101: SRL (Shift Right Logical)
      4'b0101: begin
        // Shift 'a' right by the amount specified in lower 6 bits of 'b'
        result = a >> b[5:0];
      end
      
      // 0110: SUB (Subtract)
      4'b0110: begin
        {carryOut, result} = a - b;
      end
      
      // 0111: SLT (Set Less Than)
      4'b0111: begin
        // Result is 1 if a < b (signed comparison), 0 otherwise
        result = ($signed(a) < $signed(b)) ? 64'd1 : 64'd0;
      end
      
      // Default: Output zero
      default: begin
        result = 64'd0;
      end
      
    endcase
    
    // Set zero flag
    zero = (result == 64'd0);
  end

endmodule


//=============================================================================
// Testbench for ALU
//=============================================================================
module testbench_alu;

  reg [63:0] a, b;
  reg [3:0] ALUControl;
  wire [63:0] result;
  wire carryOut, zero;
  
  // Instantiate ALU
  ALU alu (
    .a(a),
    .b(b),
    .ALUControl(ALUControl),
    .result(result),
    .carryOut(carryOut),
    .zero(zero)
  );
  
  // Test sequence
  initial begin
    $display("========================================");
    $display("Testing ALU - All Operations");
    $display("========================================");
    
    //-----------------------------------
    // Test 1: AND operation
    //-----------------------------------
    $display("\n--- Test 1: AND Operation ---");
    a = 64'hFFFF_FFFF_FFFF_FFFF;
    b = 64'h0000_0000_0000_00FF;
    ALUControl = 4'b0000;
    #10;
    $display("a = %h, b = %h", a, b);
    $display("AND result = %h (expected: 00000000000000FF)", result);
    $display("Zero flag = %b (expected: 0)", zero);
    
    //-----------------------------------
    // Test 2: OR operation
    //-----------------------------------
    $display("\n--- Test 2: OR Operation ---");
    a = 64'h0000_0000_0000_00F0;
    b = 64'h0000_0000_0000_000F;
    ALUControl = 4'b0001;
    #10;
    $display("a = %h, b = %h", a, b);
    $display("OR result = %h (expected: 00000000000000FF)", result);
    $display("Zero flag = %b (expected: 0)", zero);
    
    //-----------------------------------
    // Test 3: ADD operation
    //-----------------------------------
    $display("\n--- Test 3: ADD Operation ---");
    a = 64'd100;
    b = 64'd50;
    ALUControl = 4'b0010;
    #10;
    $display("a = %0d, b = %0d", a, b);
    $display("ADD result = %0d (expected: 150)", result);
    $display("Carry out = %b", carryOut);
    $display("Zero flag = %b (expected: 0)", zero);
    
    //-----------------------------------
    // Test 4: XOR operation
    //-----------------------------------
    $display("\n--- Test 4: XOR Operation ---");
    a = 64'hFFFF_FFFF_FFFF_FFFF;
    b = 64'hFFFF_FFFF_FFFF_FFFF;
    ALUControl = 4'b0011;
    #10;
    $display("a = %h, b = %h", a, b);
    $display("XOR result = %h (expected: 0000000000000000)", result);
    $display("Zero flag = %b (expected: 1)", zero);
    
    //-----------------------------------
    // Test 5: SLL (Shift Left Logical)
    //-----------------------------------
    $display("\n--- Test 5: SLL Operation ---");
    a = 64'd1;
    b = 64'd3;  // Shift by 3 positions
    ALUControl = 4'b0100;
    #10;
    $display("a = %0d, shift amount = %0d", a, b);
    $display("SLL result = %0d (expected: 8)", result);
    $display("Binary: %b", result);
    
    //-----------------------------------
    // Test 6: SRL (Shift Right Logical)
    //-----------------------------------
    $display("\n--- Test 6: SRL Operation ---");
    a = 64'd16;
    b = 64'd2;  // Shift by 2 positions
    ALUControl = 4'b0101;
    #10;
    $display("a = %0d, shift amount = %0d", a, b);
    $display("SRL result = %0d (expected: 4)", result);
    $display("Binary: %b", result);
    
    //-----------------------------------
    // Test 7: SUB operation
    //-----------------------------------
    $display("\n--- Test 7: SUB Operation ---");
    a = 64'd100;
    b = 64'd50;
    ALUControl = 4'b0110;
    #10;
    $display("a = %0d, b = %0d", a, b);
    $display("SUB result = %0d (expected: 50)", result);
    $display("Zero flag = %b (expected: 0)", zero);
    
    //-----------------------------------
    // Test 8: SUB with zero result (for BEQ)
    //-----------------------------------
    $display("\n--- Test 8: SUB with Equal Values (BEQ) ---");
    a = 64'd100;
    b = 64'd100;
    ALUControl = 4'b0110;
    #10;
    $display("a = %0d, b = %0d", a, b);
    $display("SUB result = %0d (expected: 0)", result);
    $display("Zero flag = %b (expected: 1) <- This is used for BEQ", zero);
    
    //-----------------------------------
    // Test 9: SLT (Set Less Than)
    //-----------------------------------
    $display("\n--- Test 9: SLT Operation ---");
    a = 64'd10;
    b = 64'd20;
    ALUControl = 4'b0111;
    #10;
    $display("a = %0d, b = %0d", a, b);
    $display("SLT result = %0d (expected: 1, because 10 < 20)", result);
    
    a = 64'd30;
    b = 64'd20;
    ALUControl = 4'b0111;
    #10;
    $display("a = %0d, b = %0d", a, b);
    $display("SLT result = %0d (expected: 0, because 30 >= 20)", result);
    
    //-----------------------------------
    // Test 10: Real-world instruction examples
    //-----------------------------------
    $display("\n--- Test 10: Real Instruction Examples ---");
    
    // addi x1, x0, 5  -> x1 = 0 + 5
    a = 64'd0;
    b = 64'd5;
    ALUControl = 4'b0010;  // ADD
    #10;
    $display("ADDI: x1 = x0 + 5 = %0d (expected: 5)", result);
    
    // add x3, x1, x2  -> x3 = x1 + x2
    a = 64'd5;
    b = 64'd10;
    ALUControl = 4'b0010;  // ADD
    #10;
    $display("ADD: x3 = x1 + x2 = %0d (expected: 15)", result);
    
    // sub x4, x3, x1  -> x4 = x3 - x1
    a = 64'd15;
    b = 64'd5;
    ALUControl = 4'b0110;  // SUB
    #10;
    $display("SUB: x4 = x3 - x1 = %0d (expected: 10)", result);
    
    // slli x5, x1, 3  -> x5 = x1 << 3
    a = 64'd5;
    b = 64'd3;
    ALUControl = 4'b0100;  // SLL
    #10;
    $display("SLLI: x5 = x1 << 3 = %0d (expected: 40)", result);
    
    $display("\n========================================");
    $display("All ALU Tests Completed Successfully!");
    $display("========================================");
    
    $finish;
  end

endmodule
