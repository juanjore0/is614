// ============================================================
// risc_debug_display.sv - DISPLAY COMPLETO DE DEBUG
// Muestra: Registros, PC, Instrucción, ALU, Inmediatos, Memoria
// ============================================================

module risc_debug_display(
    input  logic        clock,
    input  logic        sw0,
    input  logic        sw1, sw2, sw3, sw4, sw5,

    // Registros
    input  logic [31:0] regs_demo [0:31],
    input  logic [31:0] changed_mask,
    
    // PC e Instrucción
    input  logic [31:0] pc_value,
    input  logic [31:0] instruction,
    
    // ALU
    input  logic [31:0] alu_operand_a,
    input  logic [31:0] alu_operand_b,
    input  logic [31:0] alu_result,
    
    // Inmediato
    input  logic [31:0] immediate,
    
    // Memoria (primeras 8 posiciones)
    input  logic [31:0] memory [0:7],

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
        .ref_clk_clk(clock),
        .ref_reset_reset(sw0),
        .vga_clk_clk(vgaclk),
        .reset_source_reset()
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
    // Parámetros de caracteres
    // ============================================================
    localparam CHAR_W = 8;
    localparam CHAR_H = 16;
    
    // ============================================================
    // VENTANA 1: REGISTROS (Izquierda, 2 columnas)
    // ============================================================
    localparam REG_X = 10;
    localparam REG_Y = 10;
    localparam REG_COL_WIDTH = 21;
    localparam REG_W = REG_COL_WIDTH * 2 * CHAR_W;  // 336px
    localparam REG_H = 18 * CHAR_H;  // 288px
    
    logic in_reg_window;
    logic [10:0] reg_rel_x;
    logic [9:0]  reg_rel_y;
    logic [5:0]  reg_char_col;
    logic [4:0]  reg_char_row;
    logic        reg_column_sel;
    logic [5:0]  reg_local_col;
    logic [4:0]  reg_idx;
    
    assign in_reg_window = (x >= REG_X && x < REG_X + REG_W && 
                           y >= REG_Y && y < REG_Y + REG_H);
    assign reg_rel_x = in_reg_window ? (x - REG_X) : 11'd0;
    assign reg_rel_y = in_reg_window ? (y - REG_Y) : 10'd0;
    assign reg_char_col = reg_rel_x / CHAR_W;
    assign reg_char_row = reg_rel_y / CHAR_H;
    assign reg_column_sel = (reg_char_col >= REG_COL_WIDTH);
    assign reg_local_col = reg_column_sel ? (reg_char_col - REG_COL_WIDTH) : reg_char_col;
    assign reg_idx = reg_column_sel ? (reg_char_row - 2 + 5'd16) : (reg_char_row - 2);
    
    // ============================================================
    // VENTANA 2: PC E INSTRUCCIÓN (Derecha arriba)
    // ============================================================
    localparam INFO_X = 360;
    localparam INFO_Y = 10;
    localparam INFO_W = 25 * CHAR_W;  // 200px
    localparam INFO_H = 6 * CHAR_H;   // 96px
    
    logic in_info_window;
    logic [10:0] info_rel_x;
    logic [9:0]  info_rel_y;
    logic [5:0]  info_char_col;
    logic [4:0]  info_char_row;
    
    assign in_info_window = (x >= INFO_X && x < INFO_X + INFO_W && 
                            y >= INFO_Y && y < INFO_Y + INFO_H);
    assign info_rel_x = in_info_window ? (x - INFO_X) : 11'd0;
    assign info_rel_y = in_info_window ? (y - INFO_Y) : 10'd0;
    assign info_char_col = info_rel_x / CHAR_W;
    assign info_char_row = info_rel_y / CHAR_H;
    
    // ============================================================
    // VENTANA 3: ALU (Derecha medio)
    // ============================================================
    localparam ALU_X = 360;
    localparam ALU_Y = 120;
    localparam ALU_W = 25 * CHAR_W;  // 200px
    localparam ALU_H = 8 * CHAR_H;   // 128px
    
    logic in_alu_window;
    logic [10:0] alu_rel_x;
    logic [9:0]  alu_rel_y;
    logic [5:0]  alu_char_col;
    logic [4:0]  alu_char_row;
    
    assign in_alu_window = (x >= ALU_X && x < ALU_X + ALU_W && 
                           y >= ALU_Y && y < ALU_Y + ALU_H);
    assign alu_rel_x = in_alu_window ? (x - ALU_X) : 11'd0;
    assign alu_rel_y = in_alu_window ? (y - ALU_Y) : 10'd0;
    assign alu_char_col = alu_rel_x / CHAR_W;
    assign alu_char_row = alu_rel_y / CHAR_H;
    
    // ============================================================
    // VENTANA 4: MEMORIA (Abajo izquierda)
    // ============================================================
    localparam MEM_X = 10;
    localparam MEM_Y = 310;
    localparam MEM_W = 25 * CHAR_W;  // 200px
    localparam MEM_H = 11 * CHAR_H;  // 176px
    
    logic in_mem_window;
    logic [10:0] mem_rel_x;
    logic [9:0]  mem_rel_y;
    logic [5:0]  mem_char_col;
    logic [4:0]  mem_char_row;
    logic [2:0]  mem_idx;
    
    assign in_mem_window = (x >= MEM_X && x < MEM_X + MEM_W && 
                           y >= MEM_Y && y < MEM_Y + MEM_H);
    assign mem_rel_x = in_mem_window ? (x - MEM_X) : 11'd0;
    assign mem_rel_y = in_mem_window ? (y - MEM_Y) : 10'd0;
    assign mem_char_col = mem_rel_x / CHAR_W;
    assign mem_char_row = mem_rel_y / CHAR_H;
    assign mem_idx = (mem_char_row >= 2) ? (mem_char_row - 2) : 3'd0;
    
    // ============================================================
    // Posición dentro del carácter (común para todas)
    // ============================================================
    logic [3:0] char_row_in;
    logic [2:0] char_col_in;
    
    always_comb begin
        if (in_reg_window) begin
            char_row_in = reg_rel_y[3:0];
            char_col_in = reg_rel_x[2:0];
        end else if (in_info_window) begin
            char_row_in = info_rel_y[3:0];
            char_col_in = info_rel_x[2:0];
        end else if (in_alu_window) begin
            char_row_in = alu_rel_y[3:0];
            char_col_in = alu_rel_x[2:0];
        end else if (in_mem_window) begin
            char_row_in = mem_rel_y[3:0];
            char_col_in = mem_rel_x[2:0];
        end else begin
            char_row_in = 4'd0;
            char_col_in = 3'd0;
        end
    end
    
    assign row_in_char = char_row_in;
    assign col_in_char = char_col_in;
    
    // ============================================================
    // Función hex
    // ============================================================
    function automatic [7:0] to_hex(input [3:0] nib);
        case (nib)
            4'h0: return "0"; 4'h1: return "1"; 4'h2: return "2"; 4'h3: return "3";
            4'h4: return "4"; 4'h5: return "5"; 4'h6: return "6"; 4'h7: return "7";
            4'h8: return "8"; 4'h9: return "9"; 4'hA: return "A"; 4'hB: return "B";
            4'hC: return "C"; 4'hD: return "D"; 4'hE: return "E"; 4'hF: return "F";
            default: return "?";
        endcase
    endfunction
    
    // ============================================================
    // Generación de texto
    // ============================================================
    always_comb begin
        ascii_code = 8'd32; // espacio por defecto
        
        // ===== VENTANA 1: REGISTROS =====
        if (in_reg_window) begin
            if (reg_char_row == 0) begin
                if (!reg_column_sel) begin
                    case (reg_local_col)
                        6'd5: ascii_code = "R"; 6'd6: ascii_code = "E"; 6'd7: ascii_code = "G";
                        6'd8: ascii_code = "I"; 6'd9: ascii_code = "S"; 6'd10: ascii_code = "T";
                        6'd11: ascii_code = "E"; 6'd12: ascii_code = "R"; 6'd13: ascii_code = "S";
                        default: ascii_code = 8'd32;
                    endcase
                end
            end else if (reg_char_row == 1) begin
                if (reg_local_col < 20) ascii_code = 8'd45;
            end else if (reg_char_row >= 2 && reg_char_row < 18) begin
                case (reg_local_col)
                    6'd0: ascii_code = "x";
                    6'd1: ascii_code = 8'd48 + 8'(reg_idx / 10);
                    6'd2: ascii_code = 8'd48 + 8'(reg_idx % 10);
                    6'd3: ascii_code = ":";
                    6'd4: ascii_code = 8'd32;
                    6'd5: ascii_code = "0";
                    6'd6: ascii_code = "x";
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
        
        // ===== VENTANA 2: PC E INSTRUCCIÓN =====
        else if (in_info_window) begin
            case (info_char_row)
                5'd0: begin // "PC & INSTRUCTION"
                    case (info_char_col)
                        6'd0: ascii_code = "P"; 6'd1: ascii_code = "C";
                        6'd3: ascii_code = "&";
                        6'd5: ascii_code = "I"; 6'd6: ascii_code = "N"; 6'd7: ascii_code = "S";
                        6'd8: ascii_code = "T"; 6'd9: ascii_code = "R";
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd1: if (info_char_col < 20) ascii_code = 8'd45;
                5'd2: begin // "PC: 0x________"
                    case (info_char_col)
                        6'd0: ascii_code = "P"; 6'd1: ascii_code = "C"; 6'd2: ascii_code = ":";
                        6'd4: ascii_code = "0"; 6'd5: ascii_code = "x";
                        6'd6:  ascii_code = to_hex(pc_value[31:28]);
                        6'd7:  ascii_code = to_hex(pc_value[27:24]);
                        6'd8:  ascii_code = to_hex(pc_value[23:20]);
                        6'd9:  ascii_code = to_hex(pc_value[19:16]);
                        6'd10: ascii_code = to_hex(pc_value[15:12]);
                        6'd11: ascii_code = to_hex(pc_value[11:8]);
                        6'd12: ascii_code = to_hex(pc_value[7:4]);
                        6'd13: ascii_code = to_hex(pc_value[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd3: begin // "IR: 0x________"
                    case (info_char_col)
                        6'd0: ascii_code = "I"; 6'd1: ascii_code = "R"; 6'd2: ascii_code = ":";
                        6'd4: ascii_code = "0"; 6'd5: ascii_code = "x";
                        6'd6:  ascii_code = to_hex(instruction[31:28]);
                        6'd7:  ascii_code = to_hex(instruction[27:24]);
                        6'd8:  ascii_code = to_hex(instruction[23:20]);
                        6'd9:  ascii_code = to_hex(instruction[19:16]);
                        6'd10: ascii_code = to_hex(instruction[15:12]);
                        6'd11: ascii_code = to_hex(instruction[11:8]);
                        6'd12: ascii_code = to_hex(instruction[7:4]);
                        6'd13: ascii_code = to_hex(instruction[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd4: begin // "IMM: 0x________"
                    case (info_char_col)
                        6'd0: ascii_code = "I"; 6'd1: ascii_code = "M"; 6'd2: ascii_code = "M"; 6'd3: ascii_code = ":";
                        6'd5: ascii_code = "0"; 6'd6: ascii_code = "x";
                        6'd7:  ascii_code = to_hex(immediate[31:28]);
                        6'd8:  ascii_code = to_hex(immediate[27:24]);
                        6'd9:  ascii_code = to_hex(immediate[23:20]);
                        6'd10: ascii_code = to_hex(immediate[19:16]);
                        6'd11: ascii_code = to_hex(immediate[15:12]);
                        6'd12: ascii_code = to_hex(immediate[11:8]);
                        6'd13: ascii_code = to_hex(immediate[7:4]);
                        6'd14: ascii_code = to_hex(immediate[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
            endcase
        end
        
        // ===== VENTANA 3: ALU =====
        else if (in_alu_window) begin
            case (alu_char_row)
                5'd0: begin // "ALU"
                    case (alu_char_col)
                        6'd0: ascii_code = "A"; 6'd1: ascii_code = "L"; 6'd2: ascii_code = "U";
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd1: if (alu_char_col < 20) ascii_code = 8'd45;
                5'd2: begin // "A: 0x________"
                    case (alu_char_col)
                        6'd0: ascii_code = "A"; 6'd1: ascii_code = ":";
                        6'd3: ascii_code = "0"; 6'd4: ascii_code = "x";
                        6'd5:  ascii_code = to_hex(alu_operand_a[31:28]);
                        6'd6:  ascii_code = to_hex(alu_operand_a[27:24]);
                        6'd7:  ascii_code = to_hex(alu_operand_a[23:20]);
                        6'd8:  ascii_code = to_hex(alu_operand_a[19:16]);
                        6'd9:  ascii_code = to_hex(alu_operand_a[15:12]);
                        6'd10: ascii_code = to_hex(alu_operand_a[11:8]);
                        6'd11: ascii_code = to_hex(alu_operand_a[7:4]);
                        6'd12: ascii_code = to_hex(alu_operand_a[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd3: begin // "B: 0x________"
                    case (alu_char_col)
                        6'd0: ascii_code = "B"; 6'd1: ascii_code = ":";
                        6'd3: ascii_code = "0"; 6'd4: ascii_code = "x";
                        6'd5:  ascii_code = to_hex(alu_operand_b[31:28]);
                        6'd6:  ascii_code = to_hex(alu_operand_b[27:24]);
                        6'd7:  ascii_code = to_hex(alu_operand_b[23:20]);
                        6'd8:  ascii_code = to_hex(alu_operand_b[19:16]);
                        6'd9:  ascii_code = to_hex(alu_operand_b[15:12]);
                        6'd10: ascii_code = to_hex(alu_operand_b[11:8]);
                        6'd11: ascii_code = to_hex(alu_operand_b[7:4]);
                        6'd12: ascii_code = to_hex(alu_operand_b[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd4: if (alu_char_col < 13) ascii_code = 8'd45;
                5'd5: begin // "R: 0x________"
                    case (alu_char_col)
                        6'd0: ascii_code = "R"; 6'd1: ascii_code = ":";
                        6'd3: ascii_code = "0"; 6'd4: ascii_code = "x";
                        6'd5:  ascii_code = to_hex(alu_result[31:28]);
                        6'd6:  ascii_code = to_hex(alu_result[27:24]);
                        6'd7:  ascii_code = to_hex(alu_result[23:20]);
                        6'd8:  ascii_code = to_hex(alu_result[19:16]);
                        6'd9:  ascii_code = to_hex(alu_result[15:12]);
                        6'd10: ascii_code = to_hex(alu_result[11:8]);
                        6'd11: ascii_code = to_hex(alu_result[7:4]);
                        6'd12: ascii_code = to_hex(alu_result[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
            endcase
        end
        
        // ===== VENTANA 4: MEMORIA =====
        else if (in_mem_window) begin
            if (mem_char_row == 0) begin
                case (mem_char_col)
                    6'd0: ascii_code = "M"; 6'd1: ascii_code = "E"; 6'd2: ascii_code = "M";
                    6'd3: ascii_code = "O"; 6'd4: ascii_code = "R"; 6'd5: ascii_code = "Y";
                    default: ascii_code = 8'd32;
                endcase
            end else if (mem_char_row == 1) begin
                if (mem_char_col < 20) ascii_code = 8'd45;
            end else if (mem_char_row >= 2 && mem_char_row < 10) begin
                case (mem_char_col)
                    6'd0: ascii_code = "[";
                    6'd1: ascii_code = 8'd48 + 8'(mem_idx);
                    6'd2: ascii_code = "]";
                    6'd3: ascii_code = ":";
                    6'd5: ascii_code = "0";
                    6'd6: ascii_code = "x";
                    6'd7:  ascii_code = to_hex(memory[mem_idx][31:28]);
                    6'd8:  ascii_code = to_hex(memory[mem_idx][27:24]);
                    6'd9:  ascii_code = to_hex(memory[mem_idx][23:20]);
                    6'd10: ascii_code = to_hex(memory[mem_idx][19:16]);
                    6'd11: ascii_code = to_hex(memory[mem_idx][15:12]);
                    6'd12: ascii_code = to_hex(memory[mem_idx][11:8]);
                    6'd13: ascii_code = to_hex(memory[mem_idx][7:4]);
                    6'd14: ascii_code = to_hex(memory[mem_idx][3:0]);
                    default: ascii_code = 8'd32;
                endcase
            end
        end
    end
    
    // ============================================================
    // Colores - SOLO BLANCO Y NEGRO
    // ============================================================
    always_comb begin
        if (~videoOn) begin
            // Fuera de área visible: negro
            {vga_red, vga_green, vga_blue} = 24'h000000;
        end else if (pixel_on) begin
            // Todo el texto en blanco
            {vga_red, vga_green, vga_blue} = 24'hFFFFFF;
        end else begin
            // Fondo: negro
            {vga_red, vga_green, vga_blue} = 24'h000000;
        end
    end

endmodule