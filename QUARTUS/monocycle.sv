// Procesador RISC-V monociclo optimizado para DE1-SoC
module monocycle (
  // Entradas de la placa DE1-SoC
  input  logic        CLOCK_50,    // Reloj de 50 MHz (No se usa para la lógica principal)
  input  logic [3:0]  KEY,         // Botones (lógica negada)
  input  logic [9:0]  SW,          // Switches
  
  // Salidas a displays de 7 segmentos (SOLO 4 DISPLAYS)
  output logic [6:0]  HEX0,        // dato[3:0]
  output logic [6:0]  HEX1,        // dato[7:4]
  output logic [6:0]  HEX2,        // dato[11:8]
  output logic [6:0]  HEX3,        // dato[15:12]
  
  // LEDs para debug
  output logic [9:0]  LEDR         // PC y bits de instrucción
);

  // ========== SEÑALES DE CONTROL ==========
  logic        clk;
  logic        reset;
  logic        tr;
  logic        show_result;    // SW[9] cambiar entre instrucción y resultado
  logic        show_high_bits; // SW[8] cambiar entre bits bajos y altos
  
  // Configuración de controles
  assign clk = ~KEY[0];              // KEY[0] como reloj manual (activo bajo)
  assign reset = ~KEY[1];            // KEY[1] como reset (activo bajo)
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
  
  assign subsra = alu_op[3];
  
  // Multiplexores
  assign aluOperandA = rs1Data;  // Por ahora siempre rs1
  assign aluOperandB = alu_b_src ? immediate : rs2Data;
  
  // Multiplexor para seleccionar fuente de datos para registro
  always_comb begin
    case (ru_data_src)
      2'b00:   ruWriteData = aluResult;    // Resultado de ALU
      2'b01:   ruWriteData = memReadData;  // Datos de memoria
      2'b10:   ruWriteData = pc_sum;       // PC+4 (para JAL/JALR)
      default: ruWriteData = aluResult;
    endcase
  end
  
  // LEDs: Muestra PC[7:0] en los bits bajos y los 2 bits de instrucción
  assign LEDR[7:0] = pc_current[7:0];
  assign LEDR[9:8] = instruction[1:0];
  
  // ========== MÓDULOS DEL PROCESADOR ==========
  
  // Program Counter
  pc program_counter (
    .next_address(pc_next),
    .clk(clk),
    .reset(reset),
    .initial_address(32'h00000000),
    .address(pc_current)
  );
  
  // Sumador PC + 4
  sumador pc_adder (
    .input_1(pc_current),
    .output_32(pc_sum)
  );
  
  // Lógica para PC next (considera reset)
  assign pc_next = reset ? 32'h00000000 : pc_sum;
  
  // Memoria de instrucciones
  instruction_memory imem (
    .address(pc_current),
    .instruction(instruction)
  );
  
  // Decodificador de instrucciones
  instruction_decoder decoder (
    .instruction(instruction),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7)
  );
  
  // Unidad de control
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
  
  // Generador de inmediatos
  immediate_generator imm_gen (
    .instruction(instruction),
    .imm_src(imm_src),
    .immediate(immediate)
  );
  
  // Banco de registros
  registerUnit reg_file (
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .clk(clk),
    .writeEnable(ru_write),
    .data(ruWriteData),
    .tr(tr),
    .rs1Data(rs1Data),
    .rs2Data(rs2Data)
  );
  
  // ALU
  alu alu_unit (
    .operand1(aluOperandA),
    .operand2(aluOperandB),
    .funct3(funct3),
    .subsra(subsra),
    .result(aluResult)
  );
  
  // Memoria de datos
  data_memory dmem (
    .clk(clk),
    .address(aluResult),        // Dirección = resultado ALU (rs1 + imm)
    .write_data(rs2Data),       // Dato a escribir = rs2
    .write_enable(dm_write),    // Habilitador de escritura
    .dm_ctrl(dm_ctrl),          // Control de tamaño/signo
    .read_data(memReadData)     // Dato leído
  );
  
  // ========== DECODIFICADORES 7 SEGMENTOS (4 DISPLAYS) ==========
  // SW[9] selecciona el dato base:
  //   0 = instrucción en hexadecimal
  //   1 = dato que se escribirá en el registro (ruWriteData)
  // SW[8] selecciona qué 16 bits mostrar:
  //   0 = bits [15:0] (4 dígitos menos significativos)
  //   1 = bits [31:16] (4 dígitos más significativos)
  
  logic [31:0] display_data_full;  // Dato completo (32 bits)
  logic [15:0] display_data;       // Dato a mostrar en displays (16 bits)
  
  // Selección del dato base
  assign display_data_full = show_result ? ruWriteData : instruction;
  
  // Selección de qué 16 bits mostrar
  always_comb begin
    if (show_high_bits)
      display_data = display_data_full[31:16];  // 4 dígitos altos
    else
      display_data = display_data_full[15:0];   // 4 dígitos bajos
  end
  
  logic [6:0] seg0, seg1, seg2, seg3;
  logic [6:0] ZERO_7SEG = 7'b1000000; // Código para mostrar '0'

  hex_to_7seg display0 (.hex(display_data[3:0]),   .seg(seg0));
  hex_to_7seg display1 (.hex(display_data[7:4]),   .seg(seg1));
  hex_to_7seg display2 (.hex(display_data[11:8]),  .seg(seg2));
  hex_to_7seg display3 (.hex(display_data[15:12]), .seg(seg3));

  assign HEX0 = reset ? ZERO_7SEG : seg0;
  assign HEX1 = reset ? ZERO_7SEG : seg1;
  assign HEX2 = reset ? ZERO_7SEG : seg2;
  assign HEX3 = reset ? ZERO_7SEG : seg3;

endmodule