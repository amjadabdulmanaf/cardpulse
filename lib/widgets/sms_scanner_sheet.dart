import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/transaction.dart';
import '../services/sms_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class SmsScannerSheet extends StatefulWidget {
  final StorageService? storageService;
  final List<CreditCard> cards;
  final List<TransactionItem> existingTransactions;
  final Function(List<TransactionItem>) onImport;

  const SmsScannerSheet({
    super.key,
    this.storageService,
    required this.cards,
    required this.existingTransactions,
    required this.onImport,
  });

  @override
  State<SmsScannerSheet> createState() => _SmsScannerSheetState();
}

class _SmsScannerSheetState extends State<SmsScannerSheet> {
  bool _isLoading = true;
  List<ParsedSmsTransaction> _parsedList = [];
  Set<int> _selectedIndices = {};
  Set<int> _syncedIndices = {};
  Set<int> _deletedIndices = {};

  @override
  void initState() {
    super.initState();
    _scan();
  }

  bool _isDuplicate(ParsedSmsTransaction parsed) {
    return widget.existingTransactions.any((tx) {
      if (tx.rawSms != null && tx.rawSms == parsed.rawBody) return true;
      final sameCard = tx.cardId == parsed.matchedCardId;
      final sameAmount = (tx.amount - parsed.amount).abs() < 0.01;
      final sameTitle = tx.title.toLowerCase().trim() == parsed.merchant.toLowerCase().trim();
      final sameDay = tx.date.year == parsed.date.year &&
          tx.date.month == parsed.date.month &&
          tx.date.day == parsed.date.day;
      return sameCard && sameAmount && sameTitle && sameDay;
    });
  }

  Future<void> _scan() async {
    setState(() {
      _isLoading = true;
    });

    final results = await SmsService.fetchAndParseSms(widget.cards);

    final Set<int> selected = {};
    final Set<int> synced = {};
    final Set<int> deleted = {};

    for (int i = 0; i < results.length; i++) {
      final p = results[i];
      bool isDeleted = false;
      if (widget.storageService != null) {
        isDeleted = await widget.storageService!.isTransactionDeleted(
          rawSms: p.rawBody,
          cardId: p.matchedCardId,
          amount: p.amount,
          date: p.date,
        );
      }

      if (_isDuplicate(p)) {
        synced.add(i);
      } else if (isDeleted) {
        deleted.add(i);
      } else {
        selected.add(i); // Auto-select NEW transactions only!
      }
    }

    setState(() {
      _parsedList = results;
      _isLoading = false;
      _selectedIndices = selected;
      _syncedIndices = synced;
      _deletedIndices = deleted;
    });
  }

  void _importSelected() {
    final List<TransactionItem> imported = [];
    for (final index in _selectedIndices) {
      if (index < _parsedList.length) {
        final item = _parsedList[index];
        imported.add(TransactionItem(
          id: '${item.date.millisecondsSinceEpoch}_$index',
          cardId: item.matchedCardId,
          title: item.merchant,
          amount: item.amount,
          date: item.date,
          category: 'Shopping',
          isEmi: false,
          rawSms: item.rawBody,
        ));
      }
    }

    widget.onImport(imported);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161F30),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF222F46),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sms_outlined,
                      color: Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Fetch Spends from SMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 4),
          const Text(
            'Scans bank SMS offline. Existing transactions are automatically deduplicated.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),

          const SizedBox(height: 16),

          // Content State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF34D399)),
                        SizedBox(height: 16),
                        Text('Scanning SMS inbox offline...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  )
                : _parsedList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mark_chat_read, size: 48, color: Color(0xFF34D399)),
                            const SizedBox(height: 12),
                            const Text(
                              'No New Spends Found in SMS',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'All financial SMS debits in active cycle are already synced.',
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _scan,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF222F46)),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.refresh, color: Color(0xFF34D399)),
                              label: const Text('Retry Scan'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_parsedList.length} Detected (${_selectedIndices.length} New)',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {
                                  final totalDisabled = _syncedIndices.length + _deletedIndices.length;
                                  setState(() {
                                    if (_selectedIndices.length == _parsedList.length - totalDisabled) {
                                      _selectedIndices.clear();
                                    } else {
                                      _selectedIndices = Set.from(
                                        List.generate(_parsedList.length, (i) => i)
                                            .where((i) => !_syncedIndices.contains(i) && !_deletedIndices.contains(i)),
                                      );
                                    }
                                  });
                                },
                                child: Text(
                                  _selectedIndices.length == _parsedList.length - (_syncedIndices.length + _deletedIndices.length)
                                      ? 'Deselect All'
                                      : 'Select New',
                                  style: const TextStyle(color: Color(0xFF34D399)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _parsedList.length,
                              itemBuilder: (context, index) {
                                final item = _parsedList[index];
                                final isSelected = _selectedIndices.contains(index);
                                final isSynced = _syncedIndices.contains(index);
                                final isDeleted = _deletedIndices.contains(index);
                                final isDisabled = isSynced || isDeleted;

                                final card = widget.cards.firstWhere(
                                  (c) => c.id == item.matchedCardId,
                                  orElse: () => widget.cards.first,
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111827),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDisabled
                                          ? const Color(0xFF222F46)
                                          : (isSelected ? const Color(0xFF34D399) : const Color(0xFF222F46)),
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    activeColor: const Color(0xFF34D399),
                                    checkColor: Colors.black,
                                    onChanged: isDisabled
                                        ? null
                                        : (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedIndices.add(index);
                                              } else {
                                                _selectedIndices.remove(index);
                                              }
                                            });
                                          },
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.merchant,
                                            style: TextStyle(
                                              color: isDisabled ? const Color(0xFF9CA3AF) : Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          Formatters.formatCurrency(item.amount),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDisabled ? const Color(0xFF9CA3AF) : const Color(0xFF34D399),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${card.cardName} (••${card.last4}) • ${Formatters.formatDateShort(item.date)}',
                                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                                        ),
                                        if (isSynced)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF374151),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Already Synced',
                                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        else if (isDeleted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.delete_outline, color: Color(0xFFF87171), size: 10),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Deleted',
                                                  style: TextStyle(color: Color(0xFFF87171), fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),

          const SizedBox(height: 12),

          if (!_isLoading && _parsedList.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _selectedIndices.isEmpty ? null : _importSelected,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF34D399),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF222F46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.download),
                label: Text(
                  'Import ${_selectedIndices.length} New Transactions',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
