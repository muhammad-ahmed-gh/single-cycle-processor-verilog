// Register File & Immediate Generator
// You will implement:
// A. Register File
// • 32 registers
// • x0 always 0
// • two read ports, one write port
// • synchronous write, asynchronous read
// B. Immediate Generator
// • Correct extraction and sign-extension of immediates for
// addi, andi, xori, ori, ld, sd, beq, shift-immediates

// Your responsibilities:
// • Implement both modules in Verilog
// • Create a testbench to verify register reads/writes and immediate formats

// Register File & Immediate Generator
// Task 3 - Mohamed Wael - 221000499

//=============================================================================
// 1. Register File Module
//=============================================================================
module register_file (
  input clk,                    // System clock
  input reset,                  // Reset signal
  input regWrite,               // Write enable (1 = write, 0 = no write)
  input [4:0] readReg1,         // Address of first register to read (0-31)
  input [4:0] readReg2,         // Address of second register to read (0-31)
  input [4:0] writeReg,         // Address of register to write (0-31)
  input [63:0] writeData,       // Data to write
  output [63:0] readData1,      // Data read from first register
  output [63:0] readData2       // Data read from second register
);

  // Array of 32 registers, each 64 bits wide
  reg [63:0] registers [31:0];
  
  integer i;
  
  // Reset and write operations (synchronous)
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Initialize all registers to 0 on reset
      for (i = 0; i < 32; i = i + 1) begin
        registers[i] <= 64'd0;
      end
    end
    else if (regWrite && writeReg != 5'd0) begin
      // Write to register (except x0 which is always 0)
      registers[writeReg] <= writeData;
    end
  end
  
  // Read operations (asynchronous - combinational)
  // x0 is always 0
  assign readData1 = (readReg1 == 5'd0) ? 64'd0 : registers[readReg1];
  assign readData2 = (readReg2 == 5'd0) ? 64'd0 : registers[readReg2];

endmodule


//=============================================================================
// 2. Immediate Generator Module
//=============================================================================
module immediate_generator (
  input [31:0] instruction,     // 32-bit instruction
  output reg [63:0] immediate   // Sign-extended immediate (64 bits)
);

  wire [6:0] opcode;
  
  assign opcode = instruction[6:0];
  
  always @(*) begin
    case (opcode)
      
      // I-Type: addi, andi, ori, xori, ld, slli, srli
      7'b0010011, // Arithmetic immediate operations (addi, andi, ori, xori, slli, srli)
      7'b0000011: begin // Load operations (ld - load doubleword)
        // Immediate is in bits [31:20]
        // Sign-extend from 12 bits to 64 bits
        immediate = {{52{instruction[31]}}, instruction[31:20]};
      end
      
      // S-Type: sd (store doubleword)
      7'b0100011: begin
        // Immediate is split: [31:25] and [11:7]
        // Concatenate and sign-extend
        immediate = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};
      end
      
      // B-Type: beq (branch if equal)
      7'b1100011: begin
        // Immediate is split in a special pattern for branching
        // Bits: [31] [7] [30:25] [11:8] with implicit 0 at end
        // This gives us a 13-bit signed immediate (always even)
        immediate = {{51{instruction[31]}}, instruction[31], instruction[7], 
                     instruction[30:25], instruction[11:8], 1'b0};
      end
      
      // R-Type: add, sub, and, or, xor, sll, srl
      7'b0110011: begin
        // R-Type instructions don't have immediates
        immediate = 64'd0;
      end
      
      // Default case
      default: begin
        immediate = 64'd0;
      end
      
    endcase
  end

endmodule


//=============================================================================
// 3. Testbench for Task 3 - Register File & Immediate Generator
//=============================================================================
module testbench_task3;

  // Signals for Register File
  reg clk, reset, regWrite;
  reg [4:0] readReg1, readReg2, writeReg;
  reg [63:0] writeData;
  wire [63:0] readData1, readData2;
  
  // Signals for Immediate Generator
  reg [31:0] instruction;
  wire [63:0] immediate;
  
  // Instantiate modules
  register_file rf (
    .clk(clk),
    .reset(reset),
    .regWrite(regWrite),
    .readReg1(readReg1),
    .readReg2(readReg2),
    .writeReg(writeReg),
    .writeData(writeData),
    .readData1(readData1),
    .readData2(readData2)
  );
  
  immediate_generator imm_gen (
    .instruction(instruction),
    .immediate(immediate)
  );
  
  // Generate clock signal
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Toggle every 5ns
  end
  
  // Test sequence
  initial begin
    $display("========================================");
    $display("Testing Task 3: Register File & Immediate Generator");
    $display("========================================");
    
    // Reset the system
    reset = 1;
    regWrite = 0;
    #10;
    reset = 0;
    #10;
    
    //-----------------------------------
    // Test 1: Writing to Registers
    //-----------------------------------
    $display("\n--- Test 1: Writing to Registers ---");
    regWrite = 1;
    
    // Write 100 to x5
    writeReg = 5'd5;
    writeData = 64'd100;
    #10;
    $display("Written: x5 = 100");
    
    // Write 200 to x10
    writeReg = 5'd10;
    writeData = 64'd200;
    #10;
    $display("Written: x10 = 200");
    
    // Try to write 999 to x0 (should remain 0)
    writeReg = 5'd0;
    writeData = 64'd999;
    #10;
    $display("Attempted to write 999 to x0 (should remain 0)");
    
    //-----------------------------------
    // Test 2: Reading from Registers
    //-----------------------------------
    $display("\n--- Test 2: Reading from Registers ---");
    regWrite = 0;
    readReg1 = 5'd5;
    readReg2 = 5'd10;
    #10;
    $display("x5 = %0d (expected: 100)", readData1);
    $display("x10 = %0d (expected: 200)", readData2);
    
    if (readData1 == 64'd100 && readData2 == 64'd200) begin
      $display("✓ Register reads PASSED");
    end else begin
      $display("✗ Register reads FAILED");
    end
    
    // Read from x0
    readReg1 = 5'd0;
    #10;
    $display("x0 = %0d (expected: 0)", readData1);
    
    if (readData1 == 64'd0) begin
      $display("✓ x0 always zero PASSED");
    end else begin
      $display("✗ x0 always zero FAILED");
    end
    
    //-----------------------------------
    // Test 3: Immediate Generator
    //-----------------------------------
    $display("\n--- Test 3: Immediate Generator ---");
    
    // I-Type: addi x1, x0, 5
    // Format: imm[11:0] | rs1[5] | funct3[3] | rd[5] | opcode[7]
    // imm=5, rs1=0, funct3=000, rd=1, opcode=0010011
    instruction = 32'b00000000010100000000000010010011;
    #10;
    $display("I-Type (addi x1, x0, 5): immediate = %0d (expected: 5)", $signed(immediate));
    
    if (immediate == 64'd5) begin
      $display("✓ I-Type immediate PASSED");
    end else begin
      $display("✗ I-Type immediate FAILED");
    end
    
    // S-Type: sd x3, 8(x0)
    // Format: imm[11:5] | rs2[5] | rs1[5] | funct3[3] | imm[4:0] | opcode[7]
    // imm=8, rs2=3, rs1=0, funct3=011, opcode=0100011
    instruction = 32'b00000000001100000011010000100011;
    #10;
    $display("S-Type (sd x3, 8(x0)): immediate = %0d (expected: 8)", $signed(immediate));
    
    if (immediate == 64'd8) begin
      $display("✓ S-Type immediate PASSED");
    end else begin
      $display("✗ S-Type immediate FAILED");
    end
    
    // B-Type: beq x1, x2, 16
    // Format: imm[12|10:5] | rs2[5] | rs1[5] | funct3[3] | imm[4:1|11] | opcode[7]
    // offset=16 (binary: 10000), rs2=2, rs1=1, funct3=000, opcode=1100011
    instruction = 32'b00000000001000001000010001100011;
    #10;
    $display("B-Type (beq x1, x2, 16): immediate = %0d (expected: 16)", $signed(immediate));
    
    if (immediate == 64'd16) begin
      $display("✓ B-Type immediate PASSED");
    end else begin
      $display("✗ B-Type immediate FAILED");
    end
    
    // Test negative immediate
    // addi x2, x0, -10
    // imm=-10 in 12-bit two's complement = 111111110110
    instruction = 32'b11111111011000000000000100010011;
    #10;
    $display("I-Type (addi x2, x0, -10): immediate = %0d (expected: -10)", $signed(immediate));
    
    if ($signed(immediate) == -10) begin
      $display("✓ Negative immediate PASSED");
    end else begin
      $display("✗ Negative immediate FAILED");
    end
    
    $display("\n========================================");
    $display("All Task 3 Tests Completed!");
    $display("========================================");
    
    $finish;
  end

endmodule
