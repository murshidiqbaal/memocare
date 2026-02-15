import 'dart:io';
import 'package:just_audio/just_audio.dart';

class VoicePlaybackService {
  final AudioPlayer _player = AudioPlayer();

  /// Plays audio from a local file path
  Future<void> playLocalAudio(String filePath) async {
    try {
      if (await File(filePath).exists()) {
        await _player.setFilePath(filePath);
        await _player.play();
      } else {
        print('Voice note file not found at: $filePath');
      }
    } catch (e) {
      print('Error playing local audio: $e');
    }
  }

  /// Plays audio from a remote URL
  Future<void> playRemoteAudio(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      print('Error playing remote audio: $e');
    }
  }

  /// Plays a bundled asset (e.g. gentle tone)
  Future<void> playAsset(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      print('Error playing asset audio: $e');
    }
  }

  /// Stops current playback
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Seeks to a position (default is start)
  Future<void> replay() async {
    try {
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (e) {
      print('Error replaying audio: $e');
    }
  }

  /// Expose player state stream
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void dispose() {
    _player.dispose();
  }
}
