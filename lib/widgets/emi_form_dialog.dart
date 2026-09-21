import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../utils/formatters.dart';

class EmiFormDialog extends StatefulWidget {
  final List<CreditCard> cards;
  final CreditCard? initialCard;
  final Function(EmiItem) onSave;

  const EmiFormDialog({
    super.key,
    required this.cards,
    this.initialCard,
    required this.onSave,
  });

  @override
  State<EmiFormDialog> createState() => _EmiFormDialogState();
}

class _EmiFormDialogState extends State<EmiFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late CreditCard _selectedCard;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _beneficiaryController = TextEditingController();

  EmiType _type = EmiType.self;
  int _tenureMonths = 6;
  final int _startYear = DateTime.now().year;
  int _startMonth = DateTime.now().month;

  final List<TextEditingController> _scheduleControllers = [];
  List<EmiScheduleItem> _scheduleItems = [];

  @override
  void initState() {
    super.initState();
    _selectedCard = widget.initialCard ?? widget.cards.first;
    _totalAmountController.text = '10072';
    _titleController.text = 'Gadget Purchase';
    _generateSchedule();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalAmountController.dispose();
    _beneficiaryController.dispose();
    for (final controller in _scheduleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _generateSchedule() {
    // Dispose previous controllers
    for (final controller in _scheduleControllers) {
      controller.dispose();
    }
    _scheduleControllers.clear();

    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    final defaultMonthlyAmount = _tenureMonths > 0 ? (totalAmount / _tenureMonths) : 0.0;

    final List<EmiScheduleItem> items = [];

    for (int i = 0; i < _tenureMonths; i++) {
      int month = _startMonth + i;
      int year = _startYear;
      while (month > 12) {
        month -= 12;
        year += 1;
      }

      final monthLabel = Formatters.formatMonthLabel(year, month);
      final roundedAmount = defaultMonthlyAmount.roundToDouble();

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
        setState(() {}); // refresh total sum
      });
      _scheduleControllers.add(controller);
    }

    _scheduleItems = items;
  }

  double get _calculatedScheduleTotal {
    double total = 0.0;
    for (var i = 0; i < _scheduleItems.length; i++) {
      final textVal = double.tryParse(_scheduleControllers[i].text) ?? 0.0;
      total += textVal;
    }
    return total;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final double totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;

    // Update schedule items with controller values
    for (int i = 0; i < _scheduleItems.length; i++) {
      final amt = double.tryParse(_scheduleControllers[i].text) ?? 0.0;
      _scheduleItems[i].amount = amt;
    }

    final emi = EmiItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardId: _selectedCard.id,
      title: _titleController.text.trim(),
      totalAmount: totalAmount,
      type: _type,
      beneficiaryName: _type == EmiType.others ? _beneficiaryController.text.trim() : null,
      schedule: _scheduleItems,
    );

    widget.onSave(emi);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.table_chart_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add EMI Schedule',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Selector Dropdown
                      DropdownButtonFormField<CreditCard>(
                        initialValue: _selectedCard,
                        decoration: const InputDecoration(
                          labelText: 'Select Credit Card',
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(),
                        ),
                        items: widget.cards.map((card) {
                          return DropdownMenuItem(
                            value: card,
                            child: Text('${card.cardName} (${card.bank} •• ${card.last4})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCard = val;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // Title & Total Amount Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Item / EMI Title',
                                hintText: 'e.g. iPhone 15',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty
                                  ? 'Enter EMI title'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _totalAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total (₹)',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _generateSchedule();
                                });
                              },
                              validator: (val) =>
                                  val == null || double.tryParse(val) == null
                                      ? 'Valid amount'
                                      : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Self vs Others Toggle Option
                      Text(
                        'EMI For:',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<EmiType>(
                        segments: const [
                          ButtonSegment(
                            value: EmiType.self,
                            label: Text('Self'),
                            icon: Icon(Icons.person),
                          ),
                          ButtonSegment(
                            value: EmiType.others,
                            label: Text('Others'),
                            icon: Icon(Icons.group),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (set) {
                          setState(() {
                            _type = set.first;
                          });
                        },
                      ),

                      if (_type == EmiType.others) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _beneficiaryController,
                          decoration: const InputDecoration(
                            labelText: 'Person Name / Beneficiary',
                            hintText: 'e.g. Rahul / Dad / Friend',
                            prefixIcon: Icon(Icons.person_pin),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => _type == EmiType.others &&
                                  (val == null || val.trim().isEmpty)
                              ? 'Enter person name'
                              : null,
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Tenure (Months) & Start Month Selectors
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _tenureMonths,
                              decoration: const InputDecoration(
                                labelText: 'Tenure (Months)',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(36, (i) => i + 1).map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text('$m Months'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _tenureMonths = val;
                                    _generateSchedule();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _startMonth,
                              decoration: const InputDecoration(
                                labelText: 'Start Month',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(12, (i) => i + 1).map((m) {
                                final label = Formatters.formatMonthLabel(_startYear, m);
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _startMonth = val;
                                    _generateSchedule();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // EMI Schedule Entry Table (Exact match to reference image!)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly Schedule Table',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          Text(
                            'Total: ${Formatters.formatCurrency(_calculatedScheduleTotal)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _calculatedScheduleTotal ==
                                      (double.tryParse(_totalAmountController.text) ?? 0.0)
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Table Container
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(2.5),
                            2: FlexColumnWidth(3),
                          },
                          border: TableBorder.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          children: [
                            // Table Header Row
                            TableRow(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  child: Text(
                                    '#',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  child: Text(
                                    'Month',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  child: Text(
                                    'EMI (₹)',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),

                            // Dynamic Schedule Rows (Matching Image format!)
                            ...List.generate(_scheduleItems.length, (index) {
                              final item = _scheduleItems[index];
                              final controller = _scheduleControllers[index];

                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      '${item.installmentNumber}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      item.monthLabel,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text(
                    'Save EMI Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
