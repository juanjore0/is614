// ============================================================
// risc_debug_display.sv - DISPLAY COMPLETO DE DEBUG
// VERSIÓN COMPATIBLE CON QUARTUS (SIN VARIABLES LOCALES EN ALWAYS_COMB)
// CORRECCIÓN: Inversión de índices de registros para display
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
    
    // Memoria 
    input  logic [31:0] memory [0:63],


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
    // SINCRONIZACIÓN CDC
    // ============================================================
    logic [31:0] regs_sync1 [0:31];
    logic [31:0] pc_sync1, instruction_sync1;
    logic [31:0] alu_a_sync1, alu_b_sync1, alu_r_sync1;
    logic [31:0] imm_sync1;
    logic [31:0] mem_sync1 [0:63];
    
    always_ff @(posedge clock) begin
        regs_sync1 <= regs_demo;
        pc_sync1 <= pc_value;
        instruction_sync1 <= instruction;
        alu_a_sync1 <= alu_operand_a;
        alu_b_sync1 <= alu_operand_b;
        alu_r_sync1 <= alu_result;
        imm_sync1 <= immediate;
        mem_sync1 <= memory;
    end
    
    logic [31:0] regs_vga [0:31];
    logic [31:0] pc_vga, instruction_vga;
    logic [31:0] alu_a_vga, alu_b_vga, alu_r_vga;
    logic [31:0] imm_vga;
    logic [31:0] mem_vga [0:63];
    
    always_ff @(posedge vgaclk) begin
        regs_vga <= regs_sync1;
        pc_vga <= pc_sync1;
        instruction_vga <= instruction_sync1;
        alu_a_vga <= alu_a_sync1;
        alu_b_vga <= alu_b_sync1;
        alu_r_vga <= alu_r_sync1;
        imm_vga <= imm_sync1;
        mem_vga <= mem_sync1;
    end


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


    localparam CHAR_W = 8;
    localparam CHAR_H = 16;
    
    // ============================================================
    // VENTANA 1: REGISTROS
    // ============================================================
    localparam REG_X = 10;
    localparam REG_Y = 10;
    localparam REG_COL_WIDTH = 21;
    localparam REG_W = REG_COL_WIDTH * 2 * CHAR_W;
    localparam REG_H = 18 * CHAR_H;
    
    logic in_reg_window;
    logic [10:0] reg_rel_x, reg_rel_y;
    logic [5:0] reg_char_col;
    logic [4:0] reg_char_row;
    logic reg_column_sel;
    logic [5:0] reg_local_col;
    logic [4:0] reg_idx;
    logic [4:0] actual_reg_idx;  // ← NUEVO: índice real invertido
    
    assign in_reg_window = (x >= REG_X && x < REG_X + REG_W && y >= REG_Y && y < REG_Y + REG_H);
    assign reg_rel_x = in_reg_window ? (x - REG_X) : 11'd0;
    assign reg_rel_y = in_reg_window ? (y - REG_Y) : 10'd0;
    assign reg_char_col = reg_rel_x / CHAR_W;
    assign reg_char_row = reg_rel_y / CHAR_H;
    assign reg_column_sel = (reg_char_col >= REG_COL_WIDTH);
    assign reg_local_col = reg_column_sel ? (reg_char_col - REG_COL_WIDTH) : reg_char_col;
    assign reg_idx = reg_column_sel ? (reg_char_row - 2 + 5'd16) : (reg_char_row - 2);
    assign actual_reg_idx = 5'd31 - reg_idx;  // ← CORRECCIÓN: Invertir el índice
    
    // ============================================================
    // VENTANA 2: PC E INSTRUCCIÓN
    // ============================================================
    localparam INFO_X = 360;
    localparam INFO_Y = 10;
    localparam INFO_W = 25 * CHAR_W;
    localparam INFO_H = 6 * CHAR_H;
    
    logic in_info_window;
    logic [10:0] info_rel_x;
    logic [9:0] info_rel_y;
    logic [5:0] info_char_col;
    logic [4:0] info_char_row;
    
    assign in_info_window = (x >= INFO_X && x < INFO_X + INFO_W && y >= INFO_Y && y < INFO_Y + INFO_H);
    assign info_rel_x = in_info_window ? (x - INFO_X) : 11'd0;
    assign info_rel_y = in_info_window ? (y - INFO_Y) : 10'd0;
    assign info_char_col = info_rel_x / CHAR_W;
    assign info_char_row = info_rel_y / CHAR_H;
    
    // ============================================================
    // VENTANA 3: ALU
    // ============================================================
    localparam ALU_X = 360;
    localparam ALU_Y = 120;
    localparam ALU_W = 25 * CHAR_W;
    localparam ALU_H = 8 * CHAR_H;
    
    logic in_alu_window;
    logic [10:0] alu_rel_x;
    logic [9:0] alu_rel_y;
    logic [5:0] alu_char_col;
    logic [4:0] alu_char_row;
    
    assign in_alu_window = (x >= ALU_X && x < ALU_X + ALU_W && y >= ALU_Y && y < ALU_Y + ALU_H);
    assign alu_rel_x = in_alu_window ? (x - ALU_X) : 11'd0;
    assign alu_rel_y = in_alu_window ? (y - ALU_Y) : 10'd0;
    assign alu_char_col = alu_rel_x / CHAR_W;
    assign alu_char_row = alu_rel_y / CHAR_H;
    
    // ============================================================
    // VENTANA 4: MEMORIA
    // ============================================================
    localparam MEM_X = 10;
    localparam MEM_Y = 310;
    localparam MEM_W = 60 * CHAR_W;
    localparam MEM_H = 18 * CHAR_H;
    
    logic in_mem_window;
    logic [10:0] mem_rel_x;
    logic [9:0] mem_rel_y;
    logic [5:0] mem_char_col;
    logic [4:0] mem_char_row;
    
    // Variables para memoria (declaradas fuera de always_comb)
    logic [5:0] mem_display_idx;
    logic [1:0] mem_column;
    logic [3:0] mem_row_offset;
    logic [3:0] mem_col_pos;
    
    assign in_mem_window = (x >= MEM_X && x < MEM_X + MEM_W && y >= MEM_Y && y < MEM_Y + MEM_H);
    assign mem_rel_x = in_mem_window ? (x - MEM_X) : 11'd0;
    assign mem_rel_y = in_mem_window ? (y - MEM_Y) : 10'd0;
    assign mem_char_col = mem_rel_x / CHAR_W;
    assign mem_char_row = mem_rel_y / CHAR_H;
    
    // Calcular índices de memoria
    assign mem_row_offset = (mem_char_row >= 2) ? (mem_char_row - 2) : 4'd0;
    
    always_comb begin
        if (mem_char_col < 15) begin
            mem_column = 0;
            mem_display_idx = mem_row_offset;
        end else if (mem_char_col < 30) begin
            mem_column = 1;
            mem_display_idx = 16 + mem_row_offset;
        end else if (mem_char_col < 45) begin
            mem_column = 2;
            mem_display_idx = 32 + mem_row_offset;
        end else if (mem_char_col < 60) begin
            mem_column = 3;
            mem_display_idx = 48 + mem_row_offset;
        end else begin
            mem_column = 0;
            mem_display_idx = 0;
        end
        
        mem_col_pos = mem_char_col - (mem_column * 15);
    end
    
    // ============================================================
    // Posición dentro del carácter
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
        ascii_code = 8'd32;
        
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
                    // ← CORRECCIÓN: Usar actual_reg_idx (invertido) para acceder al array
                    6'd7:  ascii_code = to_hex(regs_vga[actual_reg_idx][31:28]);
                    6'd8:  ascii_code = to_hex(regs_vga[actual_reg_idx][27:24]);
                    6'd9:  ascii_code = to_hex(regs_vga[actual_reg_idx][23:20]);
                    6'd10: ascii_code = to_hex(regs_vga[actual_reg_idx][19:16]);
                    6'd11: ascii_code = to_hex(regs_vga[actual_reg_idx][15:12]);
                    6'd12: ascii_code = to_hex(regs_vga[actual_reg_idx][11:8]);
                    6'd13: ascii_code = to_hex(regs_vga[actual_reg_idx][7:4]);
                    6'd14: ascii_code = to_hex(regs_vga[actual_reg_idx][3:0]);
                    default: ascii_code = 8'd32;
                endcase
            end
        end
        
        else if (in_info_window) begin
            case (info_char_row)
                5'd0: begin
                    case (info_char_col)
                        6'd0: ascii_code = "P"; 6'd1: ascii_code = "C";
                        6'd3: ascii_code = "&";
                        6'd5: ascii_code = "I"; 6'd6: ascii_code = "N"; 6'd7: ascii_code = "S";
                        6'd8: ascii_code = "T"; 6'd9: ascii_code = "R";
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd1: if (info_char_col < 20) ascii_code = 8'd45;
                5'd2: begin
                    case (info_char_col)
                        6'd0: ascii_code = "P"; 6'd1: ascii_code = "C"; 6'd2: ascii_code = ":";
                        6'd4: ascii_code = "0"; 6'd5: ascii_code = "x";
                        6'd6:  ascii_code = to_hex(pc_vga[31:28]);
                        6'd7:  ascii_code = to_hex(pc_vga[27:24]);
                        6'd8:  ascii_code = to_hex(pc_vga[23:20]);
                        6'd9:  ascii_code = to_hex(pc_vga[19:16]);
                        6'd10: ascii_code = to_hex(pc_vga[15:12]);
                        6'd11: ascii_code = to_hex(pc_vga[11:8]);
                        6'd12: ascii_code = to_hex(pc_vga[7:4]);
                        6'd13: ascii_code = to_hex(pc_vga[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd3: begin
                    case (info_char_col)
                        6'd0: ascii_code = "I"; 6'd1: ascii_code = "R"; 6'd2: ascii_code = ":";
                        6'd4: ascii_code = "0"; 6'd5: ascii_code = "x";
                        6'd6:  ascii_code = to_hex(instruction_vga[31:28]);
                        6'd7:  ascii_code = to_hex(instruction_vga[27:24]);
                        6'd8:  ascii_code = to_hex(instruction_vga[23:20]);
                        6'd9:  ascii_code = to_hex(instruction_vga[19:16]);
                        6'd10: ascii_code = to_hex(instruction_vga[15:12]);
                        6'd11: ascii_code = to_hex(instruction_vga[11:8]);
                        6'd12: ascii_code = to_hex(instruction_vga[7:4]);
                        6'd13: ascii_code = to_hex(instruction_vga[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd4: begin
                    case (info_char_col)
                        6'd0: ascii_code = "I"; 6'd1: ascii_code = "M"; 6'd2: ascii_code = "M"; 6'd3: ascii_code = ":";
                        6'd5: ascii_code = "0"; 6'd6: ascii_code = "x";
                        6'd7:  ascii_code = to_hex(imm_vga[31:28]);
                        6'd8:  ascii_code = to_hex(imm_vga[27:24]);
                        6'd9:  ascii_code = to_hex(imm_vga[23:20]);
                        6'd10: ascii_code = to_hex(imm_vga[19:16]);
                        6'd11: ascii_code = to_hex(imm_vga[15:12]);
                        6'd12: ascii_code = to_hex(imm_vga[11:8]);
                        6'd13: ascii_code = to_hex(imm_vga[7:4]);
                        6'd14: ascii_code = to_hex(imm_vga[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                default: ascii_code = 8'd32;
            endcase
        end
        
        else if (in_alu_window) begin
            case (alu_char_row)
                5'd0: begin
                    case (alu_char_col)
                        6'd0: ascii_code = "A"; 6'd1: ascii_code = "L"; 6'd2: ascii_code = "U";
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd1: if (alu_char_col < 20) ascii_code = 8'd45;
                5'd2: begin
                    case (alu_char_col)
                        6'd0: ascii_code = "A"; 6'd1: ascii_code = ":";
                        6'd3: ascii_code = "0"; 6'd4: ascii_code = "x";
                        6'd5:  ascii_code = to_hex(alu_a_vga[31:28]);
                        6'd6:  ascii_code = to_hex(alu_a_vga[27:24]);
                        6'd7:  ascii_code = to_hex(alu_a_vga[23:20]);
                        6'd8:  ascii_code = to_hex(alu_a_vga[19:16]);
                        6'd9:  ascii_code = to_hex(alu_a_vga[15:12]);
                        6'd10: ascii_code = to_hex(alu_a_vga[11:8]);
                        6'd11: ascii_code = to_hex(alu_a_vga[7:4]);
                        6'd12: ascii_code = to_hex(alu_a_vga[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd3: begin
                    case (alu_char_col)
                        6'd0: ascii_code = "B"; 6'd1: ascii_code = ":";
                        6'd3: ascii_code = "0"; 6'd4: ascii_code = "x";
                        6'd5:  ascii_code = to_hex(alu_b_vga[31:28]);
                        6'd6:  ascii_code = to_hex(alu_b_vga[27:24]);
                        6'd7:  ascii_code = to_hex(alu_b_vga[23:20]);
                        6'd8:  ascii_code = to_hex(alu_b_vga[19:16]);
                        6'd9:  ascii_code = to_hex(alu_b_vga[15:12]);
                        6'd10: ascii_code = to_hex(alu_b_vga[11:8]);
                        6'd11: ascii_code = to_hex(alu_b_vga[7:4]);
                        6'd12: ascii_code = to_hex(alu_b_vga[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd4: if (alu_char_col < 13) ascii_code = 8'd45;
                5'd5: begin
                    case (alu_char_col)
                        6'd0: ascii_code = "R"; 6'd1: ascii_code = ":";
                        6'd3: ascii_code = "0"; 6'd4: ascii_code = "x";
                        6'd5:  ascii_code = to_hex(alu_r_vga[31:28]);
                        6'd6:  ascii_code = to_hex(alu_r_vga[27:24]);
                        6'd7:  ascii_code = to_hex(alu_r_vga[23:20]);
                        6'd8:  ascii_code = to_hex(alu_r_vga[19:16]);
                        6'd9:  ascii_code = to_hex(alu_r_vga[15:12]);
                        6'd10: ascii_code = to_hex(alu_r_vga[11:8]);
                        6'd11: ascii_code = to_hex(alu_r_vga[7:4]);
                        6'd12: ascii_code = to_hex(alu_r_vga[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                default: ascii_code = 8'd32;
            endcase
        end
        
        else if (in_mem_window) begin
            if (mem_char_row == 0) begin
                case (mem_char_col)
                    6'd0: ascii_code = "M"; 6'd1: ascii_code = "E"; 6'd2: ascii_code = "M";
                    6'd3: ascii_code = "O"; 6'd4: ascii_code = "R"; 6'd5: ascii_code = "Y";
                    6'd7: ascii_code = "("; 6'd8: ascii_code = "6"; 6'd9: ascii_code = "4";
                    6'd10: ascii_code = ")";
                    default: ascii_code = 8'd32;
                endcase
            end else if (mem_char_row == 1) begin
                ascii_code = (mem_char_col < 60) ? 8'd45 : 8'd32;
            end else if (mem_char_row >= 2 && mem_char_row < 18 && mem_char_col < 60) begin
                case (mem_col_pos)
                    4'd0: ascii_code = "[";
                    4'd1: ascii_code = 8'd48 + (mem_display_idx / 10);
                    4'd2: ascii_code = 8'd48 + (mem_display_idx % 10);
                    4'd3: ascii_code = "]";
                    4'd4: ascii_code = ":";
                    4'd5: ascii_code = "0";
                    4'd6: ascii_code = "x";
                    4'd7:  ascii_code = to_hex(mem_vga[mem_display_idx][31:28]);
                    4'd8:  ascii_code = to_hex(mem_vga[mem_display_idx][27:24]);
                    4'd9:  ascii_code = to_hex(mem_vga[mem_display_idx][23:20]);
                    4'd10: ascii_code = to_hex(mem_vga[mem_display_idx][19:16]);
                    4'd11: ascii_code = to_hex(mem_vga[mem_display_idx][15:12]);
                    4'd12: ascii_code = to_hex(mem_vga[mem_display_idx][11:8]);
                    4'd13: ascii_code = to_hex(mem_vga[mem_display_idx][7:4]);
                    4'd14: ascii_code = to_hex(mem_vga[mem_display_idx][3:0]);
                    default: ascii_code = 8'd32;
                endcase
            end else begin
                ascii_code = 8'd32;
            end
        end
    end
    
    // ============================================================
    // Colores
    // ============================================================
    always_comb begin
        if (~videoOn) begin
            {vga_red, vga_green, vga_blue} = 24'h000000;
        end else if (pixel_on) begin
            {vga_red, vga_green, vga_blue} = 24'hFFFFFF;
        end else begin
            {vga_red, vga_green, vga_blue} = 24'h000000;
        end
    end


endmodule
