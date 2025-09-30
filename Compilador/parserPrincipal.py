import os
from sly import Parser
from lexer import RISCVLexer
from diccionarios import ins_type_R, ins_type_I, ins_type_S, ins_type_U, ins_type_B, ins_type_J, Registros
from parserlabel import ParserLabel

# Variable global para el contador de línea
count_line = 0

def num_binary(numero, bits):
    """
    Convierte un número entero a su representación binaria de 'bits' de longitud.
    Maneja tanto números positivos como negativos (utilizando complemento a dos).
    """
    if numero >= 0:
        return bin(numero)[2:].zfill(bits)
    else:
        # Complemento a dos para números negativos
        return bin(2**bits + numero)[2:]

def validate_imm(imm, bits):
    """
    Valida que el valor inmediato esté dentro del rango permitido para 'bits' bits con signo.
    """
    min_val = -(2**(bits - 1))
    max_val = 2**(bits - 1) - 1
    if not (min_val <= imm <= max_val):
        raise ValueError(f"Immediate value {imm} out of range for {bits} bits")

class RISCVParser(Parser):
    # Definición de los tokens basados en el lexer
    tokens = RISCVLexer.tokens

    def __init__(self, label_dict, memory):
        super().__init__()
        self.label_dict = label_dict  # Diccionario de etiquetas
        self.memory = memory

    # Reglas. Un programa es una o más líneas
    @_('line program')
    def program(self, p):
        return [p.line] + p.program

    @_('line')
    def program(self, p):
        return [p.line]

    # ----------- INSTRUCCIONES BASE -----------
    
    # Directivas
    @_('DIRECTIVE')
    def line(self, p):
        return ('directive', p.DIRECTIVE)
    
    @_('LABEL COLON DATA_DIRECTIVE NUMBER')
    def line(self, p):
        return ('data_def', {
            'label': p.LABEL,
            'type': p.DATA_DIRECTIVE,
            'value': int(p.NUMBER)
        })

    @_('LABEL COLON')
    def line(self, p):
        return ('label', p.LABEL)
    
        
    @_('INSTRUCTION_TYPE_R REGISTER COMMA REGISTER COMMA REGISTER')
    def line(self, p):
        """
        Funcion que procesa las instrucciones de tipo R.
        Args: 
            p: objeto que contiene los componentes de la instrucción.
            - INSTRUCTION_TYPE_R: tipo de instrucción (e.g., 'add', 'sub').
            - REGISTER: registros involucrados (rd, rs1, rs2).

        Returns:
            Tupla con el tipo de instrucción y su representación binaria.
        """
        global count_line
        ins_info = ins_type_R[p.INSTRUCTION_TYPE_R]
        #Formato: funct7 | rs2 | rs1 | funct3 | rd | opcode
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        rs2 = Registros(p.REGISTER2)
        binary_instruction = f"{ins_info['funct7']}{rs2}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_r', binary_instruction)
    
    @_('INSTRUCTION_TYPE_I REGISTER COMMA REGISTER COMMA NUMBER')
    def line(self, p):
        """
        Funcion que procesa las instrucciones de tipo I.
        Args: 
            p: objeto que contiene los componentes de la instrucción.
            - INSTRUCTION_TYPE_I: tipo de instrucción (e.g., 'addi', 'andi').
            - REGISTER: registros involucrados (rd, rs1).
            - NUMBER: valor inmediato.
        Returns:
            Tupla con el tipo de instrucción y su representación binaria.
        """
        global count_line
        ins_info = ins_type_I[p.INSTRUCTION_TYPE_I]
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)

        validate_imm(int(p.NUMBER), 12)
        
        imm = num_binary(int(p.NUMBER), 12)
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)
    
    @_('INSTRUCTION_TYPE_I_LOAD REGISTER COMMA NUMBER LPAREN REGISTER RPAREN')
    def line(self, p):
        global count_line
        ins_info = ins_type_I[p.INSTRUCTION_TYPE_I_LOAD]
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)

        if not (-2048 <= int(p.NUMBER) <= 2047):
            raise ValueError(f"Immediate value {p.NUMBER} out of range for 12 bits")

        imm = num_binary(int(p.NUMBER), 12)
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)

    @_('INSTRUCTION_TYPE_I_CB')
    def line(self, p):
        global count_line
        ins_info = ins_type_I[p.INSTRUCTION_TYPE_I_CB]  # Cambiar de INSTRUCTION_TYPE_CB a INSTRUCTION_TYPE_I_CB
        
        # Para ebreak y ecall, todos los campos son fijos según la especificación RISC-V
        rd = "00000"    # rd = x0
        rs1 = "00000"   # rs1 = x0  
        imm = ins_info['imm']  # El valor inmediato específico (ebreak=1, ecall=0)
        
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)
    
    @_('INSTRUCTION_TYPE_S REGISTER COMMA NUMBER LPAREN REGISTER RPAREN')
    def line(self, p):
        global count_line
        ins_info = ins_type_S[p.INSTRUCTION_TYPE_S]
        rs1 = Registros(p.REGISTER1)
        rs2 = Registros(p.REGISTER0)

        if not (-2048 <= int(p.NUMBER) <= 2047):
            raise ValueError(f"Immediate value {p.NUMBER} out of range for 12 bits")

        imm = num_binary(int(p.NUMBER), 12)
        imm_high = imm[:7]  # Bits 11 a 5
        imm_low = imm[7:]   # Bits 4 a 0
        binary_instruction = f"{imm_high}{rs2}{rs1}{ins_info['funct3']}{imm_low}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_s', binary_instruction)
    
    @_('INSTRUCTION_TYPE_U REGISTER COMMA NUMBER')
    def line(self, p):
        global count_line
        ins_info = ins_type_U[p.INSTRUCTION_TYPE_U]
        rd = Registros(p.REGISTER)

        if not (-524288 <= int(p.NUMBER) <= 524287):
            raise ValueError(f"Immediate value {p.NUMBER} out of range for 20 bits")

        imm = num_binary(int(p.NUMBER), 20)
        binary_instruction = f"{imm}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_u', binary_instruction)
    
    @_('INSTRUCTION_TYPE_B REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        global count_line
        ins_info = ins_type_B[p.INSTRUCTION_TYPE_B]
        rs1 = Registros(p.REGISTER0)
        rs2 = Registros(p.REGISTER1)
        offset = self.label_dict[p.LABEL] - count_line

        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        # Extraer los bits del inmediato para el formato B
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)
    
    @_('INSTRUCTION_TYPE_J REGISTER COMMA LABEL')
    def line(self, p):
        global count_line
        ins_info = ins_type_J[p.INSTRUCTION_TYPE_J]
        rd = Registros(p.REGISTER)
        offset = self.label_dict[p.LABEL] - count_line

        if not (-1048576 <= offset <= 1048575):
            raise ValueError(f"Jump offset {offset} out of range for 21 bits")
        
        imm = num_binary(offset, 21)
        # Extraer los bits del inmediato para el formato J
        imm20 = imm[0]
        imm10_1 = imm[10:20]
        imm11 = imm[9]
        imm19_12 = imm[1:9]
        
        binary_instruction = f"{imm20}{imm10_1}{imm11}{imm19_12}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_j', binary_instruction)
    
    # ----------- PSEUDO INSTRUCCIONES -----------

    # PSEUDOINSTRUCCIONES SIN OPERANDOS
    @_('NOP')
    def line(self, p):
        # nop -> addi x0, x0, 0
        global count_line
        ins_info = ins_type_I['addi']
        rd = "00000"  # x0
        rs1 = "00000"  # x0
        imm = "000000000000"  # 0
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)

    @_('RET')
    def line(self, p):
        # ret -> jalr x0, x1, 0
        global count_line
        ins_info = ins_type_I['jalr']
        rd = "00000"  # x0
        rs1 = "00001"  # x1
        imm = "000000000000"  # 0
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)

    # PSEUDOINSTRUCCIONES CON DOS OPERANDOS (rd, rs)
    @_('MV REGISTER COMMA REGISTER')
    def line(self, p):
        # mv rd, rs -> addi rd, rs, 0
        global count_line
        ins_info = ins_type_I['addi']
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        imm = "000000000000"  # 0
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)

    @_('NOT REGISTER COMMA REGISTER')
    def line(self, p):
        # not rd, rs -> xori rd, rs, -1
        global count_line
        ins_info = ins_type_I['xori']
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        imm = num_binary(-1, 12)
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)

    @_('NEG REGISTER COMMA REGISTER')
    def line(self, p):
        # neg rd, rs -> sub rd, x0, rs
        global count_line
        ins_info = ins_type_R['sub']
        rd = Registros(p.REGISTER0)
        rs1 = "00000"  # x0
        rs2 = Registros(p.REGISTER1)
        binary_instruction = f"{ins_info['funct7']}{rs2}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_r', binary_instruction)

    @_('SEQZ REGISTER COMMA REGISTER')
    def line(self, p):
        # seqz rd, rs -> sltiu rd, rs, 1
        global count_line
        ins_info = ins_type_I['sltiu']
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        imm = "000000000001"  # 1
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)

    @_('SNEZ REGISTER COMMA REGISTER')
    def line(self, p):
        # snez rd, rs -> sltu rd, x0, rs
        global count_line
        ins_info = ins_type_R['sltu']
        rd = Registros(p.REGISTER0)
        rs1 = "00000"  # x0
        rs2 = Registros(p.REGISTER1)
        binary_instruction = f"{ins_info['funct7']}{rs2}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_r', binary_instruction)

    @_('SLTZ REGISTER COMMA REGISTER')
    def line(self, p):
        # sltz rd, rs -> slt rd, rs, x0
        global count_line
        ins_info = ins_type_R['slt']
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        rs2 = "00000"  # x0
        binary_instruction = f"{ins_info['funct7']}{rs2}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_r', binary_instruction)

    @_('SGTZ REGISTER COMMA REGISTER')
    def line(self, p):
        # sgtz rd, rs -> slt rd, x0, rs
        global count_line
        ins_info = ins_type_R['slt']
        rd = Registros(p.REGISTER0)
        rs1 = "00000"  # x0
        rs2 = Registros(p.REGISTER1)
        binary_instruction = f"{ins_info['funct7']}{rs2}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_r', binary_instruction)
