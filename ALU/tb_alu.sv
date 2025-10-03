`timescale 1ns/1ps

module tb_alu;
  
  // Señales del testbench
  logic [31:0] operand1;
  logic [31:0] operand2;
  logic [2:0]  func3;
  logic        subsra;
  logic [31:0] result;
  logic [31:0] expected;
  
  // Instancia del DUT (Device Under Test)
  alu dut (
    .operand1(operand1),
    .operand2(operand2),
    .func3(func3),
    .subsra(subsra),
    .result(result)
  );
  
  // Variables para verificación
  int errors = 0;
  int tests = 0;
  
  // Task para verificar resultados
  task check_result(input logic [31:0] exp, input string operation);
    tests++;
    if (result !== exp) begin
      $display("ERROR en %s: operand1=%h, operand2=%h, func3=%b, subsra=%b", 
               operation, operand1, operand2, func3, subsra);
      $display("  Esperado: %h, Obtenido: %h", exp, result);
      errors++;
    end else begin
      $display("OK: %s - Resultado: %h", operation, result);
    end
  endtask
  
  initial begin
    $display("=== Iniciando testbench de ALU ===\n");
    
    // Test 1: ADD (func3=000, subsra=0)
    $display("--- Test ADD ---");
    operand1 = 32'h0000_0010;
    operand2 = 32'h0000_0005;
    func3 = 3'b000;
    subsra = 1'b0;
    #10;
    expected = 32'h0000_0015;
    check_result(expected, "ADD");
    
    // Test 2: SUB (func3=000, subsra=1)
    $display("\n--- Test SUB ---");
    operand1 = 32'h0000_0010;
    operand2 = 32'h0000_0005;
    func3 = 3'b000;
    subsra = 1'b1;
    #10;
    expected = 32'h0000_000B;
    check_result(expected, "SUB");
    
    // Test 3: SLL - Shift Left Logical (func3=001)
    $display("\n--- Test SLL ---");
    operand1 = 32'h0000_0001;
    operand2 = 32'h0000_0004; // shift 4 posiciones
    func3 = 3'b001;
    subsra = 1'b0;
    #10;
    expected = 32'h0000_0010;
    check_result(expected, "SLL");
    
    // Test 4: SLT - Set Less Than (signed) (func3=010)
    $display("\n--- Test SLT (signed) ---");
    operand1 = 32'hFFFF_FFFF; // -1 en complemento a 2
    operand2 = 32'h0000_0001;
    func3 = 3'b010;
    subsra = 1'b0;
    #10;
    expected = 32'h0000_0001; // -1 < 1 = true
    check_result(expected, "SLT (negativo < positivo)");
    
    operand1 = 32'h0000_0005;
    operand2 = 32'h0000_0003;
    #10;
    expected = 32'h0000_0000; // 5 < 3 = false
    check_result(expected, "SLT (mayor < menor)");
    
    // Test 5: SLTU - Set Less Than Unsigned (func3=011)
    $display("\n--- Test SLTU (unsigned) ---");
    operand1 = 32'hFFFF_FFFF; // Gran número sin signo
    operand2 = 32'h0000_0001;
    func3 = 3'b011;
    subsra = 1'b0;
    #10;
    expected = 32'h0000_0000; // 0xFFFFFFFF > 1 en unsigned
    check_result(expected, "SLTU (grande > pequeño)");
    
    operand1 = 32'h0000_0002;
    operand2 = 32'h0000_0005;
    #10;
    expected = 32'h0000_0001; // 2 < 5 = true
    check_result(expected, "SLTU (pequeño < grande)");
    
    // Test 6: XOR (func3=100)
    $display("\n--- Test XOR ---");
    operand1 = 32'h0F0F_0F0F;
    operand2 = 32'hFFFF_FFFF;
    func3 = 3'b100;
    subsra = 1'b0;
    #10;
    expected = 32'hF0F0_F0F0;
    check_result(expected, "XOR");
    
    // Test 7: SRL - Shift Right Logical (func3=101, subsra=0)
    $display("\n--- Test SRL ---");
    operand1 = 32'h8000_0000;
    operand2 = 32'h0000_0004; // shift 4 posiciones
    func3 = 3'b101;
    subsra = 1'b0;
    #10;
    expected = 32'h0800_0000;
    check_result(expected, "SRL");
    
    // Test 8: SRA - Shift Right Arithmetic (func3=101, subsra=1)
    $display("\n--- Test SRA ---");
    operand1 = 32'h8000_0000; // Número negativo
    operand2 = 32'h0000_0004;
    func3 = 3'b101;
    subsra = 1'b1;
    #10;
    expected = 32'hF800_0000; // Mantiene el signo
    check_result(expected, "SRA");
    
    // Test 9: OR (func3=110)
    $display("\n--- Test OR ---");
    operand1 = 32'h0F0F_0F0F;
    operand2 = 32'hF0F0_F0F0;
    func3 = 3'b110;
    subsra = 1'b0;
    #10;
    expected = 32'hFFFF_FFFF;
    check_result(expected, "OR");
    
    // Test 10: AND (func3=111)
    $display("\n--- Test AND ---");
    operand1 = 32'hFFFF_FFFF;
    operand2 = 32'h0F0F_0F0F;
    func3 = 3'b111;
    subsra = 1'b0;
    #10;
    expected = 32'h0F0F_0F0F;
    check_result(expected, "AND");
    
    // Test 11: Verificar que solo se usan 5 bits para shift
    $display("\n--- Test límite de shift (5 bits) ---");
    operand1 = 32'h0000_0001;
    operand2 = 32'h0000_0025; // 37 decimal, pero solo se usan 5 bits = 5
    func3 = 3'b001;
    subsra = 1'b0;
    #10;
    expected = 32'h0000_0020; // shift de 5 posiciones
    check_result(expected, "SLL con límite 5 bits");
    
    // Resumen de resultados
    $display("\n=== Resumen de Tests ===");
    $display("Tests ejecutados: %0d", tests);
    $display("Tests exitosos: %0d", tests - errors);
    $display("Tests fallidos: %0d", errors);
    
    if (errors == 0)
      $display("\n¡Todos los tests pasaron exitosamente!");
    else
      $display("\nSe encontraron errores. Revisar el diseño.");
    
    $finish;
  end
  
endmodule