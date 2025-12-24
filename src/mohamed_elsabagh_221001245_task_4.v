// Program Counter, Branch Logic & PC Update
// You will design all components related to instruction sequencing:
// • PC register (updates every cycle)
// • PC + 4 adder
// • Branch target calculation
// • Branch decision logic
// • MUX for selecting the next PC
// • Handling branching correctly

// Your responsibilities:
// • Implement PC logic in Verilog
// • Verify correct branching behavior in a testbench

// Program Counter, Branch Logic & PC Update
// Task 4 - Mohamed Elsabagh - 221001245

//=============================================================================
// Program Counter Module
//=============================================================================
module pc (
  input clk,                    // System clock
  input reset,                  // Reset signal
  input [63:0] pc_next,         // Next PC value
  output reg [63:0] pc_current  // Current PC value
);

  always @(posedge clk or posedge reset) begin
    if (reset)
      pc_current <= 64'd0;      // Reset PC to 0
    else
      pc_current <= pc_next;    // Update PC to next value
  end

endmodule


//=============================================================================
// PC Adder Module (calculates PC + 4)
//=============================================================================
module pc_adder (
  input [63:0] pc_current,      // Current PC
  output [63:0] pc_plus4        // PC + 4 (next sequential instruction)
);

  assign pc_plus4 = pc_current + 64'd4;

endmodule


//=============================================================================
// Branch Target Calculator (calculates PC + immediate)
//=============================================================================
module branch_target_calc (
  input [63:0] pc_current,      // Current PC
  input [63:0] immediate,       // Branch offset (sign-extended)
  output [63:0] branch_target   // Target address for branch
);

  assign branch_target = pc_current + immediate;

endmodule


//=============================================================================
// Branch Decision Logic
//=============================================================================
module branch_decision (
  input branch,                 // Branch instruction flag from control unit
  input zero,                   // Zero flag from ALU
  output branch_taken           // Final branch decision
);

  // Branch is taken if:
  // 1. Instruction is a branch (branch = 1)
  // 2. AND condition is met (zero = 1 for beq)
  assign branch_taken = branch && zero;

endmodule


//=============================================================================
// PC MUX - Selects next PC value
//=============================================================================
module pc_mux (
  input branch_taken,           // Branch decision
  input [63:0] pc_plus4,        // Sequential next address (PC + 4)
  input [63:0] branch_target,   // Branch target address
  output [63:0] pc_next         // Selected next PC
);

  // If branch taken: use branch target
  // Otherwise: use PC + 4
  assign pc_next = branch_taken ? branch_target : pc_plus4;

endmodule


//=============================================================================
// Complete PC and Branch Logic Integration Module
//=============================================================================
module pc_and_branch_logic (
  input clk,                    // System clock
  input reset,                  // Reset signal
  input branch,                 // Branch flag from control unit
  input zero,                   // Zero flag from ALU
  input [63:0] immediate,       // Immediate value (branch offset)
  output [63:0] pc_current      // Current PC output
);

  // Internal wires
  wire [63:0] pc_plus4;
  wire [63:0] branch_target;
  wire branch_taken;
  wire [63:0] pc_next;
  
  // Instantiate PC register
  pc program_counter (
    .clk(clk),
    .reset(reset),
    .pc_next(pc_next),
    .pc_current(pc_current)
  );
  
  // Instantiate PC + 4 adder
  pc_adder adder (
    .pc_current(pc_current),
    .pc_plus4(pc_plus4)
  );
  
  // Instantiate branch target calculator
  branch_target_calc branch_calc (
    .pc_current(pc_current),
    .immediate(immediate),
    .branch_target(branch_target)
  );
  
  // Instantiate branch decision logic
  branch_decision branch_dec (
    .branch(branch),
    .zero(zero),
    .branch_taken(branch_taken)
  );
  
  // Instantiate PC MUX
  pc_mux mux (
    .branch_taken(branch_taken),
    .pc_plus4(pc_plus4),
    .branch_target(branch_target),
    .pc_next(pc_next)
  );

endmodule


//=============================================================================
// Testbench for PC and Branch Logic
//=============================================================================
module testbench_pc_branch;

  reg clk, reset, branch, zero;
  reg [63:0] immediate;
  wire [63:0] pc_current;
  
  // Instantiate the integrated module
  pc_and_branch_logic pc_branch (
    .clk(clk),
    .reset(reset),
    .branch(branch),
    .zero(zero),
    .immediate(immediate),
    .pc_current(pc_current)
  );
  
  // Generate clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Test sequence
  initial begin
    $display("========================================");
    $display("Testing PC and Branch Logic");
    $display("========================================");
    
    // Reset
    reset = 1;
    branch = 0;
    zero = 0;
    immediate = 64'd0;
    #10;
    reset = 0;
    
    //-----------------------------------
    // Test 1: Sequential execution (PC + 4)
    //-----------------------------------
    $display("\n--- Test 1: Sequential Execution ---");
    branch = 0;
    zero = 0;
    #10;
    $display("Cycle 1: PC = %0d (expected: 0)", pc_current);
    #10;
    $display("Cycle 2: PC = %0d (expected: 4)", pc_current);
    #10;
    $display("Cycle 3: PC = %0d (expected: 8)", pc_current);
    #10;
    $display("Cycle 4: PC = %0d (expected: 12)", pc_current);
    
    //-----------------------------------
    // Test 2: Branch taken (forward)
    //-----------------------------------
    $display("\n--- Test 2: Branch Taken (Forward) ---");
    branch = 1;       // Branch instruction
    zero = 1;         // Condition is true (beq)
    immediate = 64'd16; // Jump forward by 16 bytes
    #10;
    $display("After branch: PC = %0d (expected: 32)", pc_current);
    
    //-----------------------------------
    // Test 3: Branch not taken
    //-----------------------------------
    $display("\n--- Test 3: Branch Not Taken ---");
    branch = 1;       // Branch instruction
    zero = 0;         // Condition is false
    immediate = 64'd100;
    #10;
    $display("After failed branch: PC = %0d (expected: 36)", pc_current);
    
    //-----------------------------------
    // Test 4: Branch taken (backward)
    //-----------------------------------
    $display("\n--- Test 4: Branch Taken (Backward) ---");
    branch = 1;
    zero = 1;
    immediate = -64'd20; // Jump backward
    #10;
    $display("After backward branch: PC = %0d (expected: 20)", pc_current);
    
    //-----------------------------------
    // Test 5: Continue sequential
    //-----------------------------------
    $display("\n--- Test 5: Back to Sequential ---");
    branch = 0;
    zero = 0;
    #10;
    $display("PC = %0d (expected: 24)", pc_current);
    #10;
    $display("PC = %0d (expected: 28)", pc_current);
    
    $display("\n========================================");
    $display("PC and Branch Logic Tests Completed!");
    $display("========================================");
    
    $finish;
  end
  
  // Monitor PC changes
  initial begin
    $monitor("Time=%0t | PC=%0d | Branch=%b | Zero=%b | BranchTaken=%b", 
             $time, pc_current, branch, zero, pc_branch.branch_taken);
  end

endmodule
