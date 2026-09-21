import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../widgets/notifications_sheet.dart';
import 'add_emi_screen.dart';

enum EmiFilter { all, self, others }

class EmiListScreen extends StatefulWidget {
  final StorageService? storageService;
  final List<CreditCard> cards;
  final List<TransactionItem> transactions;
  final List<EmiItem> emis;
  final Function(EmiItem) onAddEmi;
  final Function(String) onDeleteEmi;

  const EmiListScreen({
    super.key,
    this.storageService,
    required this.cards,
    required this.transactions,
    required this.emis,
    required this.onAddEmi,
    required this.onDeleteEmi,
  });

  @override
  State<EmiListScreen> createState() => _EmiListScreenState();
}

class _EmiListScreenState extends State<EmiListScreen> {
  EmiFilter _filter = EmiFilter.all;
  int _selectedEmiIndex = 0;

  void _editEmi(EmiItem emi) {
    CreditCard? card;
    try {
      card = widget.cards.firstWhere((c) => c.id == emi.cardId);
    } catch (_) {
      if (widget.cards.isNotEmpty) card = widget.cards.first;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEmiScreen(
          cards: widget.cards,
          initialCard: card,
          initialEmi: emi,
          onSave: widget.onAddEmi,
        ),
      ),
    );
  }

  void _confirmDeleteEmi(EmiItem emi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF161F30),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Delete EMI Schedule?',
              style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to delete "${emi.title}"? This will permanently remove the repayment schedule from local storage.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF222F46)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete EMI', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _selectedEmiIndex = 0;
                      });
                      widget.onDeleteEmi(emi.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${emi.title}" EMI schedule.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCurrentInstallmentStatus(EmiItem emi) {
    final now = DateTime.now();
    EmiScheduleItem? targetItem;

    for (final item in emi.schedule) {
      if (item.year == now.year && item.month == now.month) {
        targetItem = item;
        break;
      }
    }
    targetItem ??= emi.schedule.firstWhere((i) => !i.isPaid, orElse: () => emi.schedule.first);

    final newStatus = !targetItem.isPaid;
    targetItem.isPaid = newStatus;

    widget.onAddEmi(emi); // Save updated EMI to StorageService!
    setState(() {});

    final actionText = newStatus ? 'Paid' : 'Due';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked ${targetItem.monthLabel} installment as $actionText for "${emi.title}"'),
        backgroundColor: newStatus ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final notifications = NotificationsHelper.generateNotifications(
      cards: widget.cards,
      transactions: widget.transactions,
      emis: widget.emis,
    );

    // Filter EMIs
    final filteredEmis = widget.emis.where((emi) {
      if (_filter == EmiFilter.self) return emi.type == EmiType.self;
      if (_filter == EmiFilter.others) return emi.type == EmiType.others;
      return true;
    }).toList();

    // Calculate Totals for Current Month
    double totalMonthly = 0.0;
    double selfMonthly = 0.0;
    double othersMonthly = 0.0;
    String? mainBeneficiary;

    for (final emi in widget.emis) {
      final monthlyAmt = emi.getAmountForDate(now);
      totalMonthly += monthlyAmt;
      if (emi.type == EmiType.self) {
        selfMonthly += monthlyAmt;
      } else {
        othersMonthly += monthlyAmt;
        if (mainBeneficiary == null && emi.beneficiaryName != null) {
          mainBeneficiary = emi.beneficiaryName;
        }
      }
    }

    // Currently inspected EMI for schedule table below
    final selectedEmi = (filteredEmis.isNotEmpty && _selectedEmiIndex < filteredEmis.length)
        ? filteredEmis[_selectedEmiIndex]
        : null;

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
            // 1. Filter Pills Row (All EMIs | Self | Others)
            Row(
              children: [
                _buildFilterChip(
                  label: 'All EMIs',
                  count: widget.emis.length,
                  filter: EmiFilter.all,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Self',
                  count: widget.emis.where((e) => e.type == EmiType.self).length,
                  filter: EmiFilter.self,
                  color: const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Others',
                  count: widget.emis.where((e) => e.type == EmiType.others).length,
                  filter: EmiFilter.others,
                  color: const Color(0xFFFBBF24),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2. TOTAL MONTHLY OBLIGATION Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF222F46)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL MONTHLY OBLIGATION',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 6),

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: Formatters.formatCurrency(totalMonthly),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(
                          text: ' /month',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Self Share
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.circle, color: Color(0xFF34D399), size: 8),
                          SizedBox(width: 6),
                          Text('Self Share', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        '${Formatters.formatCurrency(selfMonthly)} /mo',
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Others Share
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.circle, color: Color(0xFFFBBF24), size: 8),
                          SizedBox(width: 6),
                          Text(
                            'Others',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '${Formatters.formatCurrency(othersMonthly)} /mo',
                        style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Active Liabilities Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Liabilities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Swipe or inspect below',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Active Liabilities Horizontal Cards
            if (filteredEmis.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.calendar_month_outlined, color: Color(0xFF34D399), size: 36),
                    SizedBox(height: 8),
                    Text('No Active EMIs Found', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Tap + button on Dashboard to create an EMI schedule.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  ],
                ),
              )
            else
              SizedBox(
                height: 165,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredEmis.length,
                  itemBuilder: (context, index) {
                    final emi = filteredEmis[index];
                    final isSelected = index == _selectedEmiIndex;
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

                    // Find active installment index
                    int currentInst = 1;
                    for (int i = 0; i < emi.schedule.length; i++) {
                      if (emi.schedule[i].year == now.year && emi.schedule[i].month == now.month) {
                        currentInst = i + 1;
                        break;
                      }
                    }

                    final isSelf = emi.type == EmiType.self;
                    final accentColor = isSelf ? const Color(0xFF34D399) : const Color(0xFFFBBF24);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmiIndex = index),
                      child: Container(
                        width: 290,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F30),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? accentColor : const Color(0xFF222F46),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111827),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    emi.title.toLowerCase().contains('phone') || emi.title.toLowerCase().contains('iphone')
                                        ? Icons.phone_iphone
                                        : Icons.laptop_mac,
                                    color: accentColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emi.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${card.bank} •••• ${card.last4}',
                                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                // Edit & Delete Action Buttons
                                InkWell(
                                  onTap: () => _editEmi(emi),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF34D399)),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _confirmDeleteEmi(emi),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.formatCurrency(emi.totalAmount),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tenure', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${emi.schedule.length} mos',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Current', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$currentInst of ${emi.schedule.length}',
                                      style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: emi.schedule.isNotEmpty ? (currentInst / emi.schedule.length) : 0.0,
                                minHeight: 5,
                                backgroundColor: const Color(0xFF0F172A),
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // 4. Installment Schedule Inspector Table
            if (selectedEmi != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF222F46)),
                ),
                child: Column(
                  children: [
                    // Table Header Bar
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card_outlined, color: Color(0xFF34D399), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${selectedEmi.title} Schedule',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF34D399)),
                                tooltip: 'Edit EMI Schedule',
                                onPressed: () => _editEmi(selectedEmi),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                tooltip: 'Delete EMI Schedule',
                                onPressed: () => _confirmDeleteEmi(selectedEmi),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Table Columns Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      color: const Color(0xFF111827),
                      child: const Row(
                        children: [
                          SizedBox(width: 20, child: Text('#', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 80, child: Text('MONTH', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(child: Text('EMI (₹)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 100, child: Text('STATUS', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),

                    // Schedule Rows
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedEmi.schedule.length,
                      itemBuilder: (context, index) {
                        final item = selectedEmi.schedule[index];
                        final isCurrentMonth = item.year == now.year && item.month == now.month;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCurrentMonth
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                : null,
                            border: Border(
                              bottom: BorderSide(
                                color: isCurrentMonth
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFF222F46),
                                width: isCurrentMonth ? 1.5 : 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                child: Text(
                                  '${item.installmentNumber}',
                                  style: TextStyle(
                                    color: isCurrentMonth ? const Color(0xFFFBBF24) : const Color(0xFF9CA3AF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  item.monthLabel,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: isCurrentMonth ? FontWeight.w800 : FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  Formatters.formatCurrency(item.amount),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isCurrentMonth ? const Color(0xFFFBBF24) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: item.isPaid ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 105,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        final newPaid = !item.isPaid;
                                        setState(() {
                                          item.isPaid = newPaid;
                                        });
                                        widget.onAddEmi(selectedEmi);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              newPaid
                                                  ? 'Marked ${item.monthLabel} installment as Paid'
                                                  : 'Marked ${item.monthLabel} installment as Due',
                                            ),
                                            backgroundColor: newPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.isPaid
                                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: item.isPaid
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFFFBBF24),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              item.isPaid ? Icons.check_circle : Icons.hourglass_bottom,
                                              color: item.isPaid ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                              size: 11,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              item.isPaid ? 'Paid' : (isCurrentMonth ? 'Due' : 'Due'),
                                              style: TextStyle(
                                                color: item.isPaid ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.swap_vert,
                                              color: item.isPaid ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                              size: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (selectedEmi.type == EmiType.others && !item.isPaid)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '${selectedEmi.beneficiaryName ?? "Others"} to pay',
                                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Mark Collected / Due Action Button
              Builder(
                builder: (context) {
                  EmiScheduleItem? currentItem;
                  for (final item in selectedEmi.schedule) {
                    if (item.year == now.year && item.month == now.month) {
                      currentItem = item;
                      break;
                    }
                  }
                  currentItem ??= selectedEmi.schedule.firstWhere((i) => !i.isPaid, orElse: () => selectedEmi.schedule.first);

                  final isPaid = currentItem.isPaid;
                  final isOthers = selectedEmi.type == EmiType.others;
                  final person = selectedEmi.beneficiaryName ?? 'Others';

                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => _toggleCurrentInstallmentStatus(selectedEmi),
                      style: FilledButton.styleFrom(
                        backgroundColor: isPaid ? const Color(0xFFF59E0B) : const Color(0xFF34D399),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(isPaid ? Icons.remove_circle_outline : Icons.payments_outlined, size: 18),
                      label: Text(
                        isPaid
                            ? (isOthers ? 'Mark Status as Due from $person' : 'Change Status to Due')
                            : (isOthers ? 'Mark Collected from $person' : 'Change Status to Paid'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => AddEmiScreen(
                cards: widget.cards,
                onSave: widget.onAddEmi,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF34D399),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add EMI', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required EmiFilter filter,
    required Color color,
  }) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = filter;
          _selectedEmiIndex = 0;
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
