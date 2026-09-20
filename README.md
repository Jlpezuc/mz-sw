# mz-sw – MicroZohm

Repositorio de software y lógica programable del **MicroZohm** (plataforma de control en
tiempo real para electrónica de potencia basada en Zynq UltraScale+). Es la versión
reducida y reorganizada del repositorio heredado del UltraZohm; el árbol original se
conserva en `../mz-sw (old)`.

| Carpeta | Contenido |
|---|---|
| `docs/` | Documentación (Sphinx). Fuentes en `docs/source`, HTML generado en `docs/build/html/index.html` |
| `ip_cores/` | IP cores de la PL, empaquetados como `microzohm:user:*` (ver `ip_cores/README.md`) |
| `vivado/` | Proyecto Vivado `microzohm`: `build.tcl` genera `project/microzohm.xpr` a partir de `bd/mzsys.tcl` (ver `vivado/README.md`) |
| `vitis/` | Software del PS: R5 baremetal (`software/Baremetal`), A53 FreeRTOS (`software/FreeRTOS`), FSBL, workspace (ver `vitis/README.md`) |
| `tcl_scripts/` | Scripts Tcl: `vivado_*` (exportar XSA, limpiar), `vitis_*` (generar/actualizar el workspace, debug) y `ci_*` |
| `safety_controller/` | Proyectos Lattice Diamond del CPLD de seguridad (sin cambios) |
| `mzscope/` | MicroZohm Scope: osciloscopio/registrador/control en Python (sustituye al JavaScope, mismo protocolo) |
| `javascope/` | JavaScope original (Java), solo como referencia; no se mantiene |

Flujo de trabajo resumido (detalles en la documentación, *Getting-Started → MicroZohm Setup*):

1. `vivado`: `source build.tcl` → *Generate Bitstream* → `source ../../tcl_scripts/vivado_export_xsa.tcl`
2. `vitis`: workspace `vitis/workspace`, consola XSCT: `cd [getws]; source {../../tcl_scripts/vitis_generate_MicroZohm_workspace.tcl}`
3. Depurar con la configuración `Debug_FreeRTOS_Baremetal_FPGA` y conectar el scope (`cd mzscope && run.bat`, placa en `192.168.1.233`).

Para regenerar la documentación: `cd docs && pip install -r requirements.txt && make html` (requiere `doxygen` en el PATH).
