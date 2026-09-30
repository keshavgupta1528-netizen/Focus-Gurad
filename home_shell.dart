import 'package:flutter/material.dart';
import 'focus/focus_screen.dart';
import 'theme.dart';

/// Horizontal swipe paging: Focus Engine (left) <-> Daily Tasks (right).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _page = i),
            children: const [FocusScreen(), _TasksPlaceholder()],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 2; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? FG.indigo : FG.slate.withAlpha(90),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Replaced by the real Daily Tasks screen in build step 4.
class _TasksPlaceholder extends StatelessWidget {
  const _TasksPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Daily Tasks', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('Swipe gestures, quick-add and alarms arrive in step 4.',
                    textAlign: TextAlign.center, style: TextStyle(color: FG.slate)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
