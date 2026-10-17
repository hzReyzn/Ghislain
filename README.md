# Reyzn X | Amethyst Edition

Made By Reyzn.

**Versión pública: 1.0.** Este valor se cambia únicamente cuando Reyzn lo solicita explícitamente. Las correcciones visuales no incrementan la versión. El identificador interno `Build` permite distinguir cambios de código sin alterar la versión mostrada.

```lua
local url = "https://raw.githubusercontent.com/hzReyzn/Ghislain/main/Reyzn%20X.lua"
local source = game:HttpGet(url .. "?build=fly-ss3-fe-20261017&t=" .. tostring(os.time()))
loadstring(source)()
```

## Main: interruptores y ejecutables

Main separa los controles en dos columnas: **No Fall Damage** con **OFF / ON** a la izquierda y el ejecutable **FLY SS3 FE** a la derecha. Entre ambos quedan un espacio libre y una línea con 88% de transparencia y extremos desvanecidos. No se agregan descripciones ni encabezados. Los controles mantienen el acabado metálico, Rajdhani y el neón del Hub; en pantallas estrechas el contenido permite desplazamiento horizontal para conservar botones legibles y táctiles.

**No Fall Damage** empieza en OFF. El diseño apagado es carbón y gris; al activar aparecen el neón celeste/amatista, un destello breve y una compresión suave. Al apagar, el destello se cancela y el brillo se desvanece. La tarjeta mide hasta 340 × 60 px; en columnas estrechas acomoda el estado debajo del título, sin agrandar el Hub.

Se integra el mecanismo del código suministrado: guardar la velocidad de `HumanoidRootPart`, ponerla a cero en `Heartbeat` y restaurarla en `RenderStepped`. Su comprobación de juego se conserva: **Natural Disaster Survival, PlaceId 189707**. En otros lugares permanece OFF y se informa por consola, sin cerrar el GUI ni añadir textos al panel. Se omite la escritura al portapapeles del ejemplo porque no forma parte del efecto.

El controlador conserva ON al morir, reaparecer, cambiar de sección, plegar, minimizar o arrastrar el GUI fuera de pantalla. Mientras falta el personaje o su raíz, sigue habilitado y espera sus eventos; no crea esperas bloqueantes. También admite una raíz reemplazada dentro del mismo personaje. Solo OFF manual o la destrucción completa del GUI desconectan el efecto. Reejecutar destruye primero la instancia anterior y empieza de nuevo en OFF.

La adaptación evita acumular `RenderStepped:Wait()` dentro de Heartbeat. Mantiene una sola restauración pendiente, la libera antes de física si no hubo renderizado y descarta callbacks de activaciones anteriores. OFF y cierre restauran el valor pendiente si todavía corresponde a la escritura del controlador; una velocidad nueva distinta de cero aplicada por otro script se respeta. No modifica salud, colisiones, gravedad ni estados del Humanoid. Esto reduce conflictos, pero no garantiza compatibilidad con cualquier controlador externo ni la cancelación del daño calculado por el servidor: esas dos cosas requieren probarse en el juego real.

### FLY SS3 FE

Un clic abre el GUI independiente **FLY DBZ**, inicialmente OFF y con velocidad 5. Los clics repetidos conservan la misma ventana y sus ajustes. Su interruptor externo activa/desactiva el vuelo y la animación; permite editar la velocidad mientras se vuela, con pasos de 5 y límite 5000. Mantiene WASD/joystick, arrastre, animación SSJ3 compatible y ausencia de VFX/aviso. Morir, reiniciar o reemplazar la raíz lo deja OFF hasta pulsar ON de nuevo.

La protección principal de Reyzn X tiene prioridad mientras está ON: la de FLY se suspende sin detener el vuelo. Al apagar la principal, FLY retoma su protección solo si sigue activo. Un registro local compartido permite un único escritor de velocidad, termina cualquier pulso pendiente antes de transferir el control y evita restauraciones obsoletas. La prioridad funciona aunque FLY se haya ejecutado por separado antes de abrir el Hub. Ambos conservan el filtro de PlaceId 189707.

FLY conserva su ventana y ciclo de vida independientes: cerrar Reyzn X libera la prioridad y permite que el vuelo activo continúe; cerrar FLY elimina sus propios recursos y no apaga la opción principal. Reejecutar el Hub empieza su interruptor principal en OFF sin duplicar ni reiniciar un FLY que ya esté abierto.

La copia de [`features/FLY-SSJ3.lua`](features/FLY-SSJ3.lua) está incluida como función en el archivo distribuido: el clic no depende de descargar ni compilar código remoto. Para actualizarla desde el repositorio FLY-SSJ3, ejecuta `python tools/sync_fly.py ../fly-ssj3/FLY-SSJ3.lua`; sin argumento vuelve a incluir la copia guardada. Las pruebas exigen igualdad exacta entre la copia, la función incluida y los coordinadores.

## Fuego compartido, neón celeste y aviso de carga

