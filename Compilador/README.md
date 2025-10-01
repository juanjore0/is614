
## Ensamblador RISC-V en Python 

Este proyecto es un ensamblador de dos pasadas para un subconjunto de la arquitectura RISC-V de 32 bits (RV32I), desarrollado completamente en Python. El programa es capaz de leer código ensamblador RISC-V, procesar etiquetas, directivas de datos e instrucciones, y generar como salida los archivos correspondientes en código máquina binario y hexadecimal.

El núcleo del ensamblador está construido utilizando la librería sly para el análisis léxico y sintáctico.

## Características Principales
Ensamblador de Dos Pasadas: Resuelve eficientemente las referencias a etiquetas (símbolos) antes de la generación del código final.

Manejo de Secciones de Código y Datos: Soporta las directivas .data y .text para una correcta organización de la memoria.

Soporte para Directivas de Datos: Reconoce .word, .half y .byte para la definición de variables en la memoria.

Amplio Soporte de Instrucciones: Ensambla las instrucciones base del conjunto RV32I, incluyendo tipos R, I, S, B, U y J.

Traducción de Pseudoinstrucciones: Resuelve pseudoinstrucciones comunes de RISC-V para facilitar la programación.

Generación de Múltiples Formatos: Crea archivos de salida tanto en hexadecimal (.hex) como en binario (.bin).

Gestión de Memoria: Simula la asignación de direcciones para la sección de datos a partir de una dirección base (por defecto 0x10010000).

## Estructura del Proyecto
El ensamblador está organizado en varios módulos, cada uno con una responsabilidad específica:

assembler.py: Orquestador principal. Es el punto de entrada que coordina el proceso de ensamblaje, gestiona las dos pasadas y escribe los archivos de salida.

lexer.py: Analizador Léxico. Se encarga de escanear el código fuente .asm y convertirlo en una secuencia de tokens (instrucciones, registros, números, etc.).

parserlabel.py: Parser de la Primera Pasada. Recorre el código para encontrar todas las etiquetas (labels) y almacenar sus direcciones en una tabla de símbolos.

parserPrincipal.py: Parser de la Segunda Pasada. Utiliza la tabla de símbolos generada en la primera pasada para analizar la sintaxis del código y traducir cada instrucción a su representación binaria.

memory.py: Gestor de Memoria. Simula la sección .data, asignando direcciones a las variables definidas con .word, .byte, etc., y manejando la alineación de datos.

diccionarios.py: Base de Datos de Instrucciones. Contiene las definiciones (opcodes, funct3, funct7) para todas las instrucciones soportadas, sirviendo como referencia para la traducción.

## ¿Cómo Usarlo? 

### 1. Requisitos Previos
Asegúrate de tener instalada la librería sly. Si no la tienes, puedes instalarla fácilmente con pip:
pip install sly

### 2. Prepara tu Código Ensamblador
Crea un archivo con tu código RISC-V. Por ejemplo, programa.asm:

Fragmento de código

```python
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
```

### 3. Ejecuta el Ensamblador
Ejecuta el script assembler.py desde tu terminal, pasándole como argumentos el archivo de entrada y los nombres de los archivos de salida.

Sintaxis:
python assembler.py <archivo_entrada.asm> <archivo_salida.hex> <archivo_salida.bin>

Ejemplo:

python assembler.py programa.asm programa.hex programa.bin

### 4. Revisa los Resultados
Después de la ejecución, se crearán dos archivos en la misma carpeta:

programa.hex: Contendrá el código máquina en formato hexadecimal de 32 bits, con una instrucción por línea.

programa.bin: Contendrá el mismo código máquina, pero en formato binario de 32 bits.

## Flujo de Ejecución del Ensamblador 
El proceso sigue un enfoque clásico de dos pasadas para resolver las dependencias de las etiquetas de salto.

Primera Pasada (parserlabel.py):
El assembler.py invoca al ParserLabel.

Este parser lee todo el archivo .asm con un objetivo simple: identificar todas las etiquetas (como main: o loop:) y calcular su dirección de memoria (PC). Las etiquetas y sus direcciones se almacenan en una tabla de símbolos.
También procesa la sección .data para asignar direcciones a las variables con la ayuda de memory.py.

Segunda Pasada (parserPrincipal.py):
El assembler.py invoca al RISCVParser, entregándole la tabla de símbolos creada en la primera pasada. Este parser vuelve a leer el archivo .asm, pero esta vez traduce cada instrucción a código máquina. Cuando encuentra una instrucción que usa una etiqueta (ej. jal main), busca su dirección en la tabla de símbolos para calcular el offset necesario.
Consulta los diccionarios.py para obtener los opcodes y functs correspondientes a cada instrucción.
El resultado final es una lista de instrucciones en formato binario.

Generación de Archivos:

Finalmente, assembler.py toma la lista de instrucciones binarias, las formatea y las escribe en los archivos de salida .hex y .bin.

Este enfoque modular y de dos pasadas permite que el código sea limpio, mantenible y capaz de manejar referencias a futuro sin complicaciones.