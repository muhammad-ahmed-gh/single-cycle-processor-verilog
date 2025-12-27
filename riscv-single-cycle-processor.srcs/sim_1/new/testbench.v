`timescale 1ns / 1ps

module tb;
    initial begin
        $display("Hello Vivado");
        #10;
        $finish;
    end
endmodule