El menú y el panel usan ahora el mismo fuego ascendente aprobado en el **logo R minimizado**: textura, colores, mezcla de capas y ritmo de animación compartidos. Se retiró el sistema anterior de llamas orientadas hacia los cuatro lados. Las fuentes del Hub se distribuyen por el contorno, pero todas las llamas suben; los efectos quedan detrás del contenido.

- La imagen R original mantiene sus bytes y colores. Su región visible se ajusta dentro del mismo botón de 68 × 68; no se añade un marco. Un reflejo diagonal discreto y una compresión de 3.5% responden sin mover la zona de toque ni bloquear el arrastre.
- El fuego nace en una base común debajo del logo. Ocho fuentes superpuestas mezclan dos llamas completas y un núcleo luminoso por fuente, con alturas y ciclos escalonados. Seis volutas y ocho brasas suben y desaparecen progresivamente; las llamas no se orientan hacia los lados ni hacia abajo.
- Púrpura, celeste y rosa oscuro forman el volumen del fuego. Las capas completas evitan costuras de franjas y las transiciones complementarias mantienen encendida la base sin saltos visibles al reiniciar cada ciclo. El tamaño de las llamas del Hub se adapta al espacio disponible sin cambiar la escala ni la posición del GUI.
- El aviso inferior derecho muestra exactamente **The script has loaded successfully :))**. Entra desde la derecha en 0.48 segundos, permanece completamente visible **4 segundos** y sale hacia la derecha en 0.42 segundos, con transparencia progresiva y una superficie de obsidiana metálica.
- El aviso tiene una superficie de carbón con reflejos celestes, un indicador de éxito, el mensaje en dos líneas y un borde metálico animado. Su propia aura conserva doce fuentes, ocho volutas y ocho brasas. No captura toques. Su posición se adapta al área segura de pantalla y su duración continúa al minimizar, plegar o arrastrar el GUI fuera de la pantalla.
- Tras salir, el aviso elimina sus instancias y se retira del compositor de transparencia y del conjunto de imágenes VFX. Cerrar o reejecutar el script cancela también el aviso; las descargas tardías no lo recrean.

## Neón integrado

El celeste **RGB(141, 220, 255)** del fuego también ilumina el menú, el panel, Home y las cinco opciones de navegación. Es parte del diseño fijo; no se agrega un selector de color, tema ni calidad.

`NeonFlow` desplaza suavemente los degradados de color y de transparencia. Cada zona tiene una fase distinta: el botón seleccionado recibe más luz, los demás conservan un acabado discreto, y los textos e iconos permanecen por encima del neón. Los reflejos puntuales anteriores siguen coordinados para evitar destellos simultáneos. La luz interior ahora combina celeste y amatista; el neón de la X grande conserva su animación rosa/morado.

## Home

- El nombre visible es **Reyzn** en el menú y en Home. Se retiraron únicamente las dos X tipográficas; el emblema X grande y el logo R minimizado se conservan.
- El botón Main, su línea decorativa y los accesos rápidos Main/Visuals de Home se eliminaron. Las cinco opciones del menú lateral siguen presentes.
- Home muestra **Status: Active** y **Version: 1.0**. Active indica que esta interfaz está ejecutándose; no representa una consulta de disponibilidad a servidores externos.
- El emblema X tiene dos capas de brillo y un reflejo rosa/morado que viajan de izquierda a derecha. Las capas alternan su intensidad y se reinician invisibles, sin salto luminoso. El PNG original permanece intacto debajo de los efectos.
- Los campos de luz interiores se mueven y se desvanecen tanto hacia el centro como en sus extremos. Se retiró su silueta de barra redondeada. El brillo es más notable y mantiene libres los textos y controles.

## Fondo, iconos y tipografía

El fondo suministrado se muestra en el menú, el panel principal y la tarjeta Home con **83% de transparencia** (`ImageTransparency = 0.83`). Las capas de imagen tienen un orden explícito y quedan debajo del contenido.

**Corrección del fondo invisible:** el adjunto `1000190889.png` contiene bytes JPEG, aunque su nombre termina en PNG. La validación anterior lo rechazaba. Ahora se conserva exactamente la imagen original como `background-cyber-v2.jpg`, con nombre de caché nuevo y validación JPEG. No se convirtió, recomprimió ni retocó la imagen. Las pruebas inspeccionan el formato real de cada recurso del repositorio.

| Opción | Icono suministrado | Transparencia |
|---|---|---:|
| Home | Casa amatista | 85% |
| Main | Cubo amatista | 85% |
| Visuals | Estrella cristalina rosa | 85% |
| Scripts | Pergamino amatista | 85% |
| Settings | Controles deslizantes rosas | 85% |

Los iconos conservan sus colores, se ajustan proporcionalmente y usan `ImageTransparency = 0.85`, es decir, 15% de opacidad. **Rajdhani SemiBold** se mantiene en las opciones y títulos de sección con el recurso oficial de Roblox `12187375422` y `FontFace`. Reyzn utiliza su lettering nativo cromado; Made By Reyzn permanece intacto.

