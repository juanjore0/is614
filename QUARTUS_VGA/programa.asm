addi x1, x0, 10       # x1 = 10
addi x2, x0, 20       # x2 = 20
addi x3, x0, 0        # x3 = 0 (base)
add  x4, x1, x2       # x4 = 30

addi x20, x0, 100     # x20 = 100
addi x21, x0, 200     # x21 = 200
addi x22, x0, 44      # x22 = 44
add  x23, x20, x21    # x23 = 300

sw x1, 0(x3)          # Mem[0]  = 10
sw x2, 4(x3)          # Mem[4]  = 20
sw x4, 8(x3)          # Mem[8]  = 30

sw x20, 12(x3)        # Mem[12] = 100
sw x21, 16(x3)        # Mem[16] = 200
sw x23, 20(x3)        # Mem[20] = 300

lw x5, 0(x3)          # x5 = 10
lw x6, 4(x3)          # x6 = 20
lw x7, 8(x3)          # x7 = 30
lw x24, 12(x3)        # x24 = 100
lw x25, 16(x3)        # x25 = 200
lw x26, 20(x3)        # x26 = 300

addi x8, x0, 255      # x8 = 0xFF
sb x8, 24(x3)         # Mem[24][7:0] = 0xFF

addi x9, x0, -1       # x9 = 0xFFFFFFFF
sh x9, 28(x3)         # Mem[28][15:0] = 0xFFFF

lb x10, 24(x3)        # x10 = Mem[24] (sign extended)

lh x11, 28(x3)        # x11 = Mem[28] (sign extended)

add x12, x5, x6       # x12 = 10 + 20 = 30
add x13, x24, x25     # x13 = 100 + 200 = 300
add x14, x7, x22      # x14 = 30 + 44 = 74
add x15, x23, x26     # x15 = 300 + 300 = 600

addi x0, x0, 0        # NOP
addi x0, x0, 0        # NOP
