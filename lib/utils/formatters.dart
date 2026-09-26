import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _plainNumberFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 0,
  );

  static final NumberFormat _currencyDecimalFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _currencyDecimalFormat.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String formatCurrencyWithoutSymbol(double amount) {
    return _plainNumberFormat.format(amount).trim();
  }

  /// Formats date to "Oct-26" like in the user reference image
  static String formatMonthLabel(int year, int month) {
    final dt = DateTime(year, month, 1);
    return DateFormat('MMM-yy').format(dt);
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String formatDateShort(DateTime dt) {
    return DateFormat('dd MMM').format(dt);
  }

  /// List of modern gradient themes for credit cards
  static const List<List<Color>> cardGradients = [
    [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)], // Deep Indigo
    [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)], // Slate Dark
    [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)], // Emerald
    [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFF59E0B)], // Amber Sunset
    [Color(0xFF881337), Color(0xFFBE123C), Color(0xFFF43F5E)], // Rose Ruby
  ];

  static List<Color> getCardGradient(int index) {
    return cardGradients[index % cardGradients.length];
  }
}
