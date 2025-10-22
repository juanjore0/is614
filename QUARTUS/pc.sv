module pc (
  input  logic [31:0] next_address,
  input  logic clk,
  input  logic reset,             // Reset activo en alto
  input  logic [31:0] initial_address, // Primer valor de memoria (por ej. 0)
  output logic [31:0] address
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      address <= initial_address;   // Vuelve a 0 o dirección inicial
    else
      address <= next_address;      // Avanza normalmente
  end

endmodule
