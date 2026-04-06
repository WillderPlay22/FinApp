enum TransactionType {
  income, // Para Ingresos
  expense, // Para Gastos
  saving // Para Ahorros
}

enum Frequency {
  none,      // Pago único (no se repite)
  daily,     // Diario
  weekly,    // Semanal
  biweekly,  // Quincenal (Vital para tu planificación)
  monthly,   // Mensual
  yearly     // Anual
}

enum SavingType {
  goal, // Meta (Con tope)
  fund  // Fondo (Indefinido)
}

enum SavingMethod {
  fixed,      // Monto Fijo
  percentage  // Porcentaje del remanente
}

enum PaymentMode {
  singleCurrency, // Legacy / pago en una sola moneda
  allReference,    // Todo en USD (monto fijo, no cambia)
  allLocal,        // Todo en BS (equivalente USD fluctúa con la tasa)
  mixed,           // Parte en USD, parte en BS
}