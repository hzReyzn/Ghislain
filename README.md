# Reyzn X | Amethyst Edition

Made By Reyzn.

**Versión pública: 1.0.** Este valor se cambia únicamente cuando Reyzn lo solicita explícitamente. Las correcciones visuales no incrementan la versión. El identificador interno `Build` permite distinguir cambios de código sin alterar la versión mostrada.

```lua
local url = "https://raw.githubusercontent.com/hzReyzn/Ghislain/main/Reyzn%20X.lua"
loadstring(game:HttpGet(url .. "?build=water-antifling-20261017&t=" .. tostring(os.time())))()
```

**Cargador permanente elegido por Reyzn:** mantener exactamente estas dos líneas, también después de agregar funciones o actualizar el código. Está guardado en `Loader.lua` y verificado por las pruebas. El parámetro `build=water-antifling-20261017` permanece fijo; `t` ya cambia en cada ejecución. El atributo interno `Build` del GUI puede identificar una revisión sin modificar este cargador ni la versión pública.

## Scripts: ejecutables externos

Dos botones compactos conservan Rajdhani, la superficie metálica, el neón y la respuesta táctil del Hub. Solo muestran sus nombres:

- **Telekinesis UI** → `https://scriptblox.com/raw/Universal-Script-Telekinesis-Ui-95037`
- **Super Black Hole** → `https://scriptblox.com/raw/Natural-Disaster-Survival-Ultra-Blackhole-and-Super-ring-no-lying-Full-FE+Keyless-228862`

Cada botón descarga y ejecuta su enlace únicamente al pulsarlo. No se ejecutan al abrir el Hub ni al cambiar de sección. La descarga y ejecución tienen un bloqueo independiente por botón para evitar duplicados durante una carga; los errores de red, compilación o arranque se capturan y permiten reintentar. El estado `ExecutableState` y la consola permiten distinguir `loading`, `running`, `ready` y `error` sin añadir descripciones al GUI.

Cerrar Reyzn X cancela sus descargas pendientes y evita un arranque tardío. Una vez iniciado, cada script externo conserva su propio ciclo de vida. Estos dos scripts no se reescriben ni se integran en el coordinador físico interno del Hub; sus enlaces y comportamiento dependen de la fuente externa. Las pruebas usan respuestas simuladas y no ejecutan el contenido real de ScriptBlox.

## Main: interruptores y ejecutables

Main separa los controles en dos columnas: **No Fall Damage**, **Walk on Water**, **Antifling** y **Disaster Prediction**, con **OFF / ON**, a la izquierda; el ejecutable **FLY SS3 FE** a la derecha. **Predict Disaster** queda inmediatamente debajo de Disaster Prediction para consultar manualmente. Entre las columnas quedan un espacio libre y una línea con 88% de transparencia y extremos desvanecidos. No se agregan descripciones ni encabezados. Los controles mantienen el acabado metálico, Rajdhani y el neón del Hub; en pantallas estrechas el contenido permite desplazamiento horizontal para conservar botones legibles y táctiles, y vertical para alcanzar todas las filas.

**No Fall Damage** empieza en OFF. El diseño apagado es carbón y gris; al activar aparecen el neón celeste/amatista, un destello breve y una compresión suave. Al apagar, el destello se cancela y el brillo se desvanece. La tarjeta mide hasta 340 × 60 px; en columnas estrechas acomoda el estado debajo del título, sin agrandar el Hub.

Se integra el mecanismo del código suministrado: guardar la velocidad de `HumanoidRootPart`, ponerla a cero en `Heartbeat` y restaurarla en `RenderStepped`. Su comprobación de juego se conserva: **Natural Disaster Survival, PlaceId 189707**. En otros lugares permanece OFF y se informa por consola, sin cerrar el GUI ni añadir textos al panel. Se omite la escritura al portapapeles del ejemplo porque no forma parte del efecto.

El controlador conserva ON al morir, reaparecer, cambiar de sección, plegar, minimizar o arrastrar el GUI fuera de pantalla. Mientras falta el personaje o su raíz, sigue habilitado y espera sus eventos; no crea esperas bloqueantes. También admite una raíz reemplazada dentro del mismo personaje. Solo OFF manual o la destrucción completa del GUI desconectan el efecto. Reejecutar destruye primero la instancia anterior y empieza de nuevo en OFF.

