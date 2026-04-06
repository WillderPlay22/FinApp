---
name: Arquitectura modulo Home FinApp
description: Stack tecnico y patrones del modulo Home de FinApp identificados en revision de abril 2026
type: project
---

Stack del modulo Home (lib/ui/home/):
- Estado: Riverpod (FutureProvider, StreamProvider, StateProvider, Provider)
- DB: Isar con queries directas en los providers
- Animaciones: AnimationController unico con staggered via _staggered() helper, TweenAnimationBuilder en cards
- Visual: Glassmorphism con BackdropFilter + ClipRRect en GlassCard, CustomPaint con parallax en HomeBackground
- Scroll: CustomScrollView con SliverChildListDelegate (no lazy — todos los widgets se construyen a la vez)
- Navegacion: HomeScreen como ConsumerStatefulWidget

Providers clave:
- homeSummaryDataProvider: FutureProvider pesado, hace 6+ queries Isar, depende de nowProvider (se recalcula cada tick)
- previousPeriodSummaryProvider: FutureProvider que duplica queries de gastos (bug detectado)
- summaryFilterProvider: StateProvider<SummaryFilter>
- isMultiCurrencyEnabledProvider: Provider<bool> derivado de StreamProvider de currencySettings
- fixedPaymentsStatusProvider: StreamProvider con watch() de Isar
- recentTransactionsProvider: StreamProvider con watch() de Isar

Widgets clave:
- GlassCard: BackdropFilter + ClipRRect (crea layer de compositing por cada instancia)
- HomeBackground: CustomPainter con RepaintBoundary (bien implementado), recibe scrollOffset
- HeroBalanceCard: ConsumerStatefulWidget, watch de 2 FutureProviders
- GlassSummaryMetrics: ConsumerWidget, crea NumberFormat en cada build dentro de _GlassMetricCard

**Why:** Contexto para entender impacto de optimizaciones futuras en este modulo.
**How to apply:** Al analizar o modificar el modulo Home, usar este contexto para evaluar cambios sin releer todos los archivos.
