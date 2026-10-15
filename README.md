# Reyzn X

Made By Reyzn.

GUI de Roblox creado desde cero en la copia de trabajo `hzReyzn/Ghislain`, inspirado en la referencia negra y violeta. `Reyzn X.lua` contiene toda la interfaz y se ejecuta en el cliente.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hzReyzn/Ghislain/main/Reyzn%20X.lua"))()
```

- Home, Main, Visuals, Scripts y Settings. Main y Scripts comienzan vacíos.
- Avatar circular del jugador, UserId y tiempo de sesión `HH:MM:SS`, desde cero en cada ejecución. El contador continúa al minimizar y al reaparecer.
- Acento Amethyst por defecto; Moonstone y Ember opcionales en Visuals. Halo y animaciones configurables.
- Arrastre con ratón o toque, minimizar/restaurar, ampliar, cerrar y ajuste al área segura. `RightShift` también minimiza/restaura.
- Ventana, iconos, corona y arte abstracto construidos con objetos nativos. La única imagen es el avatar obtenido mediante Roblox.
- Sin personajes decorativos, Key System, Featured Scripts, Links, Combat, World, Universal ni Player. Sin pantallas de mantenimiento/carga, audio, funciones de juego ni ejecución de scripts externos.

`hzReyzn/scriptshz` conserva la versión anterior. Este repositorio es el espacio de trabajo para Reyzn X.

## Verificación

`python tests/run.py /ruta/a/luau` compila y prueba la interfaz en un entorno de Roblox simulado: navegación, avatar, contador, cambios visuales, adaptación de tamaño, arrastre, minimizar, cierre, reejecución y limpieza. Estas pruebas no sustituyen la comprobación visual en Roblox.
