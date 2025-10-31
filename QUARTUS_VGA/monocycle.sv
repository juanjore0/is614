// ============================================================
// monocycle.sv - Procesador RISC-V con Display VGA
// TOP MODULE para DE1-SoC con salida VGA
// ============================================================

module monocycle (
  // Entradas de la placa DE1-SoC
  input  logic        CLOCK_50,    // Reloj de 50 MHz
  input  logic [3:0]  KEY,         // Botones (lógica negada)
  input  logic [9:0]  SW,          // Switches
  
  // Salidas a displays de 7 segmentos
  output logic [6:0]  HEX0,
  output logic [6:0]  HEX1,
  output logic [6:0]  HEX2,
  output logic [6:0]  HEX3,
  
  // LEDs para debug
  output logic [9:0]  LEDR,
  
  // Salidas VGA
  output logic [7:0]  VGA_R,
  output logic [7:0]  VGA_G,
  output logic [7:0]  VGA_B,
  output logic        VGA_HS,
  output logic        VGA_VS,
  output logic        VGA_CLK
);

  // ========== SEÑALES DE CONTROL ==========
  logic        clk;
  logic        reset;
  logic        tr;
  logic        show_result;
  logic        show_high_bits;
  
  assign clk = ~KEY[0];              // KEY[0] como reloj manual
  assign reset = ~KEY[1];            // KEY[1] como reset
  assign tr = SW[1];                 // SW[1] para modo trace
  assign show_result = SW[9];        // SW[9]: 0=instrucción, 1=resultado
  assign show_high_bits = SW[8];     // SW[8]: 0=bits[15:0], 1=bits[31:16]
  
  // ========== SEÑALES DEL PROCESADOR ==========
  logic [31:0] pc_current;
  logic [31:0] pc_next;
  logic [31:0] pc_sum;
  logic [31:0] instruction;
  
  // Señales del decoder
  logic [6:0]  opcode;
  logic [4:0]  rd, rs1, rs2;
  logic [2:0]  funct3;
  logic [6:0]  funct7;
  
  // Señales de control
  logic        ru_write;
  logic [3:0]  alu_op;
  logic [2:0]  imm_src;
  logic [1:0]  alu_a_src;
  logic        alu_b_src;
  logic        dm_write;
  logic [2:0]  dm_ctrl;
  logic [4:0]  br_op;
  logic [1:0]  ru_data_src;
  
  // Señales de datos
  logic [31:0] rs1Data, rs2Data;
  logic [31:0] aluResult;
  logic [31:0] immediate;
  logic [31:0] aluOperandA, aluOperandB;
  logic [31:0] ruWriteData;
  logic [31:0] memReadData;
  logic        subsra;
  
  // ← NUEVO: Para VGA debug
  logic [31:0] registers [0:31];
  logic [31:0] reg_changed_mask;
  
  assign subsra = alu_op[3];

  // Multiplexor para operando A de la ALU
  always_comb begin
    case (alu_a_src)
      2'b00:   aluOperandA = rs1Data;   // Usar rs1
      2'b01:   aluOperandA = pc_current; // Usar PC (para AUIPC)
      default: aluOperandA = rs1Data;
    endcase
  end 
  
  // Multiplexores
  
  assign aluOperandB = alu_b_src ? immediate : rs2Data;
  
  // Multiplexor para seleccionar fuente de datos
  always_comb begin
    case (ru_data_src)
      2'b00:   ruWriteData = aluResult;
      2'b01:   ruWriteData = memReadData;
      2'b10:   ruWriteData = pc_sum;
      2'b11:   ruWriteData = immediate;
      default: ruWriteData = aluResult;
    endcase
  end
  
  // LEDs
  assign LEDR[7:0] = pc_current[7:0];
  assign LEDR[9:8] = instruction[1:0];
  
  // ========== DETECTOR DE CAMBIOS EN REGISTROS ==========
  logic [31:0] registers_prev [0:31];
  logic [15:0] highlight_counter [0:31];  // Contador de highlight por registro
  
  always_ff @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
      reg_changed_mask <= 32'h0;
      for (int i = 0; i < 32; i++) begin
        registers_prev[i] <= 32'h0;
        highlight_counter[i] <= 16'h0;
      end
    end else begin
      for (int i = 0; i < 32; i++) begin
        // Detectar cambio
        if (registers[i] != registers_prev[i]) begin
          reg_changed_mask[i] <= 1'b1;
          highlight_counter[i] <= 16'hFFFF;  // ~1.3ms @ 50MHz
          registers_prev[i] <= registers[i];
        end 
        // Mantener highlight por un tiempo
        else if (highlight_counter[i] > 0) begin
          highlight_counter[i] <= highlight_counter[i] - 1;
          reg_changed_mask[i] <= 1'b1;
        end 
        // Apagar highlight
        else begin
          reg_changed_mask[i] <= 1'b0;
        end
      end
    end
  end
  
  // ========== MÓDULOS DEL PROCESADOR ==========
  
  assign pc_next = pc_sum;
  
  pc program_counter (
    .next_address(pc_next),
    .clk(clk),
    .reset(reset),
    .initial_address(32'h00000000),
    .address(pc_current)
  );
  
  sumador pc_adder (
    .input_1(pc_current),
    .output_32(pc_sum)
  );
  
  instruction_memory imem (
    .address(pc_current),
    .instruction(instruction)
  );
  
  instruction_decoder decoder (
    .instruction(instruction),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7)
  );
  
  control_unit ctrl (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .ru_write(ru_write),
    .alu_op(alu_op),
    .imm_src(imm_src),
    .alu_a_src(alu_a_src),
    .alu_b_src(alu_b_src),
    .dm_write(dm_write),
    .dm_ctrl(dm_ctrl),
    .br_op(br_op),
    .ru_data_src(ru_data_src)
  );
  
  immediate_generator imm_gen (
    .instruction(instruction),
    .imm_src(imm_src),
    .immediate(immediate)
  );
  
  // Banco de registros - CON SALIDA PARA VGA
  registerUnit reg_file (
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .clk(clk),
    .reset(reset),
    .writeEnable(ru_write),
    .data(ruWriteData),
    .tr(tr),
    .rs1Data(rs1Data),
    .rs2Data(rs2Data),
    .registers_out(registers)  // ← NUEVA CONEXIÓN
  );
  
  alu alu_unit (
    .operand1(aluOperandA),
    .operand2(aluOperandB),
    .funct3(funct3),
    .subsra(subsra),
    .result(aluResult)
  );
  
  
  // ========== EXPONER MEMORIA PARA VGA ==========
  logic [31:0] memory_display [0:7];
  
  data_memory dmem (
	  .clk(clk),
	  .address(aluResult),
	  .write_data(rs2Data),
	  .write_enable(dm_write),
	  .dm_ctrl(dm_ctrl),
	  .read_data(memReadData),
	  .memory_out(memory_display)  // ← AGREGAR ESTA LÍNEA
	);
  
  // ========== DISPLAY VGA ==========
  risc_debug_display vga_debug (
    .clock(CLOCK_50),
    .sw0(reset),
    .sw1(SW[2]), .sw2(SW[3]), .sw3(SW[4]), .sw4(SW[5]), .sw5(SW[6]),
    
    // Registros
    .regs_demo(registers),
    .changed_mask(reg_changed_mask),
    
    // PC e Instrucción
    .pc_value(pc_current),
    .instruction(instruction),
    
    // ALU
    .alu_operand_a(aluOperandA),
    .alu_operand_b(aluOperandB),
    .alu_result(aluResult),
    
    // Inmediato
    .immediate(immediate),
    
    // Memoria
    .memory(memory_display),
    
    // VGA outputs
    .vga_red(VGA_R),
    .vga_green(VGA_G),
    .vga_blue(VGA_B),
    .vga_hsync(VGA_HS),
    .vga_vsync(VGA_VS),
    .vga_clock(VGA_CLK)
  );
  
  // ========== DISPLAYS 7 SEGMENTOS ==========
  logic [31:0] display_data_full;
  logic [15:0] display_data;
  
  assign display_data_full = show_result ? ruWriteData : instruction;
  
  always_comb begin
    if (show_high_bits)
      display_data = display_data_full[31:16];
    else
      display_data = display_data_full[15:0];
  end
  
  logic [6:0] seg0, seg1, seg2, seg3;
  logic [6:0] ZERO_7SEG = 7'b1000000;

  hex_to_7seg display0 (.hex(display_data[3:0]),   .seg(seg0));
  hex_to_7seg display1 (.hex(display_data[7:4]),   .seg(seg1));
  hex_to_7seg display2 (.hex(display_data[11:8]),  .seg(seg2));
  hex_to_7seg display3 (.hex(display_data[15:12]), .seg(seg3));

  assign HEX0 = reset ? ZERO_7SEG : seg0;
  assign HEX1 = reset ? ZERO_7SEG : seg1;
  assign HEX2 = reset ? ZERO_7SEG : seg2;
  assign HEX3 = reset ? ZERO_7SEG : seg3;

endmodule