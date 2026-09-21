import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final DateTime timestamp;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.timestamp,
  });
}

class NotificationsHelper {
  static List<AppNotificationItem> generateNotifications({
    required List<CreditCard> cards,
    required List<TransactionItem> transactions,
    required List<EmiItem> emis,
    List<String> dismissedIds = const [],
    double thresholdPercent = 80.0,
  }) {
    final List<AppNotificationItem> notifications = [];
    final now = DateTime.now();

    for (final card in cards) {
      final cycle = CycleCalculator.getBillingCycle(card);
      final totalSpend = CycleCalculator.getTotalCycleSpend(card, transactions, emis, cycle: cycle);
      final percentVal = card.monthlyLimit > 0 ? (totalSpend / card.monthlyLimit) * 100 : 0.0;

      // 1. Limit Exceeded or Threshold Alert
      if (card.monthlyLimit > 0 && totalSpend > card.monthlyLimit) {
        final id = 'limit_exceeded_${card.id}';
        if (!dismissedIds.contains(id)) {
          notifications.add(AppNotificationItem(
            id: id,
            title: '${card.bank} ${card.cardName}: Limit Exceeded!',
            subtitle: 'Spent ${Formatters.formatCurrency(totalSpend)} of ${Formatters.formatCurrency(card.monthlyLimit)} limit (${percentVal.toStringAsFixed(0)}% utilized).',
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            timestamp: now,
          ));
        }
      } else if (card.monthlyLimit > 0 && percentVal >= thresholdPercent) {
        final id = 'limit_alert_${card.id}';
        if (!dismissedIds.contains(id)) {
          notifications.add(AppNotificationItem(
            id: id,
            title: '${card.bank} ${card.cardName}: Spend Limit Alert',
            subtitle: 'Spent ${Formatters.formatCurrency(totalSpend)} (${percentVal.toStringAsFixed(0)}% of ${Formatters.formatCurrency(card.monthlyLimit)} threshold).',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFFBBF24),
            timestamp: now,
          ));
        }
      }

      // 2. Cycle Reset / Bill Generation Alert
      if (cycle.daysRemaining <= 5) {
        final id = 'reset_alert_${card.id}';
        if (!dismissedIds.contains(id)) {
          notifications.add(AppNotificationItem(
            id: id,
            title: '${card.bank} ${card.cardName}: Bill Statement Reset',
            subtitle: 'Statement generates in ${cycle.daysRemaining} days on ${Formatters.formatDateShort(cycle.nextResetDate)}.',
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFF38BDF8),
            timestamp: now,
          ));
        }
      }
    }

    // 3. EMI Alerts (Triggers for all active EMIs, whether Paid or Due)
    for (final emi in emis) {
      final currentMonthAmt = emi.getAmountForDate(now);
      if (currentMonthAmt > 0) {
        EmiScheduleItem? scheduleItem;
        try {
          scheduleItem = emi.schedule.firstWhere((s) => s.year == now.year && s.month == now.month);
        } catch (_) {
          if (emi.schedule.isNotEmpty) scheduleItem = emi.schedule.first;
        }

        final isPaid = scheduleItem?.isPaid ?? false;
        final beneficiaryStr = emi.type == EmiType.others ? (emi.beneficiaryName ?? "Others") : "Self";
        final monthLabel = scheduleItem?.monthLabel ?? "current";
        final id = 'emi_notif_${emi.id}_$monthLabel';

        if (!dismissedIds.contains(id)) {
          notifications.add(AppNotificationItem(
            id: id,
            title: emi.type == EmiType.others
                ? 'Reimbursement ${isPaid ? "Collected" : "Pending"} from $beneficiaryStr'
                : 'EMI Installment ${isPaid ? "Paid" : "Due"} for "${emi.title}"',
            subtitle: '${Formatters.formatCurrency(currentMonthAmt)} ${isPaid ? "paid" : "due"} for "${emi.title}" this cycle (${isPaid ? "Paid" : "Unpaid"}).',
            icon: isPaid ? Icons.check_circle_outline : Icons.person_pin_outlined,
            iconColor: isPaid ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
            timestamp: now,
          ));
        }
      }
    }

    return notifications;
  }

  static void showNotificationsSheet({
    required BuildContext context,
    StorageService? storageService,
    required List<CreditCard> cards,
    required List<TransactionItem> transactions,
    required List<EmiItem> emis,
    double thresholdPercent = 80.0,
  }) async {
    final initialDismissed = storageService != null
        ? await storageService.getDismissedNotifications()
        : <String>[];
    final localDismissed = Set<String>.from(initialDismissed);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final notifications = generateNotifications(
            cards: cards,
            transactions: transactions,
            emis: emis,
            dismissedIds: localDismissed.toList(),
            thresholdPercent: thresholdPercent,
          );

          return Container(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_outlined, color: Color(0xFF34D399), size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Notifications & Alerts',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${notifications.length}',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (notifications.isNotEmpty)
                            TextButton(
                              onPressed: () async {
                                final idsToClear = notifications.map((n) => n.id).toList();
                                setSheetState(() {
                                  localDismissed.addAll(idsToClear);
                                });
                                await storageService?.clearAllNotifications(idsToClear);
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (notifications.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 36),
                          SizedBox(height: 8),
                          Text('No Active Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('All alerts cleared or card budgets healthy.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF222F46)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: item.iconColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(item.icon, color: item.iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.subtitle,
                                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                                onPressed: () async {
                                  setSheetState(() {
                                    localDismissed.add(item.id);
                                  });
                                  await storageService?.dismissNotification(item.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
