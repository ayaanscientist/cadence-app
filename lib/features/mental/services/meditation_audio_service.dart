import 'dart:developer' as developer;
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Available bundled audio sound effects for meditation.
enum MeditationSound {
  startBell('assets/audio/bell_start.mp3', 'Tibetan Singing Bowl (Start)'),
  intervalChime('assets/audio/bell_interval.mp3', 'Mindful Interval Chime'),
  finishBell('assets/audio/bell_finish.mp3', 'Deep Gong (Completion)');

  const MeditationSound(this.assetPath, this.label);
  final String assetPath;
  final String label;
}

/// Ambient background noise options.
enum AmbientTrack {
  none('', 'Silence'),
  singingBowls('assets/audio/ambient_singing_bowl.mp3', 'Tibetan Singing Bowls'),
  whiteNoise('assets/audio/ambient_white_noise.mp3', 'Pure White Noise'),
  rain('assets/audio/ambient_rain.mp3', 'Gentle Rain');

  const AmbientTrack(this.assetPath, this.label);
  final String assetPath;
  final String label;
}

/// Lightweight audio service for zero-latency local meditation sounds.
///
/// Uses two distinct [AudioPlayer] instances:
/// 1. `_cuePlayer`: For one-shot sound effects (start bell, interval chime, finish bell).
/// 2. `_ambientPlayer`: For continuous, looping background audio.
class MeditationAudioService {
  MeditationAudioService._();
  static final MeditationAudioService instance = MeditationAudioService._();

  late final AudioPlayer _cuePlayer;
  late final AudioPlayer _ambientPlayer;
  bool _isInitialized = false;

  /// Initializes the audio session and players.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _cuePlayer = AudioPlayer();
    _ambientPlayer = AudioPlayer();

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      developer.log('AudioSession configuration notice: $e', name: 'MeditationAudioService');
    }

    _isInitialized = true;
  }

  /// Plays a one-shot meditation cue (e.g. singing bowl, interval bell).
  Future<void> playCue(MeditationSound sound) async {
    await initialize();
    try {
      await _cuePlayer.setAsset(sound.assetPath);
      await _cuePlayer.play();
    } catch (e) {
      developer.log('Asset ${sound.assetPath} not loaded or offline fallback: $e',
          name: 'MeditationAudioService');
    }
  }

  /// Starts looping an ambient background audio track.
  Future<void> startAmbient(AmbientTrack track, {double volume = 0.5}) async {
    if (track == AmbientTrack.none) {
      await stopAmbient();
      return;
    }

    await initialize();
    try {
      await _ambientPlayer.setAsset(track.assetPath);
      await _ambientPlayer.setLoopMode(LoopMode.one);
      await _ambientPlayer.setVolume(volume.clamp(0.0, 1.0));
      await _ambientPlayer.play();
    } catch (e) {
      developer.log('Ambient asset ${track.assetPath} fallback: $e',
          name: 'MeditationAudioService');
    }
  }

  /// Pauses the current ambient audio track.
  Future<void> pauseAmbient() async {
    if (_isInitialized && _ambientPlayer.playing) {
      await _ambientPlayer.pause();
    }
  }

  /// Resumes the paused ambient audio track.
  Future<void> resumeAmbient() async {
    if (_isInitialized && !_ambientPlayer.playing) {
      await _ambientPlayer.play();
    }
  }

  /// Stops and resets the ambient audio track.
  Future<void> stopAmbient() async {
    if (_isInitialized) {
      await _ambientPlayer.stop();
    }
  }

  /// Adjusts the volume of the looping ambient sound (0.0 to 1.0).
  Future<void> setAmbientVolume(double volume) async {
    if (_isInitialized) {
      await _ambientPlayer.setVolume(volume.clamp(0.0, 1.0));
    }
  }

  /// Releases audio resources.
  Future<void> dispose() async {
    if (_isInitialized) {
      await _cuePlayer.dispose();
      await _ambientPlayer.dispose();
      _isInitialized = false;
    }
  }
}
