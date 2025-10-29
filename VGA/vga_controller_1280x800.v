module vga_controller_1280x800(
    input  wire clk,
    input  wire reset,
    output wire video_on,
    output wire hsync,
    output wire vsync,
    output wire [10:0] hcount,
    output wire [9:0]  vcount
);

// Parámetros para 1280x800 @ 60Hz
localparam H_DISPLAY = 1280;
localparam H_FRONT   = 72;
localparam H_SYNC    = 128;
localparam H_BACK    = 200;
localparam H_TOTAL   = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; // 1680

localparam V_DISPLAY = 800;
localparam V_FRONT   = 3;
localparam V_SYNC    = 6;
localparam V_BACK    = 22;
localparam V_TOTAL   = V_DISPLAY + V_FRONT + V_SYNC + V_BACK; // 831

reg [10:0] h_count_reg;
reg [9:0]  v_count_reg;

// Contadores
always @(posedge clk or posedge reset) begin
    if (reset) begin
        h_count_reg <= 0;
        v_count_reg <= 0;
    end else begin
        if (h_count_reg < H_TOTAL - 1) begin
            h_count_reg <= h_count_reg + 1;
        end else begin
            h_count_reg <= 0;
            if (v_count_reg < V_TOTAL - 1) begin
                v_count_reg <= v_count_reg + 1;
            end else begin
                v_count_reg <= 0;
            end
        end
    end
end

// Señales de salida
assign hcount = h_count_reg;
assign vcount = v_count_reg;

assign hsync = ~((h_count_reg >= H_DISPLAY + H_FRONT) && 
                 (h_count_reg < H_DISPLAY + H_FRONT + H_SYNC));
                 
assign vsync = ~((v_count_reg >= V_DISPLAY + V_FRONT) && 
                 (v_count_reg < V_DISPLAY + V_FRONT + V_SYNC));

assign video_on = (h_count_reg < H_DISPLAY) && (v_count_reg < V_DISPLAY);

endmodule
