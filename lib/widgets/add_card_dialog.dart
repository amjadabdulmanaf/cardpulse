import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../widgets/metro_tile_flip_entrance.dart';

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
      colorIndex: 0,
    );

    widget.onSave(card);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF121212), // Metro Obsidian Background
        borderRadius: BorderRadius.zero, // Windows Phone Sharp Edge
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0078D7),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: const Icon(Icons.credit_card, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.initialCard != null ? 'EDIT CREDIT CARD' : 'ADD CREDIT CARD',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bank Name (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank Name', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _bankController,
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'e.g. HDFC Bank, SBI Card, ICICI',
                        hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                        prefixIcon: Icon(Icons.account_balance_outlined, color: Color(0xFF0078D7)),
                        filled: true,
                        fillColor: Color(0xFF1E1E1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter bank name' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Card Variant Name & Last 4 Digits (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 80,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Card Nickname / Variant', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: 'e.g. Regalia Gold',
                              hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                              prefixIcon: Icon(Icons.credit_card_outlined, color: Color(0xFF0078D7)),
                              filled: true,
                              fillColor: Color(0xFF1E1E1E),
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter card name' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last 4 Digits', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _last4Controller,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                            decoration: const InputDecoration(
                              hintText: '4321',
                              counterText: '',
                              hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                              filled: true,
                              fillColor: Color(0xFF1E1E1E),
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                            ),
                            validator: (v) => v == null || v.length != 4 ? '4 digits' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Monthly Spend Limit (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Spend Limit (₹)', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(color: Color(0xFF0078D7), fontSize: 18, fontWeight: FontWeight.bold),
                        hintText: '50000',
                        hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                        filled: true,
                        fillColor: Color(0xFF1E1E1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                      ),
                      validator: (v) =>
                          v == null || double.tryParse(v) == null ? 'Enter valid limit' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Bill Generation Date (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bill Generation Date', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('Day $_billGenerationDay of month', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, color: Color(0xFF0078D7), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Statement generates on $_billGenerationDay${_getDaySuffix(_billGenerationDay)} of month',
                              style: GoogleFonts.workSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _billGenerationDay,
                              dropdownColor: const Color(0xFF1E1E1E),
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0078D7)),
                              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Save Button (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 360,
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0078D7), // Solid Metro Blue
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      widget.initialCard != null ? 'UPDATE CREDIT CARD' : 'SAVE CREDIT CARD',
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
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
