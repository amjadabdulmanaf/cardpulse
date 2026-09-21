import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../utils/formatters.dart';

class AddCardSheet extends StatefulWidget {
  final CreditCard? initialCard;
  final Function(CreditCard) onSave;

  const AddCardSheet({
    super.key,
    this.initialCard,
    required this.onSave,
  });

  @override
  State<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<AddCardSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bankController;
  late TextEditingController _last4Controller;
  late TextEditingController _limitController;

  int _billGenerationDay = 15;
  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCard?.cardName ?? '');
    _bankController = TextEditingController(text: widget.initialCard?.bank ?? '');
    _last4Controller = TextEditingController(text: widget.initialCard?.last4 ?? '');
    _limitController = TextEditingController(
      text: widget.initialCard?.monthlyLimit != null
          ? widget.initialCard!.monthlyLimit.toInt().toString()
          : '50000',
    );
    _billGenerationDay = widget.initialCard?.billGenerationDay ?? 15;
    _colorIndex = widget.initialCard?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _last4Controller.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final card = CreditCard(
      id: widget.initialCard?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      cardName: _nameController.text.trim(),
      bank: _bankController.text.trim(),
      last4: _last4Controller.text.trim(),
      monthlyLimit: double.tryParse(_limitController.text.trim()) ?? 50000,
      billGenerationDay: _billGenerationDay,
      colorIndex: _colorIndex,
    );

    widget.onSave(card);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161F30), // Dark Slate
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom Sheet Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222F46),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_card, color: Color(0xFF34D399), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        widget.initialCard != null ? 'Edit Credit Card' : 'Add Credit Card',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bank Name
              const Text('Bank Name', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bankController,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g. HDFC Bank, SBI Card, ICICI',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.account_balance, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF222F46)),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter bank name' : null,
              ),
              const SizedBox(height: 12),

              // Card Variant Name & Last 4 Digits
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Card Nickname / Variant', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. Regalia Gold',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                            prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF9CA3AF)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF222F46)),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter card name' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Last 4 Digits', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _last4Controller,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                          decoration: InputDecoration(
                            hintText: '4321',
                            counterText: '',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF222F46)),
                            ),
                          ),
                          validator: (v) => v == null || v.length != 4 ? '4 digits' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Monthly Spend Limit
              const Text('Monthly Spend Limit (₹)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.bold),
                  hintText: '50000',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF222F46)),
                  ),
                ),
                validator: (v) =>
                    v == null || double.tryParse(v) == null ? 'Enter valid limit' : null,
              ),
              const SizedBox(height: 14),

              // Bill Generation Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bill Generation Date', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('Day $_billGenerationDay of month', style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF222F46)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF9CA3AF), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Statement generates on $_billGenerationDay${_getDaySuffix(_billGenerationDay)} of every month',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _billGenerationDay,
                        dropdownColor: const Color(0xFF161F30),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF34D399)),
                        style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                        items: List.generate(31, (i) => i + 1).map((day) {
                          return DropdownMenuItem(
                            value: day,
                            child: Text('$day${_getDaySuffix(day)}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _billGenerationDay = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Color Theme Selector
              const Text('Card Theme Gradient', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(Formatters.cardGradients.length, (index) {
                  final colors = Formatters.cardGradients[index];
                  final isSelected = index == _colorIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _colorIndex = index;
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: colors),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Security Green Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF34D399), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stored strictly offline in encrypted local device storage',
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF34D399), // Mint Green
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    widget.initialCard != null ? 'Update Card' : 'Save Credit Card',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
