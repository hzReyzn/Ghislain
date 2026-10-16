# Reyzn X | Amethyst Edition

Made By Reyzn.

La versión 2.3 mejora los acabados del GUI existente en `hzReyzn/Ghislain`. Conserva su distribución, sus secciones, los logos R y X, los tres controles PNG y sus funciones. Incorpora los cuatro iconos y el fondo suministrados por el usuario. No incluye funciones de juego.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hzReyzn/Ghislain/main/Reyzn%20X.lua?revision=reyzn-x-2.3"))()
```

## Cambios visuales

- **Nombre nativo y legible.** «Reyzn X» vuelve a ser texto: lettering Grenze Gotisch para Reyzn, una X recta en Gotham Bold, degradado cromado y contorno oscuro fino. El PNG del nombre ya no se descarga ni se muestra; el archivo original se conserva. «Made By Reyzn» permanece intacto.
- **Fuego exterior Ultra High.** Dos lenguas ascendentes por raíz se alternan con envolventes complementarias, variaciones de altura, inclinación y desplazamiento. Las bases permanecen junto al borde; los reinicios de ciclo ocurren con transparencia total y pendiente cero. Los sprites tienen mayor altura e intensidad y proporciones más naturales: ya no se aplana una llama a lo largo de un lado entero. La paleta combina amatista, rosa, azul frío y plata. Rodea el menú, el panel desplegado y el logo minimizado, detrás del contenido.
- **Partículas reutilizables.** Fragmentos cristalinos y pequeños destellos plateados aparecen fuera de las superficies, con velocidades y duraciones diferentes. Se desvanecen y reutilizan los mismos objetos. No capturan entradas ni se dibujan encima de los textos y botones.
- **Luz interior y acabado inferior.** Cuatro campos de luz por superficie se desplazan lentamente dentro de sus bordes, con desvanecimiento hacia el interior. Se eliminó la sombra exterior que causaba la franja negra inferior y el contorno morado adicional del logo minimizado. Los logos originales conservan sus píxeles. Se mantienen el carbón degradado, los bordes metálicos, la energía que recorre las esquinas y un único reflejo diagonal activo a la vez.
- **Respuesta al pulsar.** Los botones comprimen ligeramente su superficie y elevan la luz antes de recuperar su escala. La zona táctil conserva su tamaño y posición. La selección cambia de forma progresiva; un segundo dedo no libera la pulsación del primero.
- **Transiciones conservadas y coordinadas.** Apertura progresiva, despliegue lateral, cambio de página, minimizar, restaurar y cierre. Las animaciones nuevas cancelan las anteriores y las transparencias se calculan desde valores base, sin pérdida acumulativa de nitidez.

- **Rajdhani.** Todas las opciones de navegación, los accesos Main/Visuals y el título de sección usan Rajdhani SemiBold mediante `FontFace`, con el recurso oficial de Roblox `12187375422`. «Reyzn X», «Made By Reyzn», el ID y el reloj conservan sus fuentes.
- **Iconos suministrados.** Casa → Home; cubo → Main y su acceso directo; pergamino → Scripts; controles deslizantes → Settings. Se muestran completos con `ScaleType.Fit`, manteniendo sus colores y **85% de transparencia** (`ImageTransparency = 0.85`, es decir, 15% de opacidad). Visuals conserva su icono porque no se proporcionó un reemplazo.
- **Fondo suministrado.** Se aplica al menú y al panel principal con esquinas redondeadas, ajuste proporcional y **76% de transparencia** (`ImageTransparency = 0.76`). Está detrás del contenido y no captura toques.

## Calidad visual

**Ultra High es fijo desde el inicio, también en Android.** Se retiraron el selector Low/Medium/High y la adaptación automática. Settings vuelve a estar vacío. No hay opciones de PERFORMANCE ni ajustes de calidad ocultos.

Se reservan **74 raíces de fuego con dos capas cada una** (148 imágenes que comparten una textura), **32 partículas** y ocho campos de luz interior. Un único `Heartbeat` actualiza los VFX hasta **60 veces por segundo**, con tiempo real acumulado; esto es un límite de actualización, no una garantía de 60 FPS en todos los dispositivos. Los atributos del ScreenGui solo informan de la versión y el nivel fijo.

Los mismos objetos se reutilizan durante toda la sesión. Se suspenden las animaciones de los grupos ocultos o totalmente fuera de pantalla; la cantidad y el detalle del efecto visible no se reducen. La ventana y el logo minimizado solo se animan a la vez durante su transición. No se crean instancias por fotograma ni se cambia la geometría del GUI según el rendimiento.

## Funciones conservadas

- Home, Main, Visuals, Scripts y Settings mantienen sus nombres. Al elegir una opción se abre únicamente su panel a la derecha. Pulsar la misma opción o la flecha deja visible solo el menú.
- Main, Visuals, Scripts y Settings siguen vacíos para el trabajo posterior. No se incluyen Themes, controles de tamaño ni textos de relleno.
- Avatar circular del usuario, UserId y contador `HH:MM:SS` desde cero por ejecución. El contador sigue al plegar, minimizar y reaparecer.
- Arrastre con ratón o toque desde las cabeceras. El logo R minimizado también se puede arrastrar. Se permite sacar el GUI de cualquiera de los cuatro bordes de la pantalla.
- Si queda totalmente fuera, aparece una R de recuperación. `RightShift` también minimiza, restaura o recupera la ventana.
- Controles PNG originales: línea → minimizar; flecha → plegar/desplegar; X → cerrar. Los márgenes transparentes se recortan únicamente para mostrarlos con `ImageRectOffset`/`ImageRectSize`, sin modificar sus archivos.
- Desplazamiento vertical del contenido cuando falta espacio. Deslizar una página no arrastra la ventana. Se conserva el ajuste automático al tamaño del dispositivo.

## Arquitectura y recursos

El código completo permanece en **Reyzn X.lua**, sin módulos externos descargados. Sus componentes locales reutilizables son `FireAura`, `ParticlePool`, `InwardLight` y el coordinador `VFX.reflections`. Comparten un solo `Heartbeat`, la gestión de tweens, las conexiones, los hilos de carga y el compositor de transparencia. Al cerrar o reejecutar se cancelan animaciones y cargas y se desconectan todos los eventos.

La animación usa objetos GUI y APIs nativas de Roblox, incluyendo `ImageLabel`, `ImageButton`, `UIGradient`, `UIStroke`, `UICorner`, `UIScale`, `TweenService` y `RunService`. No usa shaders personalizados ni emisores 3D superpuestos a la pantalla. El compositor existente evita añadir un `CanvasGroup` del tamaño de toda la ventana y su textura intermedia.

Se conservó el cargador de imágenes del proyecto: diez PNG suministrados y una textura de fuego compartida, desde once URL fijas de este repositorio. Necesita `getcustomasset` (o `getsynasset`) y `writefile` del entorno de ejecución; **esas funciones no son APIs de Roblox Studio**. `isfile`/`readfile` permiten reutilizar la caché, validando tamaño, firma y final PNG. Si faltan las APIs o falla la red, aparecen los iconos nativos de respaldo y la interfaz sigue respondiendo; el fuego texturizado no se muestra. Para imágenes nativas en una experiencia publicada, los recursos deben subirse a Roblox y usar sus IDs autorizados.

No se ejecuta ningún contenido descargado por el GUI. Los recursos del usuario están sin cambios en `assets/reyzn-x/`; [ASSET_NOTES.md](assets/reyzn-x/ASSET_NOTES.md) documenta la textura nueva y su prompt.

El repositorio original `hzReyzn/scriptshz` no se modifica. No se incorporaron scripts afiliados, mantenimiento, pantallas de carga, vídeo ni audio.

## Verificación

```sh
python tests/run.py /ruta/a/luau
```

El comando compila el archivo y ejecuta **22 escenarios deterministas**. Comprueban navegación y plegado, arrastre libre y recuperación, ratón/toque, cambios rápidos, ocho ciclos de minimizar/restaurar, reloj, avatar, seis tamaños de pantalla, carga/caché/fallos de recursos, reejecución y limpieza. Las pruebas nuevas verifican texto nativo, compatibilidad de los PNG originales, límites y reutilización de partículas, posición exterior, cancelación de pulsaciones, reflejos alternados, Ultra High fijo incluso con tiempos de fotograma altos, ciclos de fuego continuos a 60 Hz, iluminación interior contenida, Rajdhani, correspondencia de iconos, transparencias exactas después de inversiones de transición y ausencia de la sombra inferior/contorno adicional.

Estas pruebas simulan el cliente; no miden FPS reales ni sustituyen la comprobación del renderizado, la carga de imágenes y los gestos en Roblox/Android.
