import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _kCardsKey = 'cardpulse_cards';
  static const String _kTxKey = 'cardpulse_transactions';
  static const String _kEmisKey = 'cardpulse_emis';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- CARDS ---
  Future<List<CreditCard>> getCards() async {
    try {
      final jsonString = _prefs?.getString(_kCardsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List decoded = jsonDecode(jsonString);
      return decoded.map((e) => CreditCard.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('Error loading cards: $e');
      return [];
    }
  }

  Future<void> saveCards(List<CreditCard> cards) async {
    final encoded = jsonEncode(cards.map((e) => e.toJson()).toList());
    await _prefs?.setString(_kCardsKey, encoded);
  }

  Future<void> saveCard(CreditCard card) async {
    final cards = await getCards();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      cards[index] = card;
    } else {
      cards.add(card);
    }
    await saveCards(cards);
  }

  Future<void> deleteCard(String cardId) async {
    final cards = await getCards();
    cards.removeWhere((c) => c.id == cardId);
    await saveCards(cards);

    // Also remove associated transactions & EMIs
    final txs = await getTransactions();
    txs.removeWhere((t) => t.cardId == cardId);
    await saveTransactions(txs);

    final emis = await getEmis();
    emis.removeWhere((e) => e.cardId == cardId);
    await saveEmis(emis);
  }

  // --- TRANSACTIONS DEDUPLICATION LOGIC ---
  bool _isDuplicate(TransactionItem a, TransactionItem b) {
    if (a.id == b.id) return true;
    if (a.rawSms != null && b.rawSms != null && a.rawSms == b.rawSms) return true;
    final sameCard = a.cardId == b.cardId;
    final sameAmount = (a.amount - b.amount).abs() < 0.01;
    final sameTitle = a.title.toLowerCase().trim() == b.title.toLowerCase().trim();
    final sameDay = a.date.year == b.date.year &&
        a.date.month == b.date.month &&
        a.date.day == b.date.day;

    return sameCard && sameAmount && sameTitle && sameDay;
  }

  Future<List<TransactionItem>> getTransactions() async {
    try {
      final jsonString = _prefs?.getString(_kTxKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List decoded = jsonDecode(jsonString);
      final rawList = decoded.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>)).toList();

      // Collapse existing duplicates automatically
      final List<TransactionItem> unique = [];
      for (final tx in rawList) {
        if (!unique.any((existing) => _isDuplicate(existing, tx))) {
          unique.add(tx);
        }
      }

      // If duplicates were pruned, save cleaned list back
      if (unique.length != rawList.length) {
        await saveTransactions(unique);
      }

      return unique;
    } catch (e) {
      if (kDebugMode) print('Error loading transactions: $e');
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionItem> transactions) async {
    final List<TransactionItem> unique = [];
    for (final tx in transactions) {
      if (!unique.any((existing) => _isDuplicate(existing, tx))) {
        unique.add(tx);
      }
    }
    final encoded = jsonEncode(unique.map((e) => e.toJson()).toList());
    await _prefs?.setString(_kTxKey, encoded);
  }

  static const String _kDeletedTxKey = 'cardpulse_deleted_tx_ids';

  Future<List<String>> getDeletedTransactionIds() async {
    return _prefs?.getStringList(_kDeletedTxKey) ?? [];
  }

  Future<bool> isTransactionDeleted({
    String? id,
    String? rawSms,
    String? cardId,
    double? amount,
    DateTime? date,
  }) async {
    final deletedList = await getDeletedTransactionIds();
    if (id != null && deletedList.contains(id)) return true;
    if (rawSms != null && rawSms.isNotEmpty && deletedList.contains(rawSms)) return true;
    if (cardId != null && amount != null && date != null) {
      final fingerprint = '${cardId}_${amount.toInt()}_${date.year}_${date.month}_${date.day}';
      if (deletedList.contains(fingerprint)) return true;
    }
    return false;
  }

  Future<void> addTransaction(TransactionItem transaction) async {
    final isDeleted = await isTransactionDeleted(
      id: transaction.id,
      rawSms: transaction.rawSms,
      cardId: transaction.cardId,
      amount: transaction.amount,
      date: transaction.date,
    );
    if (isDeleted) return;

    final txs = await getTransactions();
    final isDup = txs.any((existing) => _isDuplicate(existing, transaction));
    if (!isDup) {
      txs.insert(0, transaction); // latest first
      await saveTransactions(txs);
    }
  }

  Future<void> updateTransaction(TransactionItem transaction) async {
    final txs = await getTransactions();
    final index = txs.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) {
      txs[index] = transaction;
      await saveTransactions(txs);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final txs = await getTransactions();
    final itemIndex = txs.indexWhere((t) => t.id == id);

    if (itemIndex >= 0) {
      final tx = txs[itemIndex];
      final deletedList = List<String>.from(_prefs?.getStringList(_kDeletedTxKey) ?? []);

      if (!deletedList.contains(tx.id)) {
        deletedList.add(tx.id);
      }
      if (tx.rawSms != null && tx.rawSms!.isNotEmpty && !deletedList.contains(tx.rawSms)) {
        deletedList.add(tx.rawSms!);
      }
      final fingerprint = '${tx.cardId}_${tx.amount.toInt()}_${tx.date.year}_${tx.date.month}_${tx.date.day}';
      if (!deletedList.contains(fingerprint)) {
        deletedList.add(fingerprint);
      }

      await _prefs?.setStringList(_kDeletedTxKey, deletedList);
      txs.removeAt(itemIndex);
      await saveTransactions(txs);
    } else {
      txs.removeWhere((t) => t.id == id);
      await saveTransactions(txs);
    }
  }

  // --- EMIS ---
  Future<List<EmiItem>> getEmis() async {
    try {
      final jsonString = _prefs?.getString(_kEmisKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List decoded = jsonDecode(jsonString);
      return decoded.map((e) => EmiItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('Error loading EMIs: $e');
      return [];
    }
  }

  Future<void> saveEmis(List<EmiItem> emis) async {
    final encoded = jsonEncode(emis.map((e) => e.toJson()).toList());
    await _prefs?.setString(_kEmisKey, encoded);
  }

  Future<void> saveEmi(EmiItem emi) async {
    final emis = await getEmis();
    final index = emis.indexWhere((e) => e.id == emi.id);
    if (index >= 0) {
      emis[index] = emi;
    } else {
      emis.add(emi);
    }
    await saveEmis(emis);
  }

  Future<void> deleteEmi(String id) async {
    final emis = await getEmis();
    emis.removeWhere((e) => e.id == id);
    await saveEmis(emis);
  }

  static const String _kDismissedNotifsKey = 'cardpulse_dismissed_notifs';

  Future<List<String>> getDismissedNotifications() async {
    return _prefs?.getStringList(_kDismissedNotifsKey) ?? [];
  }

  Future<void> dismissNotification(String id) async {
    final list = List<String>.from(_prefs?.getStringList(_kDismissedNotifsKey) ?? []);
    if (!list.contains(id)) {
      list.add(id);
      await _prefs?.setStringList(_kDismissedNotifsKey, list);
    }
  }

  Future<void> clearAllNotifications(List<String> ids) async {
    final list = List<String>.from(_prefs?.getStringList(_kDismissedNotifsKey) ?? []);
    for (final id in ids) {
      if (!list.contains(id)) list.add(id);
    }
    await _prefs?.setStringList(_kDismissedNotifsKey, list);
  }

  Future<void> purgeVault() async {
    await _prefs?.remove(_kCardsKey);
    await _prefs?.remove(_kTxKey);
    await _prefs?.remove(_kEmisKey);
    await _prefs?.remove(_kDeletedTxKey);
    await _prefs?.remove(_kDismissedNotifsKey);
    await _prefs?.remove(_kAutoReadSmsKey);
    await _prefs?.clear();
    await _prefs?.reload();
  }

  static const String _kAutoReadSmsKey = 'cardpulse_auto_read_sms';
  static const String _kAlertThresholdKey = 'cardpulse_alert_threshold';
  static const String _kCycleResetAlertKey = 'cardpulse_cycle_reset_alert';

  Future<bool> getAutoReadSms() async {
    return _prefs?.getBool(_kAutoReadSmsKey) ?? true;
  }

  Future<void> setAutoReadSms(bool enabled) async {
    await _prefs?.setBool(_kAutoReadSmsKey, enabled);
  }

  Future<double> getAlertThreshold() async {
    return _prefs?.getDouble(_kAlertThresholdKey) ?? 80.0;
  }

  Future<void> setAlertThreshold(double threshold) async {
    await _prefs?.setDouble(_kAlertThresholdKey, threshold);
  }

  Future<bool> getCycleResetAlert() async {
    return _prefs?.getBool(_kCycleResetAlertKey) ?? true;
  }

  Future<void> setCycleResetAlert(bool enabled) async {
    await _prefs?.setBool(_kCycleResetAlertKey, enabled);
  }

  Future<void> flushCache() async {
    await _prefs?.remove(_kTxKey);
    await _prefs?.remove(_kDeletedTxKey);
  }

  Future<String> exportBackupJson() async {
    final cards = await getCards();
    final txs = await getTransactions();
    final emis = await getEmis();
    final data = {
      'version': '1.4.0',
      'timestamp': DateTime.now().toIso8601String(),
      'cards': cards.map((c) => c.toJson()).toList(),
      'transactions': txs.map((t) => t.toJson()).toList(),
      'emis': emis.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  Future<bool> restoreBackupJson(String jsonStr) async {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      if (decoded.containsKey('cards')) {
        final List cards = decoded['cards'];
        await saveCards(cards.map((e) => CreditCard.fromJson(e)).toList());
      }
      if (decoded.containsKey('transactions')) {
        final List txs = decoded['transactions'];
        await saveTransactions(txs.map((e) => TransactionItem.fromJson(e)).toList());
      }
      if (decoded.containsKey('emis')) {
        final List emis = decoded['emis'];
        await saveEmis(emis.map((e) => EmiItem.fromJson(e)).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
