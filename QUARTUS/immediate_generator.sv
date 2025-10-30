module immediate_generator (
  input  logic [31:0] instruction,
  input  logic [2:0]  imm_src,
  
  output logic [31:0] immediate
);

  always_comb begin
    case (imm_src)
      3'b000: // Tipo I (ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
        immediate = {{20{instruction[31]}}, instruction[31:20]};
		      
		3'b001: begin // Tipo S (STORE) 
        // imm[11:5] = instruction[31:25]
        // imm[4:0]  = instruction[11:7]
        immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
		end
      
      3'b100: begin // Tipo U (LUI, AUIPC)
        // imm[31:12] = instruction[31:12]
        // imm[11:0]  = 0 (ceros en bits bajos)
        immediate = {instruction[31:12], 12'b0};	  
		  
      end
      
      
      default:
        immediate = 32'd0;
    endcase
  end

endmodule