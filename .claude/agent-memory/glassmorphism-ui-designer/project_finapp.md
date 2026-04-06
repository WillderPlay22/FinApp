---
name: Perfil del proyecto FinApp
description: App Flutter de finanzas personales con sistema glassmorphism, dark/light mode, Riverpod, Material Design 3
type: project
---

App Flutter de finanzas personales llamada "FinApp".

**Stack:**
- Flutter con Riverpod para estado
- Material Design 3
- `AppColors` como `ThemeExtension<AppColors>` con tokens glassmorphism
- Paquetes: fl_chart, gap, isar (base de datos local)

**Arquitectura de pantallas:**
- `HomeScreen` usa un `Stack` con `HomeBackground` (capa 0) y `CustomScrollView` (capa 1)
- `HomeBackground` pinta circulos gradientes difuminados con `CustomPaint` + `MaskFilter.blur`
- El `Scaffold.backgroundColor` es `appColors.backgroundPrimary` (negro mate en dark)

**Widgets glass existentes:**
- `GlassCard` — `lib/ui/home/widgets/glass_card.dart`
- `GlassDecoration` — `lib/config/theme/glass_decoration.dart`
- `HomeBackground` — `lib/ui/home/widgets/home_background.dart`

**Why:** El usuario quiere un sistema visual coherente glassmorphism en toda la app.
**How to apply:** Mantener consistencia de blur sigma, border opacity y background opacity entre todos los widgets glass.
