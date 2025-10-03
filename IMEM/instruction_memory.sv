module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  // Memoria de instrucciones
  logic [31:0] memory [0:255]; // 256 palabras de 32 bits
  
  // Lectura combinacional
  assign instruction = memory[address[31:2]]; // Divide por 4 (word-aligned)
  
  // Inicialización (puedes cargar desde archivo)
  initial begin
    // Ejemplo de instrucciones tipo R
    // ADD x1, x2, x3: 0x003100B3
    memory[0] = 32'h003100B3;
    // Inicializa el resto en 0
    for (int i = 1; i < 256; i++) 
      memory[i] = 32'h00000000;
  end
endmodule