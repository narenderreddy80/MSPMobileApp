import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A circular icon with the app's orange-green gradient border,
/// matching the style of the custom JPEG icons.
class ThemedIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? iconColor;
  final bool filled;
  final bool muted;

  const ThemedIcon({
    super.key,
    required this.icon,
    this.size = 48,
    this.iconColor,
    this.filled = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (muted) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Icon(
          icon,
          size: size * 0.48,
          color: Colors.grey[400],
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          startAngle: 0.5,
          endAngle: 6.0,
          colors: [
            AppTheme.secondary,      // orange
            AppTheme.secondaryLight,  // bright orange
            AppTheme.primaryLight,    // light green
            AppTheme.primary,         // green
            AppTheme.primaryDark,     // dark green
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white,
        ),
        child: Icon(
          icon,
          size: size * 0.48,
          color: iconColor ?? AppTheme.primary,
        ),
      ),
    );
  }
}

/// A circular asset image icon with the orange-green gradient border.
class ThemedAssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final bool muted;

  const ThemedAssetIcon({
    super.key,
    required this.assetPath,
    this.size = 48,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: muted
            ? null
            : const SweepGradient(
                startAngle: 0.5,
                endAngle: 6.0,
                colors: [
                  AppTheme.secondary,
                  AppTheme.secondaryLight,
                  AppTheme.primaryLight,
                  AppTheme.primary,
                  AppTheme.primaryDark,
                ],
              ),
        border: muted ? Border.all(color: Colors.grey[300]!, width: 2) : null,
      ),
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: ColorFiltered(
            colorFilter: muted
                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
            child: Image.asset(assetPath, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
