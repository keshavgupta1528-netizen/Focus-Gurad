import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Touch-and-drag circular dial: 5m..180m in 5m steps, haptic tick per step,
/// spring-physics bounce on the knob when released.
class TimerDial extends StatefulWidget {
  const TimerDial({
    super.key,
    required this.minutes,
    required this.running,
    required this.progress,
    required this.centerText,
    required this.subText,
    required this.onChanged,
  });

  final int minutes;
  final bool running;
  final double progress;
  final String centerText;
  final String subText;
  final ValueChanged<int> onChanged;

  static const minMinutes = 5;
  static const maxMinutes = 180;

  @override
  State<TimerDial> createState() => _TimerDialState();
}

class _TimerDialState extends State<TimerDial> with SingleTickerProviderStateMixin {
  late final AnimationController _knob = AnimationController.unbounded(vsync: this, value: 1.0);

  double get _fraction =>
      (widget.minutes - TimerDial.minMinutes) / (TimerDial.maxMinutes - TimerDial.minMinutes);

  @override
  void dispose() {
    _knob.dispose();
    super.dispose();
  }

  void _grab() {
    if (widget.running) return;
    HapticFeedback.lightImpact();
    _knob.animateTo(1.25, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
  }

  void _release() {
    if (widget.running) return;
    _knob.animateWith(SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 320, damping: 11),
      _knob.value,
      1.0,
      0,
    ));
  }

  void _drag(Offset p, double side) {
    if (widget.running) return;
    final c = Offset(side / 2, side / 2);
    var a = math.atan2(p.dx - c.dx, c.dy - p.dy); // 0 at top, clockwise
    if (a < 0) a += 2 * math.pi;
    var f = a / (2 * math.pi);
    final prev = _fraction;
    // Stop the dial wrapping from max straight back to min.
    if (prev > 0.75 && f < 0.25) {
      f = 1;
    } else if (prev < 0.25 && f > 0.75) {
      f = 0;
    }
    final raw = TimerDial.minMinutes + f * (TimerDial.maxMinutes - TimerDial.minMinutes);
    final snapped = ((raw / 5).round() * 5).clamp(TimerDial.minMinutes, TimerDial.maxMinutes).toInt();
    if (snapped != widget.minutes) {
      HapticFeedback.selectionClick();
      widget.onChanged(snapped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final side = math.min(cons.maxWidth, 320.0);
      return Center(
        child: SizedBox(
          width: side,
          height: side,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {
              _grab();
              _drag(d.localPosition, side);
            },
            onPanUpdate: (d) => _drag(d.localPosition, side),
            onPanEnd: (_) => _release(),
            onPanCancel: _release,
            child: AnimatedBuilder(
              animation: _knob,
              builder: (context, _) => CustomPaint(
                painter: _DialPainter(
                  fraction: _fraction,
                  running: widget.running,
                  progress: widget.progress,
                  knobScale: _knob.value,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.centerText,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.subText,
                          style: const TextStyle(fontSize: 14, color: FG.slate, letterSpacing: 0.6)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.fraction,
    required this.running,
    required this.progress,
    required this.knobScale,
  });

  final double fraction;
  final bool running;
  final double progress;
  final double knobScale;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 24;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0x14FFFFFF),
    );

    final sweep = running ? 2 * math.pi * (1 - progress) : 2 * math.pi * fraction;
    if (sweep > 0.001) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          colors: [FG.indigo.withAlpha(120), FG.indigo],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
    }

    if (!running) {
      final angle = -math.pi / 2 + sweep;
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * r;
      canvas.drawCircle(
        pos,
        20 * knobScale,
        Paint()
          ..color = FG.indigo.withAlpha(130)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(pos, 12 * knobScale, Paint()..color = Colors.white);
      canvas.drawCircle(pos, 6 * knobScale, Paint()..color = FG.indigo);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => true;
}
