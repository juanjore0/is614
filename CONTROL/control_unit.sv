module control_unit (
  input  logic [6:0] opcode,
  input  logic [2:0] funct3,
  input  logic [6:0] funct7,
  
  output logic       ru_write,      // Escritura en registro
  output logic [3:0] alu_op,        // Operación ALU
  output logic [2:0] imm_src,       // Fuente de inmediato
  output logic [1:0] alu_a_src,     // Fuente operando A
  output logic       alu_b_src,     // Fuente operando B
  output logic       dm_write,      // Escritura en memoria
  output logic [2:0] dm_ctrl,       // Control de memoria
  output logic [4:0] br_op,         // Operación de branch
  output logic [1:0] ru_data_src    // Fuente de datos para registro
);

  always_comb begin
    // Valores por defecto (estado seguro)
    ru_write     = 1'b0;
    alu_op       = 4'b0000;
    imm_src      = 3'b000;
    alu_a_src    = 2'b00;
    alu_b_src    = 1'b0;
    dm_write     = 1'b0;
    dm_ctrl      = 3'b000;
    br_op        = 5'b00000;
    ru_data_src  = 2'b00;
    
    case (opcode)
      7'b0110011: begin // Tipo R (Operaciones Aritméticas/Lógicas)
        ru_write     = 1'b1;           // Habilita escritura en rd
        alu_op       = {funct7[5], funct3}; // Codifica la operación
        imm_src      = 3'bxxx;         // No usa inmediato
        alu_a_src    = 2'b00;          // Operando A = rs1
        alu_b_src    = 1'b0;           // Operando B = rs2
        dm_write     = 1'b0;           // No escribe en memoria
        dm_ctrl      = 3'bxxx;         // No usa memoria
        br_op        = 5'b00xxx;       // No es branch
        ru_data_src  = 2'b00;          // Datos = resultado ALU
      end
    endcase
  end

endmodule