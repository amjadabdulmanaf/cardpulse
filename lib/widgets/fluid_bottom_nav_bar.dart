import 'package:flutter/material.dart';

class FluidNavItem {
  final IconData icon;
  final String label;

  const FluidNavItem({
    required this.icon,
    required this.label,
  });
}

class FluidBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<FluidNavItem> items;

  const FluidBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A), // Dark slate floating dock
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF1F293D),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;

          return Stack(
            children: [
              // Dynamic Fluid Animated Indicator Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.fastOutSlowIn,
                left: selectedIndex * itemWidth + (itemWidth - 62) / 2,
                top: 2,
                child: Container(
                  width: 62,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D42),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Nav Items Row
              Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == selectedIndex;

                  return SizedBox(
                    width: itemWidth,
                    height: 52,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onTabSelected(index),
                        borderRadius: BorderRadius.circular(20),
                        splashColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                        highlightColor: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                item.icon,
                                size: 22,
                                color: isSelected
                                    ? const Color(0xFF34D399) // Mint green active
                                    : const Color(0xFF9CA3AF), // Muted gray
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF9CA3AF),
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
