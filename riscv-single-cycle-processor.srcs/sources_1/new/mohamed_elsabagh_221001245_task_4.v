`timescale 1ns / 1ps

module PC (
    input  wire        clk,
    input  wire        reset,
    input  wire        PCWrite,
    input  wire [31:0] PC_in,
    output reg  [31:0] PC_out
);

always @(posedge clk or posedge reset) begin
    if (reset)
        PC_out <= 32'd0;
    else if (PCWrite)
        PC_out <= PC_in;
end

endmodule
