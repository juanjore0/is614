module control_unit (
  input  logic [6:0] opcode,
  input  logic [2:0] funct3,
  input  logic [6:0] funct7,
  
  output logic       ru_write,
  output logic [3:0] alu_op,
  output logic [2:0] imm_src,
  output logic [1:0] alu_a_src,
  output logic       alu_b_src,
  output logic       dm_write,
  output logic [2:0] dm_ctrl,
  output logic [4:0] br_op,
  output logic [1:0] ru_data_src
);

  always_comb begin
    // Valores por defecto
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
      7'b0110011: begin // Tipo R
        ru_write     = 1'b1;
        alu_op       = {funct7[5], funct3};
        imm_src      = 3'bxxx;
        alu_a_src    = 2'b00;
        alu_b_src    = 1'b0;
        dm_write     = 1'b0;
        dm_ctrl      = 3'bxxx;
        br_op        = 5'b00xxx;
        ru_data_src  = 2'b00;
      end
      
      7'b0010011: begin // Tipo I (Operaciones inmediatas)
        ru_write     = 1'b1;
        imm_src      = 3'b000;
        alu_a_src    = 2'b00;
        alu_b_src    = 1'b1;
        dm_write     = 1'b0;
        dm_ctrl      = 3'bxxx;
        br_op        = 5'b00xxx;
        ru_data_src  = 2'b00;
        
        // Diferenciar shifts de otras operaciones
        case (funct3)
          3'b001, 3'b101: // SLLI, SRLI/SRAI (shifts usan funct7[5])
            alu_op = {funct7[5], funct3};
          default: // ADDI, SLTI, SLTIU, XORI, ORI, ANDI (no usan funct7[5])
            alu_op = {1'b0, funct3};
        endcase
      end
      
      7'b0000011: begin // Tipo I (Load)
        ru_write     = 1'b1;
        alu_op       = 4'b0000; // ADD
        imm_src      = 3'b000;
        alu_a_src    = 2'b00;
        alu_b_src    = 1'b1;
        dm_write     = 1'b0;
        dm_ctrl      = funct3;
        br_op        = 5'b00xxx;
        ru_data_src  = 2'b01;
      end
      
      default: begin
        ru_write     = 1'b0;
        alu_op       = 4'b0000;
        imm_src      = 3'b000;
        alu_a_src    = 2'b00;
        alu_b_src    = 1'b0;
        dm_write     = 1'b0;
        dm_ctrl      = 3'b000;
        br_op        = 5'b00000;
        ru_data_src  = 2'b00;
      end
    endcase
  end

endmodule