## Funciones conservadas

- Home, Main, Visuals, Scripts y Settings mantienen sus nombres y funciones en el menú lateral. Main contiene No Fall Damage y FLY SS3 FE; Visuals, Scripts y Settings siguen vacías para el trabajo posterior.
- Cada sección se despliega a la derecha. Pulsar la misma opción o el control de plegado deja visible solo el menú.
- Arrastre libre con ratón o toque, también en el logo R minimizado. Es posible sacar la interfaz de la pantalla y recuperarla mediante la R auxiliar o RightShift.
- Avatar circular del usuario, UserId y contador desde cero por ejecución, independiente de minimizar, plegar o reaparecer.
- Los tres controles PNG conservan sus acciones: minimizar, plegar/desplegar y cerrar. Las animaciones pueden invertirse sin acumular transparencia ni desplazar sus zonas táctiles.
- El contenido se puede desplazar verticalmente cuando no cabe en el dispositivo. Los efectos no capturan toques.
- Ultra High permanece fijo: el menú y el panel reutilizan 19 y 36 fuentes de fuego, respectivamente; el logo conserva sus ocho fuentes. Cada fuente tiene dos capas de llama y un núcleo. Los tres grupos comparten un presupuesto fijo de 22 volutas y 24 brasas. El aviso utiliza un conjunto temporal que se destruye al terminar. Los efectos visibles se actualizan hasta 60 veces por segundo. Esto no garantiza 60 FPS en todos los dispositivos. No hay selector de calidad ni reducción automática.

## Recursos y ejecución

El código completo está en **Reyzn X.lua**. `UpdraftFire`, `NeonFlow`, `LoadToast`, `FeatureToggle`, `InwardLight`, `EmblemNeon` y el coordinador de reflejos comparten un solo Heartbeat visual, el compositor de transparencia y la limpieza de recursos. Reutilizan objetos; las animaciones ocultas se suspenden y se cancelan las conexiones, cargas y tweens al cerrar o reejecutar. `NoFallDamage` tiene conexiones independientes mientras está ON, para que el comportamiento no dependa de la visibilidad ni de la frecuencia de los VFX. Sus listas de conexiones se vacían en OFF y al cerrar.

El cargador conserva la integración de este proyecto con `getcustomasset`/`getsynasset` y `writefile`; **estas funciones pertenecen al entorno de ejecución, no a Roblox Studio**. Los doce recursos fijos del repositorio son once PNG y un JPEG. Se valida su tamaño y firma real; `isfile`/`readfile` permiten reutilizar la caché. Si una descarga falla, la interfaz sigue operativa y utiliza los iconos nativos de respaldo. El contenido descargado por el GUI nunca se ejecuta: solo son imágenes.

La interfaz y los VFX usan APIs nativas como UIGradient, UIStroke, UICorner, ImageLabel, UIScale, TweenService y RunService. No se añadieron shaders ni dependencias de código externas. El repositorio original `hzReyzn/scriptshz` no se modifica.

Los PNG originales y el JPEG se conservan sin modificaciones. [ASSET_NOTES.md](assets/reyzn-x/ASSET_NOTES.md) documenta su procedencia.

## Verificación

```sh
python tests/run.py /ruta/a/luau
```

El comando compila el Luau, comprueba el formato y tamaño de los doce recursos reales y ejecuta **42 escenarios deterministas**. Incluye navegación y plegado, gestos, arrastre libre, recuperación, inversiones de animación, reloj, seis tamaños de pantalla, caché/fallos de recursos, limpieza, transparencia exacta del fondo, JPEG válido/inválido, versión 1.0 estable, barrido del emblema sin saltos, fuego ascendente sin asignaciones por fotograma, gestos del logo, temporización y limpieza del aviso, cambios de orientación, descargas que terminan después de desaparecer la notificación, dirección y paleta del fuego compartido, neón bajo el contenido y suspensión de las animaciones ocultas.

Las nueve pruebas nuevas cubren OFF inicial y dimensiones, pulsos/restauración de velocidad, muerte y respawn tardío, raíz reemplazada, efecto independiente de la visibilidad, restauración al apagar y coexistencia con otra escritura, cambios ON/OFF repetidos, callbacks obsoletos, cierre/destrucción/reejecución, bloqueo fuera de PlaceId 189707 y respuesta visual/táctil del control.

También ejecuta **15 escenarios de integración** con el código completo de ambos controladores: distribución en seis tamaños, lanzamiento único, velocidad en vivo, prioridad en ambos órdenes de ejecución, restauraciones pendientes y callbacks retrasados, muerte, raíz reemplazada, reejecución, cierre independiente y limpieza del registro compartido. El controlador FLY conserva sus 26 pruebas en su repositorio.

Las pruebas simulan el cliente. Ninguna sustituye el renderizado, la medición de FPS ni una caída real en Roblox/Android.
