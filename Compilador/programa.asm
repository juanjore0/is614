.data

.text
main:
    addi x1, x0, 10      # x1 = 10
    addi x2, x0, 20      # x2 = 20
    addi x3, x0, 0       # x3 = 0 (dirección base)
    add  x4, x1, x2      # x4 = x1 + x2 = 30
    sw   x1, 0(x3)       # Mem[0] = x1 = 10
    sw   x2, 4(x3)       # Mem[4] = x2 = 20
    sw   x4, 8(x3)       # Mem[8] = x4 = 30
    addi x5, x0, 255     # x5 = 0xFF
    lui  x6, 1           # x6 = 0x1000
    sb   x5, 12(x3)      # Mem[12][7:0] = 0xFF
    sh   x6, 14(x3)      # Mem[14][15:0] = 0x1000
    lw   x7, 0(x3)       # x7 = Mem[0] = 10
    lw   x8, 4(x3)       # x8 = Mem[4] = 20
    lw   x9, 8(x3)       # x9 = Mem[8] = 30
    lb   x10, 12(x3)     # x10 = Mem[12] = 0xFF (sign extended)
    lh   x11, 14(x3)     # x11 = Mem[14] = 0x1000
