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
  logic [2:0]  func3;
  logic [6:0]  func7;
  
  // Señales de control
  logic        regWrite;
  logic        aluSrc;
  logic        subsra;
  
  // Señales de registros
  logic [31:0] rs1Data, rs2Data;
  logic [31:0] aluResult;
  
  // Salidas
  assign pc_out = pc_current;
  assign instruction_out = instruction;
  
  // Instancias de módulos
  
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
    .func3(func3),
    .rs1(rs1),
    .rs2(rs2),
    .func7(func7)
  );
  
  // Control Unit
  control_unit control (
    .opcode(opcode),
    .func7(func7),
    .regWrite(regWrite),
    .aluSrc(aluSrc),
    .subsra(subsra)
  );
  
  // Register Unit
  registerUnit reg_file (
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .clk(clk),
    .writeEnable(regWrite),
    .data(aluResult),
    .tr(tr),
    .rs1Data(rs1Data),
    .rs2Data(rs2Data)
  );
  
  // ALU
  alu arithmetic_logic_unit (
    .operand1(rs1Data),
    .operand2(rs2Data),
    .func3(func3),
    .subsra(subsra),
    .result(aluResult)
  );

endmodule