import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/emi.dart';
import '../models/transaction.dart';
import '../services/cycle_calculator.dart';
import 'credit_card_widget.dart';

class StackedCardsView extends StatefulWidget {
  final List<CreditCard> cards;
  final List<TransactionItem> transactions;
  final List<EmiItem> emis;
  final Function(CreditCard)? onCardTap;
  final Function(CreditCard)? onAddEmi;
  final Function(CreditCard)? onAddTransaction;
  final Function(CreditCard)? onCardChanged;

  const StackedCardsView({
    super.key,
    required this.cards,
    required this.transactions,
    required this.emis,
    this.onCardTap,
    this.onAddEmi,
    this.onAddTransaction,
    this.onCardChanged,
  });

  @override
  State<StackedCardsView> createState() => _StackedCardsViewState();
}

class _StackedCardsViewState extends State<StackedCardsView> {
  int _currentIndex = 0;
  double _dragOffset = 0.0;

  @override
  void didUpdateWidget(StackedCardsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.cards.length) {
      _currentIndex = 0;
    }
  }

  void _nextCard() {
    if (widget.cards.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.cards.length;
      _dragOffset = 0.0;
    });
    final sorted = CycleCalculator.sortCardsByReset(widget.cards);
    if (_currentIndex < sorted.length) {
      widget.onCardChanged?.call(sorted[_currentIndex]);
    }
  }

  void _prevCard() {
    if (widget.cards.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.cards.length) % widget.cards.length;
      _dragOffset = 0.0;
    });
    final sorted = CycleCalculator.sortCardsByReset(widget.cards);
    if (_currentIndex < sorted.length) {
      widget.onCardChanged?.call(sorted[_currentIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No Credit Cards Added',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your credit cards with bill generation dates to track billing cycle spends and EMIs.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    // Sort cards so latest card to reset shows first
    final sortedCards = CycleCalculator.sortCardsByReset(widget.cards);
    final topCard = sortedCards[_currentIndex];
    final totalSpend = CycleCalculator.getTotalCycleSpend(
      topCard,
      widget.transactions,
      widget.emis,
    );

    return Column(
      children: [
        // Card Stack with Swipe Gesture
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.primaryDelta ?? 0;
            });
          },
          onHorizontalDragEnd: (details) {
            if (_dragOffset < -60 || (details.primaryVelocity ?? 0) < -300) {
              _nextCard();
            } else if (_dragOffset > 60 || (details.primaryVelocity ?? 0) > 300) {
              _prevCard();
            } else {
              setState(() {
                _dragOffset = 0.0;
              });
            }
          },
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Background Card preview if multiple cards
              if (sortedCards.length > 1) ...[
                Builder(
                  builder: (context) {
                    final nextIndex = (_currentIndex + 1) % sortedCards.length;
                    final nextCard = sortedCards[nextIndex];
                    final nextSpend = CycleCalculator.getTotalCycleSpend(
                      nextCard,
                      widget.transactions,
                      widget.emis,
                    );
                    return Transform.translate(
                      offset: const Offset(0, 14),
                      child: Transform.scale(
                        scale: 0.93,
                        child: Opacity(
                          opacity: 0.55,
                          child: CreditCardWidget(
                            card: nextCard,
                            totalSpend: nextSpend,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              // Top Active Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.translationValues(_dragOffset, 0, 0),
                child: CreditCardWidget(
                  card: topCard,
                  totalSpend: totalSpend,
                  onTap: () => widget.onCardTap?.call(topCard),
                  onAddEmi: () => widget.onAddEmi?.call(topCard),
                  onAddTransaction: () => widget.onAddTransaction?.call(topCard),
                ),
              ),
            ],
          ),
        ),

        // Navigation controls & Indicators below stack
        if (sortedCards.length > 1) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevCard,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Card',
                ),
                Row(
                  children: List.generate(sortedCards.length, (index) {
                    final isSelected = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSelected ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                IconButton(
                  onPressed: _nextCard,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Card',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
