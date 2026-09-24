import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../widgets/animated_counter_text.dart';
import '../widgets/animated_percent_text.dart';
import '../widgets/animated_progress_bar.dart';
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
  late PageController _cardPageController;

  @override
  void initState() {
    super.initState();
    _cardPageController = PageController();
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        ? ((activeCyclesTotalSpend / activeCyclesTotalLimit) * 100)
        : 0.0;

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
      backgroundColor: const Color(0xFF080B0F), // Obsidian Black
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar Header
              Row(
                children: [
                  // Pulse Wave Logo Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121620),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x4D10B981)),
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(18, 12),
                        painter: _PulseLogoPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'CardPulse',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
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
                              color: Color(0xFF00FFA3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. ACTIVE CYCLES TOTAL SPEND Card (Dynamic Animated Progress & Counters)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF121620),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E2536)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACTIVE CYCLES TOTAL SPEND',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x1F00FFA3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x4000FFA3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outlined, size: 12, color: Color(0xFF00FFA3)),
                              const SizedBox(width: 4),
                              Text(
                                'HEALTHY BUFFER',
                                style: GoogleFonts.spaceGrotesk(
                                  color: const Color(0xFF00FFA3),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Main Value & Utilization Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            AnimatedCounterText(
                              value: activeCyclesTotalSpend,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              ' / ${Formatters.formatCurrency(activeCyclesTotalLimit)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedPercentText(
                              value: overallHealthPercent,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'UTILIZATION',
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF94A3B8),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Dynamic Animated Neon Gradient Progress Bar
                    AnimatedProgressBar(
                      value: activeCyclesTotalLimit > 0 ? (activeCyclesTotalSpend / activeCyclesTotalLimit) : 0.0,
                      height: 8,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00FFA3), Color(0xFF10B981)],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Footer Stats Columns
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Buffer Left', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 11)),
                              const SizedBox(height: 2),
                              AnimatedCounterText(
                                value: bufferLeft,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF00FFA3),
                                  fontSize: 15,
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
                              Text('Overall Utilization', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 11)),
                              const SizedBox(height: 2),
                              AnimatedPercentText(
                                value: overallHealthPercent,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
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
                              Text('Next Reset In', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 11)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    minDaysRemaining == 999 ? 'N/A' : '${minDaysRemaining}d',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF00FFA3),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00FFA3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
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

              // 3. EMIS DUE THIS MONTH Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF121620),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E2536)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0x2610B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF00FFA3), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'EMIS DUE THIS MONTH',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2536),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.emis.length} ACTIVE',
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Commitment', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 11)),
                              const SizedBox(height: 4),
                              AnimatedCounterText(
                                value: totalEmiCommitment,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
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
                              Text('ALLOCATION SPLIT', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$selfEmiCount Self:', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12)),
                                  AnimatedCounterText(value: selfEmiTotal, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$otherEmiCount Other:', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF00FFA3), fontSize: 12, fontWeight: FontWeight.w600)),
                                  AnimatedCounterText(value: otherEmiTotal, style: GoogleFonts.outfit(color: const Color(0xFF00FFA3), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
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

              // 4. Cards by Billing Cycle Header with Nav Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cards by Billing Cycle',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Swipe ${safeIndex + 1} of ${sortedCards.isEmpty ? 1 : sortedCards.length}',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      // Left arrow
                      InkWell(
                        onTap: () {
                          if (sortedCards.isNotEmpty) {
                            final target = (_activeCardIndex - 1 + sortedCards.length) % sortedCards.length;
                            _cardPageController.animateToPage(
                              target,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121620),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1E2536)),
                          ),
                          child: const Icon(Icons.chevron_left, size: 16, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Right arrow
                      InkWell(
                        onTap: () {
                          if (sortedCards.isNotEmpty) {
                            final target = (_activeCardIndex + 1) % sortedCards.length;
                            _cardPageController.animateToPage(
                              target,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121620),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1E2536)),
                          ),
                          child: const Icon(Icons.chevron_right, size: 16, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Interactive Swipeable PageView Cards Carousel
              if (sortedCards.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121620),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF1E2536)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.credit_card, color: Color(0xFF00FFA3), size: 36),
                      const SizedBox(height: 8),
                      Text('No Credit Cards Added', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onAddCard,
                        icon: const Icon(Icons.add, color: Color(0xFF00FFA3)),
                        label: const Text('Add Credit Card', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 235,
                  child: PageView.builder(
                    controller: _cardPageController,
                    itemCount: sortedCards.length,
                    onPageChanged: (index) {
                      setState(() {
                        _activeCardIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final card = sortedCards[index];
                      final cycle = CycleCalculator.getBillingCycle(card);
                      final totalSpend = CycleCalculator.getTotalCycleSpend(
                        card,
                        widget.transactions,
                        widget.emis,
                        cycle: cycle,
                      );
                      final available = (card.monthlyLimit - totalSpend).clamp(0.0, double.infinity);
                      final percentUsed = card.monthlyLimit > 0
                          ? ((totalSpend / card.monthlyLimit) * 100)
                          : 0.0;

                      final daysLeft = cycle.daysRemaining > 0 ? cycle.daysRemaining : 1;
                      final safeDaily = (available / daysLeft).roundToDouble();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121620),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF1E2536)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFBBF24),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.graphic_eq, size: 18, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${card.bank} ${card.cardName}',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '📅 Cycle: ${Formatters.formatDateShort(cycle.startDate)} - ${Formatters.formatDateShort(cycle.endDate)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF00FFA3),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1F00FFA3),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0x4000FFA3)),
                                  ),
                                  child: Text(
                                    'Resets in ${cycle.daysRemaining}d',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFF00FFA3),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Spend vs Limit Label Row with Animated Counter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Cycle Spend vs Limit', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12)),
                                Row(
                                  children: [
                                    AnimatedCounterText(
                                      value: totalSpend,
                                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(' / ${Formatters.formatCurrency(card.monthlyLimit)}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Dynamic Animated Progress Bar (increases / decreases smoothly on page swipe)
                            AnimatedProgressBar(
                              value: card.monthlyLimit > 0 ? (totalSpend / card.monthlyLimit) : 0.0,
                              height: 6,
                              color: const Color(0xFF00FFA3),
                            ),

                            const SizedBox(height: 6),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AnimatedPercentText(
                                  value: percentUsed,
                                  suffix: '% Used',
                                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontSize: 11),
                                ),
                                Row(
                                  children: [
                                    AnimatedCounterText(
                                      value: available,
                                      style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00FFA3), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    Text(' Available', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00FFA3), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 2 Metrics Boxes
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF080B0F),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF1E2536)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Safe Daily Spend', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 10)),
                                        const SizedBox(height: 2),
                                        AnimatedCounterText(
                                          value: safeDaily,
                                          prefix: '₹',
                                          style: GoogleFonts.outfit(color: const Color(0xFF00FFA3), fontSize: 13, fontWeight: FontWeight.bold),
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
                                      color: const Color(0xFF080B0F),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF1E2536)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Next Bill Due', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 10)),
                                        const SizedBox(height: 2),
                                        Text(
                                          Formatters.formatDateShort(cycle.nextResetDate),
                                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ],
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
                ),

              const SizedBox(height: 20),

              // 5. Active Cycle Spends Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0x2610B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF00FFA3), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active Cycle Spends',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1F00FFA3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x4D00FFA3)),
                    ),
                    child: Text(
                      'Current Cycle Only',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF00FFA3),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Active Cycle Spends List
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
                        color: const Color(0xFF121620),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E2536)),
                      ),
                      child: Center(
                        child: Text(
                          'No Active Cycle Spends Recorded Yet',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12),
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
                          color: const Color(0xFF121620),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1E2536)),
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
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: tx.isEmi
                                              ? const Color(0xFF1E2536)
                                              : const Color(0x26FEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: tx.isEmi
                                                ? const Color(0xFF334155)
                                                : const Color(0x66FBBF24),
                                          ),
                                        ),
                                        child: Text(
                                          tx.isEmi ? 'EMI Due' : '${card.bank} Cycle',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: tx.isEmi ? const Color(0xFF94A3B8) : const Color(0xFFFBBF24),
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
                                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedCounterText(
                              value: tx.amount,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
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

class _PulseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF00FFA3), Color(0xFF38BDF8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.1);
    path.lineTo(size.width * 0.6, size.height * 0.9);
    path.lineTo(size.width * 0.75, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
