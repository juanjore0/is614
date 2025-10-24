module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  logic [31:0] memory [0:15];
  
  assign instruction = memory[address[5:2]];
  
  initial begin
    // === PROGRAMA DE PRUEBA: TIPO R, I y S ===
    
    // --- Preparar valores en registros ---
    // 0x00: ADDI x1, x0, 10    -> x1 = 10
    memory[0] = 32'h00A00093;
    
    // 0x04: ADDI x2, x0, 20    -> x2 = 20
    memory[1] = 32'h01400113;
    
    // 0x08: ADDI x3, x0, 0     -> x3 = 0 (dirección base para stores)
    memory[2] = 32'h00000193;
    
    // 0x0C: ADD x4, x1, x2     -> x4 = x1 + x2 = 30
    memory[3] = 32'h002081B3;
    
    // --- INSTRUCCIONES STORE (TIPO S) ---
    // 0x10: SW x1, 0(x3)       -> Mem[0] = x1 = 10
    // Formato: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
    // imm=0, rs2=x1, rs1=x3, funct3=010 (SW), opcode=0100011
    memory[4] = 32'h00118023;
    
    // 0x14: SW x2, 4(x3)       -> Mem[4] = x2 = 20
    // imm=4, rs2=x2, rs1=x3, funct3=010 (SW)
    memory[5] = 32'h00218223;
    
    // 0x18: SW x4, 8(x3)       -> Mem[8] = x4 = 30
    // imm=8, rs2=x4, rs1=x3, funct3=010 (SW)
    memory[6] = 32'h00418423;
    
    // --- Preparar para Store Byte y Halfword ---
    // 0x1C: ADDI x5, x0, 255   -> x5 = 0xFF
    memory[7] = 32'h0FF00293;
    
    // 0x20: ADDI x6, x0, 4096  -> x6 = 0x1000
    memory[8] = 32'h00001337;  // LUI x6, 1
    
    // 0x24: SB x5, 12(x3)      -> Mem[12][7:0] = 0xFF
    // funct3=000 (SB)
    memory[9] = 32'h00518623;
    
    // 0x28: SH x6, 14(x3)      -> Mem[14][15:0] = 0x1000
    // funct3=001 (SH)
    memory[10] = 32'h00619723;
    
    // --- Verificar con LOAD ---
    // 0x2C: LW x7, 0(x3)       -> x7 = Mem[0] = 10
    memory[11] = 32'h0001A383;
    
    // 0x30: LW x8, 4(x3)       -> x8 = Mem[4] = 20
    memory[12] = 32'h0041A403;
    
    // 0x34: LW x9, 8(x3)       -> x9 = Mem[8] = 30
    memory[13] = 32'h0081A483;
    
    // 0x38: LB x10, 12(x3)     -> x10 = Mem[12] = 0xFF (sign extended)
    memory[14] = 32'h00C18503;
    
    // 0x3C: LH x11, 14(x3)     -> x11 = Mem[14] = 0x1000
    memory[15] = 32'h00E19583;
    
    $display("=== Memoria de instrucciones inicializada ===");
    $display("Tipo I-Inmediato: 4 instrucciones (preparar registros)");
    $display("Tipo R: 1 instrucción (ADD)");
    $display("Tipo S: 5 instrucciones (SW x3, SB x1, SH x1)");
    $display("Tipo I-Load: 5 instrucciones (verificación)");
  end

endmodule