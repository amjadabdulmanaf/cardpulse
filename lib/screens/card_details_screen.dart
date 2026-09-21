import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import '../utils/formatters.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/cycle_summary_card.dart';
import '../widgets/transaction_tile.dart';

class CardDetailsScreen extends StatefulWidget {
  final CreditCard card;
  final List<TransactionItem> transactions;
  final List<EmiItem> emis;
  final Function(CreditCard) onUpdateCard;
  final Function(String) onDeleteCard;
  final Function(String) onDeleteTransaction;

  const CardDetailsScreen({
    super.key,
    required this.card,
    required this.transactions,
    required this.emis,
    required this.onUpdateCard,
    required this.onDeleteCard,
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

    final cardTxs = _localTransactions.where((t) => t.cardId == _card.id).toList();
    final cardEmis = widget.emis.where((e) => e.cardId == _card.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_card.cardName} Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Card',
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
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
                    color: Color(0xFF161F30),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Delete Credit Card?',
                        style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Are you sure you want to delete ${_card.cardName}? Associated transactions and EMIs will also be removed.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF222F46)),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Delete Card', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.of(ctx).pop(); // sheet
                                Navigator.of(context).pop(); // screen
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Credit Card Preview Widget
            CreditCardWidget(
              card: _card,
              totalSpend: totalSpend,
            ),

            // Cycle Summary Card
            CycleSummaryCard(
              card: _card,
              transactions: _localTransactions,
              emis: widget.emis,
            ),

            const SizedBox(height: 12),

            // Active EMIs for this card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active EMIs (${cardEmis.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            if (cardEmis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('No EMIs linked to this credit card.',
                    style: TextStyle(color: Colors.grey)),
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

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  emi.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: emi.type == EmiType.self
                                        ? Colors.blue.withValues(alpha: 0.15)
                                        : Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    emi.type == EmiType.self
                                        ? 'Self'
                                        : 'For: ${emi.beneficiaryName ?? "Others"}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: emi.type == EmiType.self
                                          ? Colors.blue
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: ${Formatters.formatCurrency(emi.totalAmount)} (${emi.schedule.length} Months)',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatCurrency(currentMonthAmt),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purpleAccent,
                              ),
                            ),
                            const Text(
                              'This Cycle',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            // Card Transactions in Cycle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recent Card Spends (${cardTxs.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),

            if (cardTxs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('No manual or SMS spends logged for this card yet.',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cardTxs.length,
                itemBuilder: (context, index) {
                  final tx = cardTxs[index];
                  return TransactionTile(
                    transaction: tx,
                    card: _card,
                    onDelete: () => _handleDeleteTransaction(tx.id),
                  );
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
