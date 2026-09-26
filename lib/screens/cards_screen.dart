import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/animated_counter_text.dart';
import '../widgets/animated_percent_text.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/metro_tile_flip_entrance.dart';
import '../widgets/notifications_sheet.dart';
import 'card_details_screen.dart';

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

  // Metro Solid Accent Colors for Card Tiles
  static const List<Color> _metroCardColors = [
    Color(0xFF0078D7), // Metro Electric Blue
    Color(0xFF008A00), // Metro Emerald Green
    Color(0xFFB45309), // Metro Amber/Brown
    Color(0xFFB91C1C), // Metro Crimson Red
    Color(0xFF1E1E1E), // Metro Dark Charcoal
  ];

  @override
  Widget build(BuildContext context) {
    final sortedCards = CycleCalculator.sortCardsByReset(widget.cards);

    // Calculate Combined Limit and Active Spent
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
        ? ((activeSpent / combinedLimit) * 100)
        : 0.0;

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
                    child: const Icon(Icons.credit_card_outlined, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cards',
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

            // 2. Scrollable Cards Tiles List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Combined Limit Summary Tile (Metro 3D Flip)
                    MetroTileFlipEntrance(
                      delayMs: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E), // Metro Solid Charcoal
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
                                    const Icon(Icons.pie_chart_outline, color: Color(0xFF0078D7), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'COMBINED LIMIT SUMMARY',
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
                                    color: Color(0xFF262626),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Text(
                                    '${widget.cards.length} CARDS',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFF0078D7),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Combined Limit',
                                        style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      AnimatedCounterText(
                                        value: combinedLimit,
                                        delayMs: 180,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 20,
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
                                      Text(
                                        'Active Spent',
                                        style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          AnimatedCounterText(
                                            value: activeSpent,
                                            delayMs: 180,
                                            style: GoogleFonts.spaceGrotesk(
                                              color: const Color(0xFF008A00),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          AnimatedPercentText(
                                            value: combinedPercent,
                                            delayMs: 180,
                                            style: GoogleFonts.workSans(
                                              color: const Color(0xFFA0A0A0),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            AnimatedProgressBar(
                              value: combinedLimit > 0 ? (activeSpent / combinedLimit) : 0.0,
                              delayMs: 220,
                              height: 6,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0078D7), Color(0xFF008A00)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2. Section Header & Add Card Action
                    MetroTileFlipEntrance(
                      delayMs: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'My Cards',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF262626),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Text(
                                  '${widget.cards.length} ACTIVE',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFFA0A0A0),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _openAddCardSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0078D7), // Solid Metro Blue
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ADD CARD',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 3. Individual Cards List (Metro 3D Tile Flip)
                    if (sortedCards.isEmpty)
                      MetroTileFlipEntrance(
                        delayMs: 180,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.credit_card, color: Color(0xFF0078D7), size: 36),
                              const SizedBox(height: 8),
                              Text(
                                'No Cards Registered',
                                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "+ ADD CARD" button above to add your credit cards.',
                                style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12),
                              ),
                            ],
                          ),
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
                          final percentVal = card.monthlyLimit > 0
                              ? ((spend / card.monthlyLimit) * 100)
                              : 0.0;

                          final tileBg = _metroCardColors[index % _metroCardColors.length];
                          final cardDelay = 180 + (index * 80);
                          final animDelay = cardDelay + 180;

                          return Dismissible(
                            key: Key('card_dismiss_${card.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              bool confirmed = false;
                              final messenger = ScaffoldMessenger.of(context);
                              await showModalBottomSheet(
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
                                    color: Color(0xFF121212),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 36),
                                      const SizedBox(height: 10),
                                      Text(
                                        'DELETE CREDIT CARD?',
                                        style: GoogleFonts.spaceGrotesk(color: const Color(0xFFB91C1C), fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Are you sure you want to delete "${card.cardName}" (${card.bank})? Associated transactions and EMIs will also be removed.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Color(0xFF2D2D2D)),
                                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                              ),
                                              child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                                              onPressed: () => Navigator.of(ctx).pop(),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xFFB91C1C),
                                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                              ),
                                              child: Text('Delete Card', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                                              onPressed: () {
                                                confirmed = true;
                                                Navigator.of(ctx).pop();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              if (confirmed && mounted) {
                                widget.onDeleteCard(card.id);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Deleted "${card.cardName}" card.'),
                                    backgroundColor: const Color(0xFFB91C1C),
                                  ),
                                );
                              }
                              return confirmed;
                            },
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: const Color(0xFFB91C1C), // Solid Crimson Red
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SWIPE TO DELETE',
                                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            child: MetroTileFlipEntrance(
                              delayMs: cardDelay,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: tileBg, // Solid Metro Color
                                borderRadius: BorderRadius.zero, // Windows Phone Sharp Edge
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Chip + Bank Name & Card Name + Delete Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 18,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF09609),
                                              borderRadius: BorderRadius.zero,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.wifi, color: Colors.white70, size: 16),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                card.bank.toUpperCase(),
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              Text(
                                                card.cardName.toUpperCase(),
                                                style: GoogleFonts.workSans(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Masked Last 4 & Reset Days Badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '••••  ${card.last4}',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Text(
                                          'RESETS IN ${cycle.daysRemaining}D',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Spend vs Limit Progress Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text('Spend: ', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 12)),
                                          AnimatedCounterText(
                                            value: spend,
                                            delayMs: animDelay,
                                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Limit: ${Formatters.formatCurrency(card.monthlyLimit)}',
                                        style: GoogleFonts.workSans(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  AnimatedProgressBar(
                                    value: card.monthlyLimit > 0 ? (spend / card.monthlyLimit) : 0.0,
                                    delayMs: animDelay + 40,
                                    height: 6,
                                    color: Colors.white,
                                    backgroundColor: Colors.black26,
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          AnimatedCounterText(
                                            value: available,
                                            delayMs: animDelay,
                                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          Text(' Available', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 11)),
                                        ],
                                      ),
                                      AnimatedPercentText(
                                        value: percentVal,
                                        delayMs: animDelay,
                                        suffix: '% Utilized',
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  // 3 Metro Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 34,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _openEditLimitDialog(card),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black26,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: EdgeInsets.zero,
                                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                            ),
                                            icon: const Icon(Icons.tune, size: 14),
                                            label: Text('EDIT LIMIT', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: SizedBox(
                                          height: 34,
                                          child: ElevatedButton.icon(
                                            onPressed: widget.onScanSms,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black26,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: EdgeInsets.zero,
                                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                            ),
                                            icon: const Icon(Icons.chat_bubble_outline, size: 14),
                                            label: Text('AUTO SMS', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: SizedBox(
                                          height: 34,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (ctx) => CardDetailsScreen(
                                                    card: card,
                                                    tileBg: tileBg,
                                                    transactions: widget.transactions,
                                                    emis: widget.emis,
                                                    onUpdateCard: widget.onAddCard,
                                                    onDeleteCard: widget.onDeleteCard,
                                                    onAddTransaction: widget.onAddTransaction,
                                                    onDeleteTransaction: widget.onDeleteTransaction,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black26,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: EdgeInsets.zero,
                                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                            ),
                                            icon: const Icon(Icons.table_chart_outlined, size: 14),
                                            label: Text('DETAILS', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
}
