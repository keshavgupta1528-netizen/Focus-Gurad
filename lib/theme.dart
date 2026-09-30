import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FG {
  static const bg = Color(0xFF090C10);
  static const indigo = Color(0xFF5865F2);
  static const mint = Color(0xFF00F5A0);
  static const coral = Color(0xFFFF4757);
  static const slate = Color(0xFF8A99AD);
  static const glass = Color(0x0AFFFFFF);
  static const glassBorder = Color(0x14FFFFFF);

  static ThemeData theme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: indigo,
          secondary: mint,
          error: coral,
          surface: bg,
        ),
      );
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: FG.glass,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: FG.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Wraps any widget with a scale(0.97) bounce on press plus a haptic tick.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
