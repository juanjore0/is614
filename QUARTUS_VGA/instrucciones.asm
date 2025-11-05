00A00093    addi x1,  x0, 10        # x1 = 10
01400113    addi x2,  x0, 20        # x2 = 20
00000193    addi x3,  x0, 0         # x3 = 0 (base)
00208233    add  x4,  x1, x2        # x4 = 30

06400A13    addi x20, x0, 100       # x20 = 100
0C800A93    addi x21, x0, 200       # x21 = 200
02C00B13    addi x22, x0, 44        # x22 = 44
015A0BB3    add  x23, x20, x21      # x23 = 300

0011A023    sw   x1,  0(x3)         # Mem[0]  = 10
0021A223    sw   x2,  4(x3)         # Mem[4]  = 20
0041A423    sw   x4,  8(x3)         # Mem[8]  = 30

0141A623    sw   x20, 12(x3)        # Mem[12] = 100
0151A823    sw   x21, 16(x3)        # Mem[16] = 200
0171AA23    sw   x23, 20(x3)        # Mem[20] = 300

0001A283    lw   x5,  0(x3)         # x5 = 10
0041A303    lw   x6,  4(x3)         # x6 = 20
0081A383    lw   x7,  8(x3)         # x7 = 30
00C1AC03    lw   x24, 12(x3)        # x24 = 100
0101AC83    lw   x25, 16(x3)        # x25 = 200
0141AD03    lw   x26, 20(x3)        # x26 = 300

0FF00413    addi x8,  x0, 255       # x8 = 0xFF
00818C23    sb   x8,  24(x3)        # Mem[24][7:0] = 0xFF

FFF00493    addi x9,  x0, -1        # x9 = 0xFFFFFFFF
00919E23    sh   x9,  28(x3)        # Mem[28][15:0] = 0xFFFF

01818503    lb   x10, 24(x3)        # x10 = Mem[24] (sign extended)
01C19583    lh   x11, 28(x3)        # x11 = Mem[28] (sign extended)

00628633    add  x12, x5, x6        # x12 = 10 + 20 = 30
019C06B3    add  x13, x24, x25      # x13 = 100 + 200 = 300
016B8733    add  x14, x23, x22      # ❌ x14 = 300 + 44 (debería ser x7 + x22)
01ABA7B3    add  x15, x23, x27      # ❌ x15 = 300 + x27 (debería ser x26)

00000013    addi x0, x0, 0          # NOP
00000013    addi x0, x0, 0          # NOP
