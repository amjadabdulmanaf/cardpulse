import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../models/transaction.dart';
import '../services/sms_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../widgets/animated_counter_text.dart';
import '../widgets/metro_tile_flip_entrance.dart';

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
        selected.add(i);
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
      height: MediaQuery.of(context).size.height * 0.80,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF121212), // Metro Obsidian Background
        borderRadius: BorderRadius.zero, // Windows Phone Sharp Edge
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0078D7), // Solid Metro Blue
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.sync, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'FETCH SPENDS FROM SMS',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            'Scans bank SMS inbox offline on-device. Deduplicates existing spends.',
            style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
          ),

          const SizedBox(height: 14),

          // Content State
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF0078D7)),
                        const SizedBox(height: 16),
                        Text('Scanning SMS inbox offline on-device...', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : _parsedList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mark_chat_read_outlined, size: 48, color: Color(0xFF008A00)),
                            const SizedBox(height: 12),
                            Text(
                              'No New Spends Found in SMS',
                              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'All financial SMS debits in active cycle are already synced.',
                              style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _scan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0078D7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: Text('RETRY SCAN', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
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
                                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () {
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
                                      ? 'DESELECT ALL'
                                      : 'SELECT NEW',
                                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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

                                return MetroTileFlipEntrance(
                                  delayMs: index * 60,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E1E1E), // Metro Solid Tile
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: CheckboxListTile(
                                      value: isSelected,
                                      activeColor: const Color(0xFF0078D7),
                                      checkColor: Colors.white,
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
                                              style: GoogleFonts.spaceGrotesk(
                                                color: isDisabled ? const Color(0xFFA0A0A0) : Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          AnimatedCounterText(
                                            value: item.amount,
                                            delayMs: (index * 60) + 120,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontWeight: FontWeight.bold,
                                              color: isDisabled ? const Color(0xFFA0A0A0) : const Color(0xFF0078D7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${card.cardName} (••${card.last4}) • ${Formatters.formatDateShort(item.date)}',
                                            style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                                          ),
                                          if (isSynced)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF262626),
                                                borderRadius: BorderRadius.zero,
                                              ),
                                              child: Text(
                                                'SYNCED',
                                                style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          else if (isDeleted)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: const BoxDecoration(
                                                color: Color(0x26B91C1C),
                                                borderRadius: BorderRadius.zero,
                                              ),
                                              child: Text(
                                                'DELETED',
                                                style: GoogleFonts.spaceGrotesk(color: const Color(0xFFB91C1C), fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
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
            MetroTileFlipEntrance(
              delayMs: 300,
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _selectedIndices.isEmpty ? null : _importSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0078D7),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF262626),
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(
                    'IMPORT ${_selectedIndices.length} NEW TRANSACTIONS',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