La adaptación evita acumular `RenderStepped:Wait()` dentro de Heartbeat. Mantiene una sola restauración pendiente, la libera antes de física si no hubo renderizado y descarta callbacks de activaciones anteriores. OFF y cierre restauran el valor pendiente si todavía corresponde a la escritura del controlador; una velocidad nueva distinta de cero aplicada por otro script se respeta. Los controladores integrados de agua y Antifling invalidan expresamente un pulso cuando corrigen su velocidad, incluso si la corrección es cero. No modifica salud, colisiones, gravedad ni estados del Humanoid. Esto reduce conflictos, pero no garantiza compatibilidad con cualquier controlador externo ni la cancelación del daño calculado por el servidor: esas dos cosas requieren probarse en el juego real.

### Walk on Water y Antifling

Ambos parten de los controladores de HzReyzn Hub. Comienzan **OFF**, conservan la intención **ON** al morir o reiniciar y vuelven a enlazarse con el personaje nuevo. Mientras faltan el Humanoid o la raíz, el personaje está muerto, fuera de Workspace o bajo el límite del vacío, liberan sus recursos físicos y esperan. OFF manual y cierre del Hub desconectan únicamente el controlador correspondiente. No hay activaciones heredadas después de reejecutar el Hub.

- **Walk on Water:** sigue la altura real de WaterLevel, superficies de agua y FloodLevel, incluyendo sus cambios entre rondas. Conserva el soporte bajo los pies, vehículos conectados y el área de 400 studs del código anterior. Solo transporta al personaje con el agua si ya estaba apoyado; no lo teletransporta desde el fondo ni durante un salto. Mantiene hasta seis soportes de vehículos abandonados, limita el muestreo del área y evita mover conjuntos que adquieran otro ocupante. La búsqueda del mundo se realiza una vez al activar; después usa eventos y consultas acotadas.
- **Antifling:** aísla las colisiones con jugadores cercanos mediante restricciones propias; no modifica CanCollide, grupos de colisión ni estados del Humanoid. Crea hasta 64 restricciones por paso y un máximo de 2048, priorizando vecinos cercanos. Frena impulsos y giros extremos; solo recupera una posición reciente si sigue cerca y existe suelo bajo ella. Descarta esa posición al cambiar de cuerpo, sentarse, volar o ser transportado por el agua.
- **Compatibilidad:** durante el vuelo, Walk on Water retira temporalmente sus plataformas sin cambiar su interruptor. Antifling mantiene las restricciones entre personajes, pero deja pasar la velocidad intencional de FLY, incluido su máximo de 5000. Al apagar el vuelo, el soporte de agua vuelve con el cuerpo válido. No Fall Damage principal mantiene siempre su prioridad sobre el de FLY.

Cada función tiene estado, generación de personaje, conexiones y objetos propios. El coordinador de velocidad permite leer la velocidad real entre el pulso y su restauración; una corrección de Antifling o del soporte de un vehículo no puede ser deshecha por una restauración anterior de No Fall Damage. La coordinación reconoce también una raíz soldada a la misma estructura rígida de un vehículo. Destruir un controlador no elimina los recursos de otro.

Los módulos están en `runtime/CharacterFeature.luau`, `features/WalkOnWater.luau` y `features/Antifling.luau`. Después de modificarlos, ejecuta `python tools/build_features.py` para incluirlos en el archivo distribuido. No se descarga código remoto para activar las opciones.

### Disaster Prediction

El detector que funcionó por separado está integrado, sin abrir su monitor ni su ventana Report. Al ejecutar Reyzn X también se retira una instancia anterior llamada `ReyznDisasterPrediction`, si seguía abierta. El repositorio independiente conserva su código; el Hub incluye el controlador y no descarga ni ejecuta aquel GUI.

