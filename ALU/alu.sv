module alu (
  input  logic [31:0] operand1,   // Operando 1 (32 bits)
  input  logic [31:0] operand2,   // Operando 2 (32 bits)
  input  logic [2:0]  funct3,     // ← CAMBIAR de func3 a funct3
  input  logic subsra,            // Control extra: SUB/ADD o SRA/SRL
  output logic [31:0] result      // Resultado de la operación
);

  logic signed [31:0] signed_op1;  // Variable auxiliar signed
  
  always_comb begin
    signed_op1 = operand1;  // Conversión a signed
    
    case (funct3)  // ← CAMBIAR aquí también
      3'b000: // ADD o SUB
        result = subsra ? (operand1 - operand2) : (operand1 + operand2);
      
      3'b001: // Shift Left Logical (SLL)
        result = operand1 << operand2[4:0]; // Solo 5 bits para shift en RV32
      
      3'b010: // Set Less Than (signed)
        result = ($signed(operand1) < $signed(operand2)) ? 32'd1 : 32'd0;
      
      3'b011: // Set Less Than Unsigned (SLTU)
        result = (operand1 < operand2) ? 32'd1 : 32'd0;
      
      3'b100: // XOR
        result = operand1 ^ operand2;
      
      3'b101: // Shift Right Logical (SRL) o Shift Right Arithmetic (SRA)
        if (subsra)
          result = signed_op1 >>> operand2[4:0];
        else
          result = operand1 >> operand2[4:0];
      
      3'b110: // OR
        result = operand1 | operand2;
      
      3'b111: // AND
        result = operand1 & operand2;
      
      default: // Por seguridad
        result = 32'd0;
    endcase
  end

endmodule