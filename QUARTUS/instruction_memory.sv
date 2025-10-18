module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  logic [31:0] memory [0:15];
  
  assign instruction = memory[address[5:2]];
  
  initial begin
    // === PROGRAMA DE PRUEBA CORREGIDO ===
    
    // --- TIPO R: Probar operaciones básicas ---
    // 0x00: ADD x1, x0, x0  -> x1 = 0
    memory[0] = 32'h000000B3;
    
    // 0x04: ADD x2, x1, x1  -> x2 = 0
    memory[1] = 32'h00108133;
    
    // --- TIPO I-Inmediato: Preparar registros base ---
    // 0x08: ADDI x3, x0, 0   -> x3 = 0 (dirección base)
    memory[2] = 32'h00000193;
    
    // 0x0C: ADDI x4, x0, 4   -> x4 = 4
    memory[3] = 32'h00400213;
    
    // 0x10: ADDI x5, x0, 8   -> x5 = 8
    memory[4] = 32'h00800293;
    
    // --- TIPO I-Load: Cargar desde memoria ---
    // 0x14: LW x6, 0(x3)     -> x6 = Mem[0x00] = 0x12345678
    memory[5] = 32'h0001A303;
    
    // 0x18: LW x7, 0(x4)     -> x7 = Mem[0x04] = 0xABCDEF00
    memory[6] = 32'h00022383;
    
    // 0x1C: LW x8, 0(x5)     -> x8 = Mem[0x08] = 0x00000064
    memory[7] = 32'h0002A403;
    
    // 0x20: LB x9, 0(x3)     -> x9 = 0x00000078 (signed byte)
    // Formato: imm[11:0]=0, rs1=x3, funct3=000 (LB), rd=x9
    memory[8] = 32'h00018403;  // ¡CORREGIDO! Era 0x00018483
    
    // 0x24: LBU x10, 0(x3)   -> x10 = 0x00000078 (unsigned byte)
    // funct3=100 (LBU)
    memory[9] = 32'h0001C503;
    
    // 0x28: LH x11, 0(x3)    -> x11 = 0x00005678 (signed halfword)
    // funct3=001 (LH)
    memory[10] = 32'h00019583;
    
    // 0x2C: LHU x12, 0(x3)   -> x12 = 0x00005678 (unsigned halfword)
    // funct3=101 (LHU)
    memory[11] = 32'h0001D603;
    
    // 0x30: LW x13, 12(x0)   -> x13 = Mem[0x0C] = 0xFFFFFFFF
    memory[12] = 32'h00C02683;
    
    // 0x34: LB x14, 12(x0)   -> x14 = 0xFFFFFFFF (signed)
    // funct3=000 (LB)
    memory[13] = 32'h00C00703;
    
    // --- TIPO I-Inmediato: Probar más operaciones ---
    // 0x38: XORI x15, x6, 255 -> x15 = x6 XOR 0xFF
    memory[14] = 32'h0FF34793;
    
    // 0x3C: ORI x16, x6, 15   -> x16 = x6 OR 0x0F
    memory[15] = 32'h00F36813;
    
    $display("=== Memoria de instrucciones inicializada ===");
    $display("Tipo R: 2 instrucciones");
    $display("Tipo I-Inmediato: 5 instrucciones");
    $display("Tipo I-Load: 9 instrucciones");
  end

endmodule