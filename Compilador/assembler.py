#Juan José Arango Orozco y Valeria Muñoz Ramirez


from lexer import RISCVLexer
from parserPrincipal import RISCVParser
from parserlabel import ParserLabel
from memory import MemoryManager

#python assembler.py programa.asm programa.hex programa.bin
def main(asm_file, hex_file, bin_file):
   #asm_file = 'programa.asm', hex_file = 'programa.hex', bin_file = 'programa.bin'
    memory = MemoryManager()
    #primera pasada
    label_parser = ParserLabel()
    symbol_table = label_parser.get_labels(asm_file)
    print("pass 1 complete. Symbol Table:")
    print(symbol_table)

    with open(asm_file, 'r') as f:
        for line in f:
            parts = line.strip().split()
            #linea que defina un dato (que tenga al menos 3 partes y la segunda parte empiece con .)
            if len(parts) >= 3 and parts[1].startswith("."):
                #extraer el nombre de la variable, tipo y valor
                label = parts[0].replace(":", "")
                dtype = parts[1]
                value = int(parts[2], 0)  # acepta 127, 0x7F, 0b1010, etc.
                #guardar en memoria
                memory.add_data(label, dtype, value)

    #segunda pasada: instrucciones
    #se crea una instancia del lexer para tokenizar el codigo fuente
    lexer = RISCVLexer()
    parser = RISCVParser(symbol_table, memory)

    with open(asm_file, 'r') as f:
        source_code = f.read()

    tokens = lexer.tokenize(source_code)
    #el parser analiza los tokens y devuelve la lista de instrucciones.
    ast = parser.parse(tokens)

    machine_code = []
    #iterar sobre el resultado del parser
    for instr in ast:
        if instr and instr[0].startswith("instruction_"):
            # convierto de string binario a entero
            bin_str = instr[1]
            #convierte la cadena binaria en un entero
            instruction_code = int(bin_str, 2)
            machine_code.append(instruction_code)

    # Guardar resultados
    with open(hex_file, 'w') as f_hex, open(bin_file, 'w') as f_bin:
        #escribir cada instruccion en formato hexadecimal y binario
        for instruction_code in machine_code:
            # Se formatea el entero como un número hexadecimal de 8 dígitos (32 bits),
            # rellenando con ceros a la izquierda (ej: `00000073`).
            f_hex.write(f"{instruction_code:08x}\n")
            # Se formatea el entero como un numero binario de 32 bits,
            f_bin.write(f"{instruction_code:032b}\n")
    
    print("\n--- Data Section ---")
    #mostrar en consola las variables almacenadas en la memoria de datos simulada. 
    memory.jump_data()

    print(f"Assembly complete. Output files: {hex_file}, {bin_file}")


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 4:
        # Si no se proporcionan los 4 argumentos necesarios, se muestra un mensaje de ayuda.
        print("Usage: python assembler.py <input.asm> <output.hex> <output.bin>")
    else:
        main(sys.argv[1], sys.argv[2], sys.argv[3])

