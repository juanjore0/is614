`include "../PC/pc.sv"
`include "../ALU/alu.sv"
`include "../REGISTER_UNIT/register_unit.sv"
`include "../SUMADOR/sumador.sv"
`include "../IMEM/instruction_memory.sv"
`include "../DECODER/instruction_decoder.sv"
`include "../CONTROL/control_unit.sv"

module monocycle (
  input  logic        clk,
  input  logic        reset,
  input  logic [31:0] initial_pc,
  input  logic        tr,          // trace mode
  
  output logic [31:0] pc_out,
  output logic [31:0] instruction_out
);

  // Señales internas
  logic [31:0] pc_current;
  logic [31:0] pc_next;
  logic [31:0] instruction;
  
  // Señales del decoder
  logic [6:0]  opcode;
  logic [4:0]  rd, rs1, rs2;
  logic [2:0]  funct3;
  logic [6:0]  funct7;
  
  // Señales de control completas
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
  logic        subsra;  // Extraído de alu_op
  
  // Extracción de subsra desde alu_op[3]
  assign subsra = alu_op[3];
  
  // Salidas
  assign pc_out = pc_current;
  assign instruction_out = instruction;
  
  // ========== INSTANCIAS DE MÓDULOS ==========
  
  // Program Counter
  pc program_counter (
    .next_address(pc_next),
    .clk(clk),
    .reset(reset),
    .initial_address(initial_pc),
    .address(pc_current)
  );
  
  // Sumador PC + 4
  sumador pc_adder (
    .input_1(pc_current),
    .output_32(pc_next)
  );
  
  // Instruction Memory
  instruction_memory imem (
    .address(pc_current),
    .instruction(instruction)
  );
  
  // Instruction Decoder
  instruction_decoder decoder (
    .instruction(instruction),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7)
  );
  
  // Control Unit (Completa para tipo R)
  control_unit control (
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
  
  // Register Unit
  registerUnit reg_file (
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .clk(clk),
    .writeEnable(ru_write),
    .data(aluResult),
    .tr(tr),
    .rs1Data(rs1Data),
    .rs2Data(rs2Data)
  );
  
  // ALU
  alu arithmetic_logic_unit (
    .operand1(rs1Data),
    .operand2(rs2Data),
    .func3(funct3),
    .subsra(subsra),
    .result(aluResult)
  );

endmodule