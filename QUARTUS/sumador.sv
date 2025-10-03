module sumador (
  input wire[31:0] input_1,
  output wire[31:0] output_32
);

  assign output_32 = input_1 + 4;

endmodule
