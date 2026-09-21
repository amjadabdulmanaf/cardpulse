import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';

class BillingCycle {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime nextResetDate;

  BillingCycle({
    required this.startDate,
    required this.endDate,
    required this.nextResetDate,
  });

  bool containsDate(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endDate.add(const Duration(days: 1)));
  }

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextResetDate.year, nextResetDate.month, nextResetDate.day);
    final diff = target.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }
}

class CycleCalculator {
  /// Calculates current billing cycle start, end, and next reset date for a card.
  static BillingCycle getBillingCycle(CreditCard card, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final currentDay = now.day;
    final billDay = card.billGenerationDay;

    int cycleStartYear = now.year;
    int cycleStartMonth = now.month;

    if (currentDay < billDay) {
      // Current date is before bill day, so cycle started in previous month
      if (cycleStartMonth == 1) {
        cycleStartMonth = 12;
        cycleStartYear -= 1;
      } else {
        cycleStartMonth -= 1;
      }
    }

    final startDate = _clampDate(cycleStartYear, cycleStartMonth, billDay);

    // Next reset date is billDay of next month following start
    int nextResetYear = cycleStartYear;
    int nextResetMonth = cycleStartMonth + 1;
    if (nextResetMonth > 12) {
      nextResetMonth = 1;
      nextResetYear += 1;
    }

    final nextResetDate = _clampDate(nextResetYear, nextResetMonth, billDay);
    // Cycle end date is 1 day before next reset date
    final endDate = nextResetDate.subtract(const Duration(days: 1));

    return BillingCycle(
      startDate: startDate,
      endDate: endDate,
      nextResetDate: nextResetDate,
    );
  }

  static DateTime _clampDate(int year, int month, int day) {
    // Find last day of specified month
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final validDay = day > lastDayOfMonth ? lastDayOfMonth : day;
    return DateTime(year, month, validDay);
  }

  /// Calculates total regular spend for card in current cycle
  static double getRegularSpend(
    CreditCard card,
    List<TransactionItem> allTransactions, {
    BillingCycle? cycle,
  }) {
    final currentCycle = cycle ?? getBillingCycle(card);
    double total = 0.0;

    for (final tx in allTransactions) {
      if (tx.cardId == card.id && !tx.isEmi) {
        if (currentCycle.containsDate(tx.date)) {
          total += tx.amount;
        }
      }
    }

    return total;
  }

  /// Calculates total EMI due for card in current cycle month
  static double getEmiSpend(
    CreditCard card,
    List<EmiItem> allEmis, {
    BillingCycle? cycle,
    DateTime? referenceDate,
  }) {
    final targetDate = referenceDate ?? DateTime.now();
    double total = 0.0;

    for (final emi in allEmis) {
      if (emi.cardId == card.id) {
        double amt = emi.getAmountForDate(targetDate);
        if (amt == 0.0) {
          final currentCycle = cycle ?? getBillingCycle(card, referenceDate: targetDate);
          for (final item in emi.schedule) {
            final instDate = DateTime(item.year, item.month, card.billGenerationDay);
            if (currentCycle.containsDate(instDate)) {
              amt = item.amount;
              break;
            }
          }
        }
        total += amt;
      }
    }

    return total;
  }

  /// Calculates total combined cycle spend
  static double getTotalCycleSpend(
    CreditCard card,
    List<TransactionItem> transactions,
    List<EmiItem> emis, {
    BillingCycle? cycle,
  }) {
    final c = cycle ?? getBillingCycle(card);
    final reg = getRegularSpend(card, transactions, cycle: c);
    final emi = getEmiSpend(card, emis, cycle: c);
    return reg + emi;
  }

  /// Sorts cards such that card with closest reset date (latest reset) appears first
  static List<CreditCard> sortCardsByReset(List<CreditCard> cards) {
    final sorted = List<CreditCard>.from(cards);
    sorted.sort((a, b) {
      final cycleA = getBillingCycle(a);
      final cycleB = getBillingCycle(b);
      return cycleA.daysRemaining.compareTo(cycleB.daysRemaining);
    });
    return sorted;
  }
}
