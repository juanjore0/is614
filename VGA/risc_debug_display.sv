// ============================================================
// risc_debug_display.sv (REGISTERS view added)
// Display de Debug para RISC-V - Vista de registros x0..x31
// ============================================================

module risc_debug_display(
    input  logic        clock,                 // 50 MHz
    input  logic        sw0,                   // reset
    input  logic        sw1, sw2, sw3, sw4, sw5,

    // Demo-only: registros simulados
    input  logic [31:0] regs_demo [0:31],
    input  logic [31:0] changed_mask,         // bit i = registro i ha cambiado recientemente

    // Salidas VGA
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

    clock1280x800 vgaclock(
        .clock50(clock),
        .reset(sw0),
        .vgaclk(vgaclk)
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
    // Parámetros y ventanas
    // ============================================================
    localparam int CHAR_W = 8;
    localparam int CHAR_H = 16;

    // Ventana REGISTERS: ocupa gran área lado derecho
    localparam int REG_X  = 40;               // px
    localparam int REG_Y  = 40;               // px
    localparam int REG_COLS = 44;             // caracteres por columna aprox
    localparam int REG_ROWS = 18;             // líneas visibles
    localparam int REG_W  = REG_COLS * CHAR_W;
    localparam int REG_H  = (REG_ROWS + 2) * CHAR_H; // +2 para título y línea

    // Doble columna de 16 regs cada una
    localparam int REG_COL_SPACING = (REG_COLS+2)*CHAR_W; // espacio entre columnas

    // Área total de dos columnas
    localparam int REG2_W = REG_W*1 + REG_COL_SPACING + REG_W*1;

    logic in_regs;
    assign in_regs = (x >= REG_X && x < REG_X + REG2_W && y >= REG_Y && y < REG_Y + REG_H);

    // Coordenadas relativas dentro de la ventana de registros
    logic [10:0] rx; logic [9:0] ry;
    always_comb begin
        rx = (x >= REG_X) ? (x - REG_X) : 11'd0;
        ry = (y >= REG_Y) ? (y - REG_Y) : 10'd0;
    end

    // Posición de caracter
    logic [6:0] ch_col; // hasta ~88 cols con dos columnas
    logic [5:0] ch_row; // ~20 filas
    assign ch_col = rx / CHAR_W;
    assign ch_row = ry / CHAR_H;

    assign row_in_char = ry % CHAR_H;
    assign col_in_char = rx % CHAR_W;

    // ============================================================
    // Utilidades de texto
    // ============================================================
    function automatic [7:0] to_hex(input [3:0] nib);
        to_hex = (nib < 10) ? (8'd48 + nib) : (8'd55 + nib); // '0'..'9','A'..'F'
    endfunction

    function automatic [7:0] to_dec2(input integer v);
        // convierte 0..31 a dos dígitos ('00'..'31'), devuelve primer dígito para col actual
        to_dec2 = 8'd48 + v; // no se usa aquí; se ensamblan manualmente abajo
    endfunction

    // Nombre ABI por índice xN en 3 chars máx (relleno con espacios)
    function automatic [23:0] abi_name3(input int idx);
        // devuelve {c0,c1,c2} en ASCII
        case (idx)
            0:  abi_name3 = {"z","e","r"}; // zero -> abreviado
            1:  abi_name3 = {"r","a"," "};
            2:  abi_name3 = {"s","p"," "};
            3:  abi_name3 = {"g","p"," "};
            4:  abi_name3 = {"t","p"," "};
            5:  abi_name3 = {"t","0"," "};
            6:  abi_name3 = {"t","1"," "};
            7:  abi_name3 = {"t","2"," "};
            8:  abi_name3 = {"s","0"," "};
            9:  abi_name3 = {"s","1"," "};
            10: abi_name3 = {"a","0"," "};
            11: abi_name3 = {"a","1"," "};
            12: abi_name3 = {"a","2"," "};
            13: abi_name3 = {"a","3"," "};
            14: abi_name3 = {"a","4"," "};
            15: abi_name3 = {"a","5"," "};
            16: abi_name3 = {"a","6"," "};
            17: abi_name3 = {"a","7"," "};
            18: abi_name3 = {"s","2"," "};
            19: abi_name3 = {"s","3"," "};
            20: abi_name3 = {"s","4"," "};
            21: abi_name3 = {"s","5"," "};
            22: abi_name3 = {"s","6"," "};
            23: abi_name3 = {"s","7"," "};
            24: abi_name3 = {"s","8"," "};
            25: abi_name3 = {"s","9"," "};
            26: abi_name3 = {"s","1"}; // devuelve 3 chars; completar
            27: abi_name3 = {"s","1","1"};
            28: abi_name3 = {"t","3"," "};
            29: abi_name3 = {"t","4"," "};
            30: abi_name3 = {"t","5"," "};
            31: abi_name3 = {"t","6"," "};
            default: abi_name3 = {" "," "," "};
        endcase
    endfunction

    // ============================================================
    // Selección de qué caracter emitir en cada posición de la ventana
    // Formato por línea: "abi (xNN): 0xXXXXXXXX"
    // Dos columnas: col0 usa ch_col 0..(REG_COLS-1), col1 desplazada por REG_COL_SPACING/CHAR_W
    // ============================================================

    // Determinar columna y fila
    logic right_col;
    logic [5:0] row_idx; // 0..15 -> x0..x15 en izq, x16..x31 en der
    always_comb begin
        right_col = (rx >= REG_W + REG_COL_SPACING/2); // punto de corte aproximado
        row_idx   = (ch_row >= 2) ? (ch_row - 2) : 0; // dejar 2 líneas para título y separador
    end

    // Índice de registro que corresponde a esta fila/columna
    int reg_idx;
    always_comb begin
        if (row_idx < 16) begin
            reg_idx = right_col ? (row_idx + 16) : row_idx;
        end else begin
            reg_idx = -1; // fuera de rango
        end
    end

    // Componer caracteres
    logic [23:0] abi3;
    logic [31:0] rv;
    logic        reg_changed;
    always_comb begin
        ascii_code = 8'd32; // espacio por defecto
        if (!in_regs) disable_regs: begin end else begin
            // Título y línea
            if (ch_row == 0) begin
                case (ch_col)
                    0: ascii_code = "R";
                    1: ascii_code = "E";
                    2: ascii_code = "G";
                    3: ascii_code = "I";
                    4: ascii_code = "S";
                    5: ascii_code = "T";
                    6: ascii_code = "E";
                    7: ascii_code = "R";
                    8: ascii_code = "S";
                    default: ascii_code = 8'd32;
                endcase
            end else if (ch_row == 1) begin
                ascii_code = 8'd45; // '-'
            end else if (reg_idx >= 0) begin
                abi3        = abi_name3(reg_idx);
                rv          = regs_demo[reg_idx];
                reg_changed = changed_mask[reg_idx];

                // Horizontal offset por columna
                int base_col;
                base_col = right_col ? (REG_COLS + 2) : 0;
                // Columnas lógicas dentro del bloque
                int c = ch_col - base_col;

                // abi (3 chars)
                if (c == 0)      ascii_code = abi3[23:16];
                else if (c == 1) ascii_code = abi3[15:8];
                else if (c == 2) ascii_code = abi3[7:0];
                // espacio
                else if (c == 3) ascii_code = 8'd32;
                // (
                else if (c == 4) ascii_code = "(";
                // x
                else if (c == 5) ascii_code = "x";
                // dec NN
                else if (c == 6) ascii_code = 8'd48 + (reg_idx/10);
                else if (c == 7) ascii_code = 8'd48 + (reg_idx%10);
                // )
                else if (c == 8) ascii_code = ")";
                // :
                else if (c == 9) ascii_code = ":";
                else if (c == 10) ascii_code = 8'd32;
                // 0x
                else if (c == 11) ascii_code = "0";
                else if (c == 12) ascii_code = "x";
                // 8 hex nibbles
                else if (c >= 13 && c <= 20) begin
                    int idx = 31 - 4*(c-13);
                    ascii_code = to_hex(rv[idx -: 4]);
                end else begin
                    ascii_code = 8'd32;
                end
            end
        end
    end

    // ============================================================
    // Color de salida: destaca registros cambiados
    // ============================================================
    always_comb begin
        if (~videoOn) begin
            {vga_red, vga_green, vga_blue} = 24'h000000;
        end else if (in_regs && pixel_on) begin
            // Si este pixel pertenece a una línea de un registro que cambió, usa blanco; si no, gris claro
            logic use_highlight;
            use_highlight = 1'b0;
            if (ch_row >= 2 && ch_row < 18) begin
                int rid = right_col ? (ch_row-2+16) : (ch_row-2);
                if (rid >=0 && rid < 32) use_highlight = changed_mask[rid];
            end
            if (use_highlight) {vga_red, vga_green, vga_blue} = 24'hFFFFFF; else {vga_red, vga_green, vga_blue} = 24'hC0C0C0;
        end else if (in_regs) begin
            {vga_red, vga_green, vga_blue} = 24'h202020; // fondo ventana
        end else begin
            {vga_red, vga_green, vga_blue} = 24'h000000; // fondo general
        end
    end

endmodule
