# Reyzn X

Made By Reyzn.

GUI de Roblox creado desde cero en la copia de trabajo `hzReyzn/Ghislain`, inspirado en la referencia negra y violeta. `Reyzn X.lua` contiene toda la interfaz y se ejecuta en el cliente.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hzReyzn/Ghislain/main/Reyzn%20X.lua"))()
```

- Home, Main, Visuals, Scripts y Settings. Main y Scripts comienzan vacíos.
- Avatar circular del jugador, UserId y tiempo de sesión `HH:MM:SS`, desde cero en cada ejecución. El contador continúa al minimizar y al reaparecer.
- Acento Amethyst por defecto; Moonstone y Ember opcionales en Visuals. Halo y animaciones configurables.
- Ventana flotante más pequeña por defecto, con espacio real para moverla. Se arrastra desde el encabezado; el icono minimizado también se arrastra con ratón o toque. Arrastrar una ventana ampliada la devuelve a tamaño compacto.
- Menú izquierdo plegable: pulsa el botón de tres líneas para abrirlo hacia la derecha; también admite deslizamiento horizontal sobre sus opciones. Se cierra al elegir una sección o tocar fuera. El menú no agranda la ventana.
- Transiciones al cambiar de página, indicador de selección móvil, reflejos suaves, iluminación del menú y zoom con desvanecimiento al minimizar/restaurar/cerrar. El efecto respeta el tema y el ajuste de animaciones.
- Desplazamiento vertical independiente para páginas y navegación. Al volver a una sección se muestra su inicio. `RightShift` también minimiza/restaura.
- Ventana, iconos, corona y arte abstracto construidos con objetos nativos. La única imagen es el avatar obtenido mediante Roblox.
- Sin personajes decorativos, Key System, Featured Scripts, Links, Combat, World, Universal ni Player. Sin pantallas de mantenimiento/carga, audio, funciones de juego ni ejecución de scripts externos.

`hzReyzn/scriptshz` conserva la versión anterior. Este repositorio es el espacio de trabajo para Reyzn X.

## Verificación

`python tests/run.py /ruta/a/luau` compila y ejecuta 12 escenarios en un entorno de Roblox simulado. Incluyen el movimiento real en ambos ejes, arrastre desde tamaño ampliado, menú a mitad de animación y cambios rápidos, gestos táctiles, desplazamiento, tamaño móvil, ciclos de minimizar/restaurar, avatar, contador, temas, reejecución y limpieza. Estas pruebas no sustituyen la comprobación visual en Roblox.
