.data
var1: .word 100      # variable de 4 bytes (word)
var2: .byte 127      # variable de 1 byte
var3: .half 300      # variable de 2 bytes (halfword)

.text
main:
    # Cargar la dirección de var1 en x10 y su valor en x5
    la    x10, var1
    lw    x5, 0(x10)

    # Cargar la dirección de var2 en x11 y su valor en x6
    la    x11, var2
    lb    x6, 0(x11)

loop:
    # Ejemplo de bucle y salto
    addi  x5, x5, -1
    bnez  x5, loop

    # Finalizar el programa
    li    a7, 10
    ecall