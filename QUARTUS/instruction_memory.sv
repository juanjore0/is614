module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  // Memoria de instrucciones REDUCIDA - solo 16 palabras en lugar de 256
  logic [31:0] memory [0:15]; // 16 palabras de 32 bits = 64 bytes
  
  // Lectura combinacional
  assign instruction = memory[address[5:2]]; // Usa bits [5:2] para word-aligned
  
  // Inicialización directa en código
  initial begin
    // === PROGRAMA DE PRUEBA - INSTRUCCIONES TIPO R ===
    
    // 0x00: ADD x1, x0, x0  -> x1 = 0
    memory[0] = 32'h000000B3;
    
    // 0x04: ADD x2, x1, x1  -> x2 = 0
    memory[1] = 32'h001080B3;
    
    // 0x08: ADD x3, x2, x2  -> x3 = 0
    memory[2] = 32'h002101B3;
    
    // 0x0C: SUB x4, x3, x2  -> x4 = 0
    memory[3] = 32'h40218233;
    
    // 0x10: OR x5, x4, x3   -> x5 = 0
    memory[4] = 32'h003262B3;
    
    // 0x14: AND x6, x5, x4  -> x6 = 0
    memory[5] = 32'h0042F333;
    
    // 0x18: XOR x7, x6, x5  -> x7 = 0
    memory[6] = 32'h005343B3;
    
    // 0x1C: SLL x8, x1, x2  -> x8 = 0
    memory[7] = 32'h00209433;
    
    // 0x20: SRL x9, x8, x2  -> x9 = 0
    memory[8] = 32'h0024D4B3;
    
    // 0x24: SRA x10, x8, x2 -> x10 = 0
    memory[9] = 32'h4024D533;
    
    // 0x28: SLT x11, x1, x2 -> x11 = 0
    memory[10] = 32'h0020A5B3;
    
    // 0x2C: SLTU x12, x1, x2 -> x12 = 0
    memory[11] = 32'h0020B633;
    
    // Resto con NOPs
    memory[12] = 32'h00000033;
    memory[13] = 32'h00000033;
    memory[14] = 32'h00000033;
    memory[15] = 32'h00000033;
    
    $display("=== Memoria optimizada: 16 palabras (12 instrucciones + 4 NOPs) ===");
  end

endmodule