# Recursos de Reyzn X 2.2

`launcher-r-v1.png`, `emblem-x-v1.png`, `minimize-v1.png`, `collapse-v1.png` y `close-v1.png` conservan exactamente sus bytes originales. `wordmark-v1.png` se conserva archivado y ya no se utiliza en el GUI.

## Nueva textura

- Archivo: `assets/reyzn-x/flame-wisp-v1.png`.
- PNG RGBA de 1254 × 1254, 1 172 326 bytes, transparencia original conservada.
- Generada con la herramienta integrada `image_gen`, sin CLI ni servicios de imágenes en tiempo de ejecución.
- El script comparte esta única textura entre todas las llamas. Roblox aplica la paleta y las variaciones de tamaño, orientación, posición y transparencia. Los logos no se regeneraron ni se editaron.

Prompt utilizado:

> Use case: stylized-concept. Asset type: a single reusable monochrome fire-wisp VFX sprite for a premium Roblox ScreenGui, not a complete interface or logo. Create a 1024 by 1024 PNG with a truly transparent background. Subject: one compact cluster of 3 to 5 elegant ethereal upward-pointing flame tongues, delicate flowing and asymmetrical, like a silver plasma aura, widest at the lower root and tapered to curling sharp tips. Grayscale WHITE and SILVER only, so code can tint it purple/pink/blue. The root is a soft luminous semi-transparent cloud that dissolves completely into transparency, not a straight line. Smooth semi-transparent fading edges and a restrained diffuse glow surrounding brighter fine inner strands, with transparent gaps between strands. No solid filled teardrop, no candle, no smoke column, no orange, no colored background, no border, no frame, no symbols, no particles, no text, no checkerboard baked into pixels. Composition: center the one flame cluster within the square canvas, fill about 80% of the width and 85% of the height, keep all glow inside with transparent margins on all four sides. Designed to remain recognizable when displayed at only 35–70 pixels and composited sparingly around the outside edge of a dark GUI. This is only a source texture; movement, color and pooling will be implemented in Luau.
