module control_unit (
  input  logic [6:0] opcode,
  input  logic [6:0] func7,
  
  output logic       regWrite,    // Habilita escritura en registros
  output logic       aluSrc,      // Selecciona fuente ALU (0=rs2, 1=inmediato)
  output logic       subsra       // Control SUB/SRA
);

  always_comb begin
    // Valores por defecto
    regWrite = 1'b0;
    aluSrc   = 1'b0;
    subsra   = 1'b0;
    
    case (opcode)
      7'b0110011: begin // Instrucciones tipo R
        regWrite = 1'b1;
        aluSrc   = 1'b0; // usa rs2
        // Detectar SUB o SRA
        subsra = (func7 == 7'b0100000) ? 1'b1 : 1'b0;
      end
      
      default: begin
        regWrite = 1'b0;
        aluSrc   = 1'b0;
        subsra   = 1'b0;
      end
    endcase
  end

endmodule