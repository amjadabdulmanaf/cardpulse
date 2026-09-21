import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;
  final CreditCard? card;
  final EmiItem? linkedEmi;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.card,
    this.linkedEmi,
    this.onDelete,
  });

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
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
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Delete Transaction?',
              style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to delete "${transaction.title}" (${Formatters.formatCurrency(transaction.amount)})?',
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
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmi = transaction.isEmi;
    final emiType = linkedEmi?.type;
    final beneficiary = linkedEmi?.beneficiaryName;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmi
              ? Colors.purple.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          width: isEmi ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEmi
                  ? Colors.purple.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEmi ? Icons.table_chart : Icons.shopping_bag_outlined,
              color: isEmi ? Colors.purpleAccent : Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isEmi) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'EMI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    if (card != null) ...[
                      Text(
                        '${card!.cardName} (••${card!.last4})',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      Formatters.formatDateShort(transaction.date),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // Self vs Others EMI Tag
                if (isEmi && emiType != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: emiType == EmiType.self
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: emiType == EmiType.self
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          emiType == EmiType.self ? Icons.person : Icons.group,
                          size: 11,
                          color: emiType == EmiType.self ? Colors.blue : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          emiType == EmiType.self
                              ? 'Self Purchase'
                              : 'For: ${beneficiary ?? "Others"}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: emiType == EmiType.self ? Colors.blue : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Amount & Delete Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatCurrency(transaction.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isEmi ? Colors.purpleAccent : null,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _confirmDelete(context),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
