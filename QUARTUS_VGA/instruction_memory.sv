module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  logic [31:0] memory [0:31];
  
  assign instruction = memory[address[5:2]];
  
  initial begin
    // ===========================================================
    // PROGRAMA EXTENDIDO: Bajos, Altos + STORES
    // ===========================================================
    
    // ===== PARTE 1: INICIALIZAR REGISTROS BAJOS =====
    
    // 0x00: ADDI x1, x0, 10    -> x1 = 10
    memory[0] = 32'h00A00093;
    
    // 0x04: ADDI x2, x0, 20    -> x2 = 20
    memory[1] = 32'h01400113;
    
    // 0x08: ADDI x3, x0, 0     -> x3 = 0 (dirección base para memoria)
    memory[2] = 32'h00000193;
    
    // 0x0C: ADD x4, x1, x2     -> x4 = 30
    memory[3] = 32'h00208233;
    
    // ===== PARTE 2: INICIALIZAR REGISTROS ALTOS =====
    
    // 0x10: ADDI x20, x0, 100  -> x20 = 100
    memory[4] = 32'h06400A13;
    
    // 0x14: ADDI x21, x0, 200  -> x21 = 200
    memory[5] = 32'h0C800A93;
    
    // 0x18: ADDI x22, x0, 44   -> x22 = 44
    memory[6] = 32'h02C00B13;
    
    // 0x1C: ADD x23, x20, x21  -> x23 = 300
    memory[7] = 32'h015A0BB3;
    
    // ===== PARTE 3: STORE WORD (SW) - Guardar en memoria =====
    
    // 0x20: SW x1, 0(x3)       -> Mem[0] = 10
    // Formato: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
    // imm=0, rs2=x1, rs1=x3, funct3=010 (SW)
    memory[8] = 32'h0011A023;
    
    // 0x24: SW x2, 4(x3)       -> Mem[4] = 20
    // imm=4, rs2=x2, rs1=x3
    memory[9] = 32'h0021A223;
    
    // 0x28: SW x4, 8(x3)       -> Mem[8] = 30
    // imm=8, rs2=x4, rs1=x3
    memory[10] = 32'h0041A423;
    
    // ===== PARTE 4: STORE WORD CON REGISTROS ALTOS =====
    
    // 0x2C: SW x20, 12(x3)     -> Mem[12] = 100
    // imm=12, rs2=x20, rs1=x3, funct3=010 (SW)
    memory[11] = 32'h014A2623;
    
    // 0x30: SW x21, 16(x3)     -> Mem[16] = 200
    // imm=16, rs2=x21, rs1=x3
    memory[12] = 32'h015A2823;
    
    // 0x34: SW x23, 20(x3)     -> Mem[20] = 300
    // imm=20, rs2=x23, rs1=x3
    memory[13] = 32'h017A2A23;
    
    // ===== PARTE 5: LOAD WORD (LW) - Leer desde memoria =====
    
    // 0x38: LW x5, 0(x3)       -> x5 = Mem[0] = 10
    memory[14] = 32'h0001A283;
    
    // 0x3C: LW x6, 4(x3)       -> x6 = Mem[4] = 20
    memory[15] = 32'h0041A303;
    
    // 0x40: LW x7, 8(x3)       -> x7 = Mem[8] = 30
    memory[16] = 32'h0081A383;
    
    // 0x44: LW x24, 12(x3)     -> x24 = Mem[12] = 100
    memory[17] = 32'h00C1AC03;
    
    // 0x48: LW x25, 16(x3)     -> x25 = Mem[16] = 200
    memory[18] = 32'h0101AC83;
    
    // 0x4C: LW x26, 20(x3)     -> x26 = Mem[20] = 300
    memory[19] = 32'h0141AD03;
    
    // ===== PARTE 6: STORE BYTE (SB) =====
    
    // 0x50: ADDI x8, x0, 255   -> x8 = 0xFF
    memory[20] = 32'h0FF00413;
    
    // 0x54: SB x8, 24(x3)      -> Mem[24][7:0] = 0xFF
    // imm=24, rs2=x8, rs1=x3, funct3=000 (SB)
    memory[21] = 32'h0184C423;
    
    // ===== PARTE 7: STORE HALFWORD (SH) =====
    
    // 0x58: ADDI x9, x0, -1    -> x9 = 0xFFFFFFFF (sign extended from -1)
    memory[22] = 32'hFFF00493;
    
    // 0x5C: SH x9, 28(x3)      -> Mem[28][15:0] = 0xFFFF
    // imm=28, rs2=x9, rs1=x3, funct3=001 (SH)
    memory[23] = 32'h0194D623;
    
    // ===== PARTE 8: LOAD BYTE (LB) =====
    
    // 0x60: LB x10, 24(x3)     -> x10 = Mem[24] (sign extended)
    memory[24] = 32'h01818503;
    
    // ===== PARTE 9: LOAD HALFWORD (LH) =====
    
    // 0x64: LH x11, 28(x3)     -> x11 = Mem[28] (sign extended)
    memory[25] = 32'h01C19583;
    
    // ===== PARTE 10: OPERACIONES FINALES =====
    
    // 0x68: ADD x12, x5, x6    -> x12 = 10 + 20 = 30
    memory[26] = 32'h00628633;
    
    // 0x6C: ADD x13, x24, x25  -> x13 = 100 + 200 = 300
    memory[27] = 32'h019C06B3;
    
    // 0x70: ADD x14, x7, x22   -> x14 = 30 + 44 = 74
    memory[28] = 32'h016B8733;
    
    // 0x74: ADD x15, x23, x26  -> x15 = 300 + 300 = 600
    memory[29] = 32'h01ABA7B3;
    
    // 0x78: NOP
    memory[30] = 32'h00000013;
    
    // 0x7C: NOP
    memory[31] = 32'h00000013;
    
  end

endmodule
