// ============================================================
// color.v
// Controlador VGA 1280x800 + Renderizado de texto 8x16
// ============================================================

module color(
  input clock,                 // 50 MHz clock
  input sw0,                   // reset
  input sw1,
  input sw2,
  input sw3,
  input sw4,
  input sw5,
  output reg [7:0] vga_red,
  output reg [7:0] vga_green,
  output reg [7:0] vga_blue,
  output vga_hsync,
  output vga_vsync,
  output vga_clock
);

  // ============================================================
  // Señales VGA
  // ============================================================
  wire [10:0] x;
  wire [9:0]  y;
  wire videoOn;
  wire vgaclk;

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
  // Fuente 8x16
  // ============================================================
  wire [7:0] ascii_code;
  wire [3:0] row_in_char;
  wire [2:0] col_in_char;
  wire pixel_on;

  font_renderer font_inst (
      .clk(vgaclk),
      .ascii_code(ascii_code),
      .row_in_char(row_in_char),
      .col_in_char(col_in_char),
      .pixel_on(pixel_on)
  );

  // ============================================================
  // Texto: "HOLA SANTIAGO"
  // ============================================================
  reg [7:0] mensaje [0:11];
  initial begin
    mensaje[0]  = 8'd72;  // H
    mensaje[1]  = 8'd79;  // O
    mensaje[2]  = 8'd76;  // L
    mensaje[3]  = 8'd65;  // A
    mensaje[4]  = 8'd00;  // espacio
    mensaje[5]  = 8'd83;  // S
    mensaje[6]  = 8'd65;  // A
    mensaje[7]  = 8'd78;  // N
    mensaje[8]  = 8'd84;  // T
    mensaje[9]  = 8'd73;  // I
    mensaje[10] = 8'd65;  // A
    mensaje[11] = 8'd71;  // G
  end

  parameter TEXT_X = 400;
  parameter TEXT_Y = 300;
  parameter CHAR_W = 8;
  parameter CHAR_H = 16;

  wire [3:0] char_col = (x - TEXT_X) / CHAR_W;
  wire inside_text = (x >= TEXT_X && x < TEXT_X + CHAR_W * 12 &&
                      y >= TEXT_Y && y < TEXT_Y + CHAR_H);

  assign row_in_char = (y - TEXT_Y) % CHAR_H;
  assign col_in_char = (x - TEXT_X) % CHAR_W;
  assign ascii_code  = mensaje[char_col];

  // ============================================================
  // Color de salida VGA
  // ============================================================
  always @(*) begin
    if (~videoOn)
      {vga_red, vga_green, vga_blue} = 24'h000000;
    else if (inside_text && pixel_on)
      {vga_red, vga_green, vga_blue} = 24'hFFFFFF;
    else
      {vga_red, vga_green, vga_blue} = 24'h000000;
  end

endmodule


// ============================================================
// Generador de reloj VGA
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
// Controlador VGA 1280x800
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

  assign hsync = (hcount >= H_VISIBLE + H_FP) && 
                 (hcount < H_VISIBLE + H_FP + H_SYNC);
  assign vsync = (vcount >= V_VISIBLE + V_FP) && 
                 (vcount < V_VISIBLE + V_FP + V_SYNC);
  assign video_on = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);
endmodule
