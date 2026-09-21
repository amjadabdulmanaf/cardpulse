import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
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
    if (tx.isEmi) return; // EMIs are attributed via EMI screen

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
                color: Color(0xFF161F30),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              Formatters.formatCurrency(tx.amount),
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text('Who is this spend for?', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => isOthers = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isOthers
                                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                    : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !isOthers ? const Color(0xFF34D399) : const Color(0xFF222F46),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline, size: 16, color: !isOthers ? const Color(0xFF34D399) : Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mine (Self)',
                                    style: TextStyle(
                                      color: !isOthers ? const Color(0xFF34D399) : Colors.white,
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isOthers
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                    : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOthers ? const Color(0xFFFBBF24) : const Color(0xFF222F46),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.group_outlined, size: 16, color: isOthers ? const Color(0xFFFBBF24) : Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Other's Spend",
                                    style: TextStyle(
                                      color: isOthers ? const Color(0xFFFBBF24) : Colors.white,
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
                      const Text('Person / Beneficiary Name', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: personController,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'e.g. Rahul, Mom, Colleague',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          prefixIcon: const Icon(Icons.person_pin_outlined, color: Color(0xFFFBBF24)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF222F46)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Purpose / Note', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: purposeController,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'e.g. Team Dinner, Gift, Shared Ticket',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          prefixIcon: const Icon(Icons.notes_outlined, color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF222F46)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF34D399),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save Attribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                              backgroundColor: const Color(0xFF10B981),
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
    // Generate full list including active cycle and current EMI virtual items
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

    // Sort descending by date
    allList.sort((a, b) => b.date.compareTo(a.date));

    // Filter list by search & type
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

    // Group transactions by Date Header (e.g. Today, 24 Oct / Yesterday, 23 Oct)
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
      backgroundColor: const Color(0xFF0B0F19), // Dark Charcoal Slate
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.credit_score,
                color: Color(0xFF34D399),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CardPulse',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
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
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Auto-parsed from SMS Banner with WORKING "Scan Inbox" Button!
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF222F46)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34D399),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Auto-parsed from SMS',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: widget.onRefresh, // Triggers SMS Scanner Sheet!
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF34D399),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.sync, size: 14),
                      label: const Text('Scan Inbox', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Search Bar
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search merchant, person, card...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF161F30),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF222F46)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF222F46)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Filter Chips Row: All, Mine, Others, Self EMI, Others EMI
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All',
                    count: allList.length,
                    filter: TransactionFilter.all,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Mine',
                    count: allList.where((t) => !t.isOthersSpend && !t.isEmi).length,
                    filter: TransactionFilter.mine,
                    color: const Color(0xFF34D399),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Others',
                    count: allList.where((t) => t.isOthersSpend && !t.isEmi).length,
                    filter: TransactionFilter.others,
                    color: const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Self EMI',
                    count: allList.where((t) {
                      if (!t.isEmi || t.emiId == null) return false;
                      final emi = widget.emis.firstWhere((e) => e.id == t.emiId, orElse: () => widget.emis.first);
                      return emi.type == EmiType.self;
                    }).length,
                    filter: TransactionFilter.selfEmi,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Others EMI',
                    count: allList.where((t) {
                      if (!t.isEmi || t.emiId == null) return false;
                      final emi = widget.emis.firstWhere((e) => e.id == t.emiId, orElse: () => widget.emis.first);
                      return emi.type == EmiType.others;
                    }).length,
                    filter: TransactionFilter.othersEmi,
                    color: const Color(0xFFA855F7), // Purple
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Date-Grouped Transactions List
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: Color(0xFF34D399), size: 36),
                    SizedBox(height: 8),
                    Text('No Spends or EMIs Found', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Scan SMS inbox or change filters to inspect spends.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  ],
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Group Header Row
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              groupHeader,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${groupItems.length} Spends • ${Formatters.formatCurrency(groupTotal)}',
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      // Group Items List
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

                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),

            const SizedBox(height: 30),
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

    // Determine icon based on category/title
    IconData iconData = Icons.shopping_bag_outlined;
    if (tx.title.toLowerCase().contains('swiggy') || tx.category.toLowerCase().contains('dining')) {
      iconData = Icons.fastfood_outlined;
    } else if (tx.title.toLowerCase().contains('petrol') || tx.title.toLowerCase().contains('shell') || tx.category.toLowerCase().contains('fuel')) {
      iconData = Icons.local_gas_station_outlined;
    } else if (tx.title.toLowerCase().contains('apple') || tx.title.toLowerCase().contains('macbook') || tx.title.toLowerCase().contains('laptop')) {
      iconData = Icons.laptop_mac;
    } else if (isEmi) {
      iconData = Icons.inventory_2_outlined;
    }

    final accentColor = isEmi ? const Color(0xFFA855F7) : (tx.isOthersSpend ? const Color(0xFFFBBF24) : const Color(0xFF34D399));

    return GestureDetector(
      onTap: () {
        if (!isEmi) {
          _openAttributionSheet(tx);
        } else if (emi != null && scheduleItem != null) {
          // Toggle Paid / Due status for EMI
          final newPaidStatus = !scheduleItem.isPaid;
          setState(() {
            scheduleItem!.isPaid = newPaidStatus;
          });
          widget.onUpdateEmi?.call(emi);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newPaidStatus
                    ? 'Marked ${scheduleItem.monthLabel} installment as Paid for "${emi.title}"'
                    : 'Marked ${scheduleItem.monthLabel} installment as Due for "${emi.title}"',
              ),
              backgroundColor: newPaidStatus ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161F30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEmi
                ? const Color(0xFFA855F7).withValues(alpha: 0.3)
                : (tx.isOthersSpend ? const Color(0xFFFBBF24).withValues(alpha: 0.3) : const Color(0xFF222F46)),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isEmi
                          ? const Color(0xFFA855F7).withValues(alpha: 0.15)
                          : (tx.isOthersSpend ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : const Color(0xFF111827)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: accentColor, size: 20),
                  ),

                  const SizedBox(width: 10),

                  // Details Column
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isEmi && emi != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 10, color: Color(0xFFC084FC)),
                                    const SizedBox(width: 3),
                                    Text(
                                      'EMI $instNum/${emi.schedule.length}',
                                      style: const TextStyle(color: Color(0xFFC084FC), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Card details & Category / Others tag line
                        Row(
                          children: [
                            Text(
                              '${card.bank} •••• ${card.last4}',
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                            ),
                            const Text(' • ', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                            if (tx.isOthersSpend)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '👤 ${tx.personName ?? "Others"}${tx.purpose != null && tx.purpose!.isNotEmpty ? " (${tx.purpose})" : ""}',
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Text(
                                tx.category,
                                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Amount & Sub-status Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(tx.amount),
                        style: TextStyle(
                          color: isEmi ? const Color(0xFFC084FC) : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isEmi && scheduleItem != null)
                        GestureDetector(
                          onTap: () {
                            if (emi != null && scheduleItem != null) {
                              final newPaidStatus = !scheduleItem.isPaid;
                              setState(() {
                                scheduleItem!.isPaid = newPaidStatus;
                              });
                              widget.onUpdateEmi?.call(emi);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    newPaidStatus
                                        ? 'Marked ${scheduleItem.monthLabel} installment as Paid for "${emi.title}"'
                                        : 'Marked ${scheduleItem.monthLabel} installment as Due for "${emi.title}"',
                                  ),
                                  backgroundColor: newPaidStatus ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheduleItem.isPaid
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  scheduleItem.isPaid ? Icons.check_circle_outline : Icons.access_time,
                                  size: 10,
                                  color: scheduleItem.isPaid ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  scheduleItem.isPaid ? 'Paid' : 'Due',
                                  style: TextStyle(
                                    color: scheduleItem.isPaid ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (isEmi)
                        const Text('Per month', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10))
                      else if (tx.rawSms != null || tx.title.toLowerCase().contains('zara'))
                        GestureDetector(
                          onTap: onToggleExpand,
                          child: Row(
                            children: [
                              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 14, color: const Color(0xFF34D399)),
                              const SizedBox(width: 2),
                              const Text('💬 Parsed', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else if (tx.isOthersSpend)
                        const Text('Reimbursement', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold))
                      else
                        const Row(
                          children: [
                            Icon(Icons.check, size: 10, color: Color(0xFF34D399)),
                            SizedBox(width: 2),
                            Text('Settled', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Expandable Telemetry Box (for SMS parsed transactions)
            if (isExpanded || (tx.rawSms != null && isExpanded)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: Color(0xFF34D399), size: 12),
                            SizedBox(width: 6),
                            Text(
                              'Raw SMS Parser Telemetry',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          'Sender: VM-${card.bank.toUpperCase()}BK',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Original Raw SMS Text Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0F19),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1F293D)),
                      ),
                      child: Text(
                        tx.rawSms ??
                            'Alert: Your A/C •••• ${card.last4} spent INR ${tx.amount.toInt()}.00 at ${tx.title.toUpperCase()} on ${Formatters.formatDateShort(tx.date)} 19:42:11. Avl bal: INR 48,210.30. Not you? SMS BLOCK to 5676712.',
                        style: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_outline, color: Color(0xFF34D399), size: 12),
                            SizedBox(width: 4),
                            Text(
                              '100% On-device parsed (Zero Cloud)',
                              style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: widget.onRefresh,
                          child: const Text(
                            'Re-parse',
                            style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF161F30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF222F46),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFF222F46),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
