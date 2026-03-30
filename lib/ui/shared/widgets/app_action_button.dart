import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';

enum AppActionButtonVariant { filled, outlined, text }

class AppWaveLoader extends StatelessWidget {
  final double size;
  final Color color;

  const AppWaveLoader({
    super.key,
    this.size = 16,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size * 1.9,
      child: SpinKitWave(
        color: color,
        size: size,
        itemCount: 4,
      ),
    );
  }
}

class AppActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppActionButtonVariant variant;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? loadingColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool compact;

  const AppActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppActionButtonVariant.filled,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
    this.loadingColor,
    this.padding,
    this.borderRadius = 10,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final fg = foregroundColor ??
        (variant == AppActionButtonVariant.filled
            ? AppColors.white
            : AppColors.primary);

    final child = _buildChild(fg);

    switch (variant) {
      case AppActionButtonVariant.outlined:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            side: BorderSide(color: borderColor ?? AppColors.primary),
            backgroundColor: backgroundColor,
            padding: padding ??
                EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 8 : 12,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        );
      case AppActionButtonVariant.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: fg,
            padding: padding ??
                EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 8 : 10,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        );
      case AppActionButtonVariant.filled:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: fg,
            backgroundColor: backgroundColor ?? AppColors.primary,
            padding: padding ??
                EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 9 : 12,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        );
    }
  }

  Widget _buildChild(Color textColor) {
    final textStyle = TextStyle(
      fontSize: compact ? 12 : 13,
      fontWeight: FontWeight.w600,
      color: textColor,
      height: 1,
    );

    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppWaveLoader(
            size: compact ? 12 : 14,
            color: loadingColor ?? textColor,
          ),
          const SizedBox(width: 8),
          Text(label, style: textStyle),
        ],
      );
    }

    if (icon == null) {
      return Text(label, style: textStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 16 : 18),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );
  }
}
