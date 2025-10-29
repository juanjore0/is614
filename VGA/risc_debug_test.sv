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
    logic [25:0] tick; // para temporizar cambios
    logic [4:0] rot_idx;
    // Inicialización de los registros demo
    initial begin
        integer i;
        for (i=0; i<32; i=i+1) regs_demo[i] = 32'(i) * 32'h11111111;
    end
    // Cambia cíclicamente los registros y resalta el cambiado
    always_ff @(posedge clock or posedge sw0) begin
        if (sw0) begin
            tick <= 0;
            rot_idx <= 0;
            changed_mask <= 0;
        end else begin
            tick <= tick + 1;
            if (tick[20]) begin
                tick <= 0;
                changed_mask <= 0;
                rot_idx <= rot_idx + 1;
                regs_demo[rot_idx] <= regs_demo[rot_idx] + 32'h01010101;
                changed_mask[rot_idx] <= 1'b1;
            end else begin
                changed_mask <= 0;
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
