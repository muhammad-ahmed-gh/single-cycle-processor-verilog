// Control Unit (Main Control + ALU Control Merged)
// You will design and implement the Control Unit, responsible for generating all
// internal control signals, including:
// • RegWrite
// • MemWrite
// • MemRead
// • ALUSrc
// • MemToReg
// • Branch
// • ALUControl (merged inside)

// Your responsibilities:
// • Build the control table for all required instructions
// • Implement instruction decoding logic
// • Generate ALUControl directly from opcode + funct3/funct7
// • Provide a testbench that applies opcodes and checks correct control signals

// Control Unit (Main Control + ALU Control Merged)
// Task 2 - Yassin Elish - 231000604

//=============================================================================
// Control Unit Module
//=============================================================================
module control_unit (
  input [31:0] instruction,     // 32-bit instruction
  output reg regWrite,          // Register write enable
  output reg memWrite,          // Memory write enable
  output reg memRead,           // Memory read enable
  output reg aluSrc,            // ALU source select (0=register, 1=immediate)
  output reg memToReg,          // Write back source (0=ALU result, 1=memory)
  output reg branch,            // Branch instruction flag
  output reg [3:0] aluControl   // ALU operation control (merged ALU control)
);

  // Extract fields from instruction
  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;
  
  assign opcode = instruction[6:0];
  assign funct3 = instruction[14:12];
  assign funct7 = instruction[31:25];
  
  // Control signal generation
  always @(*) begin
    // Default values (all signals off)
    regWrite = 0;
    memWrite = 0;
    memRead = 0;
    aluSrc = 0;
    memToReg = 0;
    branch = 0;
    aluControl = 4'b0000;
    
    case (opcode)
      
      //=================================================================
      // R-Type Instructions (add, sub, and, or, xor, sll, srl)
      // opcode = 0110011
      //=================================================================
      7'b0110011: begin
        regWrite = 1;           // Write result to register
        aluSrc = 0;             // Use register for ALU input
        memToReg = 0;           // Write ALU result to register
        memRead = 0;
        memWrite = 0;
        branch = 0;
        
        // Determine ALU operation based on funct3 and funct7
        case (funct3)
          3'b000: begin
            // ADD or SUB
            if (funct7 == 7'b0000000)
              aluControl = 4'b0010;  // ADD
            else if (funct7 == 7'b0100000)
              aluControl = 4'b0110;  // SUB
          end
          
          3'b111: aluControl = 4'b0000;  // AND
          3'b110: aluControl = 4'b0001;  // OR
          3'b100: aluControl = 4'b0011;  // XOR
          3'b001: aluControl = 4'b0100;  // SLL (shift left logical)
          3'b101: aluControl = 4'b0101;  // SRL (shift right logical)
          
          default: aluControl = 4'b0000;
        endcase
      end
      
      //=================================================================
      // I-Type Arithmetic (addi, andi, ori, xori, slli, srli)
      // opcode = 0010011
      //=================================================================
      7'b0010011: begin
        regWrite = 1;           // Write result to register
        aluSrc = 1;             // Use immediate for ALU input
        memToReg = 0;           // Write ALU result to register
        memRead = 0;
        memWrite = 0;
        branch = 0;
        
        // Determine ALU operation based on funct3
        case (funct3)
          3'b000: aluControl = 4'b0010;  // ADDI (add immediate)
          3'b111: aluControl = 4'b0000;  // ANDI (and immediate)
          3'b110: aluControl = 4'b0001;  // ORI (or immediate)
          3'b100: aluControl = 4'b0011;  // XORI (xor immediate)
          3'b001: aluControl = 4'b0100;  // SLLI (shift left logical immediate)
          3'b101: aluControl = 4'b0101;  // SRLI (shift right logical immediate)
          
          default: aluControl = 4'b0000;
        endcase
      end
      
      //=================================================================
      // Load Instructions (ld - load doubleword)
      // opcode = 0000011
      //=================================================================
      7'b0000011: begin
        regWrite = 1;           // Write loaded data to register
        aluSrc = 1;             // Use immediate (offset) for address calculation
        memToReg = 1;           // Write memory data to register
        memRead = 1;            // Read from memory
        memWrite = 0;
        branch = 0;
        aluControl = 4'b0010;   // ADD (base + offset)
      end
      
      //=================================================================
      // Store Instructions (sd - store doubleword)
      // opcode = 0100011
      //=================================================================
      7'b0100011: begin
        regWrite = 0;           // Don't write to register file
        aluSrc = 1;             // Use immediate (offset) for address calculation
        memToReg = 0;           // Don't care (not writing to register)
        memRead = 0;
        memWrite = 1;           // Write to memory
        branch = 0;
        aluControl = 4'b0010;   // ADD (base + offset)
      end
      
      //=================================================================
      // Branch Instructions (beq - branch if equal)
      // opcode = 1100011
      //=================================================================
      7'b1100011: begin
        regWrite = 0;           // Don't write to register file
        aluSrc = 0;             // Compare two registers
        memToReg = 0;           // Don't care
        memRead = 0;
        memWrite = 0;
        branch = 1;             // This is a branch instruction
        aluControl = 4'b0110;   // SUB (for comparison: a - b)
      end
      
      //=================================================================
      // Default case - NOP (no operation)
      //=================================================================
      default: begin
        regWrite = 0;
        memWrite = 0;
        memRead = 0;
        aluSrc = 0;
        memToReg = 0;
        branch = 0;
        aluControl = 4'b0000;
      end
      
    endcase
  end

endmodule


//=============================================================================
// Testbench for Control Unit
//=============================================================================
module testbench_control_unit;

  reg [31:0] instruction;
  wire regWrite, memWrite, memRead, aluSrc, memToReg, branch;
  wire [3:0] aluControl;
  
  // Instantiate control unit
  control_unit cu (
    .instruction(instruction),
    .regWrite(regWrite),
    .memWrite(memWrite),
    .memRead(memRead),
    .aluSrc(aluSrc),
    .memToReg(memToReg),
    .branch(branch),
    .aluControl(aluControl)
  );
  
  // Test sequence
  initial begin
    $display("========================================");
    $display("Testing Control Unit");
    $display("========================================");
    
    //-----------------------------------
    // Test 1: R-Type ADD (add x3, x1, x2)
    //-----------------------------------
    $display("\n--- Test 1: R-Type ADD ---");
    instruction = 32'b0000000_00010_00001_000_00011_0110011;
    #10;
    $display("Instruction: add x3, x1, x2");
    $display("RegWrite=%b MemWrite=%b MemRead=%b ALUSrc=%b MemToReg=%b Branch=%b ALUControl=%b",
             regWrite, memWrite, memRead, aluSrc, memToReg, branch, aluControl);
    $display("Expected: RegWrite=1 MemWrite=0 MemRead=0 ALUSrc=0 MemToReg=0 Branch=0 ALUControl=0010");
    
    //-----------------------------------
    // Test 2: R-Type SUB (sub x4, x5, x6)
    //-----------------------------------
    $display("\n--- Test 2: R-Type SUB ---");
    instruction = 32'b0100000_00110_00101_000_00100_0110011;
    #10;
    $display("Instruction: sub x4, x5, x6");
    $display("RegWrite=%b MemWrite=%b MemRead=%b ALUSrc=%b MemToReg=%b Branch=%b ALUControl=%b",
             regWrite, memWrite, memRead, aluSrc, memToReg, branch, aluControl);
    $display("Expected: RegWrite=1 MemWrite=0 MemRead=0 ALUSrc=0 MemToReg=0 Branch=0 ALUControl=0110");
    
    //-----------------------------------
    // Test 3: I-Type ADDI (addi x1, x0, 5)
    //-----------------------------------
    $display("\n--- Test 3: I-Type ADDI ---");
    instruction = 32'b000000000101_00000_000_00001_0010011;
    #10;
    $display("Instruction: addi x1, x0, 5");
    $display("RegWrite=%b MemWrite=%b MemRead=%b ALUSrc=%b MemToReg=%b Branch=%b ALUControl=%b",
             regWrite, memWrite, memRead, aluSrc, memToReg, branch, aluControl);
    $display("Expected: RegWrite=1 MemWrite=0 MemRead=0 ALUSrc=1 MemToReg=0 Branch=0 ALUControl=0010");
    
    //-----------------------------------
    // Test 4: Load (ld x4, 0(x0))
    //-----------------------------------
    $display("\n--- Test 4: Load Doubleword ---");
    instruction = 32'b000000000000_00000_011_00100_0000011;
    #10;
    $display("Instruction: ld x4, 0(x0)");
    $display("RegWrite=%b MemWrite=%b MemRead=%b ALUSrc=%b MemToReg=%b Branch=%b ALUControl=%b",
             regWrite, memWrite, memRead, aluSrc, memToReg, branch, aluControl);
    $display("Expected: RegWrite=1 MemWrite=0 MemRead=1 ALUSrc=1 MemToReg=1 Branch=0 ALUControl=0010");
    
    //-----------------------------------
    // Test 5: Store (sd x3, 0(x0))
    //-----------------------------------
    $display("\n--- Test 5: Store Doubleword ---");
    instruction = 32'b0000000_00011_00000_011_00000_0100011;
    #10;
    $display("Instruction: sd x3, 0(x0)");
    $display("RegWrite=%b MemWrite=%b MemRead=%b ALUSrc=%b MemToReg=%b Branch=%b ALUControl=%b",
             regWrite, memWrite, memRead, aluSrc, memToReg, branch, aluControl);
    $display("Expected: RegWrite=0 MemWrite=1 MemRead=0 ALUSrc=1 MemToReg=0 Branch=0 ALUControl=0010");
    
    //-----------------------------------
    // Test 6: Branch (beq x1, x2, offset)
    //-----------------------------------
    $display("\n--- Test 6: Branch Equal ---");
    instruction = 32'b0000000_00010_00001_000_01000_1100011;
    #10;
    $display("Instruction: beq x1, x2, 16");
    $display("RegWrite=%b MemWrite=%b MemRead=%b ALUSrc=%b MemToReg=%b Branch=%b ALUControl=%b",
             regWrite, memWrite, memRead, aluSrc, memToReg, branch, aluControl);
    $display("Expected: RegWrite=0 MemWrite=0 MemRead=0 ALUSrc=0 MemToReg=0 Branch=1 ALUControl=0110");
    
    $display("\n========================================");
    $display("Control Unit Tests Completed!");
    $display("========================================");
    
    $finish;
  end

endmodule
