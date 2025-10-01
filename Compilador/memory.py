
class MemoryManager:
    def __init__(self, base_addr=0x10010000):
       # base_addr: Dirección base donde empieza la memoria de datos (por defecto 0x10010000)
        self.base_addr = base_addr
        self.memory = {}  # Diccionario para almacenar las variables (etiqueta -> info)
        self.current_addr = base_addr

    # ======================
    # --- MANEJO DE DATA ---
    # ======================
    def add_data(self, label, dtype, value):
        """
        Agrega una variable a la sección .data
        
        Parámetros:
        - label: nombre de la variable o etiqueta en ensamblador
        - dtype: tipo de dato ('.word' = 4 bytes, '.half' = 2 bytes, '.byte' = 1 byte)
        - value: valor a almacenar
        """
        # Guardar en memoria
        if dtype == ".word":
            size = 4
        elif dtype == ".half":
            size = 2
        elif dtype == ".byte":
            size = 1
        else:
            raise ValueError(f"Tipo de dato no soportado: {dtype}")

         # Guardar en memoria (diccionario)
        addr = self.current_addr
        self.memory[label] = {
            "addr": self.current_addr,
            "type": dtype,
            "value": value
        }

        # Avanzar la dirección actual para el siguiente dato
        self.current_addr += size

    def jump_data(self): #mostrar en consola la memoria de datos
        for label, info in self.memory.items():
            print(f"{label} ({info['type']}): addr={hex(info['addr'])}, value={info['value']}")