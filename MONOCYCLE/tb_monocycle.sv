`timescale 1ns/1ps

module tb_monocycle;

  // Señales del testbench
  logic        clk;
  logic        reset;
  logic [31:0] initial_pc;
  logic        tr;
  logic [31:0] pc_out;
  logic [31:0] instruction_out;
  
  // Instancia del DUT (Device Under Test)
  monocycle dut (
    .clk(clk),
    .reset(reset),
    .initial_pc(initial_pc),
    .tr(tr),
    .pc_out(pc_out),
    .instruction_out(instruction_out)
  );
  
  // Generador de reloj (periodo de 10ns = 100MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Variables para control
  int cycle_count = 0;
  
  // Contador de ciclos
  always @(posedge clk) begin
    if (!reset) begin
      cycle_count++;
    end
  end
  
  // Proceso de prueba
  initial begin
    $display("========================================");
    $display("   TESTBENCH MONOCICLO - TIPO R");
    $display("========================================\n");
    
    // Inicialización
    reset = 1;
    initial_pc = 32'h00000000;
    tr = 0;  // Desactivar trace inicialmente
    
    // Aplicar reset
    #15;
    reset = 0;
    $display("Reset liberado en t=%0t", $time);
    $display("PC inicial: 0x%08h\n", pc_out);
    
    // Ejecutar 15 ciclos (12 instrucciones + margen)
    repeat(15) begin
      @(posedge clk);
      #1; // Pequeño delay para estabilizar señales
      
      $display("----------------------------------------");
      $display("Ciclo %0d | Tiempo: %0t", cycle_count, $time);
      $display("PC: 0x%08h", pc_out);
      $display("Instrucción: 0x%08h", instruction_out);
      
      // Decodificar y mostrar la instrucción
      decode_and_display(instruction_out);
      
      $display("");
    end
    
    // Mostrar estado final de los registros
    $display("\n========================================");
    $display("   ESTADO FINAL DE REGISTROS");
    $display("========================================");
    tr = 1; // Activar trace para mostrar registros
    @(posedge clk);
    #1;
    tr = 0;
    
    $display("\n========================================");
    $display("   SIMULACIÓN COMPLETADA");
    $display("========================================");
    $display("Total de ciclos ejecutados: %0d", cycle_count);
    $display("Tiempo total: %0t", $time);
    
    #20;
    $finish;
  end
  
  // Task para decodificar y mostrar instrucciones
  task decode_and_display(input logic [31:0] instr);
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;
    string operation;
    
    opcode = instr[6:0];
    rd     = instr[11:7];
    funct3 = instr[14:12];
    rs1    = instr[19:15];
    rs2    = instr[24:20];
    funct7 = instr[31:25];
    
    if (opcode == 7'b0110011) begin
      // Tipo R
      case ({funct7[5], funct3})
        4'b0000: operation = "ADD";
        4'b1000: operation = "SUB";
        4'b0001: operation = "SLL";
        4'b0010: operation = "SLT";
        4'b0011: operation = "SLTU";
        4'b0100: operation = "XOR";
        4'b0101: operation = "SRL";
        4'b1101: operation = "SRA";
        4'b0110: operation = "OR";
        4'b0111: operation = "AND";
        default: operation = "UNKNOWN";
      endcase
      
      $display("Tipo: R");
      $display("Operación: %s x%0d, x%0d, x%0d", operation, rd, rs1, rs2);
      $display("  opcode=0x%02h, rd=%0d, func3=0x%01h, rs1=%0d, rs2=%0d, func7=0x%02h",
               opcode, rd, funct3, rs1, rs2, funct7);
    end else begin
      $display("Tipo: NO TIPO R (opcode=0x%02h)", opcode);
    end
  endtask
  
  // Monitor de señales críticas
  initial begin
    $monitor("T=%0t | PC=0x%08h | Instr=0x%08h", 
             $time, pc_out, instruction_out);
  end
  
  // Generación de archivo VCD para GTKWave (opcional)
  initial begin
    $dumpfile("tb_monocycle.vcd");
    $dumpvars(0, tb_monocycle);
  end

endmodule