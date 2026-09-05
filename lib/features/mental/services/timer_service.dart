import 'dart:async';
import 'package:cadence/features/mental/services/meditation_audio_service.dart';

/// Current lifecycle state of the meditation timer.
enum MeditationTimerStatus {
  idle,
  running,
  paused,
  completed,
}

/// Snapshot of the active meditation timer tick.
class MeditationTimerTick {
  const MeditationTimerTick({
    required this.status,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.elapsedSeconds,
  });

  final MeditationTimerStatus status;
  final int remainingSeconds;
  final int totalSeconds;
  final int elapsedSeconds;

  double get progress => totalSeconds > 0
      ? (elapsedSeconds / totalSeconds).clamp(0.0, 1.0)
      : 0.0;

  String get formattedRemaining {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get formattedElapsed {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Controller service for meditation countdown timers with audio cues.
class TimerService {
  TimerService({MeditationAudioService? audioService})
      : _audio = audioService ?? MeditationAudioService.instance;

  final MeditationAudioService _audio;

  Timer? _ticker;
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  int _intervalChimeSeconds = 0;
  AmbientTrack _ambientTrack = AmbientTrack.none;
  MeditationTimerStatus _status = MeditationTimerStatus.idle;

  final StreamController<MeditationTimerTick> _tickController =
      StreamController<MeditationTimerTick>.broadcast();

  Stream<MeditationTimerTick> get tickStream => _tickController.stream;
  MeditationTimerStatus get status => _status;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;

  /// Starts a new meditation session with countdown and sound cues.
  Future<void> start({
    required int durationMinutes,
    AmbientTrack ambient = AmbientTrack.singingBowls,
    int? intervalMinutes,
    Future<void> Function(int minutesCompleted)? onComplete,
  }) async {
    _ticker?.cancel();

    _totalSeconds = durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _intervalChimeSeconds = (intervalMinutes != null && intervalMinutes > 0)
        ? intervalMinutes * 60
        : 0;
    _ambientTrack = ambient;
    _status = MeditationTimerStatus.running;

    _emitTick();

    // 1. Play starting singing bowl cue
    await _audio.playCue(MeditationSound.startBell);

    // 2. Start looping ambient background sound
    if (_ambientTrack != AmbientTrack.none) {
      await _audio.startAmbient(_ambientTrack, volume: 0.4);
    }

    // 3. Start 1-second countdown ticker
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 1) {
        _remainingSeconds--;
        final elapsed = _totalSeconds - _remainingSeconds;

        // Check for periodic interval chime
        if (_intervalChimeSeconds > 0 &&
            elapsed % _intervalChimeSeconds == 0 &&
            _remainingSeconds > 10) {
          await _audio.playCue(MeditationSound.intervalChime);
        }

        _emitTick();
      } else {
        // Session Finished
        _remainingSeconds = 0;
        _status = MeditationTimerStatus.completed;
        timer.cancel();
        _emitTick();

        // Stop ambient & play completion bell
        await _audio.stopAmbient();
        await _audio.playCue(MeditationSound.finishBell);

        // Record completed session minutes
        if (onComplete != null) {
          final minutes = (_totalSeconds / 60).round();
          await onComplete(minutes);
        }
      }
    });
  }

  /// Pauses an ongoing session.
  Future<void> pause() async {
    if (_status == MeditationTimerStatus.running) {
      _ticker?.cancel();
      _status = MeditationTimerStatus.paused;
      await _audio.pauseAmbient();
      _emitTick();
    }
  }

  /// Resumes a paused session.
  Future<void> resume() async {
    if (_status == MeditationTimerStatus.paused) {
      _status = MeditationTimerStatus.running;
      await _audio.resumeAmbient();
      _emitTick();

      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
          _emitTick();
        } else {
          _remainingSeconds = 0;
          _status = MeditationTimerStatus.completed;
          timer.cancel();
          _emitTick();

          await _audio.stopAmbient();
          await _audio.playCue(MeditationSound.finishBell);
        }
      });
    }
  }

  /// Stops and resets the session.
  Future<void> stop() async {
    _ticker?.cancel();
    _status = MeditationTimerStatus.idle;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    await _audio.stopAmbient();
    _emitTick();
  }

  void _emitTick() {
    if (!_tickController.isClosed) {
      _tickController.add(
        MeditationTimerTick(
          status: _status,
          remainingSeconds: _remainingSeconds,
          totalSeconds: _totalSeconds,
          elapsedSeconds: _totalSeconds - _remainingSeconds,
        ),
      );
    }
  }

  /// Releases timer and stream resources.
  void dispose() {
    _ticker?.cancel();
    _tickController.close();
  }
}
