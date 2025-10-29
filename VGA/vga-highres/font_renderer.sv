// ============================================================
// font_renderer.sv
// Renderizador de caracteres 8x16 usando font_rom
// Convertido a SystemVerilog
// ============================================================

module font_renderer (
    input  logic        clk,
    input  logic [7:0]  ascii_code,   // código ASCII
    input  logic [3:0]  row_in_char,  // 0–15
    input  logic [2:0]  col_in_char,  // 0–7
    output logic        pixel_on
);

    logic [10:0] rom_addr;
    logic [7:0]  rom_data;

    // Dirección dentro de la ROM: carácter * 16 + fila
    assign rom_addr = {ascii_code, row_in_char};

    font_rom rom_inst (
        .addr(rom_addr),
        .data(rom_data)
    );

    // Extrae el bit de la columna correspondiente
    always_ff @(posedge clk) begin
        pixel_on <= rom_data[7 - col_in_char];
    end

endmodule