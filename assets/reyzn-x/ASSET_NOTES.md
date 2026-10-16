# Recursos de Reyzn X — versión pública 1.0

`launcher-r-v1.png`, `emblem-x-v1.png`, `minimize-v1.png`, `collapse-v1.png` y `close-v1.png` conservan exactamente sus bytes originales. `wordmark-v1.png` se conserva archivado y ya no se utiliza en el GUI.

## Recursos actuales suministrados

Se copiaron sin convertir, retocar, recolorear ni comprimir sus bytes originales. La extensión del fondo se ajustó a su formato real:

| Archivo | Adjunto | Uso | Transparencia |
|---|---|---|---:|
| `icon-home-v1.png` | `03-1000190897.png` | Home | 85% |
| `icon-main-v1.png` | `02-1000190899.png` | Main | 85% |
| `icon-scripts-v1.png` | `01-1000190900.png` | Scripts | 85% |
| `icon-settings-v1.png` | `04-1000190895.png` | Settings | 85% |
| `icon-visuals-v1.png` | `03-1000190896.png` | Visuals | 85% |
| `background-cyber-v2.jpg` | `02-1000190889.png` | Fondo del menú, panel y Home | 83% |

Los cinco iconos son PNG RGBA de 1312 × 1199; el fondo es JPEG RGB de 1536 × 864 (167 325 bytes), aunque el adjunto tenía extensión `.png`. El nombre y la validación del cargador se corrigieron para aceptar su formato real. Se conserva cada byte original, sin conversión ni recompresión. La transparencia solicitada se aplica en Roblox. `background-cyber-v1.png` queda como recurso histórico sin uso en el script actual. La retirada del contorno del logo afecta al `UIStroke` adicional del GUI; el recurso R personalizado se mantiene intacto.

Rajdhani se usa como fuente nativa de Roblox, sin descargar un TTF en tiempo de ejecución: [Rajdhani, publicada por Roblox](https://create.roblox.com/store/asset/12187375422/). El script usa `Font.new` y `FontFace` con el peso SemiBold.

## Textura de fuego conservada

- Archivo: `assets/reyzn-x/flame-wisp-v1.png`.
- PNG RGBA de 1254 × 1254, 1 172 326 bytes, transparencia original conservada.
- Generada con la herramienta integrada `image_gen`, sin CLI ni servicios de imágenes en tiempo de ejecución.
- El script comparte esta única textura entre todas las llamas. Roblox aplica la paleta y las variaciones de tamaño, orientación, posición y transparencia. Los logos no se regeneraron ni se editaron. El brillo rosa/morado de la X grande usa copias translúcidas de ese mismo PNG y UIGradient, sin texturas adicionales.

Prompt utilizado:

> Use case: stylized-concept. Asset type: a single reusable monochrome fire-wisp VFX sprite for a premium Roblox ScreenGui, not a complete interface or logo. Create a 1024 by 1024 PNG with a truly transparent background. Subject: one compact cluster of 3 to 5 elegant ethereal upward-pointing flame tongues, delicate flowing and asymmetrical, like a silver plasma aura, widest at the lower root and tapered to curling sharp tips. Grayscale WHITE and SILVER only, so code can tint it purple/pink/blue. The root is a soft luminous semi-transparent cloud that dissolves completely into transparency, not a straight line. Smooth semi-transparent fading edges and a restrained diffuse glow surrounding brighter fine inner strands, with transparent gaps between strands. No solid filled teardrop, no candle, no smoke column, no orange, no colored background, no border, no frame, no symbols, no particles, no text, no checkerboard baked into pixels. Composition: center the one flame cluster within the square canvas, fill about 80% of the width and 85% of the height, keep all glow inside with transparent margins on all four sides. Designed to remain recognizable when displayed at only 35–70 pixels and composited sparingly around the outside edge of a dark GUI. This is only a source texture; movement, color and pooling will be implemented in Luau.
