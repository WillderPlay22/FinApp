---
name: Optimizaciones módulo Home (2026-04-05)
description: 9 problemas de rendimiento detectados y corregidos en el módulo Home de FinApp
type: project
---

Se aplicaron los siguientes cambios de rendimiento al módulo Home:

1. **home_screen.dart** (reescritura): setState en _onScroll eliminado → ValueNotifier<double> + _ScrollAwareBackground; SliverChildListDelegate → SliverChildBuilderDelegate con lazy loading; Opacity+Transform.translate → FadeTransition+SlideTransition; animaciones precomputadas en initState; eliminado ValueKey en HeroBalanceCard
2. **glass_card.dart**: RepaintBoundary envuelve ClipRRect+BackdropFilter cuando enableBlur=true
3. **glass_summary_metrics.dart**: NumberFormat movido a campo estático _currencyFormat; withOpacity → withValues
4. **hero_balance_card.dart**: NumberFormat estático; ref.listen para reiniciar animación al cambiar filtro (en lugar de ValueKey que destruía el widget); TweenAnimationBuilder anima desde _displayedAmount en lugar de 0
5. **home_background.dart** (reescritura): Paint cacheados en constructor del CustomPainter; MaskFilter como const estático; withOpacity → withValues
6. **home_providers.dart**: ref.watch → ref.read para nowProvider en homeSummaryDataProvider; query duplicada de expenses/debts en previousPeriodSummaryProvider eliminada (una sola query, separación en loop)
7. **glass_decoration.dart**: 6 ocurrencias de withOpacity → withValues

**Why:** Reducir jank y rebuilds innecesarios en la pantalla principal de FinApp
**How to apply:** Al auditar el módulo Home, estos patrones ya están aplicados. Nuevos widgets deben seguir los mismos patrones.
