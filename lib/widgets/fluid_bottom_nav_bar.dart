import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121620), // Clean Dark Obsidian Dock
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: InkWell(
              onTap: () => onTabSelected(index),
              borderRadius: BorderRadius.circular(24),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: isSelected
                          ? const Color(0xFF00FFA3) // Neon Mint Highlight
                          : const Color(0xFFA0AEC0), // Muted Grey
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF00FFA3) // Neon Mint Highlight
                            : const Color(0xFFA0AEC0), // Muted Grey
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
