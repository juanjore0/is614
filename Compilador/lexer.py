from sly import Lexer

class RISCVLexer(Lexer):
    # Definición de los tokens
    tokens = {
        INSTRUCTION_TYPE_R, INSTRUCTION_TYPE_I, INSTRUCTION_TYPE_I_LOAD, INSTRUCTION_TYPE_B, 
        INSTRUCTION_TYPE_S, INSTRUCTION_TYPE_U, INSTRUCTION_TYPE_J, INSTRUCTION_TYPE_I_CB,
        # Pseudoinstrucciones específicas
        NOP, MV, NOT, NEG, SEQZ, SNEZ, SLTZ, SGTZ,
        BEQZ, BNEZ, BLEZ, BGEZ, BLTZ, BGTZ, 
        BGT, BLE, BGTU, BLEU,
        J_PSEUDO, JR, RET, LI, LA, CALL, TAIL,
        JAL_PSEUDO, JALR_PSEUDO,
        # Load/Store globales (pseudoinstrucciones)
        LB_GLOBAL, LH_GLOBAL, LW_GLOBAL,
        SB_GLOBAL, SH_GLOBAL, SW_GLOBAL,
        # Tokens existentes
        COMMA, REGISTER, NUMBER, NEWLINE, LPAREN, RPAREN, LABEL, COLON, 
        DIRECTIVE, DATA_DIRECTIVE
    }

    # IMPORTANTE: Las pseudoinstrucciones deben ir ANTES que las instrucciones base
    # para evitar conflictos de reconocimiento
    
    # Pseudoinstrucciones que pueden conflictuar con instrucciones base
    # Usamos lookahead negativo para distinguir contextos
    J_PSEUDO = r'\bj\b(?!\s+[a-zA-Z_][a-zA-Z0-9_]*\s*,)'  # j offset (no j rd, offset)
    JAL_PSEUDO = r'\bjal\b(?!\s+[a-zA-Z_][a-zA-Z0-9_]*\s*,)'  # jal offset (no jal rd, offset)
    JALR_PSEUDO = r'\bjalr\b(?!\s+[a-zA-Z_][a-zA-Z0-9_]*\s*,\s*[a-zA-Z_][a-zA-Z0-9_]*\s*,)'  # jalr rs (no jalr rd, rs, imm)
    
    # Load/Store globales (distinguir de las instrucciones base por contexto)
    # Estas reconocen el patrón: instrucción registro, etiqueta (sin paréntesis)
    LB_GLOBAL = r'\blb\b(?=\s+[a-zA-Z_][a-zA-Z0-9_]*\s*,\s*[a-zA-Z_][a-zA-Z0-9_]*\s*(?!\())'
    LH_GLOBAL = r'\blh\b(?=\s+[a-zA-Z_][a-zA-Z0-9_]*\s*,\s*[a-zA-Z_][a-zA-Z0-9_]*\s*(?!\())'
    LW_GLOBAL = r'\blw\b(?=\s+[a-zA-Z_][a-zA-Z0-9_]*\s*,\s*[a-zA-Z_][a-zA-Z0-9_]*\s*(?!\())'
    SB_GLOBAL = r'\bsb\b(?=\s+[a-zA-Z_][a-zA-Z0-9_]*\s*,\s*[a-zA-Z_][a-zA-Z0-9_]*\s*(?!\())'
    SH_GLOBAL = r'\bsh\b(?=\s+[a-zA-Z_][a-zA-Z0-9_]*\s*,\s*[a-zA-Z_][a-zA-Z0-9_]*\s*(?!\())'
    SW_GLOBAL = r'\bsw\b(?=\s+[a-zA-Z_][a-zA-Z0-9_]*\s*,\s*[a-zA-Z_][a-zA-Z0-9_]*\s*(?!\())'

    # Pseudoinstrucciones simples
    NOP = r'\bnop\b'
    MV = r'\bmv\b'
    NOT = r'\bnot\b'
    NEG = r'\bneg\b'
    SEQZ = r'\bseqz\b'
    SNEZ = r'\bsnez\b'
    SLTZ = r'\bsltz\b'
    SGTZ = r'\bsgtz\b'
    BEQZ = r'\bbeqz\b'
    BNEZ = r'\bbnez\b'
    BLEZ = r'\bblez\b'
    BGEZ = r'\bbgez\b'
    BLTZ = r'\bbltz\b'
    BGTZ = r'\bbgtz\b'
    BGT = r'\bbgt\b'
    BLE = r'\bble\b'
    BGTU = r'\bbgtu\b'
    BLEU = r'\bbleu\b'
    JR = r'\bjr\b'
    RET = r'\bret\b'
    LI = r'\bli\b'
    LA = r'\bla\b'
    CALL = r'\bcall\b'
    TAIL = r'\btail\b'

    # Instrucciones base (deben ir DESPUÉS de las pseudoinstrucciones)
    INSTRUCTION_TYPE_R = r'\b(add|sub|xor|or|and|sll|srl|sra|slt|sltu)\b'
    INSTRUCTION_TYPE_I = r'\b(addi|xori|ori|andi|slli|srli|srai|slti|sltiu|jalr)\b'
    INSTRUCTION_TYPE_I_LOAD = r'\b(lb|lh|lw|lhu|lbu)\b'
    INSTRUCTION_TYPE_I_CB = r'\b(ebreak|ecall)\b'
    INSTRUCTION_TYPE_S = r'\b(sb|sh|sw)\b'
    INSTRUCTION_TYPE_B = r'\b(beq|bne|blt|bge|bltu|bgeu)\b'
    INSTRUCTION_TYPE_U = r'\b(lui|auipc)\b'
    INSTRUCTION_TYPE_J = r'\b(jal)\b'
   
    # Otros tokens
    COMMA = r','
    LPAREN = r'\('
    RPAREN = r'\)'
    COLON = r':'
    DIRECTIVE = r'\.text|\.data'
    DATA_DIRECTIVE = r'\.(word|byte|half)'


    # Expresión regular para registros (x0-x31 y sus alias)
    REGISTER = r'\b(zero|ra|sp|gp|tp|t0|t1|t2|s0|s1|a0|a1|a2|a3|a4|a5|a6|a7|s2|s3|s4|s5|s6|s7|s8|s9|s10|s11|t3|t4|t5|t6|x[0-9]{1,2})\b'
    NUMBER = r'0x[0-9a-fA-F]+|-?[0-9]+'
    LABEL = r'[a-zA-Z_][a-zA-Z0-9_]*'

    # Ignorar espacios en blanco, tabulaciones y comentarios
    ignore = ' \t'
    ignore_comment = r'#.*'
  
    # --- Alias ---
    aliases = {
        'zero': 'x0', 'ra': 'x1', 'sp': 'x2', 'gp': 'x3', 'tp': 'x4',
        't0': 'x5', 't1': 'x6', 't2': 'x7',
        's0': 'x8', 'fp': 'x8', 's1': 'x9',
        'a0': 'x10', 'a1': 'x11', 'a2': 'x12', 'a3': 'x13', 'a4': 'x14',
        'a5': 'x15', 'a6': 'x16', 'a7': 'x17',
        's2': 'x18', 's3': 'x19', 's4': 'x20', 's5': 'x21', 's6': 'x22',
        's7': 'x23', 's8': 'x24', 's9': 'x25', 's10': 'x26', 's11': 'x27',
        't3': 'x28', 't4': 'x29', 't5': 'x30', 't6': 'x31'
    }

    @_(r'(x[0-9]{1,2})|' + '|'.join(aliases.keys()))
    def REGISTER(self, t):
        if t.value in self.aliases:
            t.value = self.aliases[t.value]
        # Validar el número de registro si es 'x' seguido de un número
        if t.value.startswith('x'):
            reg_num = int(t.value[1:])
            if not 0 <= reg_num <= 31:
                raise ValueError(f"Invalid register number: {t.value}")
        return t

    # Expresión regular para números decimales y hexadecimales
    @_(r'0x[0-9a-fA-F]+|-?[0-9]+')
    def NUMBER(self, t):
        if t.value.startswith('0x'):
            t.value = int(t.value, 16)
        else:
            t.value = int(t.value)
        return t
    
    # Manejar nuevas líneas y mantener el conteo de la línea
    @_(r'\n+')
    def NEWLINE(self, t):
        self.lineno += t.value.count('\n')
        return t
    
    # Manejo de errores de caracteres ilegales
    def error(self, t):
        print(f"Illegal character '{t.value[0]}' at line {self.lineno}")
        self.index += 1

if __name__ == "__main__":
    data = """
    .data
    x: .word 10
    y: .byte 0xFF

    .text
    main:
        addi x1, x2, 10
        lw x3, 0(x1)
        sw x3, 4(x2) # store word
    """

    lexer = RISCVLexer()
    for tok in lexer.tokenize(data):
        print(f"type={tok.type}, value={tok.value}, #line={tok.lineno}")
