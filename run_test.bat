@echo off
echo =========================================
echo   SIMULACION MONOCICLO - TIPO R
echo =========================================
echo.

REM Limpiar archivos anteriores
echo Limpiando archivos anteriores...
if exist *.vvp del /Q *.vvp
if exist *.vcd del /Q *.vcd
echo.

REM Compilar con iverilog
echo Compilando con iverilog...
iverilog -g2012 -o monocycle_sim.vvp ^
  PC/pc.sv ^
  ALU/alu.sv ^
  REGISTER_UNIT/register_unit.sv ^
  SUMADOR/sumador.sv ^
  IMEM/instruction_memory.sv ^
  DECODER/instruction_decoder.sv ^
  CONTROL/control_unit.sv ^
  MONOCYCLE/monocycle.sv ^
  MONOCYCLE/tb_monocycle.sv

if errorlevel 1 (
    echo.
    echo ERROR: Compilacion fallida
    echo Verifica que iverilog este instalado y en el PATH
    pause
    exit /b 1
)

echo Compilacion exitosa!
echo.

REM Ejecutar simulación
echo =========================================
echo   EJECUTANDO SIMULACION
echo =========================================
echo.
vvp monocycle_sim.vvp

if errorlevel 1 (
    echo.
    echo ERROR: Simulacion fallida
    pause
    exit /b 1
)

echo.
echo =========================================
echo   SIMULACION COMPLETADA
echo =========================================

REM Verificar archivos generados
if exist tb_monocycle.vcd (
    echo.
    echo [OK] Archivo de forma de onda generado: tb_monocycle.vcd
    echo Para ver las formas de onda ejecuta: gtkwave tb_monocycle.vcd
)

echo.
pause