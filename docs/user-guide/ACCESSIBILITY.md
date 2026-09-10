# Accesibilidad y preferencias

Perfil ofrece una pantalla de accesibilidad. Las preferencias se guardan localmente y se aplican a `MaterialApp` mediante `AppStateProvider`.

- Tema claro u oscuro.
- Español o inglés cuando existe traducción.
- Escala de texto adicional entre 1.0 y 1.4, además de la escala del sistema.
- Texto reforzado.
- Alto contraste.
- Reducción de movimiento.
- Paleta alternativa para chips de estado.

La app expone etiquetas de accesibilidad en componentes compartidos y respeta `disableAnimations`. La conformidad WCAG, la prueba completa con VoiceOver/TalkBack y la accesibilidad de todos los plugins y pantallas **no están certificadas**; `PRODUCTION.md` las mantiene como puerta de salida pendiente.
