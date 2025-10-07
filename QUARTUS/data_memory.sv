module data_memory (
  input  logic        clk,
  input  logic [31:0] address,      // Dirección de memoria
  input  logic [31:0] write_data,   // Datos a escribir
  input  logic        write_enable, // Habilitador de escritura
  input  logic [2:0]  dm_ctrl,      // Control de tamaño y signo
  
  output logic [31:0] read_data     // Datos leídos
);

  // Memoria de datos - 64 palabras (256 bytes)
  logic [31:0] memory [0:63];
  
  // Señales intermedias para lectura
  logic [31:0] raw_data;
  logic [7:0]  byte_data;
  logic [15:0] half_data;
  
  // Dirección word-aligned
  logic [5:0] word_addr;
  assign word_addr = address[7:2];
  
  // Selección de byte y halfword
  logic [1:0] byte_offset;
  assign byte_offset = address[1:0];
  
  // Lectura de palabra completa
  assign raw_data = memory[word_addr];
  
  // Extracción de byte según offset
  always_comb begin
    case (byte_offset)
      2'b00: byte_data = raw_data[7:0];
      2'b01: byte_data = raw_data[15:8];
      2'b10: byte_data = raw_data[23:16];
      2'b11: byte_data = raw_data[31:24];
    endcase
  end
  
  // Extracción de halfword según offset
  always_comb begin
    case (address[1])
      1'b0: half_data = raw_data[15:0];
      1'b1: half_data = raw_data[31:16];
    endcase
  end
  
  // Control de lectura según dm_ctrl
  always_comb begin
    case (dm_ctrl)
      3'b000: // LB - Load Byte (con signo)
        read_data = {{24{byte_data[7]}}, byte_data};
      
      3'b001: // LH - Load Halfword (con signo)
        read_data = {{16{half_data[15]}}, half_data};
      
      3'b010: // LW - Load Word
        read_data = raw_data;
      
      3'b100: // LBU - Load Byte Unsigned
        read_data = {24'b0, byte_data};
      
      3'b101: // LHU - Load Halfword Unsigned
        read_data = {16'b0, half_data};
      
      default:
        read_data = raw_data;
    endcase
  end
  
  // Escritura síncrona (para futuras instrucciones Store)
  always_ff @(posedge clk) begin
    if (write_enable) begin
      case (dm_ctrl)
        3'b000: begin // SB - Store Byte
          case (byte_offset)
            2'b00: memory[word_addr][7:0]   <= write_data[7:0];
            2'b01: memory[word_addr][15:8]  <= write_data[7:0];
            2'b10: memory[word_addr][23:16] <= write_data[7:0];
            2'b11: memory[word_addr][31:24] <= write_data[7:0];
          endcase
        end
        
        3'b001: begin // SH - Store Halfword
          case (address[1])
            1'b0: memory[word_addr][15:0]  <= write_data[15:0];
            1'b1: memory[word_addr][31:16] <= write_data[15:0];
          endcase
        end
        
        3'b010: begin // SW - Store Word
          memory[word_addr] <= write_data;
        end
      endcase
    end
  end
  
  // Inicialización con datos de prueba
  initial begin
    // Inicializar algunos valores para testing
    memory[0]  = 32'h12345678;  // Dirección 0x00
    memory[1]  = 32'hABCDEF00;  // Dirección 0x04
    memory[2]  = 32'h00000064;  // Dirección 0x08 = 100 decimal
    memory[3]  = 32'hFFFFFFFF;  // Dirección 0x0C = -1
    memory[4]  = 32'h000000FF;  // Dirección 0x10 = 255
    memory[5]  = 32'h80000000;  // Dirección 0x14 = número negativo
    
    // Resto en cero
    for (int i = 6; i < 64; i++) begin
      memory[i] = 32'h00000000;
    end
    
    $display("=== Memoria de datos inicializada ===");
  end

endmodule