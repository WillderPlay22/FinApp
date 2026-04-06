import 'package:flutter/material.dart';

class UpcomingPayment {
  final String title;
  final double amount;
  final DateTime dueDate;
  final bool isDebt;
  final Color color;
  final String? currencyCode;

  const UpcomingPayment({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.isDebt,
    required this.color,
    this.currencyCode,
  });
}