# PSEUDOINSTRUCCIONES CON REGISTRO E INMEDIATO/ETIQUETA
    @_('LI REGISTER COMMA NUMBER')
    def line(self, p):
        """
        Pseudoinstrucción li rd, immediate
        Traduce a: addi rd, x0, immediate
        """
        global count_line
        immediate_value = int(p.NUMBER)
        
        # Verificar si cabe en 12 bits con signo
        if -2048 <= immediate_value <= 2047:
            # Usar solo addi
            ins_info = ins_type_I['addi']
            rd = Registros(p.REGISTER)
            rs1 = "00000"  # x0
            imm = num_binary(immediate_value, 12)
            binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
            count_line += 4
            return ('instruction_i', binary_instruction)
        else:
            # Para valores más grandes, necesitarías implementar lui + addi
            # Por simplicidad, por ahora manejo solo valores de 12 bits
            raise ValueError(f"Immediate value {immediate_value} too large for simple li implementation")

    @_('LA REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción la rd, label
        Traduce a: addi rd, x0, address_of_label
        """
        global count_line
        if p.LABEL in self.memory.memory:
            symbol_address = self.memory.memory[p.LABEL]["addr"]
        else:
            raise ValueError(f"Etiqueta {p.LABEL} no encontrada en memoria")

        # Tomar los 12 bits bajos de la dirección (aunque no sea real RISC-V)
        ins_info = ins_type_I['addi']
        rd = Registros(p.REGISTER)
        rs1 = "00000"
        imm = num_binary(symbol_address & 0xFFF, 12)
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)

    # LOAD/STORE GLOBALES (implementación simplificada)
    @_('LB_GLOBAL REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción lb_global rd, label
        Traduce a: lb rd, 0(x0) con la dirección de label
        """
        global count_line
        # Buscar la dirección en memoria
        if p.LABEL in self.memory.memory:
            symbol_address = self.memory.memory[p.LABEL]["addr"]
        else:
            raise ValueError(f"Etiqueta {p.LABEL} no encontrada en memoria")

        # Validar rango de inmediato
        if -2048 <= symbol_address <= 2047:
            ins_info = ins_type_I['lb']
            rd = Registros(p.REGISTER)
            rs1 = "00000"  # x0 como base
            imm = num_binary(symbol_address, 12)
            binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
            count_line += 4
            return ('instruction_i', binary_instruction)
        else:
            raise ValueError(f"Dirección {symbol_address} demasiado grande para lb_global")

    @_('LH_GLOBAL REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción lh_global rd, label
        Traduce a: lh rd, 0(x0) con la dirección de label
        """
        global count_line
        # Buscar la dirección en memoria
        if p.LABEL in self.memory.memory:
            symbol_address = self.memory.memory[p.LABEL]["addr"]
        else:
            raise ValueError(f"Etiqueta {p.LABEL} no encontrada en memoria")

        # Validar rango de inmediato
        if -2048 <= symbol_address <= 2047:
            ins_info = ins_type_I['lh']
            rd = Registros(p.REGISTER)
            rs1 = "00000"  # x0 como base
            imm = num_binary(symbol_address, 12)
            binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
            count_line += 4
            return ('instruction_i', binary_instruction)
        else:
            raise ValueError(f"Dirección {symbol_address} demasiado grande para lh_global")

    @_('LW_GLOBAL REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción lw_global rd, label
        Traduce a: lw rd, 0(x0) con la dirección de label
        """
        global count_line
        if p.LABEL in self.memory.memory:
            symbol_address = self.memory.memory[p.LABEL]["addr"]
        else:
            raise ValueError(f"Etiqueta {p.LABEL} no encontrada en memoria")

        if -2048 <= symbol_address <= 2047:
            ins_info = ins_type_I['lw']
            rd = Registros(p.REGISTER)
            rs1 = "00000"
            imm = num_binary(symbol_address, 12)
            binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
            count_line += 4
            return ('instruction_i', binary_instruction)
        else:
            raise ValueError(f"Dirección {symbol_address} demasiado grande para lw_global")


    @_('SB_GLOBAL REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción sb_global rs2, label
        Traduce a: sb rs2, 0(x0) con la dirección de label
        """
        global count_line
        # Buscar la dirección en memoria
        if p.LABEL in self.memory.memory:
            symbol_address = self.memory.memory[p.LABEL]["addr"]
        else:
            raise ValueError(f"Etiqueta {p.LABEL} no encontrada en memoria")

        # Validar rango de inmediato
        if -2048 <= symbol_address <= 2047:
            ins_info = ins_type_S['sb']
            rs1 = "00000"  # x0 como base
            rs2 = Registros(p.REGISTER)  # valor a guardar
            imm = num_binary(symbol_address, 12)
            imm_high = imm[:7]   # bits 11-5
            imm_low = imm[7:]    # bits 4-0
            binary_instruction = f"{imm_high}{rs2}{rs1}{ins_info['funct3']}{imm_low}{ins_info['opcode']}"
            count_line += 4
            return ('instruction_s', binary_instruction)
        else:
            raise ValueError(f"Dirección {symbol_address} demasiado grande para sb_global")

    @_('SH_GLOBAL REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción sh_global rs2, label
        Traduce a: sh rs2, 0(x0) con la dirección de label
        """
        global count_line
        # Buscar la dirección en memoria
        if p.LABEL in self.memory.memory:
            symbol_address = self.memory.memory[p.LABEL]["addr"]
        else:
            raise ValueError(f"Etiqueta {p.LABEL} no encontrada en memoria")

        # Validar rango de inmediato
        if -2048 <= symbol_address <= 2047:
            ins_info = ins_type_S['sh']
            rs1 = "00000"  # x0 como base
            rs2 = Registros(p.REGISTER)  # valor a guardar
            imm = num_binary(symbol_address, 12)
            imm_high = imm[:7]   # bits 11-5
            imm_low = imm[7:]    # bits 4-0
            binary_instruction = f"{imm_high}{rs2}{rs1}{ins_info['funct3']}{imm_low}{ins_info['opcode']}"
            count_line += 4
            return ('instruction_s', binary_instruction)
        else:
            raise ValueError(f"Dirección {symbol_address} demasiado grande para sh_global")


    @_('SW_GLOBAL REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción sw_global rs2, label
        Traduce a: sw rs2, 0(x0) con la dirección de label
        """
        global count_line
        # Buscar la dirección en memoria
        if p.LABEL in self.memory.memory:
            symbol_address = self.memory.memory[p.LABEL]["addr"]
        else:
            raise ValueError(f"Etiqueta {p.LABEL} no encontrada en memoria")

        # Validar rango de inmediato
        if -2048 <= symbol_address <= 2047:
            ins_info = ins_type_S['sw']
            rs1 = "00000"  # x0 como base
            rs2 = Registros(p.REGISTER)  # valor a guardar
            imm = num_binary(symbol_address, 12)
            imm_high = imm[:7]   # bits 11-5
            imm_low = imm[7:]    # bits 4-0
            binary_instruction = f"{imm_high}{rs2}{rs1}{ins_info['funct3']}{imm_low}{ins_info['opcode']}"
            count_line += 4
            return ('instruction_s', binary_instruction)
        else:
            raise ValueError(f"Dirección {symbol_address} demasiado grande para sw_global")


    # SALTOS CONDICIONALES CON UN OPERANDO
    @_('BEQZ REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción beqz rs, label
        Traduce a: beq rs, x0, label
        """
        global count_line
        ins_info = ins_type_B['beq']
        rs1 = Registros(p.REGISTER)
        rs2 = "00000"  # x0
        offset = self.label_dict[p.LABEL] - count_line
        
        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        
        # Formato B: imm[12|10:5] rs2 rs1 funct3 imm[4:1|11] opcode
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    @_('BNEZ REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción bnez rs, label
        Traduce a: bne rs, x0, label
        """
        global count_line
        ins_info = ins_type_B['bne']
        rs1 = Registros(p.REGISTER)
        rs2 = "00000"  # x0
        offset = self.label_dict[p.LABEL] - count_line

        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    @_('BLEZ REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción blez rs, label
        Traduce a: ble rs, x0, label
        """
        global count_line
        ins_info = ins_type_B['bge']
        rs1 = "00000"  # x0
        rs2 = Registros(p.REGISTER)
        offset = self.label_dict[p.LABEL] - count_line

        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    @_('BGEZ REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción bgez rs, label
        Traduce a: bge rs, x0, label
        """
        global count_line
        ins_info = ins_type_B['bge']
        rs1 = Registros(p.REGISTER)
        rs2 = "00000"  # x0
        offset = self.label_dict[p.LABEL] - count_line

        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    @_('BLTZ REGISTER COMMA LABEL')
    def line(self, p):
        """
        Pseudoinstrucción bltz rs, label
        Traduce a: blt rs, x0, label
        """
        global count_line
        ins_info = ins_type_B['blt']
        rs1 = Registros(p.REGISTER)
        rs2 = "00000"  # x0
        offset = self.label_dict[p.LABEL] - count_line
        
        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    @_('BGTZ REGISTER COMMA LABEL')
    def line(self, p):
        # bgtz rs, offset -> blt x0, rs, offset
        global count_line
        ins_info = ins_type_B['blt']
        rs1 = "00000"  # x0
        rs2 = Registros(p.REGISTER)
        offset = self.label_dict[p.LABEL] - count_line
        
        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    # SALTOS CONDICIONALES CON DOS OPERANDOS
    @_('BGT REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        # bgt rs, rt, offset -> blt rt, rs, offset (intercambiar rs y rt)
        global count_line
        ins_info = ins_type_B['blt']
        rs1 = Registros(p.REGISTER1)  # rt (segundo registro)
        rs2 = Registros(p.REGISTER0)  # rs (primer registro)
        offset = self.label_dict[p.LABEL] - count_line
                
        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    @_('BLE REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        # ble rs, rt, offset -> bge rt, rs, offset
        global count_line
        ins_info = ins_type_B['bge']
        rs1 = Registros(p.REGISTER1)  # rt
        rs2 = Registros(p.REGISTER0)  # rs
        offset = self.label_dict[p.LABEL] - count_line

        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")
        
        imm = num_binary(offset, 13)
        
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    @_('BGTU REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        # bgtu rs, rt, offset -> bltu rt, rs, offset
        global count_line
        ins_info = ins_type_B['bltu']
        rs1 = Registros(p.REGISTER1)  # rt
        rs2 = Registros(p.REGISTER0)  # rs
        offset = self.label_dict[p.LABEL] - count_line

        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    @_('BLEU REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        # bleu rs, rt, offset -> bgeu rt, rs, offset
        global count_line
        ins_info = ins_type_B['bgeu']
        rs1 = Registros(p.REGISTER1)  # rt
        rs2 = Registros(p.REGISTER0)  # rs
        offset = self.label_dict[p.LABEL] - count_line

        if not (-4096 <= offset <= 4095):
            raise ValueError(f"Branch offset {offset} out of range for 13 bits")

        imm = num_binary(offset, 13)
        
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)

    # SALTOS INCONDICIONALES
    @_('J_PSEUDO LABEL')
    def line(self, p):
        # j offset -> jal x0, offset
        global count_line
        ins_info = ins_type_J['jal']
        rd = "00000"  # x0
        offset = self.label_dict[p.LABEL] - count_line

        if not (-1048576 <= offset <= 1048575):
            raise ValueError(f"Jump offset {offset} out of range for 21 bits")
        
        imm = num_binary(offset, 21)
        
        # Formato J: imm[20|10:1|11|19:12] rd opcode
        imm20 = imm[0]
        imm10_1 = imm[10:20]
        imm11 = imm[9]
        imm19_12 = imm[1:9]
        
        binary_instruction = f"{imm20}{imm10_1}{imm11}{imm19_12}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_j', binary_instruction)

    @_('JAL_PSEUDO LABEL')
    def line(self, p):
        # jal offset -> jal x1, offset
        global count_line
        ins_info = ins_type_J['jal']
        rd = "00001"  # x1
        offset = self.label_dict[p.LABEL] - count_line

        if not (-1048576 <= offset <= 1048575):
            raise ValueError(f"Jump offset {offset} out of range for 21 bits")
        
        imm = num_binary(offset, 21)
        #traduccion directa del offset
        #signo, pos 31
        imm20 = imm[0]

        imm10_1 = imm[10:20]
        imm11 = imm[9]
        imm19_12 = imm[1:9]
        
        binary_instruction = f"{imm20}{imm10_1}{imm11}{imm19_12}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_j', binary_instruction)

    @_('JR REGISTER')
    def line(self, p):
        # jr rs -> jalr x0, rs, 0
        global count_line
        ins_info = ins_type_I['jalr']
        rd = "00000"  # x0
        rs1 = Registros(p.REGISTER)
        imm = "000000000000"  # 0
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)

    @_('JALR_PSEUDO REGISTER')
    def line(self, p):
        # jalr rs -> jalr x1, rs, 0
        global count_line
        ins_info = ins_type_I['jalr']
        rd = "00001"  # x1
        rs1 = Registros(p.REGISTER)
        imm = "000000000000"  # 0
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)

    @_('CALL LABEL')
    def line(self, p):
        # call offset -> jalr x1, x1, offset[11:0] (versión simple)
        global count_line
        ins_info = ins_type_I['jalr']
        rd = "00001"  # x1
        rs1 = "00001"  # x1
        offset = self.label_dict.get(p.LABEL, 0)
        
        # Verificar si cabe en 12 bits
        if -2048 <= offset <= 2047:
            imm = num_binary(offset, 12)
            binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
            count_line += 4
            return ('instruction_i', binary_instruction)
        else:
            raise ValueError(f"Call offset {offset} too large for simple call implementation")

    @_('TAIL LABEL')
    def line(self, p):
        # tail offset -> jalr x0, x6, offset[11:0] (versión simple)
        global count_line
        ins_info = ins_type_I['jalr']
        rd = "00000"  # x0
        rs1 = "00110"  # x6
        offset = self.label_dict.get(p.LABEL, 0)
        
        # Verificar si cabe en 12 bits
        if -2048 <= offset <= 2047:
            imm = num_binary(offset, 12)
            binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
            count_line += 4
            return ('instruction_i', binary_instruction)
        else:
            raise ValueError(f"Tail offset {offset} too large for simple tail implementation")



    @_('NEWLINE')
    def line(self, p):
        return None

    def error(self, p):
        if p is not None:
            print(f"Error sintáctico en la línea {p.lineno}: Token inesperado '{p.value}'")
        else:
            print(f"Error sintáctico: Token inesperado al final del archivo")

if __name__ == '__main__':
    label_parser = ParserLabel()
    input_file_path = 'archivo.s48'
    output_file_path = 'instrucciones.txt'
    
    # Restablecer count_line antes de la primera pasada
    count_line = 0
    dict_label = label_parser.get_labels(input_file_path)

    lexer = RISCVLexer()
    parser = RISCVParser(dict_label)

    # Procesar todo el archivo a la vez
    with open(input_file_path, 'r') as archivo:
        full_text = archivo.read()
    
    ast = parser.parse(lexer.tokenize(full_text))

    if ast is not None:
        instrucciones = ast
    else:
        instrucciones = []

    with open(output_file_path, 'w') as output_file:
        for instruccion in instrucciones:
            if instruccion is not None:
                if instruccion[0] in ('instruction_r', 'instruction_i', 'instruction_s', 'instruction_u', 'instruction_b', 'instruction_j'):
                    output_file.write(f"{instruccion[1]}\n")
                    print(f"{instruccion[1]}")

        print(f"Total de instrucciones: {count_line // 4}")
        if count_line // 4 < 1024:
            for i in range((1024 - count_line // 4)):
                if (i == (1024 - count_line // 4) - 1):
                    output_file.write(f"00000000000000000000000000000000")
                else:
                    output_file.write(f"00000000000000000000000000000000\n")

    print(f"Instrucciones guardadas en {output_file_path}")
    print("Diccionario de Etiquetas:")
    for label, line_number in dict_label.items():
        print(f"{label}: {line_number}")