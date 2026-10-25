# Las Crónicas de Ehécatl

Prototipo de RPG original para Godot 4.2+.

## Ejecutar
1. Abre Godot 4.2 o superior.
2. Importa `project.godot`.
3. Ejecuta la escena principal con F6 o el proyecto con F5.

## Controles
WASD o flechas: mover. J o espacio: atacar/interactuar. K o Shift: correr. En Android, joystick izquierdo y botones A/B.

## Contenido
4 regiones conectadas, enemigos, diálogo con anciana y liberación del bosque. Gráficos provisionales dibujados por código.

## Exportar Android
Configura JDK, Android SDK y plantillas de exportación de Godot, crea preset Android en Proyecto > Exportar y genera APK de depuración. No se incluye APK ni se afirma que se haya probado en dispositivo.

Ver `docs/DISENO.md` para el diseño completo.

## Android (prioridad v0.1.1)
- Pantalla horizontal (landscape), interfaz 960x540 escalada por Godot.
- Multitouch: joystick y botón B pueden mantenerse pulsados simultáneamente.
- En Godot: Editor > Manage Export Templates, instalar plantillas para la misma versión.
- Editor Settings > Export > Android: configurar Java SDK Path (JDK 17) y Android SDK Path.
- Project > Export > Add > Android; exportar APK con Export With Debug habilitado.
- Instalar la APK en el teléfono y permitir la instalación desde el origen utilizado.
- No se ha compilado ni ejecutado una APK en este entorno; no hay Godot ni Android SDK instalados.
