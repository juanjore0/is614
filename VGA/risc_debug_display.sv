// ============================================================
// risc_debug_display.sv (REGISTERS view added) - Quartus-pure always_comb
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
    localparam int REG2_W = REG_W + REG_COL_SPACING + REG_W;

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
            26: abi_name3 = {"s","1","0"};
            27: abi_name3 = {"s","1","1"};
            28: abi_name3 = {"t","3"," "};
            29: abi_name3 = {"t","4"," "};
            30: abi_name3 = {"t","5"," "};
            31: abi_name3 = {"t","6"," "};
            default: abi_name3 = {" "," "," "};
        endcase
    endfunction

    // ============================================================
    // Señales auxiliares precomputadas (evitar ints dentro de always)
    // ============================================================
    logic        right_col;
    logic [5:0]  row_idx;
    assign right_col = (rx >= REG_W + (REG_COL_SPACING>>1));
    assign row_idx   = (ch_row >= 6'd2) ? (ch_row - 6'd2) : 6'd0; // dejar 2 líneas para título

    // Índice de registro para esta fila/columna
    integer reg_idx;
    always_comb begin
        if (row_idx < 16) reg_idx = right_col ? (row_idx + 16) : row_idx;
        else              reg_idx = -1;
    end

    // Cálculo de columnas lógicas sin variables locales en always
    wire [6:0] base_col_w = right_col ? (REG_COLS + 7'd2) : 7'd0;
    wire signed [7:0] c_w = $signed({1'b0,ch_col}) - $signed({1'b0,base_col_w});

    // Prepara datos a mostrar
    logic [23:0] abi3;
    logic [31:0] rv;
    logic        reg_changed;

    // ============================================================
    // Generación de caracteres (pure combinational)
    // ============================================================
    always_comb begin
        ascii_code = 8'd32; // por defecto
        if (in_regs) begin
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
                // abi (3 chars)
                if (c_w == 0)       ascii_code = abi3[23:16];
                else if (c_w == 1)  ascii_code = abi3[15:8];
                else if (c_w == 2)  ascii_code = abi3[7:0];
                else if (c_w == 3)  ascii_code = 8'd32;      // espacio
                else if (c_w == 4)  ascii_code = "(";
                else if (c_w == 5)  ascii_code = "x";
                else if (c_w == 6)  ascii_code = 8'd48 + (reg_idx/10);
                else if (c_w == 7)  ascii_code = 8'd48 + (reg_idx%10);
                else if (c_w == 8)  ascii_code = ")";
                else if (c_w == 9)  ascii_code = ":";
                else if (c_w == 10) ascii_code = 8'd32;
                else if (c_w == 11) ascii_code = "0";
                else if (c_w == 12) ascii_code = "x";
                else if (c_w >= 13 && c_w <= 20) begin
                    logic [4:0] nib_sel;
                    nib_sel = 31 - 4*(c_w-13);
                    ascii_code = to_hex(rv[nib_sel -: 4]);
                end else begin
                    ascii_code = 8'd32;
                end
            end
        end
    end

    // ============================================================
    // Color de salida: destaca registros cambiados (pure combinational)
    // ============================================================
    // rid calculado sin variables locales
    wire signed [7:0] rid_w = right_col ? ($signed({1'b0,ch_row}) - 8'sd2 + 8'sd16)
                                        : ($signed({1'b0,ch_row}) - 8'sd2);

    always_comb begin
        if (~videoOn) begin
            {vga_red, vga_green, vga_blue} = 24'h000000;
        end else if (in_regs && pixel_on) begin
            logic use_highlight;
            use_highlight = 1'b0;
            if (ch_row >= 2 && ch_row < 18) begin
                if (rid_w >= 0 && rid_w < 32) use_highlight = changed_mask[rid_w];
            end
            if (use_highlight) {vga_red, vga_green, vga_blue} = 24'hFFFFFF; else {vga_red, vga_green, vga_blue} = 24'hC0C0C0;
        end else if (in_regs) begin
            {vga_red, vga_green, vga_blue} = 24'h202020; // fondo ventana
        end else begin
            {vga_red, vga_green, vga_blue} = 24'h000000; // fondo general
        end
    end

endmodule