- **Disaster Prediction** comienza **OFF**. ON escucha señales replicadas y muestra automáticamente los desastres reconocidos; OFF cancela sus observadores y el aviso activo. Conserva ON al reaparecer y vuelve a enlazarse al personaje nuevo. Se descartan los datos de su personaje anterior.
- **Predict Disaster** realiza una consulta manual incluso con el automático en OFF. En ese caso, sus observadores son temporales y se retiran al completar la lectura. Tiene un **cooldown de 4 segundos** desde el clic aceptado, muestra los segundos restantes y rechaza clics repetidos. Los errores también consumen ese cooldown.
- La consulta comprueba un personaje vivo fuera del vacío y señales locales de participación: `SurvivalTag` válido o indicadores explícitos `InRound`, `InActiveRound`, `ParticipatingInRound` o `PlayingRound`. Un desastre global por sí solo no demuestra que el jugador participe. Muerte, retirada del personaje, intermisión o participación falsa muestran exactamente **Error, You are not in an active round**. Si hay participación confirmada pero todavía no hay datos del desastre, muestra **Disaster data is not available yet**.
- El aviso aparece en la **esquina superior derecha del área segura**. Entra desde la derecha durante 0,36 s, con transparencia progresiva; permanece visible **5 segundos completos** y sale por la derecha durante 0,32 s. Usa obsidiana, Rajdhani, bordes metálicos, neón celeste/amatista con movimiento, un brillo exterior suave y una barra de duración. Se adapta a cambios de orientación y no captura toques.
- La tarjeta de desastre mide **318 × 88**, ajusta su ancho al área segura y conserva texto Rajdhani legible. Usa los dos PNG originales del propietario, sin editar sus bytes: confirmación a la izquierda al detectar un desastre y X cuando falta información o hay un error. Ambos iconos están centrados verticalmente; tienen una copia de brillo tenue y tres destellos pequeños reutilizados. Mientras cargan, se muestran marcas nativas de líneas, sin caracteres incompatibles. El cooldown manual sigue siendo **4 segundos**.
- Se reutiliza una sola tarjeta. Los desastres múltiples se agrupan y una nueva notificación sustituye la anterior sin acumular ventanas. El aviso tiene un reloj independiente del panel: funciona al minimizar, plegar o arrastrar el Hub fuera de la pantalla. Cerrar Reyzn X cancela la consulta, desconecta el detector y desvanece el aviso.

Conserva el reconocimiento de los 13 nombres de la captura, los valores/atributos de estado, los eventos recibidos y el aviso visible como alternativa. Excluye catálogos, módulos estáticos, chat y sus propias interfaces. No modifica velocidad, colisiones, salud ni las funciones de movimiento. La anticipación sigue dependiendo de cuándo el servidor replique el dato: no inventa un desastre futuro a partir de una lista de módulos.

`runtime/DisasterDetection.luau` y `features/DisasterPrediction.luau` se incluyen mediante `python tools/build_features.py`. El detector se limita a 192 fuentes, 48 eventos, 48 etiquetas de aviso y 192 candidatos de texto; no recorre el mundo por fotograma. La notificación utiliza el compositor de transparencia y el Heartbeat visual ya existentes.

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

- Home, Main, Visuals, Scripts y Settings mantienen sus nombres y funciones en el menú lateral. Main contiene No Fall Damage, Walk on Water, Antifling, Disaster Prediction con consulta manual y FLY SS3 FE. Scripts contiene Telekinesis UI y Super Black Hole; Visuals y Settings siguen vacías para el trabajo posterior.
- Cada sección se despliega a la derecha. Pulsar la misma opción o el control de plegado deja visible solo el menú.
- Arrastre libre con ratón o toque, también en el logo R minimizado. Es posible sacar la interfaz de la pantalla y recuperarla mediante la R auxiliar o RightShift.
- Avatar circular del usuario, UserId y contador desde cero por ejecución, independiente de minimizar, plegar o reaparecer.
- Los tres controles PNG conservan sus acciones: minimizar, plegar/desplegar y cerrar. Las animaciones pueden invertirse sin acumular transparencia ni desplazar sus zonas táctiles.
- El contenido se puede desplazar verticalmente cuando no cabe en el dispositivo. Los efectos no capturan toques.
- Ultra High permanece fijo: el menú y el panel reutilizan 19 y 36 fuentes de fuego, respectivamente; el logo conserva sus ocho fuentes. Cada fuente tiene dos capas de llama y un núcleo. Los tres grupos comparten un presupuesto fijo de 22 volutas y 24 brasas. El aviso utiliza un conjunto temporal que se destruye al terminar. Los efectos visibles se actualizan hasta 60 veces por segundo. Esto no garantiza 60 FPS en todos los dispositivos. No hay selector de calidad ni reducción automática.

## Recursos y ejecución

El código completo está en **Reyzn X.lua**. `UpdraftFire`, `NeonFlow`, `LoadToast`, `FeatureToggle`, `InwardLight`, `EmblemNeon` y el coordinador de reflejos comparten un solo Heartbeat visual, el compositor de transparencia y la limpieza de recursos. Reutilizan objetos; las animaciones ocultas se suspenden y se cancelan las conexiones, cargas y tweens al cerrar o reejecutar. `NoFallDamage` tiene conexiones independientes mientras está ON, para que el comportamiento no dependa de la visibilidad ni de la frecuencia de los VFX. Sus listas de conexiones se vacían en OFF y al cerrar.

