// Procesador RISC-V monociclo optimizado para DE1-SoC
module monocycle (
  // Entradas de la placa DE1-SoC
  input  logic        CLOCK_50,    // Reloj de 50 MHz (No se usa para la lógica principal)
  input  logic [3:0]  KEY,         // Botones (lógica negada)
  input  logic [9:0]  SW,          // Switches
  
  // Salidas a displays de 7 segmentos
  output logic [6:0]  HEX0,        // instrucción[3:0]
  output logic [6:0]  HEX1,        // instrucción[7:4]
  output logic [6:0]  HEX2,        // instrucción[11:8]
  output logic [6:0]  HEX3,        // instrucción[15:12]
  output logic [6:0]  HEX4,        // instrucción[19:16]
  output logic [6:0]  HEX5,        // instrucción[23:20]
  
  // LEDs para debug
  output logic [9:0]  LEDR         // PC y bits superiores de instrucción
);

  // ========== SEÑALES DE CONTROL ==========
  logic        clk;
  logic        reset;
  logic        tr;
  
  // Configuración de controles
  // KEY[0] actúa como el reloj manual (activo bajo, por eso se niega)
  assign clk = ~KEY[0];
  // KEY[1] activa el reset (activo bajo)
  assign reset = ~KEY[1];
  // SW[1] se mantiene para el modo 'trace'
  assign tr = SW[1];
  
  // ========== SEÑALES DEL PROCESADOR ==========
  logic [31:0] pc_current;
  logic [31:0] pc_next;
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
  logic        subsra;
  
  assign subsra = alu_op[3];
  
  // LEDs: Muestra PC[7:0] en los bits bajos y los 2 bits más altos de instrucción
  assign LEDR[7:0] = pc_current[7:0];
  assign LEDR[9:8] = instruction[31:30];
  
  // ========== MÓDULOS DEL PROCESADOR ==========
  
  pc program_counter (
    .next_address(pc_next),
    .clk(clk),
    .reset(reset),
    .initial_address(32'h00000000),
    .address(pc_current)
  );
  
  sumador pc_adder (
    .input_1(pc_current),
    .output_32(pc_next)
  );
  assign pc_next = reset ? 32'h00000000 : pc_sum;
  
  instruction_memory imem (
    .address(pc_current),
    .instruction(instruction)
  );
  
  // El resto de los módulos del procesador (decoder, control_unit, etc.)
  // se conectarían aquí. Asumimos que están definidos en otros archivos.
  
  // ========== DECODIFICADORES 7 SEGMENTOS ==========
  // Muestra los 24 bits menos significativos de la instrucción.
  // Si 'reset' está activo (KEY[1] presionado), muestra '0' en todos los displays.
  
  logic [6:0] seg0, seg1, seg2, seg3, seg4, seg5;
  logic [6:0] ZERO_7SEG = 7'b1000000; // Código para mostrar '0'

  hex_to_7seg display0 (.hex(instruction[3:0]),   .seg(seg0));
  hex_to_7seg display1 (.hex(instruction[7:4]),   .seg(seg1));
  hex_to_7seg display2 (.hex(instruction[11:8]),  .seg(seg2));
  hex_to_7seg display3 (.hex(instruction[15:12]), .seg(seg3));
  hex_to_7seg display4 (.hex(instruction[19:16]), .seg(seg4));
  hex_to_7seg display5 (.hex(instruction[23:20]), .seg(seg5));

  assign HEX0 = reset ? ZERO_7SEG : seg0;
  assign HEX1 = reset ? ZERO_7SEG : seg1;
  assign HEX2 = reset ? ZERO_7SEG : seg2;
  assign HEX3 = reset ? ZERO_7SEG : seg3;
  assign HEX4 = reset ? ZERO_7SEG : seg4;
  assign HEX5 = reset ? ZERO_7SEG : seg5;

endmodule