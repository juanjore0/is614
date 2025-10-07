module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  // Memoria de instrucciones - 16 palabras
  logic [31:0] memory [0:15];
  
  // Lectura combinacional
  assign instruction = memory[address[5:2]];
  
  // Inicialización directa en código
  initial begin
    // === PROGRAMA DE PRUEBA - TIPO R, TIPO I-Inmediato, TIPO I-Load ===
    
    // --- INSTRUCCIONES TIPO R (primeras 2) ---
    // 0x00: ADD x1, x0, x0  -> x1 = 0 + 0 = 0
    memory[0] = 32'h000000B3;
    
    // 0x04: ADD x2, x0, x0  -> x2 = 0 + 0 = 0
    memory[1] = 32'h000000B3;
    
    // --- INSTRUCCIONES TIPO I-Inmediato (preparar registros base) ---
    // 0x08: ADDI x3, x0, 0   -> x3 = 0 (dirección base = 0x00)
    memory[2] = 32'h00000193;
    
    // 0x0C: ADDI x4, x0, 4   -> x4 = 4 (dirección = 0x04)
    memory[3] = 32'h00400213;
    
    // 0x10: ADDI x5, x0, 8   -> x5 = 8 (dirección = 0x08)
    memory[4] = 32'h00800293;
    
    // --- INSTRUCCIONES TIPO I-Load ---
    // 0x14: LW x6, 0(x3)     -> x6 = Mem[0x00] = 0x12345678
    memory[5] = 32'h0001A303;
    
    // 0x18: LW x7, 0(x4)     -> x7 = Mem[0x04] = 0xABCDEF00
    memory[6] = 32'h00022383;
    
    // 0x1C: LW x8, 0(x5)     -> x8 = Mem[0x08] = 0x00000064 (100)
    memory[7] = 32'h0002A403;
    
    // 0x20: LB x9, 0(x3)     -> x9 = 0x00000078 (byte bajo de 0x12345678)
    memory[8] = 32'h00018483;
    
    // 0x24: LBU x10, 0(x3)   -> x10 = 0x00000078 (unsigned)
    memory[9] = 32'h0001C503;
    
    // 0x28: LH x11, 0(x3)    -> x11 = 0x00005678 (halfword bajo)
    memory[10] = 32'h00019583;
    
    // 0x2C: LHU x12, 0(x3)   -> x12 = 0x00005678 (unsigned)
    memory[11] = 32'h0001D603;
    
    // 0x30: LW x13, 12(x0)   -> x13 = Mem[0x0C] = 0xFFFFFFFF
    memory[12] = 32'h00C02683;
    
    // 0x34: LB x14, 12(x0)   -> x14 = 0xFFFFFFFF (byte con signo)
    memory[13] = 32'h00C00703;
    
    // Resto con NOPs
    memory[14] = 32'h00000033;
    memory[15] = 32'h00000033;
    
    $display("=== Memoria: 16 palabras (2 R + 3 I-Imm + 9 I-Load + 2 NOPs) ===");
  end

endmodule