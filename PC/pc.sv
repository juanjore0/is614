module pc (
  input[31:0] next_address,
  input clk,
  input reset,
  input[31:0] initial_address,

  output reg[31:0] address
);

  always @(posedge clk) begin
    if (reset == 1'b1)
      address = initial_address;
    else 
      address = next_address;
  end
  
endmodule