import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/sms_service.dart';
import '../services/storage_service.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/fluid_bottom_nav_bar.dart';
import '../widgets/sms_scanner_sheet.dart';
import 'add_emi_screen.dart';
import 'cards_screen.dart';
import 'dashboard_screen.dart';
import 'emi_list_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final StorageService storageService;

  const MainNavigationScreen({super.key, required this.storageService});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<CreditCard> _cards = [];
  List<TransactionItem> _transactions = [];
  List<EmiItem> _emis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cards = await widget.storageService.getCards();
    final txs = await widget.storageService.getTransactions();
    final emis = await widget.storageService.getEmis();

    setState(() {
      _cards = cards;
      _transactions = txs;
      _emis = emis;
      _isLoading = false;
    });

    _autoScanSms();
  }

  Future<void> _autoScanSms() async {
    if (_cards.isEmpty) return;
    final isAutoReadOn = await widget.storageService.getAutoReadSms();
    if (!isAutoReadOn) return;

    try {
      final parsed = await SmsService.fetchAndParseSms(_cards);
      if (parsed.isNotEmpty) {
        int newlyAdded = 0;
        final existing = await widget.storageService.getTransactions();

        for (final p in parsed) {
          final tx = TransactionItem(
            id: 'sms_${p.cardLast4}_${p.date.millisecondsSinceEpoch}_${p.amount.toInt()}',
            cardId: p.matchedCardId,
            title: p.merchant,
            amount: p.amount,
            date: p.date,
            category: 'SMS Parsed',
            rawSms: p.rawBody,
          );

          final isDeleted = await widget.storageService.isTransactionDeleted(
            id: tx.id,
            rawSms: p.rawBody,
            cardId: p.matchedCardId,
            amount: p.amount,
            date: p.date,
          );
          if (isDeleted) continue;

          final isDup = existing.any((t) =>
            t.cardId == tx.cardId &&
            (t.amount - tx.amount).abs() < 0.01 &&
            t.date.year == tx.date.year &&
            t.date.month == tx.date.month &&
            t.date.day == tx.date.day
          );

          if (!isDup) {
            await widget.storageService.addTransaction(tx);
            newlyAdded++;
          }
        }

        if (newlyAdded > 0) {
          final updatedTxs = await widget.storageService.getTransactions();
          if (mounted) {
            setState(() {
              _transactions = updatedTxs;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Auto-synced $newlyAdded new spend${newlyAdded > 1 ? "s" : ""} from SMS!'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _addCard(CreditCard card) async {
    await widget.storageService.saveCard(card);
    await _loadData();
  }

  Future<void> _deleteCard(String cardId) async {
    await widget.storageService.deleteCard(cardId);
    await _loadData();
  }

  Future<void> _addTransaction(TransactionItem tx) async {
    await widget.storageService.addTransaction(tx);
    await _loadData();
  }

  Future<void> _updateTransaction(TransactionItem tx) async {
    await widget.storageService.updateTransaction(tx);
    await _loadData();
  }

  Future<void> _deleteTransaction(String txId) async {
    await widget.storageService.deleteTransaction(txId);
    await _loadData();
  }

  Future<void> _addEmi(EmiItem emi) async {
    await widget.storageService.saveEmi(emi);
    await _loadData();
  }

  Future<void> _deleteEmi(String emiId) async {
    await widget.storageService.deleteEmi(emiId);
    await _loadData();
  }

  Future<void> _importSmsTransactions(List<TransactionItem> imported) async {
    for (final tx in imported) {
      await widget.storageService.addTransaction(tx);
    }
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${imported.length} transactions from SMS!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _openAddCardDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCardSheet(
        onSave: _addCard,
      ),
    );
  }

  void _openAddEmiDialog({CreditCard? initialCard}) {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a credit card first.')),
      );
      _openAddCardDialog();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEmiScreen(
          cards: _cards,
          initialCard: initialCard ?? (_cards.isNotEmpty ? _cards.first : null),
          onSave: _addEmi,
        ),
      ),
    );
  }

  void _openAddTransactionDialog({CreditCard? initialCard}) {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a credit card first.')),
      );
      _openAddCardDialog();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionSheet(
        cards: _cards,
        initialCard: initialCard ?? (_cards.isNotEmpty ? _cards.first : null),
        onSave: _addTransaction,
      ),
    );
  }

  void _openSmsScanner() {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a credit card first to match SMS transactions.')),
      );
      _openAddCardDialog();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmsScannerSheet(
        storageService: widget.storageService,
        cards: _cards,
        existingTransactions: _transactions,
        onImport: _importSmsTransactions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F19),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF34D399)),
        ),
      );
    }

    // Screens list for 5 Bottom Nav Tabs
    final screens = [
      // 1. Dashboard / Home
      DashboardScreen(
        storageService: widget.storageService,
        cards: _cards,
        transactions: _transactions,
        emis: _emis,
        onAddCard: _openAddCardDialog,
        onAddEmi: (card) => _openAddEmiDialog(initialCard: card),
        onAddSpend: (card) => _openAddTransactionDialog(initialCard: card),
        onScanSms: _openSmsScanner,
      ),

      // 2. Cards Manager
      CardsScreen(
        storageService: widget.storageService,
        cards: _cards,
        transactions: _transactions,
        emis: _emis,
        onAddCard: _addCard,
        onDeleteCard: _deleteCard,
        onAddTransaction: _addTransaction,
        onAddEmi: _addEmi,
        onDeleteTransaction: _deleteTransaction,
        onScanSms: _openSmsScanner,
      ),

      // 3. EMI Management
      EmiListScreen(
        storageService: widget.storageService,
        cards: _cards,
        transactions: _transactions,
        emis: _emis,
        onAddEmi: _addEmi,
        onDeleteEmi: _deleteEmi,
      ),

      // 4. Spends / Full Transactions
      TransactionsScreen(
        storageService: widget.storageService,
        cards: _cards,
        transactions: _transactions,
        emis: _emis,
        onDeleteTransaction: _deleteTransaction,
        onUpdateTransaction: _updateTransaction,
        onUpdateEmi: _addEmi,
        onRefresh: _openSmsScanner,
      ),

      // 5. Settings
      SettingsScreen(
        storageService: widget.storageService,
        cards: _cards,
        transactions: _transactions,
        emis: _emis,
        onScanSms: _openSmsScanner,
        onReloadData: _loadData,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // Dynamic Fluid Design Bottom Navigation Bar
      bottomNavigationBar: FluidBottomNavBar(
        selectedIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          FluidNavItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
          FluidNavItem(icon: Icons.credit_card_outlined, label: 'Cards'),
          FluidNavItem(icon: Icons.timelapse_rounded, label: 'EMIs'),
          FluidNavItem(icon: Icons.insights_rounded, label: 'Spends'),
          FluidNavItem(icon: Icons.settings_outlined, label: 'Settings'),
        ],
      ),
    );
  }
}
