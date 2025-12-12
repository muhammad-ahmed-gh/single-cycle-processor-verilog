module test_bench;
  reg a;
  reg b;
  reg c_in;
  wire sum;
  wire c_out;

  full_adder fa (a, b, c_in, sum, c_out);

  initial begin
    a = 1'b0;
    b = 1'b0;
    c_in = 1'b0;

    $monitor("a: %d, b: %d, c in: %d, sum: %d, c out: %d",
    a, b, c_in,
    sum, c_out);
  end
endmodule