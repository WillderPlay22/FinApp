---
name: Problemas de rendimiento detectados en Home (abril 2026)
description: Lista priorizada de problemas de rendimiento identificados en el modulo Home durante revision del 2026-04-05
type: project
---

Problemas identificados en revision del 2026-04-05:

CRITICOS:
1. _onScroll() llama setState() en el widget raiz — rebuilda TODO el arbol en cada frame de scroll
2. SliverChildListDelegate construye todos los widgets de la lista sin lazy loading
3. AnimatedBuilder compartido: un solo _entranceController rebuilda todos los ~18 widgets simultaneamente
4. Opacity widget en _staggered() — es el widget mas costoso para compositing (fuerza saveLayer)
5. nowProvider posiblemente volatil — si cambia cada segundo, homeSummaryDataProvider (query pesada) se recalcula constantemente

ALTOS:
6. GlassCard sin RepaintBoundary — BackdropFilter en cada card sin aislamiento de layer
7. NumberFormat creado en cada build() dentro de _GlassMetricCard (4 instancias x cada rebuild)
8. TweenAnimationBuilder con tween recreado en cada build (cuando amount cambia, reinicia animacion)
9. previousPeriodSummaryProvider duplica la query de gastos de deuda innecesariamente
10. HeroBalanceCard usa ValueKey(ref.watch(summaryFilterProvider)) en HomeScreen pero el widget ya hace ref.watch interno

MEDIOS:
11. withOpacity() en paint del CustomPainter crea nuevos objetos Color en cada frame de scroll
12. _GlassMetricCard usa color.withOpacity(0.8) en build — deberia ser const o calculado una vez
13. GlassDecoration.card() crea BoxDecoration complejo (con Color.alphaBlend) en cada build
14. MaskFilter.blur en CustomPainter se recrea en cada paint() — deberia ser final/const

**Why:** Sirve como referencia para priorizar el trabajo de optimizacion.
**How to apply:** Al implementar mejoras, atacar los criticos primero. Verificar con Flutter DevTools Performance tab.
