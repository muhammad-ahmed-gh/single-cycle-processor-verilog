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
    input [6:0] opcode,             // instruction opcode
    input [2:0] funct3,             // function code 3
    input [6:0] funct7,             // function code 7
    output reg RegWrite,            // 1 to write to register file
    output reg MemWrite,            // 1 to write to memory
    output reg MemRead,             // 1 to read from memory
    output reg ALUSrc,              // 0=register, 1=immediate
    output reg MemToReg,            // 0=ALU result, 1=memory data
    output reg Branch,              // 1 for branch instructions
    output reg [1:0] ALUOp,         // ALU operation type
    output reg [3:0] ALUControl     // specific ALU operation
);
    
    always @(*) begin 
        // default values
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
                ALUOp = 2'b10;
                
                case(funct3)
                    3'b000: ALUControl = (funct7 == 7'b0100000) ? 4'b0110 : 4'b0010;  // sub or add
                    3'b111: ALUControl = 4'b0000;   // and
                    3'b110: ALUControl = 4'b0001;   // or
                    3'b100: ALUControl = 4'b0011;   // xor
                    3'b001: ALUControl = 4'b0100;   // sll
                    3'b101: ALUControl = 4'b0101;   // srl
                    default: ALUControl = 4'b0000;
                endcase
            end

            // I-type instructions (addi, andi, ori, xori, slli, srli)
            7'b0010011: begin
                RegWrite = 1;
                ALUSrc = 1;
                MemToReg = 0;
                MemRead = 0;
                MemWrite = 0;
                Branch = 0;
                ALUOp = 2'b00;
                
                case(funct3)
                    3'b000: ALUControl = 4'b0010;   // addi
                    3'b111: ALUControl = 4'b0000;   // andi
                    3'b110: ALUControl = 4'b0001;   // ori
                    3'b100: ALUControl = 4'b0011;   // xori
                    3'b001: ALUControl = 4'b0100;   // slli
                    3'b101: ALUControl = 4'b0101;   // srli
                    default: ALUControl = 4'b0000;
                endcase
            end
            
            // Load doubleword (ld)
            7'b0000011: begin
                RegWrite = 1;
                ALUSrc = 1;
                MemToReg = 1;
                MemRead = 1;
                MemWrite = 0;
                Branch = 0;
                ALUOp = 2'b00;
                ALUControl = 4'b0010;  // add for address calculation
            end
            
            // Store doubleword (sd)
            7'b0100011: begin
                RegWrite = 0;
                ALUSrc = 1;
                MemToReg = 0;x`
                MemRead = 0;
                MemWrite = 1;
                Branch = 0;
                ALUOp = 2'b00;
                ALUControl = 4'b0010;  // add for address calculation
            end

            // Branch equal (beq)
            7'b1100011: begin
                RegWrite = 0;
                ALUSrc = 0;
                MemToReg = 0;
                MemRead = 0;
                MemWrite = 0;
                Branch = 1;
                ALUOp = 2'b01;
                ALUControl = 4'b0110;  // subtract to compare
            end

            // default case
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
    end

endmodule

// -----------------------------------------------------

