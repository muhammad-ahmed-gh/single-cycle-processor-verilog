// Instruction Memory, Data Memory & Top-Level Integration
// You will implement:
// A. Instruction Memory
// • Preloaded 
// • Word-aligned addressing
// B. Data Memory
// • Support for ld and sd
// • Word-addressed RAM
// C. CPU Top-Level Module

// You will integrate:
// • PC
// • Instruction memory
// • Control unit
// • Register file
// • ALU
// • Immediate generator
// • Data memory
// • Branch logic
// • All multiplexers and internal wires

// Your responsibilities:
// • Make sure all modules connect correctly
// • Run the full-core simulation
// • Run RISC-V program to test the processor

// Instruction Memory, Data Memory & Top-Level Integration
// Task 5 - Mohamed Sallam (Mohamed Magdy) - 221002127

//=============================================================================
// 1. Instruction Memory Module
//=============================================================================
module instruction_memory (
  input [63:0] pc,              // Program Counter (instruction address)
  output [31:0] instruction     // 32-bit instruction read from memory
);

  // Instruction memory - 256 instructions, each 32 bits
  reg [31:0] memory [0:255];
  
  // Load instructions at initialization
  initial begin
    // Example test program
    // addi x1, x0, 5        -> x1 = 0 + 5 = 5
    memory[0] = 32'b00000000010100000000000010010011;
    
    // addi x2, x0, 10       -> x2 = 0 + 10 = 10
    memory[1] = 32'b00000000101000000000000100010011;
    
    // add x3, x1, x2        -> x3 = x1 + x2 = 15
    memory[2] = 32'b00000000001000001000000110110011;
    
    // sd x3, 0(x0)          -> Memory[0] = x3 = 15
    memory[3] = 32'b00000000001100000011000000100011;
    
    // ld x4, 0(x0)          -> x4 = Memory[0] = 15
    memory[4] = 32'b00000000000000000011001000000011;
    
    // beq x3, x4, 8         -> if (x3 == x4) jump forward by 8 bytes
    memory[5] = 32'b00000000010000011000010001100011;
    
    // addi x5, x0, 99       -> x5 = 99 (if branch not taken)
    memory[6] = 32'b00000110001100000000001010010011;
    
    // addi x5, x0, 100      -> x5 = 100 (if branch taken)
    memory[7] = 32'b00000110010000000000001010010011;
    
    // Initialize rest of memory to 0
    integer i;
    for (i = 8; i < 256; i = i + 1) begin
      memory[i] = 32'b0;
    end
  end
  
  // Read instruction (PC / 4 because each instruction is 4 bytes)
  assign instruction = memory[pc[9:2]]; // Use pc[9:2] for word-aligned addressing

endmodule


//=============================================================================
// 2. Data Memory Module
//=============================================================================
module data_memory (
  input clk,                    // System clock
  input memWrite,               // Write enable signal (1 = write)
  input memRead,                // Read enable signal (1 = read)
  input [63:0] address,         // Memory address
  input [63:0] writeData,       // Data to write
  output [63:0] readData        // Data read from memory
);

  // Data memory - 256 locations, each 64 bits (doubleword)
  reg [63:0] memory [0:255];
  
  // Initialize memory
  integer i;
  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      memory[i] = 64'd0;
    end
  end
  
  // Write operation (synchronous with clock)
  always @(posedge clk) begin
    if (memWrite) begin
      memory[address[9:3]] <= writeData; // address/8 because each element is 8 bytes
    end
  end
  
  // Read operation (asynchronous)
  assign readData = (memRead) ? memory[address[9:3]] : 64'd0;

endmodule


