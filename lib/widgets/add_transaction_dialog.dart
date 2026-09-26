import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../widgets/metro_tile_flip_entrance.dart';

class AddTransactionSheet extends StatefulWidget {
  final List<CreditCard> cards;
  final CreditCard? initialCard;
  final Function(TransactionItem) onSave;

  const AddTransactionSheet({
    super.key,
    required this.cards,
    this.initialCard,
    required this.onSave,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();

  late CreditCard _selectedCard;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _category = 'Shopping';

  final List<String> _categories = [
    'Shopping',
    'Dining',
    'Grocery',
    'Bills & Utilities',
    'Fuel',
    'Travel',
    'Entertainment',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCard = widget.initialCard ?? widget.cards.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final tx = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardId: _selectedCard.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      category: _category,
    );

    widget.onSave(tx);
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
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0078D7), // Solid Metro Blue
                          borderRadius: BorderRadius.zero,
                        ),
                        child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ADD SPEND TRANSACTION',
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

              // Card Selector (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Credit Card', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
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
                                '${card.bank} ${card.cardName} (••${card.last4})',
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

              // Merchant / Description (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Merchant / Description', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Amazon, Swiggy, Fuel Station',
                        hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                        prefixIcon: Icon(Icons.store_outlined, color: Color(0xFF0078D7)),
                        filled: true,
                        fillColor: Color(0xFF1E1E1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter merchant name' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Amount & Category Row (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount (₹)', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 48,
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontSize: 16, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: TextStyle(color: Color(0xFF0078D7), fontSize: 16, fontWeight: FontWeight.bold),
                                hintText: '250',
                                filled: true,
                                fillColor: Color(0xFF1E1E1E),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
                              ),
                              validator: (v) =>
                                  v == null || double.tryParse(v) == null ? 'Valid amount' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 48,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: const Color(0xFF2D2D2D)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _category,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E1E1E),
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0078D7)),
                                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _category = val);
                                  },
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

              // Date Picker (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaction Date', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Formatters.formatDate(_selectedDate),
                              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.calendar_today_outlined, color: Color(0xFF0078D7), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Save Button (Metro Flip)
              MetroTileFlipEntrance(
                delayMs: 300,
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
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'SAVE SPEND TRANSACTION',
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
}
