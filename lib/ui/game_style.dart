import 'dart:math' as math;

import 'package:flutter/material.dart';

class HeistBackdrop extends StatelessWidget {
  const HeistBackdrop({
    super.key,
    required this.child,
    this.safeArea = true,
  });

  final Widget child;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final base = dark ? const Color(0xFF090B12) : const Color(0xFFF2ECE1);
    final secondary = Color.alphaBlend(
      primary.withValues(alpha: dark ? 0.13 : 0.08),
      base,
    );

    final content = Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, secondary, base],
              stops: const [0, 0.56, 1],
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _BlueprintPainter(
              color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.035),
              accent: primary.withValues(alpha: dark ? 0.06 : 0.045),
            ),
          ),
        ),
        child,
      ],
    );
    return safeArea ? SafeArea(child: content) : content;
  }
}

class HeistPanel extends StatelessWidget {
  const HeistPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accent,
    this.emphasis = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final line = accent ?? theme.colorScheme.primary;
    final top = dark ? const Color(0xFF171B28) : const Color(0xFFFFFBF3);
    final bottom = dark ? const Color(0xFF111520) : const Color(0xFFECE3D4);
    final radius = BorderRadius.circular(18);

    final panel = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              line.withValues(alpha: emphasis ? 0.12 : 0.035),
              top,
            ),
            bottom,
          ],
        ),
        borderRadius: radius,
        border: Border.all(
          color: line.withValues(alpha: emphasis ? 0.72 : 0.26),
          width: emphasis ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
          if (emphasis)
            BoxShadow(
              color: line.withValues(alpha: 0.12),
              blurRadius: 22,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: emphasis ? 5 : 3,
                color: line.withValues(alpha: 0.72),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );

    if (onTap == null) return panel;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: panel,
        ),
      ),
    );
  }
}

class HeistBadge extends StatelessWidget {
  const HeistBadge({
    super.key,
    required this.icon,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class HeistButton extends StatelessWidget {
  const HeistButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = true,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final enabled = onPressed != null;
    final foreground = primary
        ? (ThemeData.estimateBrightnessForColor(color) == Brightness.dark
              ? Colors.white
              : Colors.black)
        : theme.colorScheme.onSurface;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 13 : 18,
              vertical: compact ? 10 : 13,
            ),
            decoration: BoxDecoration(
              gradient: primary
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(color, Colors.white, 0.12)!,
                        Color.lerp(color, Colors.black, 0.14)!,
                      ],
                    )
                  : null,
              color: primary
                  ? null
                  : theme.colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: primary
                    ? color.withValues(alpha: 0.9)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.18),
              ),
              boxShadow: primary && enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.23),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: compact ? 18 : 20,
                  color: primary ? foreground : color,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: primary ? foreground : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeistSectionTitle extends StatelessWidget {
  const HeistSectionTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class HeistProgressBar extends StatelessWidget {
  const HeistProgressBar({
    super.key,
    required this.value,
    this.height = 10,
  });

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * value.clamp(0.0, 1.0);
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.09),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.lerp(color, Colors.white, 0.2)!, color],
                ),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = color
      ..strokeWidth = 1;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final sweep = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final radius = math.min(size.width, size.height) * 0.42;
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.14),
      radius,
      sweep,
    );
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.86),
      radius * 0.72,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}
