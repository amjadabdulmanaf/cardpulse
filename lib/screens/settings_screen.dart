import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/sms_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../widgets/metro_card_pulse_logo.dart';
import '../widgets/metro_tile_flip_entrance.dart';
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
    final savedThreshold = await widget.storageService.getAlertThreshold();
    final savedResetAlert = await widget.storageService.getCycleResetAlert();

    if (mounted) {
      setState(() {
        _hasSmsPermission = status;
        _autoReadSms = autoReadSetting;
        _alertThreshold = savedThreshold;
        _cycleResetAlert = savedResetAlert;
      });
    }
  }

  void _confirmFlushCache() {
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
          color: Color(0xFF121212),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF09609), size: 36),
            const SizedBox(height: 10),
            Text(
              'FLUSH TRANSACTION CACHE?',
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF09609), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to clear the parsed SMS transaction cache? Raw SMS messages can be re-scanned at any time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2D2D2D)),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF09609),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text('Flush Cache', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.black)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _handleFlushCache();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFlushCache() async {
    await widget.storageService.flushCache();
    await widget.onReloadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction cache cleared successfully.', style: GoogleFonts.spaceGrotesk()),
          backgroundColor: const Color(0xFF008A00),
        ),
      );
    }
  }

  Future<void> _handlePurgeVault() async {
    await widget.storageService.purgeVault();
    await widget.onReloadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All local app data cleared.', style: GoogleFonts.spaceGrotesk()),
          backgroundColor: const Color(0xFFB91C1C),
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
            color: Color(0xFF121212),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EXPORT BACKUP PAYLOAD', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Text('Copy or save this encrypted JSON payload locally:', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.zero,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0078D7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text('COPY BACKUP PAYLOAD', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Backup payload copied to clipboard!', style: GoogleFonts.spaceGrotesk()), backgroundColor: const Color(0xFF008A00)),
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
          color: Color(0xFF121212),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RESTORE FROM BACKUP', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text('Paste your JSON backup payload below:', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON here...',
                hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                filled: true,
                fillColor: Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF2D2D2D))),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0078D7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                icon: const Icon(Icons.upload_outlined, size: 16),
                label: Text('RESTORE DATA NOW', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    final ok = await widget.storageService.restoreBackupJson(text);
                    if (ok) {
                      await widget.onReloadData();
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Data restored successfully!', style: GoogleFonts.spaceGrotesk()), backgroundColor: const Color(0xFF008A00)),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid backup JSON payload.', style: GoogleFonts.spaceGrotesk()), backgroundColor: const Color(0xFFB91C1C)),
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
        SnackBar(
          content: Text('Statement CSV copied to clipboard!', style: GoogleFonts.spaceGrotesk()),
          backgroundColor: const Color(0xFF008A00),
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
      backgroundColor: const Color(0xFF121212), // Metro Dark Obsidian
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fixed Top Header Bar (Page Name = Settings)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF121212),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0078D7),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
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
                              color: Color(0xFF0078D7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title (Metro 3D Flip)
                    MetroTileFlipEntrance(
                      delayMs: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settings & Preferences',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'App preferences & SMS parsing engine',
                                  style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF262626),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: const Icon(Icons.tune, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 1. SMS PARSING ENGINE Section (Metro 3D Flip)
                    MetroTileFlipEntrance(
                      delayMs: 100,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SMS PARSING ENGINE',
                              style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline, color: Color(0xFF0078D7), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Auto-read Bank SMS', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('Instant local regex capture from inbox', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11)),
                                    ],
                                  ),
                                ),
                                MetroSwitch(
                                  value: _autoReadSms,
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
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: widget.onScanSms,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0078D7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                icon: const Icon(Icons.sync, size: 16),
                                label: Text('SCAN PAST 30 DAYS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2. CYCLE & SPEND THRESHOLDS Section (Metro 3D Flip)
                    MetroTileFlipEntrance(
                      delayMs: 200,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CYCLE & SPEND THRESHOLDS',
                                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                ),
                                Text('Active Guardrails', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF09609), fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Cycle Limit Alert Threshold', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Triggers notification when limit is close', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0x26F09609),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Text('${_alertThreshold.toInt()}%', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF09609), fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            Slider(
                              value: _alertThreshold,
                              min: 40,
                              max: 95,
                              divisions: 11,
                              activeColor: const Color(0xFFF09609),
                              inactiveColor: const Color(0xFF262626),
                              onChanged: (v) async {
                                setState(() => _alertThreshold = v);
                                await widget.storageService.setAlertThreshold(v);
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Cycle Reset Alert', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Notify on statement generation & billing rollover', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11)),
                                    ],
                                  ),
                                ),
                                MetroSwitch(
                                  value: _cycleResetAlert,
                                  onChanged: (v) async {
                                    setState(() => _cycleResetAlert = v);
                                    await widget.storageService.setCycleResetAlert(v);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 3. DATA VAULT & EXPORT Section (Metro 3D Flip)
                    MetroTileFlipEntrance(
                      delayMs: 300,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DATA VAULT & EXPORT',
                              style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: _handleExportBackup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF262626),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                icon: const Icon(Icons.sync, size: 16, color: Color(0xFF0078D7)),
                                label: Text('EXPORT BACKUP PAYLOAD', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: _handleRestoreBackup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF262626),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                icon: const Icon(Icons.upload_outlined, size: 16, color: Color(0xFFF09609)),
                                label: Text('RESTORE FROM BACKUP PAYLOAD', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: _handleExportCsv,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF262626),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                icon: const Icon(Icons.table_chart_outlined, size: 16, color: Color(0xFF008A00)),
                                label: Text('EXPORT STATEMENT CSV FOR SPREADSHEET', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 4. RESET & PURGE Section (Metro 3D Flip)
                    MetroTileFlipEntrance(
                      delayMs: 380,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'RESET & PURGE',
                                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFFA0A0A0), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                ),
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 16),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Clear Transaction Cache', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Wipe parsed SMS data (re-parsable at any time)', style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: _confirmFlushCache,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF262626),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    ),
                                    child: Text('FLUSH CACHE', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
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
                                        color: Color(0xFF121212),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('PURGE VAULT & ALL DATA?', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFB91C1C), fontSize: 16, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 10),
                                          Text('Are you sure you want to purge all local cards, transactions, and EMI data? This cannot be undone.', textAlign: TextAlign.center, style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 12)),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(color: Color(0xFF2D2D2D)),
                                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                                  ),
                                                  child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                                                  onPressed: () => Navigator.of(ctx).pop(),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: FilledButton(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: const Color(0xFFB91C1C),
                                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                                  ),
                                                  child: Text('Purge Vault', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB91C1C), // Red
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                icon: const Icon(Icons.disabled_by_default_outlined, size: 16),
                                label: Text('PURGE ALL DATA', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bottom App Version Footer
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.credit_card, color: Color(0xFF0078D7), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'CardPulse $_appVersion',
                                style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0078D7), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CardPulse Spend Analytics Engine',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.workSans(color: const Color(0xFFA0A0A0), fontSize: 10),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Polished Metro Rounded Toggle Switch
class MetroSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MetroSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF0078D7) : const Color(0xFF1E1E1E), // Solid Metro Blue vs Dark Charcoal
          borderRadius: BorderRadius.circular(14), // Polished Smooth Rounded Pill
          border: Border.all(
            color: value ? const Color(0xFF0078D7) : const Color(0xFF3E3E3E),
            width: 1.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? Colors.white : const Color(0xFFA0A0A0), // Crisp White vs Off-White Knob
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
