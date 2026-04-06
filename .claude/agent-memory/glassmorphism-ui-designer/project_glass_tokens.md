---
name: Sistema de colores glass FinApp
description: Valores exactos de los tokens glassmorphism en AppColors para dark y light mode
type: project
---

Tokens glassmorphism definidos en `lib/config/theme/app_colors.dart`:

**Dark mode:**
- `glassBackground`: `Color(0x0FFFFFFF)` — white @ ~6% alpha
- `glassBorder`: `Color(0x1FFFFFFF)` — white @ ~12% alpha
- `glassHighlight`: `Color(0x1AFFFFFF)` — white @ ~10% alpha
- `glassBlurSigma`: 20.0

**Light mode:**
- `glassBackground`: `Color(0x73FFFFFF)` — white @ ~45% alpha
- `glassBorder`: `Color(0x99FFFFFF)` — white @ ~60% alpha
- `glassHighlight`: `Color(0x80FFFFFF)` — white @ ~50% alpha
- `glassBlurSigma`: 16.0

**Observacion critica sobre dark mode:**
El `glassBackground` en dark (6% alpha) es DEMASIADO sutil. Con un fondo casi negro y circulos con opacidad 0.08-0.15, el BackdropFilter apenas es visible. Para que el efecto sea visible se necesita al menos 12-18% de alpha en dark.

**Why:** Estos valores determinan la visibilidad del efecto glass. Si son muy bajos en dark mode, el blur no se percibe.
**How to apply:** Sugerir aumentar `glassBackground` dark a `Color(0x1AFFFFFF)` (10%) como minimo para que el blur sea perceptible.
