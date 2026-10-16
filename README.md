# Reyzn X | Amethyst Edition

Made By Reyzn.

**Versión pública: 1.0.** Este valor se cambia únicamente cuando Reyzn lo solicita explícitamente. Las correcciones visuales no incrementan la versión. El identificador interno `Build` permite distinguir cambios de código sin alterar la versión mostrada.

```lua
local url = "https://raw.githubusercontent.com/hzReyzn/Ghislain/main/Reyzn%20X.lua"
local source = game:HttpGet(url .. "?build=home-neon-20261016&t=" .. tostring(os.time()))
loadstring(source)()
```

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

- Home, Main, Visuals, Scripts y Settings mantienen sus nombres y funciones en el menú lateral. Las cuatro últimas páginas siguen vacías para el trabajo posterior.
- Cada sección se despliega a la derecha. Pulsar la misma opción o el control de plegado deja visible solo el menú.
- Arrastre libre con ratón o toque, también en el logo R minimizado. Es posible sacar la interfaz de la pantalla y recuperarla mediante la R auxiliar o RightShift.
- Avatar circular del usuario, UserId y contador desde cero por ejecución, independiente de minimizar, plegar o reaparecer.
- Los tres controles PNG conservan sus acciones: minimizar, plegar/desplegar y cerrar. Las animaciones pueden invertirse sin acumular transparencia ni desplazar sus zonas táctiles.
- El contenido se puede desplazar verticalmente cuando no cabe en el dispositivo. Los efectos no capturan toques.
- Ultra High permanece fijo: 74 raíces de fuego con dos capas, 32 partículas y hasta 60 actualizaciones VFX por segundo. Esto no garantiza 60 FPS en todos los dispositivos. No hay selector de calidad ni reducción automática.

## Recursos y ejecución

El código completo está en **Reyzn X.lua**. `FireAura`, `ParticlePool`, `InwardLight`, `EmblemNeon` y el coordinador de reflejos comparten un solo Heartbeat, el compositor de transparencia y la limpieza de recursos. Reutilizan objetos; las animaciones ocultas se suspenden y se cancelan las conexiones, cargas y tweens al cerrar o reejecutar.

El cargador conserva la integración de este proyecto con `getcustomasset`/`getsynasset` y `writefile`; **estas funciones pertenecen al entorno de ejecución, no a Roblox Studio**. Los doce recursos fijos del repositorio son once PNG y un JPEG. Se valida su tamaño y firma real; `isfile`/`readfile` permiten reutilizar la caché. Si una descarga falla, la interfaz sigue operativa y utiliza los iconos nativos de respaldo. El contenido descargado por el GUI nunca se ejecuta: solo son imágenes.

La interfaz y los VFX usan APIs nativas como UIGradient, UIStroke, UICorner, ImageLabel, UIScale, TweenService y RunService. No se añadieron shaders ni dependencias de código externas. El repositorio original `hzReyzn/scriptshz` no se modifica.

Los PNG originales y el JPEG se conservan sin modificaciones. [ASSET_NOTES.md](assets/reyzn-x/ASSET_NOTES.md) documenta su procedencia.

## Verificación

```sh
python tests/run.py /ruta/a/luau
```

El comando compila el Luau, comprueba el formato y tamaño de los doce recursos reales y ejecuta **25 escenarios deterministas**. Incluye navegación y plegado, gestos, arrastre libre, recuperación, inversiones de animación, reloj, seis tamaños de pantalla, caché/fallos de recursos, limpieza, transparencia exacta del fondo, JPEG válido/inválido, versión 1.0 estable y barrido del emblema sin saltos.

Las pruebas simulan el cliente. La revisión visual aproximada ayuda a comprobar la distribución, pero ninguna sustituye el renderizado ni la medición de FPS en Roblox/Android.
