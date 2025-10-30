module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  logic [31:0] memory [0:15];
  
  assign instruction = memory[address[5:2]];
  
  initial begin
    // === PROGRAMA DE PRUEBA: TIPO R, I, S y U ===
    
    // --- INSTRUCCIONES TIPO U (LUI y AUIPC) ---
    // 0x00: LUI x1, 0x12345    -> x1 = 0x12345000
    // Formato: imm[31:12] | rd | opcode
    // imm=0x12345, rd=x1, opcode=0110111
    memory[0] = 32'h123450B7;
    
    // 0x04: AUIPC x2, 0x1000   -> x2 = PC(0x04) + 0x01000000 = 0x01000004
    // imm=0x1000, rd=x2, opcode=0010111
    memory[1] = 32'h01000117;
    
    // 0x08: LUI x3, 0xABCDE    -> x3 = 0xABCDE000
    memory[2] = 32'hABCDE1B7;
    
    // 0x0C: AUIPC x4, 0x0      -> x4 = PC(0x0C) + 0 = 0x0000000C
    memory[3] = 32'h00000217;
    
    // --- Combinar con instrucciones inmediatas ---
    // 0x10: ADDI x5, x1, 0x678 -> x5 = x1 + 0x678 = 0x12345678
    memory[4] = 32'h678082B3;
    
    // 0x14: ADDI x6, x3, 0xF   -> x6 = x3 + 0xF = 0xABCDE00F
    memory[5] = 32'h00F18313;
    
    // --- Preparar para Store ---
    // 0x18: ADDI x7, x0, 0     -> x7 = 0 (dirección base)
    memory[6] = 32'h00000393;
    
    // 0x1C: SW x1, 0(x7)       -> Mem[0] = x1 = 0x12345000
    memory[7] = 32'h0013A023;
    
    // 0x20: SW x2, 4(x7)       -> Mem[4] = x2 = 0x01000004
    memory[8] = 32'h0023A223;
    
    // 0x24: SW x5, 8(x7)       -> Mem[8] = x5 = 0x12345678
    memory[9] = 32'h0053A423;
    
    // --- Verificar con Load ---
    // 0x28: LW x8, 0(x7)       -> x8 = Mem[0]
    memory[10] = 32'h0003A403;
    
    // 0x2C: LW x9, 4(x7)       -> x9 = Mem[4]
    memory[11] = 32'h0043A483;
    
    // 0x30: LW x10, 8(x7)      -> x10 = Mem[8]
    memory[12] = 32'h0083A503;
    
    // Resto sin usar
    memory[13] = 32'h00000013; // NOP
    memory[14] = 32'h00000013; // NOP
    memory[15] = 32'h00000013; // NOP
    
    $display("=== Memoria de instrucciones inicializada ===");
    $display("Tipo U: 4 instrucciones (LUI x2, AUIPC x2)");
    $display("Tipo I: 3 instrucciones (ADDI x3)");
    $display("Tipo S: 3 instrucciones (SW x3)");
    $display("Tipo I-Load: 3 instrucciones (LW x3)");
  end

endmodule