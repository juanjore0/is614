module color(
  input clock,                 // 50 MHz clock on de1-soc
  input sw0,                   // reset switch
  input sw1,                   // Green squares
  input sw2,                   // Blue square
  input sw3,                   // Red squares
  input sw4,                   // White squares  
  input sw5,                   // Black  
  output reg [7:0] vga_red,    // VGA outputs
  output reg [7:0] vga_green,
  output reg [7:0] vga_blue,
  output vga_hsync,
  output vga_vsync,
  output vga_clock
);
  // x and y coordinates (not used in this example)
  wire [10:0] x;
  wire [9:0] y;
  wire videoOn;
  
  wire vgaclk;
  clock1280x800 vgaclock(
	.clock50(clock),
	.reset(reset),
	.vgaclk(vgaclk)
  );
  
  assign vga_clock = vgaclk;
  
  // Creates an instance of a vga controller.
  vga_controller_1280x800 pt(
    .clk(vgaclk), 
    .reset(sw0), 
    .video_on(videoOn), 
    .hsync(vga_hsync), 
    .vsync(vga_vsync), 
    .hcount(x), .vcount(y)
  );


  // Assigns some "functionality" to the switches to change the display color

  // Square colors
  reg [23:0] color;

  always @*
    if (sw1 == 1'b1)
      color = 24'h00FF00; // Green
    else if (sw2 == 1'b1)
      color = 24'h0000FF; // Blue
    else if (sw3 == 1'b1)
      color = 24'hFF0000; // Red
    else if (sw4 == 1'b1)
      color = 24'hFFFFFF; // White
    else if (sw5 == 1'b1)
      color = 24'h000000; // Black
    else
      color = 24'hFFFF00; // Yellow


  always @*
    if (~videoOn)
      {vga_red, vga_green, vga_blue} = 8'h0;
   else if(sw4 == 1'b1)
		if ((x[5] ^ y[5]) == 1'b1)
      {vga_red, vga_green, vga_blue} = {8'hff, 8'hff, 8'hff};
		else
      {vga_red, vga_green, vga_blue} = {8'h00, 8'h00, 8'h00};
	 else if(sw5 == 1'b1)
		if ((x[3] ^ y[4]) == 1'b1)
      {vga_red, vga_green, vga_blue} = {8'hff, 8'hff, 8'hff};
		else
      {vga_red, vga_green, vga_blue} = {8'h00, 8'h00, 8'h00};
  else
    {vga_red, vga_green, vga_blue} = {8'hff, 8'hff, 8'h0};
endmodule


module clock1280x800(clock50, reset, vgaclk);
  input clock50;
  input reset;
  output vgaclk;

  wire  null;
  vgaClock clk(
	.ref_clk_clk(clock50),
	.ref_reset_reset(reset),
	.reset_source_reset(null),
	.vga_clk_clk(vgaclk));
endmodule

module vga_controller_1280x800 (
  input clk,         // 83.5 MHz clock (or close approximation)
  input reset,
  output wire hsync,
  output wire vsync,
  output reg [10:0] hcount,  // Needs 11 bits (0-1439)
  output reg [9:0] vcount,    // Needs 10 bits (0-822)
  output video_on
);

// --------------------------
// Timing Parameters (VESA Standard)
// --------------------------
// Horizontal Timings (Units: Pixels)
parameter H_VISIBLE = 1280;  // Visible area
parameter H_FP      = 48;    // Front porch
parameter H_SYNC    = 32;    // Sync pulse
parameter H_BP      = 80;    // Back porch
parameter H_TOTAL   = H_VISIBLE + H_FP + H_SYNC + H_BP; // 1440

// Vertical Timings (Units: Lines)
parameter V_VISIBLE = 800;   // Visible area
parameter V_FP      = 3;     // Front porch
parameter V_SYNC    = 6;     // Sync pulse
parameter V_BP      = 22;    // Back porch
parameter V_TOTAL   = V_VISIBLE + V_FP + V_SYNC + V_BP; // 831

// --------------------------
// Counters and Sync Logic
// --------------------------
always @(posedge clk or posedge reset) begin
  if (reset) begin
    hcount <= 0;
    vcount <= 0;
  end else begin
    // Horizontal counter
    if (hcount == H_TOTAL - 1) begin
      hcount <= 0;
      // Vertical counter
      if (vcount == V_TOTAL - 1)
        vcount <= 0;
      else
        vcount <= vcount + 1;
    end else begin
      hcount <= hcount + 1;
    end
  end
end

// --------------------------
// Sync Signals (Active HIGH for 1280x800)
// --------------------------
assign hsync = (hcount >= H_VISIBLE + H_FP) && 
              (hcount < H_VISIBLE + H_FP + H_SYNC);

assign vsync = (vcount >= V_VISIBLE + V_FP) && 
              (vcount < V_VISIBLE + V_FP + V_SYNC);

// --------------------------
// Video Active Signal
// --------------------------
assign video_on = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);

endmodule
