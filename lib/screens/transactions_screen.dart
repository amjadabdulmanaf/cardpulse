import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/animated_counter_text.dart';
import '../widgets/metro_card_pulse_logo.dart';
import '../widgets/metro_tile_flip_entrance.dart';
import '../widgets/notifications_sheet.dart';

enum TransactionFilter { all, mine, others, selfEmi, othersEmi }

class TransactionsScreen extends StatefulWidget {
  final StorageService? storageService;
  final List<CreditCard> cards;
  final List<TransactionItem> transactions;
  final List<EmiItem> emis;
  final Function(String) onDeleteTransaction;
  final Function(TransactionItem) onUpdateTransaction;
  final Function(EmiItem)? onUpdateEmi;
  final VoidCallback onRefresh;

  const TransactionsScreen({
    super.key,
    this.storageService,
    required this.cards,
    required this.transactions,
    required this.emis,
    required this.onDeleteTransaction,
    required this.onUpdateTransaction,
    this.onUpdateEmi,
    required this.onRefresh,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = TransactionFilter.all;
  String _searchQuery = '';
  final Set<String> _expandedSmsIds = {};

  void _openAttributionSheet(TransactionItem tx) {
    if (tx.isEmi) return;

    bool isOthers = tx.isOthersSpend;
    final personController = TextEditingController(text: tx.personName ?? '');
    final purposeController = TextEditingController(text: tx.purpose ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.zero,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            AnimatedCounterText(
                              value: tx.amount,
                              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text('Who is this spend for?', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => isOthers = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isOthers ? const Color(0xFF008A00) : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mine (Self)',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => isOthers = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isOthers ? const Color(0xFFF09609) : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.group_outlined, size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Other's Spend",
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (isOthers) ...[
                      const SizedBox(height: 14),
                      Text('Person / Beneficiary Name', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: personController,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Rahul, Mom, Colleague',
                          hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                          prefixIcon: Icon(Icons.person_pin_outlined, color: Color(0xFFF09609)),
                          filled: true,
                          fillColor: Color(0xFF1E1E1E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Purpose / Note', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: purposeController,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Team Dinner, Gift, Shared Ticket',
                          hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                          prefixIcon: Icon(Icons.notes_outlined, color: Color(0xFFA0A0A0)),
                          filled: true,
                          fillColor: Color(0xFF1E1E1E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0078D7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('SAVE ATTRIBUTION', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: () {
                          final updatedTx = tx.copyWith(
                            isOthersSpend: isOthers,
                            personName: isOthers ? personController.text.trim() : null,
                            purpose: isOthers ? purposeController.text.trim() : null,
                          );

                          widget.onUpdateTransaction(updatedTx);
                          Navigator.of(ctx).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isOthers
                                    ? 'Marked spend for ${personController.text.trim().isEmpty ? "Others" : personController.text.trim()}'
                                    : 'Marked spend as Mine (Self)',
                              ),
                              backgroundColor: const Color(0xFF008A00),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      personController.dispose();
      purposeController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allList = <TransactionItem>[...widget.transactions];
    final now = DateTime.now();

    for (final emi in widget.emis) {
      final card = widget.cards.firstWhere(
        (c) => c.id == emi.cardId,
        orElse: () => CreditCard(
          id: '',
          cardName: 'Card',
          bank: 'Bank',
          last4: '0000',
          monthlyLimit: 0,
          billGenerationDay: 15,
        ),
      );
      final cycle = CycleCalculator.getBillingCycle(card);

      for (final item in emi.schedule) {
        final isCurrentMonth = item.year == now.year && item.month == now.month;
        final instDate = DateTime(item.year, item.month, card.billGenerationDay);
        final inCycle = cycle.containsDate(instDate) ||
            (item.year == cycle.startDate.year && item.month == cycle.startDate.month) ||
            (item.year == cycle.endDate.year && item.month == cycle.endDate.month);
        final isUnpaidDue = !item.isPaid && ((item.year < now.year) || (item.year == now.year && item.month <= now.month));

        if (isCurrentMonth || inCycle || isUnpaidDue) {
          allList.add(TransactionItem(
            id: 'emi_${emi.id}_${item.installmentNumber}',
            cardId: emi.cardId,
            title: emi.title,
            amount: item.amount,
            date: DateTime(item.year, item.month, card.billGenerationDay),
            category: 'EMI',
            isEmi: true,
            emiId: emi.id,
            isOthersSpend: emi.type == EmiType.others,
            personName: emi.beneficiaryName,
          ));
        }
      }
    }

    allList.sort((a, b) => b.date.compareTo(a.date));

    final filtered = allList.where((tx) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = tx.title.toLowerCase().contains(query);
        final matchCategory = tx.category.toLowerCase().contains(query);
        final matchPerson = tx.personName?.toLowerCase().contains(query) ?? false;
        final matchPurpose = tx.purpose?.toLowerCase().contains(query) ?? false;
        final card = widget.cards.firstWhere((c) => c.id == tx.cardId, orElse: () => widget.cards.first);
        final matchCard = card.cardName.toLowerCase().contains(query) || card.last4.contains(query);
        if (!matchTitle && !matchCategory && !matchCard && !matchPerson && !matchPurpose) return false;
      }

      switch (_filter) {
        case TransactionFilter.mine:
          return !tx.isOthersSpend && !tx.isEmi;
        case TransactionFilter.others:
          return tx.isOthersSpend && !tx.isEmi;
        case TransactionFilter.selfEmi:
          if (!tx.isEmi || tx.emiId == null) return false;
          final emi = widget.emis.firstWhere((e) => e.id == tx.emiId, orElse: () => widget.emis.first);
          return emi.type == EmiType.self;
        case TransactionFilter.othersEmi:
          if (!tx.isEmi || tx.emiId == null) return false;
          final emi = widget.emis.firstWhere((e) => e.id == tx.emiId, orElse: () => widget.emis.first);
          return emi.type == EmiType.others;
        case TransactionFilter.all:
          return true;
      }
    }).toList();

    final Map<String, List<TransactionItem>> grouped = {};

    for (final tx in filtered) {
      String groupKey;
      if (tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day) {
        groupKey = 'Today, ${Formatters.formatDateShort(tx.date)}';
      } else if (tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day - 1) {
        groupKey = 'Yesterday, ${Formatters.formatDateShort(tx.date)}';
      } else {
        groupKey = Formatters.formatDate(tx.date);
      }

      grouped.putIfAbsent(groupKey, () => []).add(tx);
    }

    final notifications = NotificationsHelper.generateNotifications(
      cards: widget.cards,
      transactions: widget.transactions,
      emis: widget.emis,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Metro Dark Obsidian
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fixed Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF121212),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0078D7),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.insights_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Spends',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                        onPressed: () {
                          NotificationsHelper.showNotificationsSheet(
                            context: context,
                            storageService: widget.storageService,
                            cards: widget.cards,
                            transactions: widget.transactions,
                            emis: widget.emis,
                          );
                        },
                      ),
                      if (notifications.isNotEmpty)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0078D7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auto-parsed SMS Banner (Metro Flip)
                    MetroTileFlipEntrance(
                      delayMs: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              color: const Color(0xFF008A00),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Auto-parsed from SMS inbox',
                                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: widget.onRefresh,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0078D7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                icon: const Icon(Icons.sync, size: 14),
                                label: Text('SCAN INBOX', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Search Bar
                    MetroTileFlipEntrance(
                      delayMs: 80,
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search merchant, person, card...',
                          hintStyle: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFFA0A0A0), size: 18),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: Color(0xFF2D2D2D)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: Color(0xFF2D2D2D)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Filter Chips Row
                    MetroTileFlipEntrance(
                      delayMs: 160,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All',
                              count: allList.length,
                              filter: TransactionFilter.all,
                              color: const Color(0xFF0078D7),
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Mine',
                              count: allList.where((t) => !t.isOthersSpend && !t.isEmi).length,
                              filter: TransactionFilter.mine,
                              color: const Color(0xFF008A00),
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Others',
                              count: allList.where((t) => t.isOthersSpend && !t.isEmi).length,
                              filter: TransactionFilter.others,
                              color: const Color(0xFFF09609),
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Self EMI',
                              count: allList.where((t) {
                                if (!t.isEmi || t.emiId == null) return false;
                                final emi = widget.emis.firstWhere((e) => e.id == t.emiId, orElse: () => widget.emis.first);
                                return emi.type == EmiType.self;
                              }).length,
                              filter: TransactionFilter.selfEmi,
                              color: const Color(0xFF0078D7),
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Others EMI',
                              count: allList.where((t) {
                                if (!t.isEmi || t.emiId == null) return false;
                                final emi = widget.emis.firstWhere((e) => e.id == t.emiId, orElse: () => widget.emis.first);
                                return emi.type == EmiType.others;
                              }).length,
                              filter: TransactionFilter.othersEmi,
                              color: const Color(0xFFF09609),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date-Grouped Spends List
                    if (filtered.isEmpty)
                      MetroTileFlipEntrance(
                        delayMs: 220,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.receipt_long_outlined, color: Color(0xFF0078D7), size: 36),
                              const SizedBox(height: 8),
                              Text('No Spends or EMIs Found', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Scan SMS inbox or change filters to inspect spends.', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, groupIdx) {
                          final groupHeader = grouped.keys.elementAt(groupIdx);
                          final groupItems = grouped[groupHeader]!;
                          final groupTotal = groupItems.fold(0.0, (sum, item) => sum + item.amount);

                          return MetroTileFlipEntrance(
                            delayMs: 220 + (groupIdx * 60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6, top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        groupHeader,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '${groupItems.length} Spends • ',
                                            style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                                          ),
                                          AnimatedCounterText(
                                            value: groupTotal,
                                            delayMs: 300 + (groupIdx * 60),
                                            style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: groupItems.length,
                                  itemBuilder: (context, itemIdx) {
                                    final tx = groupItems[itemIdx];
                                    final card = widget.cards.firstWhere(
                                      (c) => c.id == tx.cardId,
                                      orElse: () => CreditCard(
                                        id: '',
                                        cardName: 'Credit Card',
                                        bank: 'ICICI',
                                        last4: '8910',
                                        monthlyLimit: 0,
                                        billGenerationDay: 15,
                                      ),
                                    );

                                    EmiItem? emi;
                                    if (tx.isEmi && tx.emiId != null) {
                                      try {
                                        emi = widget.emis.firstWhere((e) => e.id == tx.emiId);
                                      } catch (_) {}
                                    }

                                    final isExpanded = _expandedSmsIds.contains(tx.id);

                                    return _buildTransactionCard(
                                      tx: tx,
                                      card: card,
                                      emi: emi,
                                      isExpanded: isExpanded,
                                      itemDelay: 320 + (groupIdx * 60) + (itemIdx * 30),
                                      onToggleExpand: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedSmsIds.remove(tx.id);
                                          } else {
                                            _expandedSmsIds.add(tx.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),

                                const SizedBox(height: 6),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required TransactionItem tx,
    required CreditCard card,
    required EmiItem? emi,
    required bool isExpanded,
    required int itemDelay,
    required VoidCallback onToggleExpand,
  }) {
    final isEmi = tx.isEmi;

    int instNum = 1;
    EmiScheduleItem? scheduleItem;
    if (isEmi && emi != null) {
      if (tx.id.startsWith('emi_')) {
        final parts = tx.id.split('_');
        if (parts.length >= 3) {
          instNum = int.tryParse(parts[2]) ?? 1;
        }
      }
      try {
        scheduleItem = emi.schedule.firstWhere((s) => s.installmentNumber == instNum);
      } catch (_) {
        if (emi.schedule.isNotEmpty) scheduleItem = emi.schedule.first;
      }
    }

    IconData iconData = Icons.shopping_bag_outlined;
    if (tx.title.toLowerCase().contains('swiggy') || tx.category.toLowerCase().contains('dining')) {
      iconData = Icons.fastfood_outlined;
    } else if (tx.title.toLowerCase().contains('petrol') || tx.title.toLowerCase().contains('shell') || tx.category.toLowerCase().contains('fuel')) {
      iconData = Icons.local_gas_station_outlined;
    } else if (tx.title.toLowerCase().contains('apple') || tx.title.toLowerCase().contains('macbook') || tx.title.toLowerCase().contains('laptop')) {
      iconData = Icons.laptop_mac;
    } else if (isEmi) {
      iconData = Icons.calendar_month_outlined;
    }

    final accentColor = isEmi ? const Color(0xFF0078D7) : (tx.isOthersSpend ? const Color(0xFFF09609) : const Color(0xFF008A00));

    return GestureDetector(
      onTap: () {
        if (!isEmi) {
          _openAttributionSheet(tx);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E), // Metro Solid Tile
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Icon(iconData, color: Colors.white, size: 18),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tx.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isEmi && emi != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF262626),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Text(
                                  'EMI $instNum/${emi.schedule.length}',
                                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 3),

                        Row(
                          children: [
                            Text(
                              '${card.bank} •••• ${card.last4}',
                              style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                            ),
                            const Text(' • ', style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 11)),
                            if (tx.isOthersSpend)
                              Text(
                                '👤 ${tx.personName ?? "Others"}',
                                style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF09609), fontSize: 10, fontWeight: FontWeight.bold),
                              )
                            else
                              Text(
                                tx.category,
                                style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedCounterText(
                        value: tx.amount,
                        delayMs: itemDelay,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isEmi && scheduleItem != null)
                        Text(
                          scheduleItem.isPaid ? 'PAID' : 'DUE',
                          style: GoogleFonts.spaceGrotesk(
                            color: scheduleItem.isPaid ? const Color(0xFF008A00) : const Color(0xFFF09609),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (tx.rawSms != null)
                        GestureDetector(
                          onTap: onToggleExpand,
                          child: Text(
                            isExpanded ? '▲ RAW SMS' : '▼ SMS PARSED',
                            style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Text(
                          'SETTLED',
                          style: GoogleFonts.spaceGrotesk(color: const Color(0xFF008A00), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            if (isExpanded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: const Color(0xFF262626),
                child: Text(
                  tx.rawSms ?? 'Raw SMS telemetry data parsed locally on device.',
                  style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 10, height: 1.3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required TransactionFilter filter,
    required Color color,
  }) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: isSelected ? Colors.white : const Color(0xFFA0A0A0),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: GoogleFonts.spaceGrotesk(
                color: isSelected ? Colors.white : const Color(0xFFA0A0A0),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
