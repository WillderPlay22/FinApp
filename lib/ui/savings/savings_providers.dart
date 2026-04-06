import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers/database_providers.dart';
import '../../logic/providers/time_provider.dart';

/// Total ahorrado: suma de currentAmount de todos los savings.
final totalSavedProvider = StreamProvider<double>((ref) {
  return ref.watch(savingsDaoProvider).watchAllSavings().map(
        (list) => list.fold(0.0, (sum, s) => sum + s.currentAmount),
      );
});

/// Progreso mensual de ahorros. Depende de nowProvider para ser reactivo
/// ante cambio de mes (el provider se recalcula automáticamente).
final monthlySavingsProgressProvider = StreamProvider<
    ({
      double expected,
      double executed,
      int totalPlans,
      int executedPlans,
    })>((ref) {
  final now = ref.watch(nowProvider);
  return ref.watch(savingsDaoProvider).watchMonthlyProgress(now);
});
