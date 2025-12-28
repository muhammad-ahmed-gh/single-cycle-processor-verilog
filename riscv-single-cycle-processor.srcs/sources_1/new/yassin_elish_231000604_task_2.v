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

module Control_Unit(
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
                imm = {{52{instruction[31]}}, instruction[31:20]};  // sign-extend 12 bits
            end
            
            // S-type: sd
            7'b0100011: begin
                imm = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};  // sign-extend
            end
            
            // B-type: beq
            7'b1100011: begin
                imm = {{51{instruction[31]}}, instruction[31], instruction[7], 
                       instruction[30:25], instruction[11:8], 1'b0};  // sign-extend and shift left by 1
            end
            
            default: begin
                imm = 64'd0;
            end
        endcase
    end

endmodule


// -----------------------------------------------------

module RegisterFile(
    input clk,                      // clock signal
    input RegWrite,                 // 1 to write to register
    input [4:0] read_reg1,          // address of first register to read
    input [4:0] read_reg2,          // address of second register to read
    input [4:0] write_reg,          // address of register to write
    input [63:0] write_data,        // data to write
    output [63:0] read_data1,       // data from first register
    output [63:0] read_data2        // data from second register
);

    // 32 registers, each 64 bits wide
    reg [63:0] registers [31:0];
    
    assign read_data1 = (read_reg1 == 5'd0) ? 64'd0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'd0) ? 64'd0 : registers[read_reg2];
    
    always @(posedge clk) begin
        if (RegWrite && write_reg != 5'd0)  // write only if RegWrite=1 and not x0
            registers[write_reg] <= write_data;
    end

endmodule