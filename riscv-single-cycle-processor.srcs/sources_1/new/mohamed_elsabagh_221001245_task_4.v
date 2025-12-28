`timescale 1ns / 1ps

module PC (
  input clk,
  input reset,
  input [63:0] PCIn,
  output reg [63:0] PCOut
);

  always @(posedge clk or posedge reset) begin
    if (reset)
      PCOut <= 64'd0;
    else
      PCOut <= PCIn;
  end

endmodule