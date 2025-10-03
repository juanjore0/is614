module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  // Memoria de instrucciones
  logic [31:0] memory [0:255]; // 256 palabras de 32 bits
  
  // Lectura combinacional
  assign instruction = memory[address[31:2]]; // Divide por 4 (word-aligned)
  
  // Inicialización
  initial begin
    $readmemb("IMEM/instructions.txt", memory);  // ← Ruta completa desde la raíz
  end
endmodule