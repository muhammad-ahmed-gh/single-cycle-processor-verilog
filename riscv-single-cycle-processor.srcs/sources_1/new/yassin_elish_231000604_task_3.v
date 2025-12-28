`timescale 1ns / 1ps
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

module ImmGen(
  input [31:0] instruction,       // 32-bit instruction
  output reg [63:0] imm           // sign-extended 64-bit immediate
);

  // extract opcode to determine instruction type
  wire [6:0] opcode = instruction[6:0];
  
  always @(*) begin
    case (opcode)
      // I-type: addi, andi, ori, xori, ld, slli, srli
      7'b0010011, 7'b0000011: begin
        imm = {{52{instruction[31]}}, instruction[31:20]};
      end
      
      // sd
      7'b0100011: begin
        imm = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};
      end
      
      // beq
      7'b1100011: begin
        imm = {{51{instruction[31]}}, instruction[31], instruction[7], 
          instruction[30:25], instruction[11:8], 1'b0};
        // sign extension and shift left by 1
      end

      default: begin
        imm = 64'd0;
      end
    endcase
  end

endmodule

module RegisterFile(
  input clk,                      // clock signal
  input RegWrite,                 // 1 to write to register
  input [4:0] readReg1,          // address of first register to read
  input [4:0] readReg2,          // address of second register to read
  input [4:0] writeReg,          // address of register to write
  input [63:0] writeData,        // data to write
  output [63:0] readData1,       // data from first register
  output [63:0] readData2        // data from second register
);

  // 32 registers, each 64 bits wide
  reg [63:0] registers [31:0];
  
  assign readData1 = (readReg1 == 5'd0) ? 64'd0 : registers[readReg1];
  assign readData2 = (readReg2 == 5'd0) ? 64'd0 : registers[readReg2];

  integer i;
  initial begin
    for (i = 0; i < 32; i = i + 1)
      registers[i] = 64'd0;
  end

  always @(posedge clk) begin
    if (RegWrite && writeReg != 5'd0)  // write only if RegWrite=1 and not x0
      registers[writeReg] <= writeData;
  end

endmodule