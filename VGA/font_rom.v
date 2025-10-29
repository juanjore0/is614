// ============================================================
// font_rom.v
// ROM con fuente 8x16 cargada desde font8x16.hex
// ============================================================

module font_rom (
    input  wire [10:0] addr,  // dirección = (ascii * 16) + fila
    output reg  [7:0]  data
);

    // Memoria ROM (tamaño suficiente para 128 caracteres * 16 filas)
    reg [7:0] mem [0:2047];

    initial begin
        $readmemh("font8x16.hex", mem);
    end

    always @(*) begin
        data = mem[addr];
    end

endmodule
