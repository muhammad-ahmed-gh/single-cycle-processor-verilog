`timescale 1ns / 1ps
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

module InstructionMemory (
  input [63:0] addr,    // same as pc
  output [31:0] instr
);

  reg [31:0] intrs[255:0];

  assign instr = instrs[addr[9:2]];

endmodule



module DataMemory (
  input clk,
  input [63:0] addr,
  input [63:0] writeData,
  input memRead,
  input memWrite,
  output reg [63:0] readData
);

  reg [63:0] data[255:0];

  always @(posedge clk) begin
    if(memWrite)
      data[addr[9:3]] <= writeData;
  end

  always @(*) begin
    if(memRead)
      readData = data[addr[9:3]];
    else
      readData = 64'b0;
  end

endmodule



module Top (
  input clk,
  input rst // reset
);

  InstructionMemory instr_mem_unit (
    
  );

  ALU alu_unit(
    .a()
    .b()
    .ALUControl()
    .result()
    .carryOut()
    .zero()
  );

endmodule