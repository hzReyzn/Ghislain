# Reyzn X

Made By Reyzn.

GUI de Roblox en la copia de trabajo `hzReyzn/Ghislain`. La versión 2.1 toma la referencia minimalista negra, plateada y violeta: superficies metálicas, bordes nítidos y reflejos suaves. No incluye funciones de juego.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hzReyzn/Ghislain/main/Reyzn%20X.lua?revision=reyzn-x-2.1"))()
```

- Barra lateral con Home, Main, Visuals, Scripts y Settings. Elegir una opción despliega **solamente su panel hacia la derecha**. Pulsar la misma opción o la flecha de plegado deja únicamente la barra lateral.
- Main, Visuals, Scripts y Settings quedan vacíos para el trabajo posterior. Se eliminaron Themes, los ajustes de tamaño y los textos de relleno.
- Fuente Builder Sans Medium en las opciones Main, Visuals, Scripts y Settings, sus accesos y sus títulos. Home conserva su fuente anterior.
- Los dos textos de marca «Reyzn X» ahora usan el PNG de texto metálico suministrado. «Made By Reyzn» se mantiene como texto. La X de la portada y la R minimizada conservan sus imágenes originales. Todos los PNG se guardan sin cambios en `assets/reyzn-x/`.
- Los tres controles usan los PNG suministrados: línea → minimizar, flecha → plegar/desplegar el panel, X → cerrar. La zona pulsable permanece fija mientras la imagen anima el brillo y la presión. Se descartan únicamente los márgenes transparentes al mostrarlos mediante `ImageRectOffset`/`ImageRectSize`; no se modifican los archivos.
- Aura exterior inspirada en Ultra Instinto: halo plateado, luz blanca con reflejos fríos/violetas y 44 pequeñas estelas reutilizables en total. Rodea el menú, el panel visible y el logo minimizado; se sincroniza con el plegado y los desvanecimientos. Sus elementos no capturan clics y el aura del panel queda fuera del contenedor de recorte.
- Avatar circular real, UserId y contador `HH:MM:SS`, desde cero por ejecución; el tiempo continúa mientras está plegado o minimizado y después de reaparecer.
- Arrastre con ratón o toque desde la parte superior de la barra lateral o del panel. El botón R minimizado también se arrastra. **El arrastre permite salir de la pantalla** y no se limita al rectángulo del dispositivo.
- Si la interfaz queda completamente fuera, aparece una pequeña R en el borde izquierdo para recuperarla. `RightShift` también minimiza/restaura o recupera una interfaz fuera de pantalla.
- Controles: línea para minimizar a la R, flecha para plegar/desplegar el panel y cruz para cerrar. No hay maximizar ni ajustes manuales de tamaño; la distribución se adapta automáticamente al dispositivo.
- Desvanecimientos de minimizar, restaurar y cerrar con brillo breve y escala sutil. Una nueva acción sustituye a la transición anterior sin acumular transparencia ni mover la ventana. El cierre es definitivo para esa ejecución.
- Página Home con desplazamiento vertical cuando falta altura. Deslizar el contenido no arrastra la ventana. Los eventos distinguen el dedo que inició el arrastre.

Los PNG se descargan una sola vez desde seis URL fijas de este repositorio y se reutilizan desde caché, validando tamaño, cabecera y final PNG. Necesitan `getcustomasset` (o `getsynasset`) y `writefile` en el entorno de ejecución; `readfile` e `isfile` permiten reutilizar la caché. No son IDs de imágenes subidas a Roblox. Si el entorno no admite estos recursos, se muestran textos e iconos nativos de respaldo y el GUI sigue respondiendo. No se ejecuta ningún contenido descargado por el GUI.

El hub original `hzReyzn/scriptshz` permanece intacto. No se incorporaron scripts afiliados, pantallas de mantenimiento o carga, vídeos ni audio.

## Verificación

```sh
python tests/run.py /ruta/a/luau
```

El comando compila el script y ejecuta 17 escenarios deterministas: panel independiente, cambios rápidos, arrastre por los cuatro bordes, recuperación, ratón y toque, minimizar repetidamente e interrumpir transiciones, carga/caché/fallos de PNG, contador, avatar, tamaños móviles, reejecución y limpieza de conexiones. También comprueban los dos textos PNG, las acciones de los botones de imagen y que el aura quede fuera del marco, use una cantidad fija de objetos y desaparezca con su interfaz. Las pruebas usan un entorno simulado; no sustituyen la comprobación del renderizado y los gestos en Roblox y en el ejecutor real.
