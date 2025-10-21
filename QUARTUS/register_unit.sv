module registerUnit (
  input  logic [4:0]  rs1,
  input  logic [4:0]  rs2,
  input  logic [4:0]  rd, 
  input  logic        clk,
  input  logic        reset,        // AGREGADO: Señal de reset
  input  logic        writeEnable,
  input  logic [31:0] data,
  input  logic        tr,   // modo "trace"
  
  output logic [31:0] rs1Data,
  output logic [31:0] rs2Data
);

  // Banco de 32 registros de 32 bits
  logic [31:0] registers[31:0];

  // Escritura síncrona con reset
  always_ff @(posedge clk) begin
    if (reset) begin
      // Al resetear, limpiar todos los registros
      for (int i = 0; i < 32; i++) begin
        registers[i] <= 32'd0;
      end
    end else begin
      // Operación normal
      if (writeEnable && rd != 5'd0)
        registers[rd] <= data;
      registers[0] <= 32'd0; // x0 siempre en 0
    end
  end

  // Lectura combinacional
  assign rs1Data = registers[rs1];
  assign rs2Data = registers[rs2];

  // Debug (mostrar contenido)
  always_ff @(posedge clk) begin
    if (tr && !reset) begin  // Solo mostrar si no está en reset
      for (int i = 0; i < 32; i++) begin
        $display("R[%0d] = %0d", i, registers[i]);
      end
    end
  end

endmodule