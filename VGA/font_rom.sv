// ============================================================
// font_rom.sv
// ROM con fuente 8x16 cargada desde font8x16.hex
// Convertido a SystemVerilog
// ============================================================

module font_rom (
    input  logic [10:0] addr,  // dirección = (ascii * 16) + fila
    output logic [7:0]  data
);

    // Memoria ROM (tamaño suficiente para 128 caracteres * 16 filas)
    logic [7:0] mem [0:2047];

    initial begin
        $readmemh("font8x16.hex", mem);
    end

    always_comb begin
        data = mem[addr];
    end

endmodule