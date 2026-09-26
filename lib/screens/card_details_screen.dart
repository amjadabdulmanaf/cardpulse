import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import '../utils/formatters.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/animated_counter_text.dart';
import '../widgets/animated_percent_text.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/metro_tile_flip_entrance.dart';

class CardDetailsScreen extends StatefulWidget {
  final CreditCard card;
  final Color? tileBg;
  final List<TransactionItem> transactions;
  final List<EmiItem> emis;
  final Function(CreditCard) onUpdateCard;
  final Function(String) onDeleteCard;
  final Function(TransactionItem)? onAddTransaction;
  final Function(String) onDeleteTransaction;

  const CardDetailsScreen({
    super.key,
    required this.card,
    this.tileBg,
    required this.transactions,
    required this.emis,
    required this.onUpdateCard,
    required this.onDeleteCard,
    this.onAddTransaction,
    required this.onDeleteTransaction,
  });

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  late CreditCard _card;
  late List<TransactionItem> _localTransactions;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _localTransactions = List.from(widget.transactions);
  }

  @override
  void didUpdateWidget(CardDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions) {
      _localTransactions = List.from(widget.transactions);
    }
  }

  void _openAddSpendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionSheet(
        cards: [_card],
        initialCard: _card,
        onSave: (tx) {
          setState(() {
            _localTransactions.add(tx);
          });
          widget.onAddTransaction?.call(tx);
        },
      ),
    );
  }

  void _confirmDeleteTransaction(String txId, String title) {
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
          color: Color(0xFF121212),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 36),
            const SizedBox(height: 10),
            Text(
              'DELETE SPEND TRANSACTION?',
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFFB91C1C), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to delete "$title"? This transaction will be removed from this card cycle.',
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
                    child: Text('Delete Spend', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _handleDeleteTransaction(txId);
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

  void _handleDeleteTransaction(String txId) {
    setState(() {
      _localTransactions.removeWhere((t) => t.id == txId);
    });
    widget.onDeleteTransaction(txId);
  }

  @override
  Widget build(BuildContext context) {
    final cycle = CycleCalculator.getBillingCycle(_card);
    final totalSpend = CycleCalculator.getTotalCycleSpend(
      _card,
      _localTransactions,
      widget.emis,
      cycle: cycle,
    );
    final available = (_card.monthlyLimit - totalSpend).clamp(0.0, double.infinity);
    final percentVal = _card.monthlyLimit > 0
        ? ((totalSpend / _card.monthlyLimit) * 100)
        : 0.0;

    final cardTxs = _localTransactions.where((t) => t.cardId == _card.id).toList();
    cardTxs.sort((a, b) => b.date.compareTo(a.date));

    final currentCycleSpends = cardTxs.where((t) => cycle.containsDate(t.date)).toList();
    final previousSpends = cardTxs.where((t) => !cycle.containsDate(t.date)).toList();

    final cardEmis = widget.emis.where((e) => e.cardId == _card.id).toList();
    final tileBgColor = widget.tileBg ?? const Color(0xFF0078D7);

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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD DETAILS',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFFA0A0A0),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${_card.bank} ${_card.cardName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_outlined, color: Color(0xFF0078D7), size: 20),
                    tooltip: 'Edit Card Limit',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => AddCardSheet(
                          initialCard: _card,
                          onSave: (updatedCard) {
                            setState(() {
                              _card = updatedCard;
                            });
                            widget.onUpdateCard(updatedCard);
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C), size: 20),
                    tooltip: 'Delete Card',
                    onPressed: () {
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
                            color: Color(0xFF121212),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'DELETE CREDIT CARD?',
                                style: GoogleFonts.spaceGrotesk(color: const Color(0xFFB91C1C), fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Are you sure you want to delete ${_card.cardName}? Associated transactions and EMIs will also be removed.',
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
                                        Navigator.of(ctx).pop();
                                        Navigator.of(context).pop();
                                        widget.onDeleteCard(_card.id);
                                      },
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
              ),
            ),

            // 2. Scrollable Details Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Summary Tile (Matching Listing Page Color)
                    MetroTileFlipEntrance(
                      delayMs: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tileBgColor, // Exact same color as tile in listing page!
                          borderRadius: BorderRadius.zero, // Windows Phone Sharp Edge
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '••••  ${_card.last4}',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text('Current Spend: ', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 12)),
                                    AnimatedCounterText(
                                      value: totalSpend,
                                      delayMs: 180,
                                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Limit: ${Formatters.formatCurrency(_card.monthlyLimit)}',
                                  style: GoogleFonts.workSans(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            AnimatedProgressBar(
                              value: _card.monthlyLimit > 0 ? (totalSpend / _card.monthlyLimit) : 0.0,
                              delayMs: 220,
                              height: 6,
                              color: Colors.white,
                              backgroundColor: Colors.black26,
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    AnimatedCounterText(
                                      value: available,
                                      delayMs: 180,
                                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(' Available', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                AnimatedPercentText(
                                  value: percentVal,
                                  delayMs: 180,
                                  suffix: '% Utilized',
                                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // SECTION 1: Active EMIs
                    MetroTileFlipEntrance(
                      delayMs: 100,
                      child: Text(
                        'Active EMIs (${cardEmis.length})',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (cardEmis.isEmpty)
                      MetroTileFlipEntrance(
                        delayMs: 140,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            'No EMIs linked to this credit card.',
                            style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cardEmis.length,
                        itemBuilder: (context, index) {
                          final emi = cardEmis[index];
                          final now = DateTime.now();
                          final currentMonthAmt = emi.getAmountForDate(now);

                          return MetroTileFlipEntrance(
                            delayMs: 140 + (index * 60),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emi.title,
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${emi.type == EmiType.self ? "Self" : emi.beneficiaryName ?? "Others"} • ${emi.schedule.length} Months',
                                        style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      AnimatedCounterText(
                                        value: currentMonthAmt,
                                        delayMs: 220 + (index * 60),
                                        style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        'This Cycle',
                                        style: GoogleFonts.workSans(fontSize: 10, color: const Color(0xFFA0A0A0)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 14),

                    // SECTION 2: Current Cycle Spends
                    MetroTileFlipEntrance(
                      delayMs: 220,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Cycle Spends (${currentCycleSpends.length})',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: _openAddSpendSheet,
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
                                    'ADD SPEND',
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

                    const SizedBox(height: 8),

                    if (currentCycleSpends.isEmpty)
                      MetroTileFlipEntrance(
                        delayMs: 260,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            'No spends recorded in the active cycle.',
                            style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentCycleSpends.length,
                        itemBuilder: (context, index) {
                          final tx = currentCycleSpends[index];
                          return MetroTileFlipEntrance(
                            delayMs: 260 + (index * 50),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${tx.category} • ${Formatters.formatDateShort(tx.date)}',
                                          style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      AnimatedCounterText(
                                        value: tx.amount,
                                        delayMs: 320 + (index * 50),
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C), size: 18),
                                        onPressed: () => _confirmDeleteTransaction(tx.id, tx.title),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 14),

                    // SECTION 3: Previous Spends (Other than current cycle)
                    MetroTileFlipEntrance(
                      delayMs: 340,
                      child: Text(
                        'Previous Spends (${previousSpends.length})',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (previousSpends.isEmpty)
                      MetroTileFlipEntrance(
                        delayMs: 380,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            'No previous cycle spends recorded.',
                            style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: previousSpends.length,
                        itemBuilder: (context, index) {
                          final tx = previousSpends[index];
                          return MetroTileFlipEntrance(
                            delayMs: 380 + (index * 50),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${tx.category} • ${Formatters.formatDateShort(tx.date)}',
                                          style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      AnimatedCounterText(
                                        value: tx.amount,
                                        delayMs: 440 + (index * 50),
                                        style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C), size: 18),
                                        onPressed: () => _confirmDeleteTransaction(tx.id, tx.title),
                                      ),
                                    ],
                                  ),
                                ],
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
