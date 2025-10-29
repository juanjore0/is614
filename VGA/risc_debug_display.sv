// ============================================================
// risc_debug_display.sv
// Display de Debug para RISC-V - Muestra múltiples ventanas de información
// Compatible con resolución 1280x800
// ============================================================

module risc_debug_display(
    input logic clock,                 // 50 MHz clock
    input logic sw0,                   // reset
    input logic sw1, sw2, sw3, sw4, sw5, // switches para control
    
    // Entradas de debug desde RISC-V
    input logic [31:0] pc,            // Program Counter
    input logic [31:0] instruction,   // Instrucción actual
    input logic [31:0] alu_result,    // Resultado de ALU
    input logic [31:0] reg_data1,     // Datos registro 1
    input logic [31:0] reg_data2,     // Datos registro 2
    input logic [31:0] mem_data,      // Datos de memoria
    input logic [31:0] clock_counter, // Contador de ciclos
    
    // Salidas VGA
    output logic [7:0] vga_red,
    output logic [7:0] vga_green,
    output logic [7:0] vga_blue,
    output logic vga_hsync,
    output logic vga_vsync,
    output logic vga_clock
);

    // ============================================================
    // Señales VGA
    // ============================================================
    logic [10:0] x;
    logic [9:0]  y;
    logic videoOn;
    logic vgaclk;

    // PLL VGA
    clock1280x800 vgaclock(
        .clock50(clock),
        .reset(sw0),
        .vgaclk(vgaclk)
    );

    assign vga_clock = vgaclk;

    // Controlador VGA
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
    // Sistema de renderizado de texto
    // ============================================================
    logic [7:0] ascii_code;
    logic [3:0] row_in_char;
    logic [2:0] col_in_char;
    logic pixel_on;

    font_renderer font_inst (
        .clk(vgaclk),
        .ascii_code(ascii_code),
        .row_in_char(row_in_char),
        .col_in_char(col_in_char),
        .pixel_on(pixel_on)
    );

    // ============================================================
    // Definición de ventanas de debug
    // ============================================================
    parameter CHAR_W = 8;
    parameter CHAR_H = 16;
    parameter MARGIN = 10;
    
    // Ventana 1: PC y Instrucción (esquina superior izquierda)
    parameter WIN1_X = MARGIN;
    parameter WIN1_Y = MARGIN;
    parameter WIN1_W = 40 * CHAR_W; // 40 caracteres de ancho
    parameter WIN1_H = 6 * CHAR_H;  // 6 líneas de alto
    
    // Ventana 2: ALU y Registros (esquina superior derecha)
    parameter WIN2_X = WIN1_X + WIN1_W + MARGIN;
    parameter WIN2_Y = MARGIN;
    parameter WIN2_W = 40 * CHAR_W;
    parameter WIN2_H = 8 * CHAR_H;
    
    // Ventana 3: Memoria de datos (esquina inferior izquierda)
    parameter WIN3_X = MARGIN;
    parameter WIN3_Y = WIN1_Y + WIN1_H + MARGIN;
    parameter WIN3_W = 40 * CHAR_W;
    parameter WIN3_H = 10 * CHAR_H;
    
    // Ventana 4: Clock y estado (esquina inferior derecha)
    parameter WIN4_X = WIN2_X;
    parameter WIN4_Y = WIN2_Y + WIN2_H + MARGIN;
    parameter WIN4_W = 40 * CHAR_W;
    parameter WIN4_H = 4 * CHAR_H;

    // ============================================================
    // Detección de ventanas activas
    // ============================================================
    logic in_win1, in_win2, in_win3, in_win4;
    
    assign in_win1 = (x >= WIN1_X && x < WIN1_X + WIN1_W && y >= WIN1_Y && y < WIN1_Y + WIN1_H);
    assign in_win2 = (x >= WIN2_X && x < WIN2_X + WIN2_W && y >= WIN2_Y && y < WIN2_Y + WIN2_H);
    assign in_win3 = (x >= WIN3_X && x < WIN3_X + WIN3_W && y >= WIN3_Y && y < WIN3_Y + WIN3_H);
    assign in_win4 = (x >= WIN4_X && x < WIN4_X + WIN4_W && y >= WIN4_Y && y < WIN4_Y + WIN4_H);
    
    logic in_any_window;
    assign in_any_window = in_win1 || in_win2 || in_win3 || in_win4;

    // ============================================================
    // Cálculo de posición de caracter en ventana activa
    // ============================================================
    logic [5:0] char_col, char_row;
    logic [10:0] rel_x;
    logic [9:0]  rel_y;
    
    always_comb begin
        if (in_win1) begin
            rel_x = x - WIN1_X;
            rel_y = y - WIN1_Y;
        end else if (in_win2) begin
            rel_x = x - WIN2_X;
            rel_y = y - WIN2_Y;
        end else if (in_win3) begin
            rel_x = x - WIN3_X;
            rel_y = y - WIN3_Y;
        end else if (in_win4) begin
            rel_x = x - WIN4_X;
            rel_y = y - WIN4_Y;
        end else begin
            rel_x = 0;
            rel_y = 0;
        end
        
        char_col = rel_x / CHAR_W;
        char_row = rel_y / CHAR_H;
    end
    
    assign row_in_char = rel_y % CHAR_H;
    assign col_in_char = rel_x % CHAR_W;

    // ============================================================
    // Función para convertir nibble a ASCII hex
    // ============================================================
    function [7:0] nibble_to_ascii(input [3:0] nibble);
        if (nibble < 10)
            nibble_to_ascii = 8'd48 + nibble;  // '0'-'9'
        else
            nibble_to_ascii = 8'd65 + nibble - 10; // 'A'-'F'
    endfunction

    // ============================================================
    // Generación de contenido de texto
    // ============================================================
    always_comb begin
        ascii_code = 8'd32; // espacio por defecto
        
        if (in_win1) begin
            // Ventana 1: PC e Instrucción
            case (char_row)
                0: begin // Título
                    case (char_col)
                        0: ascii_code = 8'd80;  // P
                        1: ascii_code = 8'd67;  // C
                        2: ascii_code = 8'd32;  // espacio
                        3: ascii_code = 8'd38;  // &
                        4: ascii_code = 8'd32;  // espacio
                        5: ascii_code = 8'd73;  // I
                        6: ascii_code = 8'd78;  // N
                        7: ascii_code = 8'd83;  // S
                        8: ascii_code = 8'd84;  // T
                        9: ascii_code = 8'd82;  // R
                        10: ascii_code = 8'd85; // U
                        11: ascii_code = 8'd67; // C
                        12: ascii_code = 8'd84; // T
                        13: ascii_code = 8'd73; // I
                        14: ascii_code = 8'd79; // O
                        15: ascii_code = 8'd78; // N
                        default: ascii_code = 8'd32;
                    endcase
                end
                1: ascii_code = 8'd45; // línea separadora '-'
                2: begin // PC: valor
                    case (char_col)
                        0: ascii_code = 8'd80;  // P
                        1: ascii_code = 8'd67;  // C
                        2: ascii_code = 8'd58;  // :
                        3: ascii_code = 8'd32;  // espacio
                        4: ascii_code = 8'd48;  // 0
                        5: ascii_code = 8'd120; // x
                        6: ascii_code = nibble_to_ascii(pc[31:28]);
                        7: ascii_code = nibble_to_ascii(pc[27:24]);
                        8: ascii_code = nibble_to_ascii(pc[23:20]);
                        9: ascii_code = nibble_to_ascii(pc[19:16]);
                        10: ascii_code = nibble_to_ascii(pc[15:12]);
                        11: ascii_code = nibble_to_ascii(pc[11:8]);
                        12: ascii_code = nibble_to_ascii(pc[7:4]);
                        13: ascii_code = nibble_to_ascii(pc[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                3: begin // Instrucción: valor
                    case (char_col)
                        0: ascii_code = 8'd73;  // I
                        1: ascii_code = 8'd78;  // N
                        2: ascii_code = 8'd83;  // S
                        3: ascii_code = 8'd84;  // T
                        4: ascii_code = 8'd58;  // :
                        5: ascii_code = 8'd32;  // espacio
                        6: ascii_code = 8'd48;  // 0
                        7: ascii_code = 8'd120; // x
                        8: ascii_code = nibble_to_ascii(instruction[31:28]);
                        9: ascii_code = nibble_to_ascii(instruction[27:24]);
                        10: ascii_code = nibble_to_ascii(instruction[23:20]);
                        11: ascii_code = nibble_to_ascii(instruction[19:16]);
                        12: ascii_code = nibble_to_ascii(instruction[15:12]);
                        13: ascii_code = nibble_to_ascii(instruction[11:8]);
                        14: ascii_code = nibble_to_ascii(instruction[7:4]);
                        15: ascii_code = nibble_to_ascii(instruction[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                default: ascii_code = 8'd32;
            endcase
        end
        
        else if (in_win2) begin
            // Ventana 2: ALU y Registros
            case (char_row)
                0: begin // Título ALU
                    case (char_col)
                        0: ascii_code = 8'd65;  // A
                        1: ascii_code = 8'd76;  // L
                        2: ascii_code = 8'd85;  // U
                        3: ascii_code = 8'd32;  // espacio
                        4: ascii_code = 8'd38;  // &
                        5: ascii_code = 8'd32;  // espacio
                        6: ascii_code = 8'd82;  // R
                        7: ascii_code = 8'd69;  // E
                        8: ascii_code = 8'd71;  // G
                        9: ascii_code = 8'd83;  // S
                        default: ascii_code = 8'd32;
                    endcase
                end
                1: ascii_code = 8'd45; // línea separadora
                2: begin // ALU Result
                    case (char_col)
                        0: ascii_code = 8'd65;  // A
                        1: ascii_code = 8'd76;  // L
                        2: ascii_code = 8'd85;  // U
                        3: ascii_code = 8'd58;  // :
                        4: ascii_code = 8'd32;  // espacio
                        5: ascii_code = 8'd48;  // 0
                        6: ascii_code = 8'd120; // x
                        7: ascii_code = nibble_to_ascii(alu_result[31:28]);
                        8: ascii_code = nibble_to_ascii(alu_result[27:24]);
                        9: ascii_code = nibble_to_ascii(alu_result[23:20]);
                        10: ascii_code = nibble_to_ascii(alu_result[19:16]);
                        11: ascii_code = nibble_to_ascii(alu_result[15:12]);
                        12: ascii_code = nibble_to_ascii(alu_result[11:8]);
                        13: ascii_code = nibble_to_ascii(alu_result[7:4]);
                        14: ascii_code = nibble_to_ascii(alu_result[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                3: begin // Registro 1
                    case (char_col)
                        0: ascii_code = 8'd82;  // R
                        1: ascii_code = 8'd49;  // 1
                        2: ascii_code = 8'd58;  // :
                        3: ascii_code = 8'd32;  // espacio
                        4: ascii_code = 8'd48;  // 0
                        5: ascii_code = 8'd120; // x
                        6: ascii_code = nibble_to_ascii(reg_data1[31:28]);
                        7: ascii_code = nibble_to_ascii(reg_data1[27:24]);
                        8: ascii_code = nibble_to_ascii(reg_data1[23:20]);
                        9: ascii_code = nibble_to_ascii(reg_data1[19:16]);
                        10: ascii_code = nibble_to_ascii(reg_data1[15:12]);
                        11: ascii_code = nibble_to_ascii(reg_data1[11:8]);
                        12: ascii_code = nibble_to_ascii(reg_data1[7:4]);
                        13: ascii_code = nibble_to_ascii(reg_data1[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                4: begin // Registro 2
                    case (char_col)
                        0: ascii_code = 8'd82;  // R
                        1: ascii_code = 8'd50;  // 2
                        2: ascii_code = 8'd58;  // :
                        3: ascii_code = 8'd32;  // espacio
                        4: ascii_code = 8'd48;  // 0
                        5: ascii_code = 8'd120; // x
                        6: ascii_code = nibble_to_ascii(reg_data2[31:28]);
                        7: ascii_code = nibble_to_ascii(reg_data2[27:24]);
                        8: ascii_code = nibble_to_ascii(reg_data2[23:20]);
                        9: ascii_code = nibble_to_ascii(reg_data2[19:16]);
                        10: ascii_code = nibble_to_ascii(reg_data2[15:12]);
                        11: ascii_code = nibble_to_ascii(reg_data2[11:8]);
                        12: ascii_code = nibble_to_ascii(reg_data2[7:4]);
                        13: ascii_code = nibble_to_ascii(reg_data2[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                default: ascii_code = 8'd32;
            endcase
        end
        
        else if (in_win3) begin
            // Ventana 3: Memoria de datos
            case (char_row)
                0: begin // Título
                    case (char_col)
                        0: ascii_code = 8'd68;  // D
                        1: ascii_code = 8'd65;  // A
                        2: ascii_code = 8'd84;  // T
                        3: ascii_code = 8'd65;  // A
                        4: ascii_code = 8'd32;  // espacio
                        5: ascii_code = 8'd77;  // M
                        6: ascii_code = 8'd69;  // E
                        7: ascii_code = 8'd77;  // M
                        8: ascii_code = 8'd79;  // O
                        9: ascii_code = 8'd82;  // R
                        10: ascii_code = 8'd89; // Y
                        default: ascii_code = 8'd32;
                    endcase
                end
                1: ascii_code = 8'd45; // línea separadora
                2: begin // Datos de memoria
                    case (char_col)
                        0: ascii_code = 8'd77;  // M
                        1: ascii_code = 8'd69;  // E
                        2: ascii_code = 8'd77;  // M
                        3: ascii_code = 8'd58;  // :
                        4: ascii_code = 8'd32;  // espacio
                        5: ascii_code = 8'd48;  // 0
                        6: ascii_code = 8'd120; // x
                        7: ascii_code = nibble_to_ascii(mem_data[31:28]);
                        8: ascii_code = nibble_to_ascii(mem_data[27:24]);
                        9: ascii_code = nibble_to_ascii(mem_data[23:20]);
                        10: ascii_code = nibble_to_ascii(mem_data[19:16]);
                        11: ascii_code = nibble_to_ascii(mem_data[15:12]);
                        12: ascii_code = nibble_to_ascii(mem_data[11:8]);
                        13: ascii_code = nibble_to_ascii(mem_data[7:4]);
                        14: ascii_code = nibble_to_ascii(mem_data[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                default: ascii_code = 8'd32;
            endcase
        end
        
        else if (in_win4) begin
            // Ventana 4: Clock counter
            case (char_row)
                0: begin // Título
                    case (char_col)
                        0: ascii_code = 8'd67;  // C
                        1: ascii_code = 8'd76;  // L
                        2: ascii_code = 8'd79;  // O
                        3: ascii_code = 8'd67;  // C
                        4: ascii_code = 8'd75;  // K
                        5: ascii_code = 8'd32;  // espacio
                        6: ascii_code = 8'd67;  // C
                        7: ascii_code = 8'd79;  // O
                        8: ascii_code = 8'd85;  // U
                        9: ascii_code = 8'd78;  // N
                        10: ascii_code = 8'd84; // T
                        11: ascii_code = 8'd69; // E
                        12: ascii_code = 8'd82; // R
                        default: ascii_code = 8'd32;
                    endcase
                end
                1: ascii_code = 8'd45; // línea separadora
                2: begin // Clock counter value
                    case (char_col)
                        0: ascii_code = 8'd67;  // C
                        1: ascii_code = 8'd76;  // L
                        2: ascii_code = 8'd75;  // K
                        3: ascii_code = 8'd58;  // :
                        4: ascii_code = 8'd32;  // espacio
                        5: ascii_code = 8'd48;  // 0
                        6: ascii_code = 8'd120; // x
                        7: ascii_code = nibble_to_ascii(clock_counter[31:28]);
                        8: ascii_code = nibble_to_ascii(clock_counter[27:24]);
                        9: ascii_code = nibble_to_ascii(clock_counter[23:20]);
                        10: ascii_code = nibble_to_ascii(clock_counter[19:16]);
                        11: ascii_code = nibble_to_ascii(clock_counter[15:12]);
                        12: ascii_code = nibble_to_ascii(clock_counter[11:8]);
                        13: ascii_code = nibble_to_ascii(clock_counter[7:4]);
                        14: ascii_code = nibble_to_ascii(clock_counter[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                default: ascii_code = 8'd32;
            endcase
        end
    end

    // ============================================================
    // Color de salida VGA
    // ============================================================
    always_comb begin
        if (~videoOn) begin
            {vga_red, vga_green, vga_blue} = 24'h000000; // Negro
        end else if (in_any_window && pixel_on) begin
            // Texto blanco sobre fondo negro
            {vga_red, vga_green, vga_blue} = 24'hFFFFFF;
        end else if (in_any_window) begin
            // Fondo de ventanas - gris oscuro
            {vga_red, vga_green, vga_blue} = 24'h202020;
        end else begin
            // Fondo general - negro
            {vga_red, vga_green, vga_blue} = 24'h000000;
        end
    end

endmodule


// ============================================================
// Generador de reloj VGA (reutilizado)
// ============================================================
module clock1280x800(clock50, reset, vgaclk);
    input clock50;
    input reset;
    output vgaclk;

    wire null;
    vgaClock clk(
        .ref_clk_clk(clock50),
        .ref_reset_reset(reset),
        .reset_source_reset(null),
        .vga_clk_clk(vgaclk)
    );
endmodule


// ============================================================
// Controlador VGA 1280x800 (reutilizado)
// ============================================================
module vga_controller_1280x800 (
    input clk,
    input reset,
    output wire hsync,
    output wire vsync,
    output reg [10:0] hcount,
    output reg [9:0]  vcount,
    output video_on
);

    parameter H_VISIBLE = 1280;
    parameter H_FP      = 48;
    parameter H_SYNC    = 32;
    parameter H_BP      = 80;
    parameter H_TOTAL   = H_VISIBLE + H_FP + H_SYNC + H_BP;

    parameter V_VISIBLE = 800;
    parameter V_FP      = 3;
    parameter V_SYNC    = 6;
    parameter V_BP      = 22;
    parameter V_TOTAL   = V_VISIBLE + V_FP + V_SYNC + V_BP;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hcount <= 0;
            vcount <= 0;
        end else begin
            if (hcount == H_TOTAL - 1) begin
                hcount <= 0;
                if (vcount == V_TOTAL - 1)
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
            end else begin
                hcount <= hcount + 1;
            end
        end
    end

    assign hsync = ~((hcount >= H_VISIBLE + H_FP) && 
                     (hcount < H_VISIBLE + H_FP + H_SYNC));
    assign vsync = ~((vcount >= V_VISIBLE + V_FP) && 
                     (vcount < V_VISIBLE + V_FP + V_SYNC));
    assign video_on = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);
endmodule