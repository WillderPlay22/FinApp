---
name: Bug critico BoxDecoration color+gradient
description: BoxDecoration en Flutter lanza AssertionError si tiene color y gradient simultaneamente — siempre usar solo gradient
type: feedback
---

En Flutter, `BoxDecoration` tiene una restriccion hard en el framework: NO puede tener `color` y `gradient` definidos al mismo tiempo. Si ambos estan presentes, lanza `AssertionError` en runtime con el mensaje: "Cannot provide both a color and a gradient".

**Why:** El usuario identifico este bug en `GlassDecoration.card()` que asignaba tanto `color: bg` como `gradient: LinearGradient(...)` en el mismo `BoxDecoration`.

**How to apply:** Cuando se necesita un fondo translucido + highlight gradient en glassmorphism, se deben usar DOS `DecoratedBox` apilados (Stack o superposicion), o usar SOLO gradient incorporando el color base como primer stop del gradiente. Nunca ambos en el mismo `BoxDecoration`.

La forma correcta de combinar fondo semitransparente + highlight en glassmorphism es usar gradient con el color base como parte del gradiente:
```dart
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color.alphaBlend(glassHighlight, glassBackground), // esquina superior con highlight
    glassBackground, // resto translucido uniforme
  ],
  stops: [0.0, 0.4],
)
```
