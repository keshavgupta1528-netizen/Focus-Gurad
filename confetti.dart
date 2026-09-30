import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Full-screen confetti burst. Call `key.currentState?.play()`.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  static const double seconds = 2.8;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  final _rng = math.Random();
  List<_Piece> _pieces = const [];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void play() {
    const colors = [FG.indigo, FG.mint, FG.coral, Color(0xFFFFD166), Colors.white];
    setState(() {
      _pieces = List.generate(150, (_) {
        final a = -math.pi / 2 + (_rng.nextDouble() - 0.5) * math.pi * 0.9;
        final s = 350 + _rng.nextDouble() * 750;
        return _Piece(
          dx: math.cos(a) * s,
          dy: math.sin(a) * s,
          color: colors[_rng.nextInt(colors.length)],
          w: 6 + _rng.nextDouble() * 6,
          h: 3 + _rng.nextDouble() * 5,
          spin: (_rng.nextDouble() - 0.5) * 14,
          phase: _rng.nextDouble() * math.pi * 2,
        );
      });
    });
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c.value * seconds),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.dx,
    required this.dy,
    required this.color,
    required this.w,
    required this.h,
    required this.spin,
    required this.phase,
  });
  final double dx, dy, w, h, spin, phase;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (pieces.isEmpty || t <= 0 || t >= ConfettiOverlayState.seconds) return;
    final origin = Offset(size.width / 2, size.height * 0.62);
    const drag = 1.6;
    const gravity = 1100.0;
    final factor = (1 - math.exp(-drag * t)) / drag;
    final alpha = t > 2.0 ? (1 - (t - 2.0) / 0.8).clamp(0.0, 1.0) : 1.0;
    final paint = Paint();
    for (final p in pieces) {
      final x = origin.dx + p.dx * factor;
      final y = origin.dy + p.dy * factor + 0.5 * gravity * t * t;
      paint.color = p.color.withAlpha((255 * alpha).round());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.phase + p.spin * t);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
