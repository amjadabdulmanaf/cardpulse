import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../services/cycle_calculator.dart';
import '../utils/formatters.dart';

class CreditCardWidget extends StatelessWidget {
  final CreditCard card;
  final double totalSpend; // Combined regular + EMI for current cycle
  final VoidCallback? onTap;
  final VoidCallback? onAddEmi;
  final VoidCallback? onAddTransaction;

  const CreditCardWidget({
    super.key,
    required this.card,
    required this.totalSpend,
    this.onTap,
    this.onAddEmi,
    this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final cycle = CycleCalculator.getBillingCycle(card);
    final limit = card.monthlyLimit;
    final progress = limit > 0 ? (totalSpend / limit).clamp(0.0, 1.0) : 0.0;
    final isOverLimit = limit > 0 && totalSpend > limit;
    final gradientColors = Formatters.getCardGradient(card.colorIndex);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Bank Name, Card Name & Reset Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.bank.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            card.cardName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Cycle Reset Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history,
                            color: Colors.amberAccent,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cycle.daysRemaining == 0
                                ? 'Resets Today'
                                : 'Reset in ${cycle.daysRemaining}d',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Middle Row: Chip & Masked Card Number
                Row(
                  children: [
                    // Metallic Chip Icon
                    Container(
                      width: 36,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDE047), Color(0xFFCA8A04)],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Container(
                          width: 28,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black26,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '•••• •••• •••• ${card.last4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Cycle Range Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cycle: ${Formatters.formatDateShort(cycle.startDate)} - ${Formatters.formatDateShort(cycle.endDate)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isOverLimit ? 'EXCEEDED LIMIT' : '${(progress * 100).toStringAsFixed(0)}% Used',
                      style: TextStyle(
                        color: isOverLimit ? Colors.redAccent : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Limit Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverLimit
                          ? Colors.redAccent
                          : progress > 0.85
                              ? Colors.orangeAccent
                              : const Color(0xFF34D399),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Spend vs Limit Numbers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Cycle Spend: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: Formatters.formatCurrency(totalSpend),
                            style: TextStyle(
                              color: isOverLimit
                                  ? Colors.redAccent
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Limit: ${Formatters.formatCurrency(limit)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Action Buttons inside Card
                if (onAddEmi != null || onAddTransaction != null) ...[
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onAddEmi != null)
                        TextButton.icon(
                          onPressed: onAddEmi,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add_card, size: 14),
                          label: const Text(
                            '+ EMI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (onAddEmi != null && onAddTransaction != null)
                        const SizedBox(width: 8),
                      if (onAddTransaction != null)
                        TextButton.icon(
                          onPressed: onAddTransaction,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text(
                            '+ Spend',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
