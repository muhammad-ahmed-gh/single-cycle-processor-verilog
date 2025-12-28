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
  output [31:0] instruction
);

  reg [31:0] instructions[255:0];

  assign instruction = instructions[addr[9:2]];

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
  input rst,
);

  // wires
  wire [63:0] currentPC, nextPC;
  wire [31:0] instruction;
  wire [63:0] readData1, readData2, writeData;
  wire [63:0] ALUInput2, immed, ALUResult;
  wire [63:0] memReadData;
  wire zero, carryOut;

  // control flags
  wire  regWrite, memWrite, memRead, ALUSrc, memToReg, branch;
  wire [3:0] ALUControl;

  // loading instruction
  InstructionMemory imem (
    .addr(currentPC),
    .instruction(instruction)
  );

  // decode
  ControlUnit cu (
    .opcode(instruction[6:0]),
    .funct3(instruction[14:12]),
    .funct7(instruction[31:25]),
    .RegWrite(regWrite),
    .MemWrite(memWrite),
    .MemRead(memRead),
    .ALUSrc(ALUSrc),
    .MemToReg(memToReg),
    .Branch(branch),
    .ALUControl(ALUControl)
  );

  assign nextPC = (branch && zero)? currentPC + immed : currentPC + 4;
  PC pc (
    .clk(clk),
    .reset(rst),
    .PCIn(nextPC),
    .PCOut(currentPC)
  );

  RegisterFile rf (
    .clk(clk),
    .RegWrite(regWrite),
    .readReg1(instruction[19:15]),
    .readReg2(instruction[24:20]),
    .writeReg(instruction[11:7]),
    .writeData(writeData),
    .readData1(readData1),
    .readData2(readData2)
  );

  ImmGen imm_gen (
    .instruction(instruction),
    .imm(immed)
  );

  // execute
  assign ALUInput2 = ALUSrc ? imm : readData2;

  ALU alu_unit(
    .a(readData1),
    .b(ALUInput2),
    .ALUControl(ALUControl),
    .result(ALUResult),
    .carryOut(carryOut),
    .zero(zero)
  );

  // memory
  DataMemory dm (
    .clk(clk),
    .addr(ALUResult),
    .writeData(readData2),
    .memRead(memRead),
    .memWrite(memWrite),
    .readData(memReadData)
  );


  // write back
  assign writeData = (memToReg)? memReadData : ALUResult;
endmodule