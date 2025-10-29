// ============================================================
// risc_debug_test.sv
// Módulo de prueba para el display de debug RISC-V
// Genera datos simulados para probar la visualización
// ============================================================

module risc_debug_test(
    input logic clock,                 // 50 MHz clock
    input logic sw0,                   // reset
    input logic sw1, sw2, sw3, sw4, sw5,
    
    // Salidas VGA
    output logic [7:0] vga_red,
    output logic [7:0] vga_green,
    output logic [7:0] vga_blue,
    output logic vga_hsync,
    output logic vga_vsync,
    output logic vga_clock
);

    // ============================================================
    // Generación de datos simulados para debug
    // ============================================================
    logic [31:0] sim_pc = 32'h00001000;
    logic [31:0] sim_instruction = 32'h00000013;  // NOP
    logic [31:0] sim_alu_result = 32'h12345678;
    logic [31:0] sim_reg_data1 = 32'hAABBCCDD;
    logic [31:0] sim_reg_data2 = 32'h11223344;
    logic [31:0] sim_mem_data = 32'hDEADBEEF;
    logic [31:0] sim_clock_counter;
    
    // Contador de ciclos de reloj
    always_ff @(posedge clock or posedge sw0) begin
        if (sw0) begin
            sim_clock_counter <= 0;
        end else begin
            sim_clock_counter <= sim_clock_counter + 1;
            
            // Simular cambios en los datos cada cierto tiempo
            if (sim_clock_counter[19:0] == 0) begin // cada ~1M ciclos
                sim_pc <= sim_pc + 4;
                sim_instruction <= sim_instruction + 32'h11111111;
                sim_alu_result <= sim_alu_result + 32'h12345678;
                sim_reg_data1 <= {sim_reg_data1[30:0], sim_reg_data1[31]}; // rotate
                sim_reg_data2 <= sim_reg_data2 ^ 32'hFFFFFFFF;             // toggle
                sim_mem_data <= sim_mem_data + 32'h00000001;
            end
        end
    end
    
    // ============================================================
    // Instanciar el display de debug
    // ============================================================
    risc_debug_display debug_display(
        .clock(clock),
        .sw0(sw0),
        .sw1(sw1),
        .sw2(sw2),
        .sw3(sw3),
        .sw4(sw4),
        .sw5(sw5),
        
        // Datos simulados del RISC-V
        .pc(sim_pc),
        .instruction(sim_instruction),
        .alu_result(sim_alu_result),
        .reg_data1(sim_reg_data1),
        .reg_data2(sim_reg_data2),
        .mem_data(sim_mem_data),
        .clock_counter(sim_clock_counter),
        
        // Salidas VGA
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_clock(vga_clock)
    );

endmodule