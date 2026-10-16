# Reyzn X | Amethyst Edition

Made By Reyzn.

La versión 2.2 mejora los acabados del GUI existente en `hzReyzn/Ghislain`. Conserva su distribución, sus secciones, los logos R y X, los tres controles PNG y sus funciones. No incluye funciones de juego.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hzReyzn/Ghislain/main/Reyzn%20X.lua?revision=reyzn-x-2.2"))()
```

## Cambios visuales

- **Nombre nativo y legible.** «Reyzn X» vuelve a ser texto: lettering Grenze Gotisch para Reyzn, una X recta en Gotham Bold, degradado cromado y contorno oscuro fino. El PNG del nombre ya no se descarga ni se muestra; el archivo original se conserva. «Made By Reyzn» permanece intacto.
- **Fuego exterior.** Sustituye los seis aros rectangulares por una textura transparente de fuego en capas, con variaciones de altura, desplazamiento, color y transparencia. Una base tenue conecta las llamas locales. La paleta combina amatista, rosa suave, azul frío y plata. El efecto rodea el menú, el panel desplegado y el logo minimizado, sin recortarse en la ventana de contenido.
- **Partículas reutilizables.** Fragmentos cristalinos y pequeños destellos plateados aparecen fuera de las superficies, con velocidades y duraciones diferentes. Se desvanecen y reutilizan los mismos objetos. No capturan entradas ni se dibujan encima de los textos y botones.
- **Metal y profundidad.** Sombras de contacto, carbón degradado, bordes finos, reflejos diagonales alternados y energía que recorre las esquinas redondeadas. Solo un reflejo diagonal se activa a la vez; el resto conserva su contraste.
- **Respuesta al pulsar.** Los botones comprimen ligeramente su superficie y elevan la luz antes de recuperar su escala. La zona táctil conserva su tamaño y posición. La selección cambia de forma progresiva; un segundo dedo no libera la pulsación del primero.
- **Transiciones conservadas y coordinadas.** Apertura progresiva, despliegue lateral, cambio de página, minimizar, restaurar y cierre. Las animaciones nuevas cancelan las anteriores y las transparencias se calculan desde valores base, sin pérdida acumulativa de nitidez.

## Calidad visual

En **Settings → Visual quality** puedes elegir **Low, Medium o High**. Android y los dispositivos táctiles empiezan en Medium; los demás, en High. La elección es el máximo permitido: el sistema reduce efectos tras una caída sostenida del rendimiento y los recupera más lentamente cuando mejora. No altera posiciones, dimensiones, contenido ni controles.

| Calidad | Llamas locales activas* | Partículas activas* | Actualizaciones VFX máximas | Halo secundario / reflejos |
|---|---:|---:|---:|---|
| Low | 26 | 5 | 15/s | Desactivados |
| Medium | 30 | 14 | 30/s | Activados |
| High | 52 | 26 | 30/s | Activados |

\* Suma de los tres grupos reservados. Solo se actualizan los que están visibles: la ventana y el logo minimizado no se mantienen animando simultáneamente salvo durante su transición. Cada grupo también utiliza cuatro bases de llama tenues y un pequeño reflejo de contorno. El panel oculto y la ventana totalmente fuera de pantalla suspenden sus efectos.

La adaptación utiliza el tiempo real entre `Heartbeat`, con promedio, espera inicial y tiempos distintos para bajar/subir. Una pausa aislada larga no provoca una degradación. Se puede cambiar el máximo inicial en `DEFAULT_QUALITY` o modificar el atributo `VisualQuality` del ScreenGui con `Low`, `Medium` o `High`; `EffectiveQuality` muestra el nivel activo.

## Funciones conservadas

- Home, Main, Visuals, Scripts y Settings mantienen sus nombres. Al elegir una opción se abre únicamente su panel a la derecha. Pulsar la misma opción o la flecha deja visible solo el menú.
- Main, Visuals y Scripts siguen vacíos para el trabajo posterior. Settings contiene solamente el nuevo control de calidad; no vuelve a introducir Themes, controles de tamaño ni textos de relleno.
- Avatar circular del usuario, UserId y contador `HH:MM:SS` desde cero por ejecución. El contador sigue al plegar, minimizar y reaparecer.
- Arrastre con ratón o toque desde las cabeceras. El logo R minimizado también se puede arrastrar. Se permite sacar el GUI de cualquiera de los cuatro bordes de la pantalla.
- Si queda totalmente fuera, aparece una R de recuperación. `RightShift` también minimiza, restaura o recupera la ventana.
- Controles PNG originales: línea → minimizar; flecha → plegar/desplegar; X → cerrar. Los márgenes transparentes se recortan únicamente para mostrarlos con `ImageRectOffset`/`ImageRectSize`, sin modificar sus archivos.
- Desplazamiento vertical del contenido cuando falta espacio. Deslizar una página no arrastra la ventana. Se conserva el ajuste automático al tamaño del dispositivo.

## Arquitectura y recursos

El código completo permanece en **Reyzn X.lua**, sin módulos externos descargados. Sus componentes locales reutilizables son `FireAura`, `ParticlePool`, `Quality` y el coordinador `VFX.reflections`. Comparten un solo `Heartbeat`, la gestión de tweens, las conexiones, los hilos de carga y el compositor de transparencia. Al cerrar o reejecutar se cancelan animaciones y cargas y se desconectan todos los eventos.

La animación usa objetos GUI y APIs nativas de Roblox, incluyendo `ImageLabel`, `ImageButton`, `UIGradient`, `UIStroke`, `UICorner`, `UIScale`, `TweenService` y `RunService`. No usa shaders personalizados ni emisores 3D superpuestos a la pantalla. El compositor existente evita añadir un `CanvasGroup` del tamaño de toda la ventana y su textura intermedia.

Se conservó el cargador de imágenes del proyecto: cinco PNG originales y una nueva textura de fuego, desde seis URL fijas de este repositorio. Necesita `getcustomasset` (o `getsynasset`) y `writefile` del entorno de ejecución; **esas funciones no son APIs de Roblox Studio**. `isfile`/`readfile` permiten reutilizar la caché, validando tamaño, firma y final PNG. Si faltan las APIs o falla la red, aparecen los iconos nativos de respaldo y la interfaz sigue respondiendo; el fuego texturizado no se muestra. Para imágenes nativas en una experiencia publicada, los recursos deben subirse a Roblox y usar sus IDs autorizados.

No se ejecuta ningún contenido descargado por el GUI. Los recursos del usuario están sin cambios en `assets/reyzn-x/`; [ASSET_NOTES.md](assets/reyzn-x/ASSET_NOTES.md) documenta la textura nueva y su prompt.

El repositorio original `hzReyzn/scriptshz` no se modifica. No se incorporaron scripts afiliados, mantenimiento, pantallas de carga, vídeo ni audio.

## Verificación

```sh
python tests/run.py /ruta/a/luau
```

El comando compila el archivo y ejecuta **21 escenarios deterministas**. Comprueban navegación y plegado, arrastre libre y recuperación, ratón/toque, cambios rápidos, ocho ciclos de minimizar/restaurar, reloj, avatar, seis tamaños de pantalla, carga/caché/fallos de recursos, reejecución y limpieza. Las pruebas nuevas verifican texto nativo, compatibilidad de los PNG originales, límites y reutilización de partículas, posición exterior, cancelación de pulsaciones, reflejos alternados, calidad adaptable con histéresis y geometría invariable al cambiar de calidad.

Estas pruebas simulan el cliente; no miden FPS reales ni sustituyen la comprobación del renderizado, la carga de imágenes y los gestos en Roblox/Android.