//=============================================================================
// 3. CPU Top-Level Module (Complete Integration)
//=============================================================================
module cpu_top (
  input clk,                    // System clock
  input reset                   // Reset signal
);

  //===========================================================================
  // Internal Wires for connecting modules
  //===========================================================================
  
  // Program Counter signals
  wire [63:0] pc, pc_next, pc_plus4, pc_branch;
  wire branch_taken;
  
  // Instruction Memory
  wire [31:0] instruction;
  
  // Control Signals
  wire regWrite, memWrite, memRead, aluSrc, memToReg, branch;
  wire [3:0] aluControl;
  
  // Register File signals
  wire [63:0] readData1, readData2, writeData;
  wire [4:0] rs1, rs2, rd;
  
  // ALU signals
  wire [63:0] aluResult, aluInput2;
  wire zero, carryOut;
  
  // Immediate Generator
  wire [63:0] immediate;
  
  // Data Memory
  wire [63:0] memReadData;
  
  //===========================================================================
  // Extract instruction fields
  //===========================================================================
  assign rs1 = instruction[19:15];  // Source register 1
  assign rs2 = instruction[24:20];  // Source register 2
  assign rd  = instruction[11:7];   // Destination register
  
  //===========================================================================
  // Program Counter Register
  //===========================================================================
  reg [63:0] pc_reg;
  
  always @(posedge clk or posedge reset) begin
    if (reset)
      pc_reg <= 64'd0;
    else
      pc_reg <= pc_next;
  end
  
  assign pc = pc_reg;
  
  //===========================================================================
  // Instruction Memory Instance
  //===========================================================================
  instruction_memory imem (
    .pc(pc),
    .instruction(instruction)
  );
  
  //===========================================================================
  // Control Unit (from Task 2)
  //===========================================================================
  control_unit ctrl (
    .instruction(instruction),
    .regWrite(regWrite),
    .memWrite(memWrite),
    .memRead(memRead),
    .aluSrc(aluSrc),
    .memToReg(memToReg),
    .branch(branch),
    .aluControl(aluControl)
  );
  
  //===========================================================================
  // Register File (from Task 3)
  //===========================================================================
  register_file rf (
    .clk(clk),
    .reset(reset),
    .regWrite(regWrite),
    .readReg1(rs1),
    .readReg2(rs2),
    .writeReg(rd),
    .writeData(writeData),
    .readData1(readData1),
    .readData2(readData2)
  );
  
  //===========================================================================
  // Immediate Generator (from Task 3)
  //===========================================================================
  immediate_generator imm_gen (
    .instruction(instruction),
    .immediate(immediate)
  );
  
  //===========================================================================
  // MUX: Select second input for ALU
  //===========================================================================
  // If aluSrc = 1 -> use immediate
  // If aluSrc = 0 -> use readData2
  assign aluInput2 = aluSrc ? immediate : readData2;
  
  //===========================================================================
  // ALU (from Task 1)
  //===========================================================================
  ALU alu (
    .a(readData1),
    .b(aluInput2),
    .ALUControl(aluControl),
    .result(aluResult),
    .carryOut(carryOut),
    .zero(zero)
  );
  
  //===========================================================================
  // Data Memory Instance
  //===========================================================================
  data_memory dmem (
    .clk(clk),
    .memWrite(memWrite),
    .memRead(memRead),
    .address(aluResult),
    .writeData(readData2),
    .readData(memReadData)
  );
  
  //===========================================================================
  // MUX: Select data to write back to Register File
  //===========================================================================
  // If memToReg = 1 -> write from memory
  // If memToReg = 0 -> write from ALU
  assign writeData = memToReg ? memReadData : aluResult;
  
  //===========================================================================
  // Branch Logic (from Task 4 - partially implemented here)
  //===========================================================================
  // Calculate PC + 4 (next instruction)
  assign pc_plus4 = pc + 64'd4;
  
  // Calculate branch target address
  assign pc_branch = pc + immediate;
  
  // Branch decision
  assign branch_taken = branch && zero;
  
  // MUX: Select next PC
  assign pc_next = branch_taken ? pc_branch : pc_plus4;

endmodule


//=============================================================================
// 4. Complete Testbench for CPU Testing
//=============================================================================
module testbench_cpu;

  reg clk, reset;
  
  // Instantiate CPU
  cpu_top cpu (
    .clk(clk),
    .reset(reset)
  );
  
  // Generate clock signal
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Toggle every 5ns (10ns period = 100MHz)
  end
  
  // Test sequence
  initial begin
    $display("========================================");
    $display("CPU Simulation Started");
    $display("========================================");
    
    // Reset the CPU
    reset = 1;
    #10;
    reset = 0;
    
    // Run for 20 clock cycles
    #200;
    
    $display("\n========================================");
    $display("Simulation Results:");
    $display("========================================");
    $display("PC = %d", cpu.pc);
    $display("x1 = %d (expected: 5)", cpu.rf.registers[1]);
    $display("x2 = %d (expected: 10)", cpu.rf.registers[2]);
    $display("x3 = %d (expected: 15)", cpu.rf.registers[3]);
    $display("x4 = %d (expected: 15)", cpu.rf.registers[4]);
    $display("x5 = %d (expected: 100)", cpu.rf.registers[5]);
    $display("Memory[0] = %d (expected: 15)", cpu.dmem.memory[0]);
    
    $display("\n========================================");
    $display("CPU Simulation Completed!");
    $display("========================================");
    
    $finish;
  end
  
  // Monitor important signals
  initial begin
    $monitor("Time=%0t | PC=%0d | Instruction=%h | x1=%0d | x3=%0d", 
             $time, cpu.pc, cpu.instruction, 
             cpu.rf.registers[1], cpu.rf.registers[3]);
  end

endmodule
