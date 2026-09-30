import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/engine_channel.dart';

enum FocusStatus { idle, running }

class FocusState {
  const FocusState({
    this.minutes = 25,
    this.status = FocusStatus.idle,
    this.endMillis = 0,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.completions = 0,
  });

  final int minutes;
  final FocusStatus status;
  final int endMillis;
  final int totalSeconds;
  final int remainingSeconds;
  final int completions;

  bool get running => status == FocusStatus.running;
  double get progress => totalSeconds == 0 ? 0 : 1 - remainingSeconds / totalSeconds;

  FocusState copyWith({
    int? minutes,
    FocusStatus? status,
    int? endMillis,
    int? totalSeconds,
    int? remainingSeconds,
    int? completions,
  }) =>
      FocusState(
        minutes: minutes ?? this.minutes,
        status: status ?? this.status,
        endMillis: endMillis ?? this.endMillis,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        completions: completions ?? this.completions,
      );
}

class FocusController extends Notifier<FocusState> {
  Timer? _ticker;

  @override
  FocusState build() {
    ref.onDispose(() => _ticker?.cancel());
    Future.microtask(_restore);
    return const FocusState();
  }

  void setMinutes(int m) {
    if (state.running) return;
    state = state.copyWith(minutes: m);
  }

  Future<void> start() async {
    if (state.running) return;
    final totalMs = state.minutes * 60 * 1000;
    final end = DateTime.now().millisecondsSinceEpoch + totalMs;
    try {
      await EngineChannel.start(end, totalMs);
    } catch (_) {
      // Keep the in-app timer working even if the native bridge fails.
    }
    _begin(end, totalMs ~/ 1000);
  }

  Future<void> stopEarly() async {
    try {
      await EngineChannel.stop();
    } catch (_) {}
    _finish(completed: false);
  }

  /// Call when the app returns to the foreground.
  void resync() {
    if (state.running) _tick();
  }

  Future<void> _restore() async {
    try {
      final s = await EngineChannel.status();
      final end = s['end'] ?? 0;
      final total = s['total'] ?? 0;
      if (end > DateTime.now().millisecondsSinceEpoch && total > 0) {
        _begin(end, total ~/ 1000);
      }
    } catch (_) {}
  }

  void _begin(int end, int totalSeconds) {
    state = state.copyWith(
      status: FocusStatus.running,
      endMillis: end,
      totalSeconds: totalSeconds,
      remainingSeconds: totalSeconds,
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    final remaining = ((state.endMillis - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    if (remaining <= 0) {
      EngineChannel.stop().catchError((_) {});
      _finish(completed: true);
    } else {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  void _finish({required bool completed}) {
    _ticker?.cancel();
    state = state.copyWith(
      status: FocusStatus.idle,
      remainingSeconds: 0,
      totalSeconds: 0,
      completions: completed ? state.completions + 1 : state.completions,
    );
    if (completed) HapticFeedback.heavyImpact();
  }
}

final focusProvider = NotifierProvider<FocusController, FocusState>(FocusController.new);
