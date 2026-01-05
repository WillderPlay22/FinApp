import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controlador del "Viajero del Tiempo"
/// Si el estado es NULL, significa que estamos en la FECHA REAL.
/// Si tiene una fecha, la app creerá que es esa fecha.
class TimeController extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    return null; // Por defecto: Tiempo Real
  }

  void setSimulatedDate(DateTime date) {
    state = date;
  }

  void resetToRealDate() {
    state = null;
  }
}

/// Provider para controlar la simulación (Setear fechas, resetear)
final timeControllerProvider = NotifierProvider<TimeController, DateTime?>(TimeController.new);

/// Provider de solo lectura que te dice "Qué hora es" (Real o Simulada)
/// ÚSALO ASÍ: final hoy = ref.watch(nowProvider);
final nowProvider = Provider<DateTime>((ref) {
  final simulatedDate = ref.watch(timeControllerProvider);
  return simulatedDate ?? DateTime.now();
});