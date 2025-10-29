// ============================================================
// risc_debug_test.sv (registradores demo para VGA)
// Demo de registros RISC-V para display de VGA
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
    logic [31:0] regs_demo [0:31];
    logic [31:0] changed_mask;
    logic [23:0] counter;  // contador para temporizar cambios
    logic [4:0] active_reg; // registro activo que cambia

    // Cambia cíclicamente los registros y resalta el cambiado
    always_ff @(posedge clock or posedge sw0) begin
        if (sw0) begin
            // Valores iniciales pequeños y distintivos para evitar caracteres raros
            regs_demo[0]  <= 32'h00000000;  // x0 = zero
            regs_demo[1]  <= 32'h12345678;  // x1 = ra  
            regs_demo[2]  <= 32'h87654321;  // x2 = sp
            regs_demo[3]  <= 32'h11111111;  // x3 = gp
            regs_demo[4]  <= 32'h22222222;  // x4 = tp
            regs_demo[5]  <= 32'h33333333;  // x5 = t0
            regs_demo[6]  <= 32'h44444444;  // x6 = t1
            regs_demo[7]  <= 32'h55555555;  // x7 = t2
            regs_demo[8]  <= 32'h66666666;  // x8 = s0
            regs_demo[9]  <= 32'h77777777;  // x9 = s1
            regs_demo[10] <= 32'hAAAABBBB;  // x10 = a0
            regs_demo[11] <= 32'hCCCCDDDD;  // x11 = a1
            regs_demo[12] <= 32'hEEEEFFFF;  // x12 = a2
            regs_demo[13] <= 32'h12340000;  // x13 = a3
            regs_demo[14] <= 32'h56780000;  // x14 = a4
            regs_demo[15] <= 32'h9ABC0000;  // x15 = a5
            regs_demo[16] <= 32'hDEF00000;  // x16 = a6
            regs_demo[17] <= 32'h00001234;  // x17 = a7
            regs_demo[18] <= 32'h00005678;  // x18 = s2
            regs_demo[19] <= 32'h00009ABC;  // x19 = s3
            regs_demo[20] <= 32'h0000DEF0;  // x20 = s4
            regs_demo[21] <= 32'h11110000;  // x21 = s5
            regs_demo[22] <= 32'h22220000;  // x22 = s6
            regs_demo[23] <= 32'h33330000;  // x23 = s7
            regs_demo[24] <= 32'h44440000;  // x24 = s8
            regs_demo[25] <= 32'h55550000;  // x25 = s9
            regs_demo[26] <= 32'h66660000;  // x26 = s10
            regs_demo[27] <= 32'h77770000;  // x27 = s11
            regs_demo[28] <= 32'h88880000;  // x28 = t3
            regs_demo[29] <= 32'h99990000;  // x29 = t4
            regs_demo[30] <= 32'hAAAA0000;  // x30 = t5
            regs_demo[31] <= 32'hBBBB0000;  // x31 = t6
            
            counter <= 0;
            active_reg <= 0;
            changed_mask <= 0;
        end else begin
            counter <= counter + 1;
            
            // Cada ~16M ciclos cambia un registro (ajusta según velocidad deseada)
            if (counter[23:20] == 4'hF && counter[19:0] == 0) begin
                active_reg <= active_reg + 1;
                regs_demo[active_reg] <= regs_demo[active_reg] + 32'h00000001; // incremento pequeño
                changed_mask[active_reg] <= 1'b1;
            end else if (counter[19:16] == 4'h1) begin
                changed_mask <= 0; // apagar highlight después de un tiempo
            end
        end
    end

    risc_debug_display debug_display(
        .clock(clock),
        .sw0(sw0),
        .sw1(sw1), .sw2(sw2), .sw3(sw3), .sw4(sw4), .sw5(sw5),
        .regs_demo(regs_demo),
        .changed_mask(changed_mask),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_clock(vga_clock)
    );
endmodule
