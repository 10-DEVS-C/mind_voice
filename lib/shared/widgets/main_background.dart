import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MainBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const MainBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? const [
                  Color(0xFF0B0514),
                  Color(0xFF161121),
                  Color(0xFF221932),
                ]
              : const [
                  Color(0xFFF4F7FB),
                  Color(0xFFEDE9FE),
                  Color(0xFFFFFFFF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          if (showOrbs) ...[
            Positioned(
              top: -60,
              left: -20,
              child: _GlowOrb(
                size: 200,
                color: AppColors.primary.withOpacity(isDarkMode ? 0.22 : 0.12),
              ),
            ),
            Positioned(
              bottom: -70,
              right: -30,
              child: _GlowOrb(
                size: 240,
                color: const Color(0xFF06B6D4).withOpacity(
                  isDarkMode ? 0.18 : 0.1,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: -50,
              child: _GlowOrb(
                size: 160,
                color: const Color(0xFF7C3AED).withOpacity(
                  isDarkMode ? 0.12 : 0.08,
                ),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 90,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
