import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import '../utils/formatters.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/notifications_sheet.dart';
import 'card_details_screen.dart';

import '../services/storage_service.dart';

class CardsScreen extends StatefulWidget {
  final StorageService? storageService;
  final List<CreditCard> cards;
  final List<TransactionItem> transactions;
  final List<EmiItem> emis;
  final Function(CreditCard) onAddCard;
  final Function(String) onDeleteCard;
  final Function(TransactionItem) onAddTransaction;
  final Function(EmiItem) onAddEmi;
  final Function(String) onDeleteTransaction;
  final VoidCallback onScanSms;

  const CardsScreen({
    super.key,
    this.storageService,
    required this.cards,
    required this.transactions,
    required this.emis,
    required this.onAddCard,
    required this.onDeleteCard,
    required this.onAddTransaction,
    required this.onAddEmi,
    required this.onDeleteTransaction,
    required this.onScanSms,
  });

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  void _openEditLimitDialog(CreditCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCardSheet(
        initialCard: card,
        onSave: widget.onAddCard,
      ),
    );
  }

  void _openAddCardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCardSheet(
        onSave: widget.onAddCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedCards = CycleCalculator.sortCardsByReset(widget.cards);

    // Calculate Combined Limit and Active Spent across all cards
    double combinedLimit = 0.0;
    double activeSpent = 0.0;

    for (final card in widget.cards) {
      final cycle = CycleCalculator.getBillingCycle(card);
      final spend = CycleCalculator.getTotalCycleSpend(
        card,
        widget.transactions,
        widget.emis,
        cycle: cycle,
      );
      combinedLimit += card.monthlyLimit;
      activeSpent += spend;
    }

    final combinedPercent = combinedLimit > 0
        ? ((activeSpent / combinedLimit) * 100).toStringAsFixed(1)
        : '0.0';

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
            // 1. Local Vault - 0 Cloud Sync Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF222F46)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pie_chart_outline, color: Color(0xFF34D399), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Combined Limit Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF222F46), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Combined Limit',
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(combinedLimit),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Spent',
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: Formatters.formatCurrency(activeSpent),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ($combinedPercent%)',
                                    style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. My Cards Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'My Cards',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.cards.length} Active',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 3. Individual Credit Cards List
            if (sortedCards.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.credit_card, color: Color(0xFF34D399), size: 36),
                    SizedBox(height: 8),
                    Text(
                      'No Cards Registered',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap "Add Card" button below to add your credit cards.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCards.length,
                itemBuilder: (context, index) {
                  final card = sortedCards[index];
                  final cycle = CycleCalculator.getBillingCycle(card);
                  final spend = CycleCalculator.getTotalCycleSpend(
                    card,
                    widget.transactions,
                    widget.emis,
                    cycle: cycle,
                  );
                  final available = (card.monthlyLimit - spend).clamp(0.0, double.infinity);
                  final percentUsed = card.monthlyLimit > 0
                      ? ((spend / card.monthlyLimit) * 100).toStringAsFixed(1)
                      : '0.0';
                  final percentVal = double.tryParse(percentUsed) ?? 0.0;

                  // Usage status badge
                  String usagePill = '$percentUsed% Used';
                  Color usageColor = const Color(0xFFFBBF24);
                  if (percentVal < 30) {
                    usagePill = '$percentUsed% Healthy';
                    usageColor = const Color(0xFF34D399);
                  } else if (percentVal > 80) {
                    usagePill = '$percentUsed% High';
                    usageColor = Colors.redAccent;
                  }

                  // Card Gradient background
                  final gradientColors = Formatters.getCardGradient(card.colorIndex);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Chip + Wave Icon ... Bank Name & Variant
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFDE047), Color(0xFFCA8A04)],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.wifi, color: Colors.white54, size: 18),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  card.bank.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  card.cardName.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Masked Number & Usage Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '••••  ${card.last4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: usageColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: usageColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                usagePill,
                                style: TextStyle(
                                  color: usageColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Cycle Period & Network Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CYCLE PERIOD',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${card.billGenerationDay}th to ${(card.billGenerationDay - 1) <= 0 ? 30 : card.billGenerationDay - 1}th',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Current Spend vs Limit Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Current Spend: ',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  TextSpan(
                                    text: Formatters.formatCurrency(spend),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Limit: ${Formatters.formatCurrency(card.monthlyLimit)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: card.monthlyLimit > 0
                                ? (spend / card.monthlyLimit).clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 7,
                            backgroundColor: Colors.black26,
                            valueColor: AlwaysStoppedAnimation<Color>(usageColor),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${Formatters.formatCurrency(available)} available',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            Text(
                              percentVal > 60 ? 'Elevated balance alert' : 'Optimal buffer',
                              style: TextStyle(
                                color: percentVal > 60 ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // 3 Quick Action Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  onPressed: () => _openEditLimitDialog(card),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.black26,
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.tune, size: 14),
                                  label: const Text('Edit Limit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  onPressed: widget.onScanSms,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    foregroundColor: const Color(0xFF34D399),
                                    side: const BorderSide(color: Color(0xFF10B981)),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                                  label: const Text('Auto SMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => CardDetailsScreen(
                                          card: card,
                                          transactions: widget.transactions,
                                          emis: widget.emis,
                                          onUpdateCard: widget.onAddCard,
                                          onDeleteCard: widget.onDeleteCard,
                                          onDeleteTransaction: widget.onDeleteTransaction,
                                        ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.black26,
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.table_chart_outlined, size: 14),
                                  label: const Text('View EMIs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 80), // Bottom padding for FAB
          ],
        ),
      ),

      // Floating Action Button at the bottom (matching Add EMI FAB style)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCardSheet,
        backgroundColor: const Color(0xFF34D399), // Mint Green
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Card',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
