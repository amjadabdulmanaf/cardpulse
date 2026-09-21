import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../widgets/notifications_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final StorageService? storageService;
  final List<CreditCard> cards;
  final List<TransactionItem> transactions;
  final List<EmiItem> emis;
  final VoidCallback onAddCard;
  final Function(CreditCard?) onAddEmi;
  final Function(CreditCard?) onAddSpend;
  final VoidCallback onScanSms;

  const DashboardScreen({
    super.key,
    this.storageService,
    required this.cards,
    required this.transactions,
    required this.emis,
    required this.onAddCard,
    required this.onAddEmi,
    required this.onAddSpend,
    required this.onScanSms,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeCardIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Sort cards by closest reset date
    final sortedCards = CycleCalculator.sortCardsByReset(widget.cards);
    final safeIndex = (sortedCards.isNotEmpty && _activeCardIndex < sortedCards.length)
        ? _activeCardIndex
        : 0;

    // Consolidated Active Cycles Stats
    double activeCyclesTotalSpend = 0.0;
    double activeCyclesTotalLimit = 0.0;
    int minDaysRemaining = 999;

    for (final card in sortedCards) {
      final cycle = CycleCalculator.getBillingCycle(card);
      final spend = CycleCalculator.getTotalCycleSpend(
        card,
        widget.transactions,
        widget.emis,
        cycle: cycle,
      );
      activeCyclesTotalSpend += spend;
      activeCyclesTotalLimit += card.monthlyLimit;
      if (cycle.daysRemaining < minDaysRemaining) {
        minDaysRemaining = cycle.daysRemaining;
      }
    }

    final bufferLeft = (activeCyclesTotalLimit - activeCyclesTotalSpend)
        .clamp(0.0, double.infinity);
    final overallHealthPercent = activeCyclesTotalLimit > 0
        ? ((activeCyclesTotalSpend / activeCyclesTotalLimit) * 100).toInt()
        : 0;

    // Monthly EMI calculations
    final now = DateTime.now();
    double totalEmiCommitment = 0.0;
    int selfEmiCount = 0;
    double selfEmiTotal = 0.0;
    int otherEmiCount = 0;
    double otherEmiTotal = 0.0;

    for (final emi in widget.emis) {
      final monthlyAmt = emi.getAmountForDate(now);
      if (monthlyAmt > 0) {
        totalEmiCommitment += monthlyAmt;
        if (emi.type == EmiType.self) {
          selfEmiCount++;
          selfEmiTotal += monthlyAmt;
        } else {
          otherEmiCount++;
          otherEmiTotal += monthlyAmt;
        }
      }
    }

    final notifications = NotificationsHelper.generateNotifications(
      cards: widget.cards,
      transactions: widget.transactions,
      emis: widget.emis,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // Dark Charcoal Background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981), width: 1),
                    ),
                    child: const Icon(
                      Icons.credit_card_outlined,
                      color: Color(0xFF34D399),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CardPulse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
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
                ],
              ),

              const SizedBox(height: 16),

              // 3. Consolidated "ACTIVE CYCLES TOTAL SPEND" Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ACTIVE CYCLES TOTAL SPEND',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF34D399)),
                              SizedBox(width: 4),
                              Text(
                                'Healthy Buffer',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: Formatters.formatCurrency(activeCyclesTotalSpend),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${Formatters.formatCurrency(activeCyclesTotalLimit)}',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: activeCyclesTotalLimit > 0
                            ? (activeCyclesTotalSpend / activeCyclesTotalLimit).clamp(0.0, 1.0)
                            : 0.0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF0F172A),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overallHealthPercent > 80 ? Colors.orangeAccent : const Color(0xFF34D399),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Buffer Left',
                                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.formatCurrency(bufferLeft),
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
                                'Overall Utilization',
                                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$overallHealthPercent%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Next Reset In',
                                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                minDaysRemaining == 999 ? 'N/A' : '${minDaysRemaining}d',
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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

              const SizedBox(height: 16),

              // 4. EMIs Due This Month Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month, color: Color(0xFFF59E0B), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'EMIs Due This Month',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.emis.length} Active',
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        // Left Column: Total Commitment
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Commitment',
                                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.formatCurrency(totalEmiCommitment),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right Column: Allocation Split
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Allocation Split',
                                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$selfEmiCount Self: ${Formatters.formatCurrency(selfEmiTotal)}',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$otherEmiCount Other: ${Formatters.formatCurrency(otherEmiTotal)}',
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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

              // 5. Cards by Billing Cycle Carousel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cards by Billing Cycle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (sortedCards.isNotEmpty)
                    Text(
                      'Swipe ${safeIndex + 1} of ${sortedCards.length}',
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              if (sortedCards.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F30),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.credit_card, color: Color(0xFF34D399), size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'No Credit Cards Added',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onAddCard,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Credit Card'),
                      ),
                    ],
                  ),
                )
              else ...[
                Builder(
                  builder: (context) {
                    final card = sortedCards[safeIndex];
                    final cycle = CycleCalculator.getBillingCycle(card);
                    final totalSpend = CycleCalculator.getTotalCycleSpend(
                      card,
                      widget.transactions,
                      widget.emis,
                      cycle: cycle,
                    );
                    final available = (card.monthlyLimit - totalSpend).clamp(0.0, double.infinity);
                    final percentUsed = card.monthlyLimit > 0
                        ? ((totalSpend / card.monthlyLimit) * 100).toInt()
                        : 0;

                    final daysLeft = cycle.daysRemaining > 0 ? cycle.daysRemaining : 1;
                    final safeDaily = (available / daysLeft).roundToDouble();

                    return GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null && sortedCards.length > 1) {
                          if (details.primaryVelocity! < 0) {
                            setState(() {
                              _activeCardIndex = (_activeCardIndex + 1) % sortedCards.length;
                            });
                          } else if (details.primaryVelocity! > 0) {
                            setState(() {
                              _activeCardIndex =
                                  (_activeCardIndex - 1 + sortedCards.length) % sortedCards.length;
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F30),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF222F46)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFBBF24),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.credit_card, size: 14, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${card.bank} ${card.cardName}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '📅 Cycle: ${Formatters.formatDateShort(cycle.startDate)} - ${Formatters.formatDateShort(cycle.endDate)}',
                                        style: const TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Resets in ${cycle.daysRemaining}d',
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Cycle Spend vs Limit
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Cycle Spend vs Limit',
                                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: Formatters.formatCurrency(totalSpend),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / ${Formatters.formatCurrency(card.monthlyLimit)}',
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

                            const SizedBox(height: 6),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: card.monthlyLimit > 0
                                    ? (totalSpend / card.monthlyLimit).clamp(0.0, 1.0)
                                    : 0.0,
                                minHeight: 6,
                                backgroundColor: const Color(0xFF0F172A),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$percentUsed% Used',
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${Formatters.formatCurrency(available)} Available',
                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Metrics boxes
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111827),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Safe Daily Spend',
                                          style:
                                              TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${Formatters.formatCurrency(safeDaily)}/day',
                                          style: const TextStyle(
                                            color: Color(0xFF34D399),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111827),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Next Bill Due',
                                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          Formatters.formatDateShort(cycle.nextResetDate),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 20),

              // 6. Quick Action Grid Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onAddSpend(sortedCards.isNotEmpty ? sortedCards[safeIndex] : null),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF161F30),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF222F46)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: Color(0xFF34D399)),
                        label: const Text('Log Spend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => widget.onAddEmi(sortedCards.isNotEmpty ? sortedCards[safeIndex] : null),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF34D399),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add EMI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 7. Active Cycle Spends Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.store, color: Color(0xFF34D399), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Active Cycle Spends',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Current Cycle Only',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Recent Active Cycle Spends List
              Builder(
                builder: (context) {
                  final combinedActiveSpends = <TransactionItem>[...widget.transactions];

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
                        combinedActiveSpends.add(TransactionItem(
                          id: 'emi_${emi.id}_${item.installmentNumber}',
                          cardId: emi.cardId,
                          title: emi.type == EmiType.others
                              ? '${emi.title} (${emi.beneficiaryName ?? "Others"})'
                              : '${emi.title} (EMI ${item.installmentNumber}/${emi.schedule.length})',
                          amount: item.amount,
                          date: instDate,
                          category: 'EMI',
                          isEmi: true,
                          emiId: emi.id,
                          isOthersSpend: emi.type == EmiType.others,
                          personName: emi.beneficiaryName,
                        ));
                        break;
                      }
                    }
                  }

                  combinedActiveSpends.sort((a, b) => b.date.compareTo(a.date));

                  if (combinedActiveSpends.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F30),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No Active Cycle Spends Recorded Yet',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: combinedActiveSpends.length > 5 ? 5 : combinedActiveSpends.length,
                    itemBuilder: (context, index) {
                      final tx = combinedActiveSpends[index];
                      final card = widget.cards.firstWhere(
                        (c) => c.id == tx.cardId,
                        orElse: () => CreditCard(
                          id: '',
                          cardName: 'Card',
                          bank: 'Bank',
                          last4: '0000',
                          monthlyLimit: 0,
                          billGenerationDay: 15,
                        ),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: tx.isEmi
                                ? const Color(0xFFA855F7).withValues(alpha: 0.4)
                                : const Color(0xFF222F46),
                          ),
                        ),
                        child: Row(
                          children: [
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: tx.isEmi
                                              ? const Color(0xFFA855F7).withValues(alpha: 0.2)
                                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tx.isEmi ? 'EMI Due' : '${card.bank} Cycle',
                                          style: TextStyle(
                                            color: tx.isEmi ? const Color(0xFFC084FC) : const Color(0xFFFBBF24),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${card.bank} •••• ${card.last4} • ${Formatters.formatDateShort(tx.date)}',
                                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              Formatters.formatCurrency(tx.amount),
                              style: TextStyle(
                                color: tx.isEmi ? const Color(0xFFC084FC) : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}
}
