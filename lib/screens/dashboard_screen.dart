import 'dart:async';
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
import '../widgets/metro_card_pulse_logo.dart';
import '../widgets/metro_tile_flip_entrance.dart';
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
  final Function(int)? onNavigateTab;

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
    this.onNavigateTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int _activeCardIndex = 0;

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
    int otherEmiCount = 0;

    for (final emi in widget.emis) {
      final monthlyAmt = emi.getAmountForDate(now);
      if (monthlyAmt > 0) {
        totalEmiCommitment += monthlyAmt;
        if (emi.type == EmiType.self) {
          selfEmiCount++;
        } else {
          otherEmiCount++;
        }
      }
    }

    final notifications = NotificationsHelper.generateNotifications(
      cards: widget.cards,
      transactions: widget.transactions,
      emis: widget.emis,
    );

    // Combined Active Cycle Spends List
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

    final parsedSmsCount = widget.transactions.where((t) => t.rawSms != null && t.rawSms!.isNotEmpty).length;
    final String autoSyncSubtext = widget.cards.isEmpty
        ? 'Add credit card to enable SMS auto-parsing'
        : (parsedSmsCount > 0
            ? '$parsedSmsCount SMS spends parsed • Auto-sync active'
            : 'SMS inbox scanned • Auto-sync active');

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12), // Windows Phone Dark Obsidian
      body: SafeArea(
        child: Column(
          children: [
            // 1. FIXED TOP HEADER BAR (Outside SingleChildScrollView)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF121212),
              child: Row(
                children: [
                  const MetroCardPulseLogo(width: 30, height: 20),
                  const SizedBox(width: 8),
                  Text(
                    'CardPulse',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  // Notification Bell Icon Button
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

            // 2. SCROLLABLE LIVE TILES GRID
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Card 1: ACTIVE CYCLE SPEND (Solid Electric Blue Rectangular Tile with Metro Flip)
                    MetroTileFlipEntrance(
                      delayMs: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0078D7), // Solid Electric Blue
                          borderRadius: BorderRadius.zero, // Windows Phone Sharp Edge
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up, color: Colors.white, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ACTIVE CYCLE SPEND',
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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Text(
                                    'LIVE',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFF0078D7),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedCounterText(
                          value: activeCyclesTotalSpend,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ' / ${Formatters.formatCurrency(activeCyclesTotalLimit)}',
                          style: GoogleFonts.workSans(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Solid White Animated Progress Bar
                    AnimatedProgressBar(
                      value: activeCyclesTotalLimit > 0 ? (activeCyclesTotalSpend / activeCyclesTotalLimit) : 0.0,
                      height: 6,
                      color: Colors.white,
                      backgroundColor: Colors.white30,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedPercentText(
                              value: overallHealthPercent,
                              suffix: '% UTILIZATION',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$minDaysRemaining days to reset',
                              style: GoogleFonts.workSans(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedCounterText(
                              value: bufferLeft,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'BUFFER LEFT',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

              const SizedBox(height: 6),

              // 4. Grid Row 1 (Two Equal Width & Height Tile Cards Side-by-Side)
              Row(
                children: [
                  // Left Tile: EMIS THIS MONTH (Solid Green)
                  Expanded(
                    child: MetroTileFlipEntrance(
                      delayMs: 120,
                      child: SizedBox(
                        height: 142,
                        child: GestureDetector(
                          onTap: () => widget.onNavigateTab?.call(1),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF008A00),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: const BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.zero),
                                      child: Text(
                                        Formatters.formatMonthLabel(now.year, now.month).split('-').first.toUpperCase(),
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('EMIS THIS MONTH', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                AnimatedCounterText(value: totalEmiCommitment, delayMs: 200, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                                Text('${selfEmiCount + otherEmiCount} ACTIVE', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text('$selfEmiCount Self • $otherEmiCount Others', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Right Tile: RESETTING SOON (Live Auto-Scrolling Card Tile)
                  Expanded(
                    child: MetroTileFlipEntrance(
                      delayMs: 200,
                      child: SizedBox(
                        height: 142,
                        child: LiveScrollingCardTile(
                          cards: sortedCards,
                          transactions: widget.transactions,
                          emis: widget.emis,
                          onTap: () => widget.onNavigateTab?.call(0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 5. Card 3: ACTIVE CYCLE SPENDS (Windows Phone Live Auto-Scrolling Tile with Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 300,
                child: LiveScrollingSpendTile(
                  items: combinedActiveSpends,
                  cards: widget.cards,
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
              ),

              const SizedBox(height: 6),

              // 6. Grid Row 2 (Two Sharp Tile Cards Side-by-Side with Metro Flip)
              Row(
                children: [
                  // Left Tile: Add EMI (Solid Crimson Red)
                  Expanded(
                    child: MetroTileFlipEntrance(
                      delayMs: 420,
                      child: SizedBox(
                        height: 110,
                        child: GestureDetector(
                          onTap: () => widget.onAddEmi(null),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFB91C1C), // Solid Crimson Red
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Text(
                                        'NEW',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  'Add EMI',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'LOG SPLIT OR CARD',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Right Tile: Add Spend (Solid Dark Charcoal)
                  Expanded(
                    child: MetroTileFlipEntrance(
                      delayMs: 500,
                      child: SizedBox(
                        height: 110,
                        child: GestureDetector(
                          onTap: () => widget.onAddSpend(null),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF262626), // Solid Dark Charcoal
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Text(
                                        'MANUAL',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  'Add Spend',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'LOG REGULAR DEBIT',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 7. Tile 5: Auto-Parser Synced (Dark Grey Sharp Tile with Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 580,
                child: GestureDetector(
                  onTap: widget.onScanSms,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF262626),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: const Icon(Icons.check_box_outlined, color: Color(0xFF0078D7), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manual Transaction Sync',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                autoSyncSubtext,
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFFA0A0A0),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
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
}

/// Windows Phone Live Auto-Scrolling Spend Tile
class LiveScrollingSpendTile extends StatefulWidget {
  final List<TransactionItem> items;
  final List<CreditCard> cards;
  final VoidCallback onTap;

  const LiveScrollingSpendTile({
    super.key,
    required this.items,
    required this.cards,
    required this.onTap,
  });

  @override
  State<LiveScrollingSpendTile> createState() => _LiveScrollingSpendTileState();
}

class _LiveScrollingSpendTileState extends State<LiveScrollingSpendTile> {
  late PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted || widget.items.isEmpty) return;
      final nextIndex = (_currentIndex + 1) % widget.items.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF004880),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'ACTIVE CYCLE SPENDS',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text('0 TOTAL', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('No cycle spends logged yet', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 135,
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFF004880), // Windows Phone Dark Blue
          borderRadius: BorderRadius.zero, // Sharp Edge Tile
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE CYCLE SPENDS',
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    '${widget.items.length} TOTAL',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Live Auto-Scrolling Vertical PageView Downwards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical, // Downward vertical live scroll!
                itemCount: widget.items.length,
                onPageChanged: (idx) {
                  setState(() {
                    _currentIndex = idx;
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final card = widget.cards.firstWhere(
                    (c) => c.id == item.cardId,
                    orElse: () => CreditCard(
                      id: '',
                      cardName: 'Card',
                      bank: 'Bank',
                      last4: '0000',
                      monthlyLimit: 0,
                      billGenerationDay: 15,
                    ),
                  );

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${card.cardName} • ${item.category}',
                                  style: GoogleFonts.workSans(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedCounterText(
                                value: item.amount,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                Formatters.formatDateShort(item.date).toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white70,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            // Footer Row: Ledger link + Square Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'tap to view full cycle ledger →',
                  style: GoogleFonts.workSans(
                    color: Colors.white70,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
                Row(
                  children: List.generate(widget.items.length > 4 ? 4 : widget.items.length, (i) {
                    final isCurrent = (i == (_currentIndex % (widget.items.length > 4 ? 4 : widget.items.length)));
                    return Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.white : Colors.white30,
                        shape: BoxShape.rectangle, // Sharp square dots
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Windows Phone Live Auto-Scrolling Card Tile (Resetting Soon)
class LiveScrollingCardTile extends StatefulWidget {
  final List<CreditCard> cards;
  final List<TransactionItem> transactions;
  final List<EmiItem> emis;
  final VoidCallback onTap;

  const LiveScrollingCardTile({
    super.key,
    required this.cards,
    required this.transactions,
    required this.emis,
    required this.onTap,
  });

  @override
  State<LiveScrollingCardTile> createState() => _LiveScrollingCardTileState();
}

class _LiveScrollingCardTileState extends State<LiveScrollingCardTile> {
  late PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted || widget.cards.isEmpty) return;
      final nextIndex = (_currentIndex + 1) % widget.cards.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFB45309),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.credit_card, color: Colors.white, size: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.zero),
                    child: Text('0 DAYS', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('RESETTING SOON', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('No Cards', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFFB45309), // Amber / Brown
          borderRadius: BorderRadius.zero,
        ),
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical, // Downwards vertical live scroll!
          itemCount: widget.cards.length,
          onPageChanged: (idx) {
            setState(() {
              _currentIndex = idx;
            });
          },
          itemBuilder: (context, index) {
            final card = widget.cards[index];
            final cycle = CycleCalculator.getBillingCycle(card);
            final spend = CycleCalculator.getTotalCycleSpend(card, widget.transactions, widget.emis, cycle: cycle);
            final available = (card.monthlyLimit - spend).clamp(0.0, double.infinity);
            final daysLeft = cycle.daysRemaining > 0 ? cycle.daysRemaining : 1;
            final safeDaily = (available / daysLeft).roundToDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.credit_card, color: Colors.white, size: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.zero),
                      child: Text(
                        '${cycle.daysRemaining} DAYS',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('RESETTING SOON', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  '${card.bank} ${card.cardName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${Formatters.formatDateShort(cycle.startDate)} - ${Formatters.formatDateShort(cycle.endDate)}',
                  style: GoogleFonts.workSans(color: Colors.white70, fontSize: 11),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SAFE VELOCITY', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                    AnimatedCounterText(
                      value: safeDaily,
                      prefix: '₹',
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            );
          },
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
        colors: const [Color(0xFF0078D7), Color(0xFF008A00), Color(0xFFF09609)],
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
