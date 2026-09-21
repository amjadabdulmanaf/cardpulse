import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/credit_card.dart';
import 'cycle_calculator.dart';

class ParsedSmsTransaction {
  final String cardLast4;
  final double amount;
  final String merchant;
  final DateTime date;
  final String rawBody;
  final String matchedCardId;

  ParsedSmsTransaction({
    required this.cardLast4,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.rawBody,
    required this.matchedCardId,
  });
}

class SmsService {
  static const MethodChannel _channel = MethodChannel('com.pulse.card.cardpulse/sms');

  /// Requests SMS permissions from Android
  static Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Checks whether SMS permission is granted
  static Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Reads SMS inbox and returns parsed card transactions for registered cards
  static Future<List<ParsedSmsTransaction>> fetchAndParseSms(
    List<CreditCard> cards, {
    DateTime? referenceDate,
  }) async {
    if (cards.isEmpty) return [];

    try {
      final bool granted = await hasPermission();
      if (!granted) {
        final ok = await requestPermission();
        if (!ok) return [];
      }

      final List<dynamic>? rawList = await _channel.invokeMethod('getSmsMessages');
      if (rawList == null || rawList.isEmpty) return [];

      final List<ParsedSmsTransaction> results = [];
      final now = referenceDate ?? DateTime.now();

      for (final item in rawList) {
        if (item is! Map) continue;
        final String body = (item['body'] ?? '').toString();
        final int timestamp = (item['date'] ?? 0) as int;
        final DateTime smsDate = timestamp > 0
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : now;

        // Check if message is an actual spend/debit transaction
        if (!isSpendMessage(body)) continue;

        // Try to match with any registered card
        for (final card in cards) {
          if (messageMatchesCard(body, card)) {
            final cycle = CycleCalculator.getBillingCycle(card, referenceDate: now);

            // Parse explicit transaction date from SMS text or fallback to SMS timestamp
            final txDate = extractTransactionDate(body, referenceDate: now) ?? smsDate;

            // STRICT CYCLE FILTER: Ignore any SMS/RCS message outside the active billing cycle for this card
            if (!cycle.containsDate(txDate)) {
              continue;
            }

            final double? amount = extractAmount(body);
            if (amount != null && amount > 0) {
              final String merchant = extractMerchant(body);
              results.add(ParsedSmsTransaction(
                cardLast4: card.last4,
                amount: amount,
                merchant: merchant,
                date: txDate,
                rawBody: body,
                matchedCardId: card.id,
              ));

              break; // Matched this card
            }
          }
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Returns true if body contains non-spend keywords like OTPs, statements, bill dues, offers, vouchers
  static bool isNonSpendMessage(String body) {
    final lower = body.toLowerCase();
    final excludeTerms = [
      'declined',
      'decline',
      'txn declined',
      'transaction declined',
      'failed',
      'txn failed',
      'transaction failed',
      'unsuccessful',
      'converted into emi',
      'converted to emi',
      'converted into an emi',
      'converted to an emi',
      'converted emi',
      'converted to merchant emi',
      'convert to emi',
      'conversion to emi',
      'otp',
      'one time password',
      'verification code',
      'secret code',
      'do not share',
      'code is',
      'use code',
      'statement',
      'total amt due',
      'total amount due',
      'min amt due',
      'minimum amount due',
      'due date',
      'e-statement',
      'bill generated',
      'bill date',
      'pay bill',
      'total due',
      'bill of rs',
      'payment received',
      'thank you for payment',
      'thank you for paying',
      'credited to your',
      'refund',
      'cashback',
      'autopay',
      'credit limit',
      'limit increased',
      'limit revised',
      'reward points',
      'offer',
      'apply now',
      // Promotional & Marketing offer exclusions
      'get rs',
      'get inr',
      'voucher',
      'e-voucher',
      'gift card',
      'coupon',
      'promo',
      'promotion',
      'special offer',
      'exclusive offer',
      'limited offer',
      'by doing',
      'min. rs',
      'minimum spend',
      'minimum purchase',
      't&c',
      't&c:',
      'terms and conditions',
      'terms & conditions',
      'eligible',
      'eligibility',
      'congratulations',
      'congrats',
      'win rs',
      'earn rs',
      'earn up to',
      'discount',
      'flat rs',
      'save up to',
      'bit.ly',
      'acl.cc',
      'tinyurl',
    ];

    for (final term in excludeTerms) {
      if (lower.contains(term)) return true;
    }
    return false;
  }

  /// Returns true ONLY if message represents a real spend / debit transaction
  static bool isSpendMessage(String body) {
    final lower = body.toLowerCase();

    // Strictly exclude OTPs, bill statements, payment receipts, promotional offers, etc.
    if (isNonSpendMessage(lower)) return false;

    // Must contain an explicit spend / debit action verb or pattern
    final spendVerbs = [
      'spent',
      'debited',
      'transacted',
      'transaction',
      'txn',
      'paid',
      'purchase',
      'used',
      'swiped',
      'vpa',
      'charges',
      'sbi card',
      'sbi credit card',
      'using',
    ];

    for (final verb in spendVerbs) {
      if (lower.contains(verb)) return true;
    }

    return false;
  }

  static bool messageMatchesCard(String body, CreditCard card) {
    final lower = body.toLowerCase();
    final last4 = card.last4.trim();
    if (last4.isEmpty) return false;

    // Check for last 4 digits patterns (e.g. "3079", "xx3079", "xxxx3079", "ending 3079", "card 3079")
    if (lower.contains(last4)) return true;
    if (lower.contains('x$last4') || lower.contains('xx$last4')) return true;
    if (lower.contains('ending $last4') || lower.contains('ending with $last4') || lower.contains('ending in $last4')) return true;

    // Check bank name if explicit
    final bankLower = card.bank.toLowerCase().replaceAll('bank', '').replaceAll('card', '').trim();
    if (bankLower.length >= 2 && lower.contains(bankLower) && lower.contains(last4)) {
      return true;
    }

    return false;
  }

  static DateTime? extractTransactionDate(String body, {DateTime? referenceDate}) {
    DateTime? dt;
    final currentYear = (referenceDate ?? DateTime.now()).year;

    // 1. ISO Format: "2026-08-15" or "2026/08/15"
    final isoMatch = RegExp(r'\b(20\d{2})[\s\-/.](\d{1,2})[\s\-/.](\d{1,2})\b').firstMatch(body);
    if (isoMatch != null) {
      final y = int.tryParse(isoMatch.group(1)!);
      final m = int.tryParse(isoMatch.group(2)!);
      final d = int.tryParse(isoMatch.group(3)!);
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        dt = DateTime(y, m, d);
      }
    }

    if (dt == null) {
      // 2. Text Month: "15 Sep 24", "15-Sep-2026", "15/Sep/26", "15.Sep.24"
      final textMonthMatch = RegExp(r'\b(\d{1,2})[\s\-/.]([A-Za-z]{3})[\s\-/.](\d{2,4})\b', caseSensitive: false).firstMatch(body);
      if (textMonthMatch != null) {
        final d = int.tryParse(textMonthMatch.group(1)!);
        final monthStr = textMonthMatch.group(2)!.toLowerCase();
        var y = int.tryParse(textMonthMatch.group(3)!);
        if (y != null && y < 100) y += 2000;

        const months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        };
        final m = months[monthStr];
        if (d != null && m != null && y != null && y >= 2000 && y <= 2100) {
          dt = DateTime(y, m, d);
        }
      }
    }

    if (dt == null) {
      // 3. Numeric DMY: "17-09-26", "05/08/26", "10/09/26", "15.09.2024"
      final dmyMatch = RegExp(r'\b(\d{1,2})[\s\-/.](\d{1,2})[\s\-/.](\d{2,4})\b').firstMatch(body);
      if (dmyMatch != null) {
        final d = int.tryParse(dmyMatch.group(1)!);
        final m = int.tryParse(dmyMatch.group(2)!);
        var y = int.tryParse(dmyMatch.group(3)!);
        if (y != null && y < 100) y += 2000;
        if (d != null && m != null && y != null && m >= 1 && m <= 12 && d >= 1 && d <= 31 && y >= 2000 && y <= 2100) {
          dt = DateTime(y, m, d);
        }
      }
    }

    // NORMALIZE FUTURE YEARS: If parsed date year is in future, normalize to currentYear
    if (dt != null && dt.year > currentYear) {
      dt = DateTime(currentYear, dt.month, dt.day);
    }

    return dt;
  }

  static double? extractAmount(String body) {
    final regExps = [
      // "Spent Rs 43423.82" or "Spent INR 117" or "Spent Rs. 43423.82"
      RegExp(r'spent\s*(?:rs\.?|inr)?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      // "Rs 43423.82 spent" or "Rs. 111.23 spent" or "INR 899.00 spent"
      RegExp(r'(?:rs\.?|inr)\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:spent|debited|transacted|used)', caseSensitive: false),
      // "Txn Rs.550.00" or "Txn INR 500" or "Transaction of Rs. 269.00"
      RegExp(r'(?:txn|txn\.|transaction)\s*(?:of)?\s*(?:rs\.?|inr)?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      // "for Rs 269.00" or "for Rs. 269.00" or "for INR 269"
      RegExp(r'for\s*(?:rs\.?|inr)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      // "debited by/for Rs. 1,950.00"
      RegExp(r'debited\s*(?:by|for)?\s*(?:rs\.?|inr)?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      // Universal fallback for Rs / INR amount: "Rs 43,423.82" or "INR 43,423.82"
      RegExp(r'(?:rs\.?|inr)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
    ];

    for (final regex in regExps) {
      final match = regex.firstMatch(body);
      if (match != null) {
        final rawStr = match.group(1)?.replaceAll(',', '') ?? '';
        final val = double.tryParse(rawStr);
        if (val != null && val > 0) return val;
      }
    }
    return null;
  }

  static String extractMerchant(String body) {
    // 1. "at [MERCHANT]" (e.g. "at Flipkart", "at KIMSKOLLAM", "at QRS7501084", "at 79670663030705@cnrb")
    final atMatch = RegExp(
      r'\bat\s+([A-Za-z0-9\s.\-*&@]+?)(?=\s+on|\s+at|\s+ref|\s+avail|\s+lmt|\.|\$|val|\n|\r)',
      caseSensitive: false,
    ).firstMatch(body);
    if (atMatch != null) {
      final name = atMatch.group(1)?.trim() ?? '';
      if (name.length >= 2 && !name.toLowerCase().startsWith('card') && !name.toLowerCase().startsWith('the')) {
        return name;
      }
    }

    // 2. ICICI style: "on [DATE] on [MERCHANT]. Avl Limit:"
    final iciciMatch = RegExp(
      r'\bon\s+\d{1,2}[\s\-/.](([A-Za-z]{3})|(\d{1,2}))[\s\-/.]\d{2,4}\s+on\s+([A-Za-z0-9\s.\-*&]+?)(?=\.|\s+avl|\s+avail|\$|if)',
      caseSensitive: false,
    ).firstMatch(body);
    if (iciciMatch != null) {
      final name = iciciMatch.group(4)?.trim() ?? iciciMatch.group(1)?.trim() ?? '';
      if (name.length >= 2) return name;
    }

    // 3. Multi-line extraction (e.g. Axis Bank)
    final lines = body.split(RegExp(r'\r?\n')).map((l) => l.trim()).toList();
    for (final line in lines) {
      if (line.isEmpty) continue;
      final lLower = line.toLowerCase();
      if (lLower.startsWith('spent') ||
          lLower.startsWith('txn') ||
          lLower.contains('card') ||
          lLower.contains('avl limit') ||
          lLower.contains('not you') ||
          lLower.contains('block') ||
          lLower.contains('0002') ||
          RegExp(r'^\d{2}[-/.]\d{2}[-/.]\d{2}').hasMatch(lLower)) {
        continue;
      }
      if (line.length >= 2 && line.length <= 35) {
        return line;
      }
    }

    // 4. "for [MERCHANT]" or "to [MERCHANT]"
    final forMatch = RegExp(
      r'\b(?:for|to)\s+([A-Za-z0-9\s.\-*&]+?)(?=\s+on|\s+ref|\s+avail|\s+lmt|\.|\$|\n|\r)',
      caseSensitive: false,
    ).firstMatch(body);
    if (forMatch != null) {
      final name = forMatch.group(1)?.trim() ?? '';
      if (name.length >= 2 && !name.toLowerCase().startsWith('rs') && !name.toLowerCase().startsWith('inr') && !name.toLowerCase().startsWith('a transaction')) {
        return name;
      }
    }

    // 5. Fallback: "On [MERCHANT]" (ignoring "On [Bank/Card]")
    final onMatch = RegExp(
      r'\bon\s+([A-Za-z0-9\s.\-*&@]+?)(?=\s+at|\s+ref|\s+avail|\s+lmt|\.|\$|\n|\r)',
      caseSensitive: false,
    ).firstMatch(body);
    if (onMatch != null) {
      final name = onMatch.group(1)?.trim() ?? '';
      final lowerName = name.toLowerCase();
      if (name.length >= 2 && !lowerName.contains('card') && !lowerName.contains('bank') && !lowerName.startsWith('your')) {
        return name;
      }
    }

    return 'Merchant Purchase';
  }
}
