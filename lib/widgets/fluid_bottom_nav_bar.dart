import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FluidNavItem {
  final IconData icon;
  final String label;
  final bool isCenter;

  const FluidNavItem({
    required this.icon,
    required this.label,
    this.isCenter = false,
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
      color: const Color(0xFF121212), // Matching page background color for seamless integration
      padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottomInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;
          final isCenter = item.isCenter;

          return Expanded(
            child: InkWell(
              onTap: () => onTabSelected(index),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCenter ? 6 : 2,
                  vertical: isCenter ? 4 : 2,
                ),
                decoration: isCenter
                    ? BoxDecoration(
                        color: isSelected ? const Color(0x260078D7) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0078D7) : const Color(0xFF666666),
                          width: 1.5,
                        ),
                      )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: isCenter ? 21 : 19,
                      color: isSelected
                          ? const Color(0xFF0078D7) // Metro Electric Blue Accent
                          : const Color(0xFFFFFFFF), // White / Off-white Inactive
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isSelected
                            ? const Color(0xFF0078D7) // Metro Electric Blue Accent
                            : const Color(0xFFFFFFFF), // White / Off-white Inactive
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
