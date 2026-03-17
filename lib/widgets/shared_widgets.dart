import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A pill-shaped tag/badge widget.
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const AppBadge({
    super.key,
    required this.label,
    this.color = AppColors.primarySurface,
    this.textColor = AppColors.primaryLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Filled gradient button.
class PrimaryButton extends StatelessWidget {
  final String label;
  // FIX: changed from VoidCallback to dynamic Function() so both sync and
  // async callbacks (Future<void> Function()) are accepted without a cast.
  final dynamic Function() onTap;
  final List<Color> gradient;
  final bool isLoading;
  final double? width;
  final EdgeInsets padding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient = const [AppColors.primary, AppColors.primaryLight],
    this.isLoading = false,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: padding,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color borderColor;
  final Color textColor;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.borderColor = AppColors.surfaceBorder,
    this.textColor = AppColors.textSecondary,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A frosted-glass-style card container.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Animated code character cell.
class CodeCell extends StatelessWidget {
  final String char;
  final Color accentColor;

  const CodeCell({
    super.key,
    required this.char,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 52,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: accentColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

/// Online presence dot.
class PresenceDot extends StatelessWidget {
  final bool isOnline;

  const PresenceDot({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.success : AppColors.textTertiary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
    );
  }
}

/// Member avatar with initials and presence indicator.
class MemberAvatar extends StatelessWidget {
  final String initials;
  final bool isOnline;
  final double size;
  final Color? color;

  const MemberAvatar({
    super.key,
    required this.initials,
    this.isOnline = false,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primarySurface;
    final fg = color != null
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.primaryLight;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.surfaceBorder,
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: fg,
                fontSize: size * 0.33,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: PresenceDot(isOnline: isOnline),
        ),
      ],
    );
  }
}