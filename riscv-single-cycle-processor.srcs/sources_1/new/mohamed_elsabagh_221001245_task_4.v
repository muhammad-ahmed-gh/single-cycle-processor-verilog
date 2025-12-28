`timescale 1ns / 1ps

module PC (
  input clk,
  input reset,
  input [63:0] PC_in,
  output reg [63:0] PC_out
);

  always @(posedge clk or posedge reset) begin
    if (reset)
      PC_out <= 64'd0;
    else
      PC_out <= PC_in;
  end

endmodule