El cargador conserva la integración de este proyecto con `getcustomasset`/`getsynasset` y `writefile`; **estas funciones pertenecen al entorno de ejecución, no a Roblox Studio**. Los doce recursos gráficos fijos del repositorio son once PNG y un JPEG. Se valida su tamaño y firma real; `isfile`/`readfile` permiten reutilizar la caché. Si una imagen falla, la interfaz sigue operativa y utiliza los iconos nativos de respaldo. El descargador gráfico nunca ejecuta sus respuestas. La ejecución remota se limita a los dos enlaces solicitados en Scripts y requiere pulsar su botón.

La interfaz y los VFX usan APIs nativas como UIGradient, UIStroke, UICorner, ImageLabel, UIScale, TweenService y RunService. No se añadieron shaders ni dependencias de código externas. El repositorio original `hzReyzn/scriptshz` no se modifica.

Los PNG originales y el JPEG se conservan sin modificaciones. [ASSET_NOTES.md](assets/reyzn-x/ASSET_NOTES.md) documenta su procedencia.

## Verificación

```sh
python tests/run.py /ruta/a/luau
```

El comando compila el Luau, comprueba el formato y tamaño de los doce recursos reales y ejecuta **42 escenarios deterministas**. Incluye navegación y plegado, gestos, arrastre libre, recuperación, inversiones de animación, reloj, seis tamaños de pantalla, caché/fallos de recursos, limpieza, transparencia exacta del fondo, JPEG válido/inválido, versión 1.0 estable, barrido del emblema sin saltos, fuego ascendente sin asignaciones por fotograma, gestos del logo, temporización y limpieza del aviso, cambios de orientación, descargas que terminan después de desaparecer la notificación, dirección y paleta del fuego compartido, neón bajo el contenido y suspensión de las animaciones ocultas.

Las nueve pruebas nuevas cubren OFF inicial y dimensiones, pulsos/restauración de velocidad, muerte y respawn tardío, raíz reemplazada, efecto independiente de la visibilidad, restauración al apagar y coexistencia con otra escritura, cambios ON/OFF repetidos, callbacks obsoletos, cierre/destrucción/reejecución, bloqueo fuera de PlaceId 189707 y respuesta visual/táctil del control.

También ejecuta **15 escenarios de integración** con el código completo de ambos controladores: distribución en seis tamaños, lanzamiento único, velocidad en vivo, prioridad en ambos órdenes de ejecución, restauraciones pendientes y callbacks retrasados, muerte, raíz reemplazada, reejecución, cierre independiente y limpieza del registro compartido.

Los **25 escenarios de funciones del personaje** cubren los tres interruptores, alturas de agua y mallas, cambios de ronda, saltos y suelo, límites y reutilización de restricciones, correcciones de velocidad durante pulsos pendientes, vuelo simultáneo a 5000, muerte/reset/vacío, personajes incompletos, callbacks obsoletos, plataformas y restricciones eliminadas, vehículos compartidos o con nuevos ocupantes, limpieza y reejecución. El controlador FLY tiene **28 pruebas** en su repositorio, incluidas desactivación al caer al vacío y retirada del personaje completo.

Los **8 escenarios de ejecutables** verifican los nombres/enlaces, tamaños táctiles, ausencia de ejecución automática, cargas independientes, clics repetidos, reintentos, fallos de red/compilación/arranque, cierre durante una descarga y conservación de un script externo ya iniciado. También se fija el contenido exacto de `Loader.lua`.

Los **25 escenarios de Disaster Prediction** comprueban OFF inicial, distribución y consulta manual, sustitución del GUI anterior, fuentes y duplicados, descarte de catálogos/chat, participación local, intermisión, muerte/reset/vacío, cooldown, duración y dirección del aviso, cambios de orientación, minimización, interrupción y sustitución de avisos, consultas canceladas, limpieza, reejecución y compatibilidad con los cuatro controladores existentes. Son **115 escenarios en Ghislain**. FLY conserva además sus 28 pruebas independientes.

Las pruebas simulan el cliente. Ninguna sustituye el renderizado, la medición de FPS ni una caída real en Roblox/Android.
