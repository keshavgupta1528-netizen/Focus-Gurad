import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import 'confetti.dart';
import 'focus_controller.dart';
import 'timer_dial.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> with WidgetsBindingObserver {
  final _confetti = GlobalKey<ConfettiOverlayState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(focusProvider.notifier).resync();
    }
  }

  String _fmt(int s) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  // Step 3 replaces this with the 10-second hold / 3-step math unlock.
  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12161D),
        title: const Text('Quit this session?'),
        content: const Text('You were doing so well. Your streak will not count.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quit', style: TextStyle(color: FG.coral)),
          ),
        ],
      ),
    );
    if (quit == true) await ref.read(focusProvider.notifier).stopEarly();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(focusProvider);
    final ctrl = ref.read(focusProvider.notifier);

    ref.listen<int>(focusProvider.select((v) => v.completions), (prev, next) {
      if (next > (prev ?? 0)) _confetti.currentState?.play();
    });

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Focus Engine', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    _Badge(running: s.running),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        GlassCard(
                          child: TimerDial(
                            minutes: s.minutes,
                            running: s.running,
                            progress: s.progress,
                            centerText: s.running ? _fmt(s.remainingSeconds) : '${s.minutes}',
                            subText: s.running ? 'STAY LOCKED IN' : 'MINUTES',
                            onChanged: ctrl.setMinutes,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedOpacity(
                          opacity: s.running ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Wrap(
                            spacing: 10,
                            children: [
                              for (final m in const [15, 25, 45, 60])
                                ChoiceChip(
                                  label: Text('${m}m'),
                                  selected: s.minutes == m,
                                  selectedColor: FG.indigo,
                                  backgroundColor: FG.glass,
                                  side: const BorderSide(color: FG.glassBorder),
                                  onSelected: s.running
                                      ? null
                                      : (_) {
                                          HapticFeedback.selectionClick();
                                          ctrl.setMinutes(m);
                                        },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PressScale(
                  onTap: () => s.running ? _confirmQuit() : ctrl.start(),
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.running ? Colors.transparent : FG.indigo,
                      borderRadius: BorderRadius.circular(30),
                      border: s.running ? Border.all(color: FG.coral, width: 1.5) : null,
                      boxShadow: s.running
                          ? null
                          : [BoxShadow(color: FG.indigo.withAlpha(110), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Text(
                      s.running ? 'Give Up' : 'Start Focus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: s.running ? FG.coral : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(child: ConfettiOverlay(key: _confetti)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.running});
  final bool running;

  @override
  Widget build(BuildContext context) {
    final color = running ? FG.indigo : FG.slate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        running ? 'LOCKED IN' : 'READY',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: color),
      ),
    );
  }
}
