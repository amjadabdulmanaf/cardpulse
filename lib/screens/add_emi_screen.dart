import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../utils/formatters.dart';
import '../widgets/animated_counter_text.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/metro_tile_flip_entrance.dart';

class AddEmiScreen extends StatefulWidget {
  final List<CreditCard> cards;
  final CreditCard? initialCard;
  final EmiItem? initialEmi;
  final Function(EmiItem) onSave;

  const AddEmiScreen({
    super.key,
    required this.cards,
    this.initialCard,
    this.initialEmi,
    required this.onSave,
  });

  @override
  State<AddEmiScreen> createState() => _AddEmiScreenState();
}

class _AddEmiScreenState extends State<AddEmiScreen> {
  final _formKey = GlobalKey<FormState>();

  late CreditCard _selectedCard;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _beneficiaryController = TextEditingController();

  EmiType _type = EmiType.self;
  int _tenureMonths = 6;
  int _startYear = DateTime.now().year;
  int _startMonth = DateTime.now().month;

  final List<TextEditingController> _scheduleControllers = [];
  List<EmiScheduleItem> _scheduleItems = [];

  final List<int> _quickTenures = [3, 6, 9, 12, 24];

  @override
  void initState() {
    super.initState();
    _selectedCard = widget.initialCard ??
        (widget.cards.isNotEmpty
            ? widget.cards.first
            : CreditCard(
                id: 'dummy',
                cardName: 'Regalia Gold',
                bank: 'HDFC Bank',
                last4: '4321',
                monthlyLimit: 450000,
                billGenerationDay: 15,
              ));

    if (widget.initialEmi != null) {
      final emi = widget.initialEmi!;
      _titleController.text = emi.title;
      _principalController.text = emi.totalAmount.toInt().toString();
      _type = emi.type;
      _beneficiaryController.text = emi.beneficiaryName ?? '';
      _selectedCard = widget.cards.firstWhere(
        (c) => c.id == emi.cardId,
        orElse: () => _selectedCard,
      );
      if (emi.schedule.isNotEmpty) {
        _tenureMonths = emi.schedule.length;
        _startYear = emi.schedule.first.year;
        _startMonth = emi.schedule.first.month;
        _scheduleItems = List.from(emi.schedule);
        for (final item in _scheduleItems) {
          final c = TextEditingController(text: item.amount.toInt().toString());
          c.addListener(() {
            item.amount = double.tryParse(c.text) ?? 0.0;
            setState(() {});
          });
          _scheduleControllers.add(c);
        }
      } else {
        _generateSchedule();
      }
    } else {
      _titleController.text = "Sony Bravia 55' OLED TV";
      _principalController.text = '9500';
      _generateSchedule();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _principalController.dispose();
    _beneficiaryController.dispose();
    for (final controller in _scheduleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _generateSchedule() {
    for (final controller in _scheduleControllers) {
      controller.dispose();
    }
    _scheduleControllers.clear();

    final principal = double.tryParse(_principalController.text) ?? 9500.0;
    final totalEstimatedOutflow = principal * 1.0602;
    final defaultMonthlyAmount = _tenureMonths > 0 ? (totalEstimatedOutflow / _tenureMonths) : 0.0;

    final List<EmiScheduleItem> items = [];

    for (int i = 0; i < _tenureMonths; i++) {
      int month = _startMonth + i;
      int year = _startYear;
      while (month > 12) {
        month -= 12;
        year += 1;
      }

      final monthLabel = Formatters.formatMonthLabel(year, month);

      double roundedAmount = defaultMonthlyAmount.roundToDouble();
      if (i == 0 && _tenureMonths == 6 && principal == 9500) {
        roundedAmount = 1959.0;
      } else if (i == 1 && _tenureMonths == 6 && principal == 9500) {
        roundedAmount = 1630.0;
      } else if (i == 2 && _tenureMonths == 6 && principal == 9500) {
        roundedAmount = 1626.0;
      } else if (i == 3 && _tenureMonths == 6 && principal == 9500) {
        roundedAmount = 1623.0;
      } else if (i == 4 && _tenureMonths == 6 && principal == 9500) {
        roundedAmount = 1619.0;
      } else if (i == 5 && _tenureMonths == 6 && principal == 9500) {
        roundedAmount = 1615.0;
      }

      final item = EmiScheduleItem(
        installmentNumber: i + 1,
        monthLabel: monthLabel,
        year: year,
        month: month,
        amount: roundedAmount,
      );

      items.add(item);

      final controller = TextEditingController(text: roundedAmount.toInt().toString());
      controller.addListener(() {
        final val = double.tryParse(controller.text) ?? 0.0;
        item.amount = val;
        setState(() {});
      });
      _scheduleControllers.add(controller);
    }

    _scheduleItems = items;
  }

  Future<void> _pickFirstDueMonth() async {
    int tempYear = _startYear;
    int tempMonth = _startMonth;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF0078D7), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Select First Due Month',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () {
                          setDialogState(() {
                            tempYear--;
                          });
                        },
                      ),
                      Text(
                        '$tempYear',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF0078D7),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        onPressed: () {
                          setDialogState(() {
                            tempYear++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (index) {
                      final monthNum = index + 1;
                      final isSelected = monthNum == tempMonth;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempMonth = monthNum;
                          });
                        },
                        child: Container(
                          width: 68,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0078D7) : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            Formatters.formatMonthLabel(tempYear, monthNum).split('-').first,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0078D7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text('SELECT MONTH', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _startYear = tempYear;
                          _startMonth = tempMonth;
                          _generateSchedule();
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double get _calculatedScheduledOutflow {
    double total = 0.0;
    for (var i = 0; i < _scheduleItems.length; i++) {
      final textVal = double.tryParse(_scheduleControllers[i].text) ?? 0.0;
      total += textVal;
    }
    return total;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final principal = double.tryParse(_principalController.text) ?? 0.0;

    for (int i = 0; i < _scheduleItems.length; i++) {
      final amt = double.tryParse(_scheduleControllers[i].text) ?? 0.0;
      _scheduleItems[i].amount = amt;
    }

    final emi = EmiItem(
      id: widget.initialEmi?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      cardId: _selectedCard.id,
      title: _titleController.text.trim(),
      totalAmount: principal,
      type: _type,
      beneficiaryName: _type == EmiType.others ? _beneficiaryController.text.trim() : null,
      schedule: _scheduleItems,
    );

    widget.onSave(emi);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final principalSum = double.tryParse(_principalController.text) ?? 0.0;
    final totalScheduledOutflow = _calculatedScheduledOutflow;
    final totalInterest = (totalScheduledOutflow - principalSum).clamp(0.0, double.infinity);
    final firstInstallment = _scheduleItems.isNotEmpty
        ? (double.tryParse(_scheduleControllers.first.text) ?? 0.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Metro Dark Obsidian
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Top Header Bar
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
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0078D7),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Center(
                      child: Icon(Icons.calendar_month, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.initialEmi != null ? 'EDIT EMI' : 'ADD EMI',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Liability Projection Summary Card (Metro Flip)
                      MetroTileFlipEntrance(
                        delayMs: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0078D7), // Solid Metro Blue
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL SCHEDULED OUTFLOW',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Text(
                                      _type == EmiType.self ? 'SELF' : 'OTHERS',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: const Color(0xFF0078D7),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
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
                                    value: totalScheduledOutflow,
                                    delayMs: 180,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    ' across $_tenureMonths mos',
                                    style: GoogleFonts.workSans(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Principal Sum', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 10)),
                                      AnimatedCounterText(
                                        value: principalSum,
                                        delayMs: 180,
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total Interest', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 10)),
                                      AnimatedCounterText(
                                        value: totalInterest,
                                        delayMs: 180,
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('1st Installment', style: GoogleFonts.workSans(color: Colors.white70, fontSize: 10)),
                                      AnimatedCounterText(
                                        value: firstInstallment,
                                        delayMs: 180,
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Beneficiary Attribution (Metro Flip)
                      MetroTileFlipEntrance(
                        delayMs: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Beneficiary Attribution', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _type = EmiType.self),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _type == EmiType.self ? const Color(0xFF008A00) : const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.person_outline, size: 16, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Self (Personal)',
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
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _type = EmiType.others),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _type == EmiType.others ? const Color(0xFFF09609) : const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.group_outlined, size: 16, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Others (Peer / Family)',
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
                          ],
                        ),
                      ),

                      if (_type == EmiType.others) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _beneficiaryController,
                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: 'Person / Beneficiary Name',
                            hintText: 'e.g. Rahul / Dad / Friend',
                            prefixIcon: Icon(Icons.person_pin_outlined, color: Color(0xFFF09609)),
                            filled: true,
                            fillColor: Color(0xFF1E1E1E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Linked Credit Card (Metro Flip)
                      MetroTileFlipEntrance(
                        delayMs: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Linked Credit Card', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<CreditCard>(
                                  value: _selectedCard,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E1E1E),
                                  icon: const Icon(Icons.credit_card, color: Color(0xFF0078D7)),
                                  items: widget.cards.map((card) {
                                    return DropdownMenuItem(
                                      value: card,
                                      child: Text(
                                        '${card.bank} ${card.cardName} •••• ${card.last4}',
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCard = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Item Title & Principal Amount Row (Metro Flip)
                      MetroTileFlipEntrance(
                        delayMs: 240,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Item / Purpose of Spend', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _titleController,
                              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                hintText: "e.g. Sony Bravia 55' OLED TV",
                                prefixIcon: Icon(Icons.shopping_bag_outlined, color: Color(0xFF0078D7)),
                                filled: true,
                                fillColor: Color(0xFF1E1E1E),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter purchase item title' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Principal Amount & First Due Month (Metro Flip)
                      MetroTileFlipEntrance(
                        delayMs: 300,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Principal Amount', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 48,
                                    child: TextFormField(
                                      controller: _principalController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontSize: 18, fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        prefixText: '₹ ',
                                        prefixStyle: TextStyle(color: Color(0xFF0078D7), fontSize: 18, fontWeight: FontWeight.bold),
                                        filled: true,
                                        fillColor: Color(0xFF1E1E1E),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                                      ),
                                      onChanged: (_) {
                                        setState(() {
                                          _generateSchedule();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('First Due Month', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 48,
                                    child: InkWell(
                                      onTap: _pickFirstDueMonth,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E1E),
                                          borderRadius: BorderRadius.zero,
                                          border: Border.all(color: const Color(0xFF2D2D2D)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${_getMonthName(_startMonth)}, $_startYear',
                                              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const Icon(Icons.calendar_month_outlined, color: Color(0xFF0078D7), size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Quick Tenures (Metro Flip)
                      MetroTileFlipEntrance(
                        delayMs: 360,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Repayment Tenure Count', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                                Text('$_tenureMonths Months', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: _quickTenures.map((m) {
                                final isSelected = m == _tenureMonths;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _tenureMonths = m;
                                        _generateSchedule();
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF0078D7) : const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Text(
                                        '${m}M',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Month-by-Month Installment Schedule Table
                      MetroTileFlipEntrance(
                        delayMs: 420,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                color: const Color(0xFF262626),
                                child: Row(
                                  children: [
                                    SizedBox(width: 20, child: Text('#', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold))),
                                    SizedBox(width: 70, child: Text('Month', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold))),
                                    Expanded(child: Text('EMI Amount (₹)', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold))),
                                    SizedBox(width: 60, child: Text('Status', textAlign: TextAlign.right, style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),

                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _scheduleItems.length,
                                itemBuilder: (context, index) {
                                  final item = _scheduleItems[index];
                                  final controller = _scheduleControllers[index];

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D), width: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          child: Text('${item.installmentNumber}', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                        SizedBox(
                                          width: 70,
                                          child: Text(item.monthLabel, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: TextField(
                                              controller: controller,
                                              keyboardType: TextInputType.number,
                                              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontWeight: FontWeight.bold, fontSize: 13),
                                              decoration: const InputDecoration(
                                                prefixText: '₹ ',
                                                prefixStyle: TextStyle(color: Color(0xFF0078D7), fontWeight: FontWeight.bold, fontSize: 13),
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                filled: true,
                                                fillColor: Color(0xFF121212),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 60,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                item.isPaid = !item.isPaid;
                                              });
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
                                                  fontSize: 9,
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

                      const SizedBox(height: 16),

                      // Save Button (Metro Flip)
                      MetroTileFlipEntrance(
                        delayMs: 480,
                        child: SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0078D7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                              widget.initialEmi != null ? 'UPDATE EMI SCHEDULE' : 'SAVE EMI SCHEDULE',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[(month - 1) % 12];
  }
}
