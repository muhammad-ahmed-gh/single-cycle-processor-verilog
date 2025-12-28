`timescale 1ns / 1ps

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

module ALU(
  input [63: 0] a, b,
  input [3: 0] ALUControl,
  output reg [63: 0] result,
  output reg carryOut, zero
);

  always @(*) begin
    carryOut = 0;

    case (ALUControl)
      4'b0000: result = a & b;
      4'b0001: result = a | b;
      4'b0010: {carryOut, result} = a + b;
      4'b0110: {carryOut, result} = a - b;
      4'b0111: result = (a < b);
      default: result = 0;
    endcase

    zero = (result == 0);
  end
endmodule