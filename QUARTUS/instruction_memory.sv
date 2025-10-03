module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  // Memoria de instrucciones
  logic [31:0] memory [0:255]; // 256 palabras de 32 bits
  
  // Lectura combinacional
  assign instruction = memory[address[31:2]]; // Divide por 4 (word-aligned)
  
  // Inicialización directa en código
  initial begin
    // Inicializar toda la memoria con NOP (ADD x0, x0, x0)
    for (int i = 0; i < 256; i++) 
      memory[i] = 32'h00000033;
    
    // === PROGRAMA DE PRUEBA - INSTRUCCIONES TIPO R ===
    
    // Dirección 0x00: ADD x1, x0, x0  -> x1 = 0 + 0 = 0
    memory[0] = 32'h000000B3;
    
    // Dirección 0x04: ADD x2, x1, x1  -> x2 = x1 + x1 = 0
    memory[1] = 32'h001080B3;
    
    // Dirección 0x08: ADD x3, x2, x2  -> x3 = x2 + x2 = 0
    memory[2] = 32'h002101B3;
    
    // Dirección 0x0C: SUB x4, x3, x2  -> x4 = x3 - x2 = 0
    memory[3] = 32'h40218233;
    
    // Dirección 0x10: OR x5, x4, x3   -> x5 = x4 | x3 = 0
    memory[4] = 32'h003262B3;
    
    // Dirección 0x14: AND x6, x5, x4  -> x6 = x5 & x4 = 0
    memory[5] = 32'h0042F333;
    
    // Dirección 0x18: XOR x7, x6, x5  -> x7 = x6 ^ x5 = 0
    memory[6] = 32'h005343B3;
    
    // Dirección 0x1C: SLL x8, x1, x2  -> x8 = x1 << x2 = 0
    memory[7] = 32'h00209433;
    
    // Dirección 0x20: SRL x9, x8, x2  -> x9 = x8 >> x2 = 0
    memory[8] = 32'h0024D4B3;
    
    // Dirección 0x24: SRA x10, x8, x2 -> x10 = x8 >>> x2 = 0
    memory[9] = 32'h4024D533;
    
    // Dirección 0x28: SLT x11, x1, x2 -> x11 = (x1 < x2) = 0
    memory[10] = 32'h0020A5B3;
    
    // Dirección 0x2C: SLTU x12, x1, x2 -> x12 = (x1 < x2) = 0
    memory[11] = 32'h0020B633;
    
    $display("=== Memoria de instrucciones inicializada con 12 instrucciones tipo R ===");
  end

endmodule