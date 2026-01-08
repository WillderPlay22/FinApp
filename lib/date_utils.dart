import 'data/models/enums.dart';

/// Un objeto simple para contener un rango de fechas.
class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// Calcula el rango de fechas (inicio y fin) para un ciclo de pago específico
/// basándose en una fecha dada.
DateRange getCycleDateRange(DateTime date, Frequency frequency) {
  late DateTime start;
  late DateTime end;

  switch (frequency) {
    case Frequency.daily:
      start = DateTime(date.year, date.month, date.day);
      end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      break;
    case Frequency.weekly:
      // Asume que la semana empieza el lunes.
      start = date.subtract(Duration(days: date.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      break;
    case Frequency.biweekly:
      // Ciclo del 1 al 15 y del 16 al fin de mes.
      start = (date.day <= 15) ? DateTime(date.year, date.month, 1) : DateTime(date.year, date.month, 16);
      end = (date.day <= 15) ? DateTime(date.year, date.month, 15, 23, 59, 59) : DateTime(date.year, date.month + 1, 0, 23, 59, 59);
      break;
    case Frequency.monthly:
      start = DateTime(date.year, date.month, 1);
      end = DateTime(date.year, date.month + 1, 0, 23, 59, 59); // Día 0 del siguiente mes es el último del actual.
      break;
    case Frequency.yearly:
      start = DateTime(date.year, 1, 1);
      end = DateTime(date.year, 12, 31, 23, 59, 59);
      break;
    case Frequency.none:
      start = DateTime(date.year, date.month, date.day);
      end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      break;
  }
  return DateRange(start, end);
}

/// Devuelve la etiqueta en español para una frecuencia.
String getFrequencyLabel(Frequency? freq) {
  switch (freq) {
    case Frequency.daily:
      return 'DIARIO';
    case Frequency.weekly:
      return 'SEMANAL';
    case Frequency.biweekly:
      return 'QUINCENAL';
    case Frequency.monthly:
      return 'MENSUAL';
    case Frequency.yearly:
      return 'ANUAL';
    case Frequency.none: // Se agrupan los casos para 'none' y 'null'.
    case null:
      return 'SIN FRECUENCIA';
  }
}