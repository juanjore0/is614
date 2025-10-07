module immediate_generator (
  input  logic [31:0] instruction,
  input  logic [2:0]  imm_src,
  
  output logic [31:0] immediate
);

  always_comb begin
    case (imm_src)
      3'b000: // Tipo I (ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
        immediate = {{20{instruction[31]}}, instruction[31:20]};
      
      
      default:
        immediate = 32'd0;
    endcase
  end

endmodule