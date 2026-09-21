import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/sms_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../widgets/notifications_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final List<CreditCard> cards;
  final List<TransactionItem> transactions;
  final List<EmiItem> emis;
  final VoidCallback onScanSms;
  final Future<void> Function() onReloadData;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.cards,
    required this.transactions,
    required this.emis,
    required this.onScanSms,
    required this.onReloadData,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasSmsPermission = false;
  bool _autoReadSms = true;
  double _alertThreshold = 80;
  bool _cycleResetAlert = true;
  String _appVersion = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${info.version}';
        });
      }
    } catch (_) {}
  }

  Future<void> _checkPermission() async {
    final status = await SmsService.hasPermission();
    final autoReadSetting = await widget.storageService.getAutoReadSms();
    setState(() {
      _hasSmsPermission = status;
      _autoReadSms = autoReadSetting;
    });
  }

  Future<void> _handleFlushCache() async {
    await widget.storageService.flushCache();
    await widget.onReloadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction cache cleared successfully.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _handlePurgeVault() async {
    await widget.storageService.purgeVault();
    await widget.onReloadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All local app data cleared.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleExportBackup() async {
    final jsonStr = await widget.storageService.exportBackupJson();
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export Encrypted Backup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              const Text('Copy or save this encrypted JSON payload locally:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(color: Color(0xFF34D399), fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF34D399),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Backup Payload', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup payload copied to clipboard!'), backgroundColor: Color(0xFF10B981)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleRestoreBackup() async {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF161F30),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Restore from Backup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            const Text('Paste your JSON backup payload below:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Paste backup JSON here...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF34D399),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Restore Data Now', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    final ok = await widget.storageService.restoreBackupJson(text);
                    if (ok) {
                      await widget.onReloadData();
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data restored successfully!'), backgroundColor: Color(0xFF10B981)),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid backup JSON payload.'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExportCsv() async {
    final txs = await widget.storageService.getTransactions();
    final emis = await widget.storageService.getEmis();

    final buffer = StringBuffer();
    buffer.writeln('Type,Title,Amount,Date,Category,Attribution');

    for (final tx in txs) {
      final attr = tx.isOthersSpend ? 'Others (${tx.personName ?? "Peer"})' : 'Self';
      buffer.writeln('Regular Spend,"${tx.title}",${tx.amount},"${Formatters.formatDate(tx.date)}","${tx.category}","$attr"');
    }

    for (final emi in emis) {
      final attr = emi.type == EmiType.self ? 'Self' : 'Others (${emi.beneficiaryName ?? "Peer"})';
      buffer.writeln('EMI,"${emi.title}",${emi.totalAmount},"","EMI","$attr"');
    }

    final csvStr = buffer.toString();

    if (mounted) {
      Clipboard.setData(ClipboardData(text: csvStr));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statement CSV copied to clipboard! Ready to paste into Excel or Google Sheets.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationsHelper.generateNotifications(
      cards: widget.cards,
      transactions: widget.transactions,
      emis: widget.emis,
      thresholdPercent: _alertThreshold,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.credit_score,
                color: Color(0xFF34D399),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CardPulse',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                onPressed: () {
                  NotificationsHelper.showNotificationsSheet(
                    context: context,
                    cards: widget.cards,
                    transactions: widget.transactions,
                    emis: widget.emis,
                    thresholdPercent: _alertThreshold,
                  );
                },
              ),
              if (notifications.isNotEmpty)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings & Preferences',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'App preferences & SMS parsing engine',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF222F46)),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 18),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 1. SMS PARSING ENGINE Section
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SMS PARSING ENGINE',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF222F46)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto-read Bank SMS Toggle
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Color(0xFF34D399), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Auto-read Bank SMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Instant local regex capture from inbox', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _autoReadSms,
                        activeTrackColor: const Color(0xFF34D399),
                        onChanged: (v) async {
                          setState(() => _autoReadSms = v);
                          await widget.storageService.setAutoReadSms(v);
                          if (v) {
                            if (!_hasSmsPermission) {
                              await SmsService.requestPermission();
                              await _checkPermission();
                            }
                            await widget.onReloadData();
                          } else {
                            await widget.onReloadData();
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Scan Past 30 Days Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: widget.onScanSms,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF222F46)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.sync, size: 16, color: Color(0xFF34D399)),
                      label: const Text('Scan Past 30 Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. CYCLE & SPEND THRESHOLDS Section
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CYCLE & SPEND THRESHOLDS',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                Text('Active Guardrails', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF222F46)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cycle Limit Alert Threshold', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Triggers notification when limit is close', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${_alertThreshold.toInt()}%', style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  Slider(
                    value: _alertThreshold,
                    min: 40,
                    max: 95,
                    divisions: 11,
                    activeColor: const Color(0xFFFBBF24),
                    inactiveColor: const Color(0xFF0F172A),
                    onChanged: (v) => setState(() => _alertThreshold = v),
                  ),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('40% (Conservative)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                      Text('80% (Recommended)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                      Text('95% (Peak)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFF222F46), height: 1),
                  const SizedBox(height: 12),

                  // Cycle Reset Alert
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cycle Reset Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Notify on statement generation & billing rollover', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _cycleResetAlert,
                        activeTrackColor: const Color(0xFF34D399),
                        onChanged: (v) => setState(() => _cycleResetAlert = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. DATA VAULT & EXPORT Section
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DATA VAULT & EXPORT',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF222F46)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _handleExportBackup,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF222F46)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.sync, size: 16, color: Color(0xFF34D399)),
                      label: const Text('Export Backup Payload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _handleRestoreBackup,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF222F46)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.upload_outlined, size: 16, color: Color(0xFFFBBF24)),
                      label: const Text('Restore from Backup Payload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _handleExportCsv,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF222F46)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Export Statement CSV for Spreadsheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. RESET & PURGE Section
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RESET & PURGE',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF222F46)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Clear Transaction Cache', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 2),
                            Text('Wipe parsed SMS data (re-parsable at any time)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: _handleFlushCache,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF111827),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF222F46)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Flush Cache', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF222F46), height: 1),
                  const SizedBox(height: 14),

                  const Text('Erase All Cards & Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  const Text('Unrecoverable without a backup payload.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
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
                                const Text('Purge Vault & All Data?', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                const Text('Are you sure you want to purge all local cards, transactions, and EMI data? This cannot be undone.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                                        child: const Text('Purge Vault', style: TextStyle(fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          _handlePurgeVault();
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
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626), // Red
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.disabled_by_default_outlined, size: 18),
                      label: const Text('Purge All Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Bottom Footer
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.credit_score, color: Color(0xFF34D399), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'CardPulse $_appVersion',
                        style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'CardPulse Spend Analytics Engine',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
