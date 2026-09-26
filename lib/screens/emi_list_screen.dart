import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../widgets/animated_counter_text.dart';
import '../widgets/metro_card_pulse_logo.dart';
import '../widgets/metro_tile_flip_entrance.dart';
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
          color: Color(0xFF121212),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 36),
            const SizedBox(height: 10),
            Text(
              'DELETE EMI SCHEDULE?',
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFFB91C1C), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to delete "${emi.title}"? This will permanently remove the repayment schedule from local storage.',
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
                    child: Text('Delete EMI', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _selectedEmiIndex = 0;
                      });
                      widget.onDeleteEmi(emi.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${emi.title}" EMI schedule.'),
                          backgroundColor: const Color(0xFFB91C1C),
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final notifications = NotificationsHelper.generateNotifications(
      cards: widget.cards,
      transactions: widget.transactions,
      emis: widget.emis,
    );

    final filteredEmis = widget.emis.where((emi) {
      if (_filter == EmiFilter.self) return emi.type == EmiType.self;
      if (_filter == EmiFilter.others) return emi.type == EmiType.others;
      return true;
    }).toList();

    double totalMonthly = 0.0;
    double selfMonthly = 0.0;
    double othersMonthly = 0.0;

    for (final emi in widget.emis) {
      final monthlyAmt = emi.getAmountForDate(now);
      totalMonthly += monthlyAmt;
      if (emi.type == EmiType.self) {
        selfMonthly += monthlyAmt;
      } else {
        othersMonthly += monthlyAmt;
      }
    }

    final selectedEmi = (filteredEmis.isNotEmpty && _selectedEmiIndex < filteredEmis.length)
        ? filteredEmis[_selectedEmiIndex]
        : null;

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
                    child: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EMIs',
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
                    // Filter Pills Row
                    MetroTileFlipEntrance(
                      delayMs: 0,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All EMIs',
                            count: widget.emis.length,
                            filter: EmiFilter.all,
                            color: const Color(0xFF0078D7),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: 'Self',
                            count: widget.emis.where((e) => e.type == EmiType.self).length,
                            filter: EmiFilter.self,
                            color: const Color(0xFF008A00),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: 'Others',
                            count: widget.emis.where((e) => e.type == EmiType.others).length,
                            filter: EmiFilter.others,
                            color: const Color(0xFFF09609),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // TOTAL MONTHLY OBLIGATION Card (Metro Flip Tile)
                    MetroTileFlipEntrance(
                      delayMs: 100,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL MONTHLY OBLIGATION',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFFA0A0A0),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => AddEmiScreen(
                                          cards: widget.cards,
                                          onSave: widget.onAddEmi,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF008A00), // Solid Metro Green
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.add, color: Colors.white, size: 12),
                                        const SizedBox(width: 3),
                                        Text(
                                          'ADD EMI',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                AnimatedCounterText(
                                  value: totalMonthly,
                                  delayMs: 250,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  ' /month',
                                  style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(width: 6, height: 6, color: const Color(0xFF008A00)),
                                    const SizedBox(width: 6),
                                    Text('Self Share', style: GoogleFonts.workSans(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                                AnimatedCounterText(
                                  value: selfMonthly,
                                  delayMs: 250,
                                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFF008A00), fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(width: 6, height: 6, color: const Color(0xFFF09609)),
                                    const SizedBox(width: 6),
                                    Text('Others', style: GoogleFonts.workSans(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                                AnimatedCounterText(
                                  value: othersMonthly,
                                  delayMs: 250,
                                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF09609), fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Active Liabilities Header
                    MetroTileFlipEntrance(
                      delayMs: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Liabilities',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Swipe or inspect below',
                            style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Active Liabilities Cards
                    if (filteredEmis.isEmpty)
                      MetroTileFlipEntrance(
                        delayMs: 240,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_month_outlined, color: Color(0xFF0078D7), size: 36),
                              const SizedBox(height: 8),
                              Text('No Active EMIs Found', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Tap + button on Dashboard to create an EMI schedule.', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 160,
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

                            int currentInst = 1;
                            for (int i = 0; i < emi.schedule.length; i++) {
                              if (emi.schedule[i].year == now.year && emi.schedule[i].month == now.month) {
                                currentInst = i + 1;
                                break;
                              }
                            }

                            final isSelf = emi.type == EmiType.self;
                            final tileBg = isSelf ? const Color(0xFF008A00) : const Color(0xFFB45309);

                            return MetroTileFlipEntrance(
                              delayMs: 240 + (index * 80),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedEmiIndex = index),
                                child: Container(
                                  width: 280,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: tileBg, // Solid Metro Color
                                    borderRadius: BorderRadius.zero,
                                    border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius: BorderRadius.zero,
                                            ),
                                            child: Icon(
                                              emi.title.toLowerCase().contains('phone') || emi.title.toLowerCase().contains('iphone')
                                                  ? Icons.phone_iphone
                                                  : Icons.laptop_mac,
                                              color: Colors.white,
                                              size: 16,
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
                                                  style: GoogleFonts.spaceGrotesk(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  '${card.bank} •••• ${card.last4}',
                                                  style: GoogleFonts.workSans(color: Colors.white70, fontSize: 11),
                                                ),
                                                if (emi.type == EmiType.others && emi.beneficiaryName != null && emi.beneficiaryName!.isNotEmpty) ...[
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    emi.beneficiaryName!,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.spaceGrotesk(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _editEmi(emi),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _confirmDeleteEmi(emi),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.delete_outline, size: 16, color: Colors.white),
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
                                              Text('Total', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 10)),
                                              AnimatedCounterText(
                                                value: emi.totalAmount,
                                                delayMs: 350 + (index * 80),
                                                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Tenure', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 10)),
                                              Text(
                                                '${emi.schedule.length} mos',
                                                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('Current', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 10)),
                                              Text(
                                                '$currentInst of ${emi.schedule.length}',
                                                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const Spacer(),

                                      ClipRRect(
                                        borderRadius: BorderRadius.zero,
                                        child: LinearProgressIndicator(
                                          value: emi.schedule.isNotEmpty ? (currentInst / emi.schedule.length) : 0.0,
                                          minHeight: 5,
                                          backgroundColor: Colors.black26,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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

                    const SizedBox(height: 16),

                    // 4. Installment Schedule Table
                    if (selectedEmi != null) ...[
                      MetroTileFlipEntrance(
                        delayMs: 360,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.credit_card_outlined, color: Color(0xFF0078D7), size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${selectedEmi.title} Schedule',
                                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0078D7)),
                                          onPressed: () => _editEmi(selectedEmi),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB91C1C)),
                                          onPressed: () => _confirmDeleteEmi(selectedEmi),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                color: const Color(0xFF262626),
                                child: Row(
                                  children: [
                                    SizedBox(width: 20, child: Text('#', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold))),
                                    SizedBox(width: 75, child: Text('MONTH', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold))),
                                    Expanded(child: Text('EMI (₹)', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold))),
                                    SizedBox(width: 90, child: Text('STATUS', textAlign: TextAlign.right, style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),

                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: selectedEmi.schedule.length,
                                itemBuilder: (context, index) {
                                  final item = selectedEmi.schedule[index];
                                  final isCurrentMonth = item.year == now.year && item.month == now.month;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isCurrentMonth ? const Color(0x260078D7) : null,
                                      border: const Border(
                                        bottom: BorderSide(color: Color(0xFF2D2D2D), width: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          child: Text(
                                            '${item.installmentNumber}',
                                            style: GoogleFonts.spaceGrotesk(
                                              color: isCurrentMonth ? const Color(0xFF0078D7) : const Color(0xFFA0A0A0),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 75,
                                          child: Text(
                                            item.monthLabel,
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: AnimatedCounterText(
                                            value: item.amount,
                                            delayMs: 400 + (index * 20),
                                            style: GoogleFonts.spaceGrotesk(
                                              color: isCurrentMonth ? const Color(0xFF0078D7) : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 90,
                                          child: GestureDetector(
                                            onTap: () {
                                              final newPaid = !item.isPaid;
                                              setState(() {
                                                item.isPaid = newPaid;
                                              });
                                              widget.onAddEmi(selectedEmi);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: item.isPaid ? const Color(0x26008A00) : const Color(0x26F09609),
                                                borderRadius: BorderRadius.zero,
                                              ),
                                              child: Text(
                                                item.isPaid ? 'PAID' : 'DUE',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: item.isPaid ? const Color(0xFF008A00) : const Color(0xFFF09609),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
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
                      ),
                    ],

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
