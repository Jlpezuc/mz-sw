# user – codigo que cambia con cada experimento

Aqui va lo que un usuario del MicroZohm edita continuamente; el resto de `src/` es la plataforma
(arranque, drivers, comunicacion con el scope) y no deberia hacer falta tocarlo.

* `isr.c` / `isr.h`: la interrupcion de control (`ISR_Control`). Plantilla minima: leer ADC,
  bloque de control, senales al scope. Ver `docs` -> *RPU Software / Interrupts*.
* Anadir aqui ficheros de parametros, tablas de calibracion, algoritmos, etc. Vitis los compila
  solos (la carpeta `src/` esta enlazada entera en el proyecto Baremetal).

Datos que se usan desde aqui (`globalData.h`): `Global_Data.aa` (ADC), `Global_Data.cv`
(consignas de la GUI), `Global_Data.sv` (senales del scope, lista `MZ_SCOPE_SIGNALS`),
`Global_Data.av` (variables globales). Botones y consignas de la GUI: `app/javascope.h`
(`gui_button_mapping`) + `app/ipc_ARM.c`.
