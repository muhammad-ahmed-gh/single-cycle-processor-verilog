`timescale 1ns / 1ps
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

module ControlUnit(
  input [6:0] opcode,
  input [2:0] funct3,
  input [6:0] funct7,
  output reg RegWrite,          // 1 -> write to register file
  output reg MemWrite,          // 1 -> write to memory
  output reg MemRead,           // 1 -> read from memory
  output reg ALUSrc,            // 0=register, 1=immediate
  output reg MemToReg,          // 0=ALU result, 1=memory data
  output reg Branch,
  // output reg [1:0] ALUOp,    // already integrated
  output reg [3:0] ALUControl
);

  reg [1:0] ALUOp;

  always @(*) begin 
    RegWrite = 0;
    ALUSrc = 0;
    MemToReg = 0;
    MemRead = 0;
    MemWrite = 0;
    Branch = 0;
    ALUOp = 2'b00;
    ALUControl = 4'b0000;

    case(opcode)
      // R-type instructions (add, sub, and, or, xor, sll, srl)
      7'b0110011: begin
        RegWrite = 1;
        ALUSrc = 0;
        MemToReg = 0;
        MemRead = 0;
        MemWrite = 0;
        Branch = 0;
        ALUOp = 2'b10;  // R/I-type
      end

      // I-type instructions (addi, andi, ori, xori, slli, srli)
      7'b0010011: begin
        RegWrite = 1;
        ALUSrc = 1;
        MemToReg = 0;
        MemRead = 0;
        MemWrite = 0;
        Branch = 0;
        ALUOp = 2'b10; // R/I-type
      end
      
      // ls
      7'b0000011: begin
        RegWrite = 1;
        ALUSrc = 1;
        MemToReg = 1;
        MemRead = 1;
        MemWrite = 0;
        Branch = 0;
        ALUOp = 2'b00;  // add for offsit calculation
      end
      
      // sd
      7'b0100011: begin
        RegWrite = 0;
        ALUSrc = 1;
        MemToReg = 0;
        MemRead = 0;
        MemWrite = 1;
        Branch = 0;
        ALUOp = 2'b00;  // add for offsit calculation
      end

      // beq
      7'b1100011: begin
        RegWrite = 0;
        ALUSrc = 0;
        MemToReg = 0;
        MemRead = 0;
        MemWrite = 0;
        Branch = 1;
        ALUOp = 2'b01; // subtract to compare
      end

      default: begin
        RegWrite = 0;
        MemWrite = 0;
        MemRead = 0;
        ALUSrc = 0;
        MemToReg = 0;
        Branch = 0;
        ALUOp = 2'b00;
        ALUControl = 4'b0000;
      end
    endcase

    // ALU Control Unit
    case (ALUOp)
      2'b00: // ld/sd
        ALUControl = 4'b0010; // add

      2'b01: // beq
        ALUControl = 4'b0110; // sub

      2'b10: // R/I-type
        case(funct3)

          3'b000: begin // add or sub

            if(opcode == 7'b0110011) begin // R-type
              ALUControl = (funct7 == 7'b0100000) ? 4'b0110 : 4'b0010; // sub/add
            end

            else begin
              ALUControl = 4'b0010;
            end

          end

          3'b111: ALUControl = 4'b0000;   // and
          3'b110: ALUControl = 4'b0001;   // or
          3'b100: ALUControl = 4'b0011;   // xor
          3'b001: ALUControl = 4'b0100;   // sll
          3'b101: ALUControl = 4'b0101;   // srl
          default: ALUControl = 4'b0000;
        endcase
    endcase
  end

endmodule