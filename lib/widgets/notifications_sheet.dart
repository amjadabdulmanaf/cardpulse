import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final Color badgeBg;
  final DateTime timestamp;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.badgeBg,
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
    bool enableCycleResetAlert = true,
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
            icon: Icons.error_outline_rounded,
            iconColor: Colors.white,
            badgeBg: const Color(0xFFB91C1C), // Solid Red
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
            iconColor: Colors.white,
            badgeBg: const Color(0xFFB45309), // Solid Amber
            timestamp: now,
          ));
        }
      }

      // 2. Cycle Reset / Bill Generation Alert
      if (enableCycleResetAlert && cycle.daysRemaining <= 5) {
        final id = 'reset_alert_${card.id}';
        if (!dismissedIds.contains(id)) {
          notifications.add(AppNotificationItem(
            id: id,
            title: '${card.bank} ${card.cardName}: Bill Statement Reset',
            subtitle: 'Statement generates in ${cycle.daysRemaining} days on ${Formatters.formatDateShort(cycle.nextResetDate)}.',
            icon: Icons.calendar_month_outlined,
            iconColor: Colors.white,
            badgeBg: const Color(0xFF0078D7), // Solid Metro Blue
            timestamp: now,
          ));
        }
      }
    }

    // 3. EMI Alerts
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
            icon: isPaid ? Icons.check_circle_outline : Icons.schedule_outlined,
            iconColor: Colors.white,
            badgeBg: isPaid ? const Color(0xFF008A00) : const Color(0xFF0078D7), // Metro Green vs Blue
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
    double? thresholdPercent,
    bool? enableCycleResetAlert,
  }) async {
    final initialDismissed = storageService != null
        ? await storageService.getDismissedNotifications()
        : <String>[];
    final localDismissed = Set<String>.from(initialDismissed);

    double activeThreshold = thresholdPercent ?? (storageService != null ? await storageService.getAlertThreshold() : 80.0);
    bool activeResetAlert = enableCycleResetAlert ?? (storageService != null ? await storageService.getCycleResetAlert() : true);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final notifications = generateNotifications(
            cards: cards,
            transactions: transactions,
            emis: emis,
            dismissedIds: localDismissed.toList(),
            thresholdPercent: activeThreshold,
            enableCycleResetAlert: activeResetAlert,
          );

          return Container(
            padding: EdgeInsets.only(
              top: 14,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).padding.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF121212), // Metro Obsidian Background
              borderRadius: BorderRadius.zero, // Windows Phone Sharp Edge
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed Metro Top Header
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
                          child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'NOTIFICATIONS & ALERTS',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF262626),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            '${notifications.length}',
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFF0078D7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Scrollable Notifications List Under Fixed Header
                Flexible(
                  child: SingleChildScrollView(
                    child: notifications.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF008A00), size: 36),
                                const SizedBox(height: 8),
                                Text(
                                  'No Active Notifications',
                                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All alerts cleared or card budgets healthy.',
                                  style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                        final item = notifications[index];

                        return CurtainFallNotificationItem(
                          index: index,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                color: const Color(0xFFB91C1C), // Solid Red Swipe
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.centerLeft,
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 6),
                                    Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                color: const Color(0xFFB91C1C),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.centerRight,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                    SizedBox(width: 6),
                                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                              onDismissed: (direction) async {
                                setSheetState(() {
                                  localDismissed.add(item.id);
                                });
                                await storageService?.dismissNotification(item.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E1E1E), // Metro Solid Card
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: item.badgeBg,
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Icon(item.icon, color: item.iconColor, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item.subtitle,
                                            style: GoogleFonts.workSans(
                                              color: const Color(0xFFA0A0A0),
                                              fontSize: 11,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Windows 8 Metro Curtain Fall Entrance Animation for Notification Tiles
class CurtainFallNotificationItem extends StatefulWidget {
  final Widget child;
  final int index;

  const CurtainFallNotificationItem({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<CurtainFallNotificationItem> createState() => _CurtainFallNotificationItemState();
}

class _CurtainFallNotificationItemState extends State<CurtainFallNotificationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.4), // Curtain fall down from top
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    final delay = (widget.index * 70) + 50; // Staggered curtain fall delay
    _timer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}
