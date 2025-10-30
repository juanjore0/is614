// ============================================================
// risc_debug_display.sv - VERSIÓN CORREGIDA
// Muestra registros x00-x15 con highlighting
// ============================================================

module risc_debug_display(
    input  logic        clock,
    input  logic        sw0,
    input  logic        sw1, sw2, sw3, sw4, sw5,

    input  logic [31:0] regs_demo [0:31],
    input  logic [31:0] changed_mask,

    output logic [7:0]  vga_red,
    output logic [7:0]  vga_green,
    output logic [7:0]  vga_blue,
    output logic        vga_hsync,
    output logic        vga_vsync,
    output logic        vga_clock
);

    // ============================================================
    // Señales VGA base
    // ============================================================
    logic [10:0] x;
    logic [9:0]  y;
    logic        videoOn;
    logic        vgaclk;

    vgaClock vgaclock(
        .ref_clk_clk(clock),         // 50MHz input
        .ref_reset_reset(sw0),       // reset input
        .vga_clk_clk(vgaclk),        // VGA clock output
        .reset_source_reset()        // unused reset output
    );
    assign vga_clock = vgaclk;

    vga_controller_1280x800 ctrl(
        .clk(vgaclk),
        .reset(sw0),
        .video_on(videoOn),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .hcount(x),
        .vcount(y)
    );

    // ============================================================
    // Font renderer
    // ============================================================
    logic [7:0] ascii_code;
    logic [3:0] row_in_char;
    logic [2:0] col_in_char;
    logic       pixel_on;

    font_renderer font_inst (
        .clk(vgaclk),
        .ascii_code(ascii_code),
        .row_in_char(row_in_char),
        .col_in_char(col_in_char),
        .pixel_on(pixel_on)
    );

    // ============================================================
    // Parámetros de ventana
    // ============================================================
    localparam CHAR_W = 8;
    localparam CHAR_H = 16;
    localparam START_X = 100;
    localparam START_Y = 50;
    localparam WIN_W = 20 * CHAR_W;  // "x00: 0x12345678" = 20 chars
    localparam WIN_H = 18 * CHAR_H;  // 16 registros + título + línea

    logic in_window;
    assign in_window = (x >= START_X && x < START_X + WIN_W && 
                       y >= START_Y && y < START_Y + WIN_H);

    // Coordenadas relativas
    logic [10:0] rel_x;
    logic [9:0]  rel_y;
    assign rel_x = in_window ? (x - START_X) : 11'd0;
    assign rel_y = in_window ? (y - START_Y) : 10'd0;

    // Posición de carácter
    logic [5:0] char_col;
    logic [4:0] char_row;
    assign char_col = rel_x / CHAR_W;
    assign char_row = rel_y / CHAR_H;
    assign row_in_char = rel_y[3:0]; // rel_y % 16
    assign col_in_char = rel_x[2:0]; // rel_x % 8

    // Índice de registro
    logic [4:0] reg_idx;
    assign reg_idx = (char_row >= 2) ? (char_row - 2) : 5'd0;

    // ============================================================
    // Función hex
    // ============================================================
    function automatic [7:0] to_hex(input [3:0] nib);
        case (nib)
            4'h0: return "0";   4'h1: return "1";
            4'h2: return "2";   4'h3: return "3";
            4'h4: return "4";   4'h5: return "5";
            4'h6: return "6";   4'h7: return "7";
            4'h8: return "8";   4'h9: return "9";
            4'hA: return "A";   4'hB: return "B";
            4'hC: return "C";   4'hD: return "D";
            4'hE: return "E";   4'hF: return "F";
            default: return "?";
        endcase
    endfunction

    // ============================================================
    // Generación de texto
    // ============================================================
    always_comb begin
        ascii_code = 8'd32; // espacio por defecto
        
        if (in_window) begin
            if (char_row == 0) begin
                // Título "REGISTERS"
                case (char_col)
                    6'd0: ascii_code = "R";
                    6'd1: ascii_code = "E";
                    6'd2: ascii_code = "G";
                    6'd3: ascii_code = "I";
                    6'd4: ascii_code = "S";
                    6'd5: ascii_code = "T";
                    6'd6: ascii_code = "E";
                    6'd7: ascii_code = "R";
                    6'd8: ascii_code = "S";
                    default: ascii_code = 8'd32;
                endcase
            end else if (char_row == 1) begin
                // Línea separadora
                ascii_code = 8'd45; // '-'
            end else if (char_row >= 2 && char_row < 18) begin
                // Formato: "x00: 0x12345678"
                case (char_col)
                    6'd0: ascii_code = "x";
                    6'd1: ascii_code = 8'd48 + 8'(reg_idx / 10); // Cast explícito
                    6'd2: ascii_code = 8'd48 + 8'(reg_idx % 10);
                    6'd3: ascii_code = ":";
                    6'd4: ascii_code = 8'd32;  // espacio
                    6'd5: ascii_code = "0";
                    6'd6: ascii_code = "x";
                    // 8 dígitos hex
                    6'd7:  ascii_code = to_hex(regs_demo[reg_idx][31:28]);
                    6'd8:  ascii_code = to_hex(regs_demo[reg_idx][27:24]);
                    6'd9:  ascii_code = to_hex(regs_demo[reg_idx][23:20]);
                    6'd10: ascii_code = to_hex(regs_demo[reg_idx][19:16]);
                    6'd11: ascii_code = to_hex(regs_demo[reg_idx][15:12]);
                    6'd12: ascii_code = to_hex(regs_demo[reg_idx][11:8]);
                    6'd13: ascii_code = to_hex(regs_demo[reg_idx][7:4]);
                    6'd14: ascii_code = to_hex(regs_demo[reg_idx][3:0]);
                    default: ascii_code = 8'd32;
                endcase
            end
        end
    end

    // ============================================================
    // Colores
    // ============================================================
    always_comb begin
        if (~videoOn) begin
            {vga_red, vga_green, vga_blue} = 24'h000000; // negro
        end else if (in_window && pixel_on) begin
            // Resaltar registros cambiados
            if (char_row >= 2 && char_row < 18 && changed_mask[reg_idx]) begin
                {vga_red, vga_green, vga_blue} = 24'hFFFF00; // amarillo (más visible)
            end else begin
                {vga_red, vga_green, vga_blue} = 24'hC0C0C0; // gris claro
            end
        end else if (in_window) begin
            {vga_red, vga_green, vga_blue} = 24'h202020; // fondo gris oscuro
        end else begin
            {vga_red, vga_green, vga_blue} = 24'h000000; // fondo negro
        end
    end

endmodule