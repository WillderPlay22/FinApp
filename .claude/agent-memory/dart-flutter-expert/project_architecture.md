---
name: Arquitectura FinApp
description: Stack técnico, patrones y convenciones del proyecto FinApp
type: project
---

- State management: Riverpod (FutureProvider, StreamProvider, StateProvider, Provider)
- Base de datos local: Isar
- Navegación: pendiente de confirmar (probablemente go_router)
- UI: glassmorphism custom con GlassCard, GlassDecoration, AppColors
- Estructura: feature-first (lib/ui/<feature>/, lib/data/, lib/logic/providers/)
- Módulo Home: HomeScreen + home_providers.dart + widgets/ (glass_card, hero_balance_card, home_background, etc.)
- Modelos con records de Dart 3: ({double income, double expenses, double debts, double available})
- Conversión de moneda: referenceAmountWithRate(rateValue) en FinancialTransaction

**Why:** App de finanzas personales con soporte multi-moneda (USD/BS Venezuela)
**How to apply:** Al sugerir código, usar los patrones existentes (Riverpod, Isar, records Dart 3, glassmorphism)
