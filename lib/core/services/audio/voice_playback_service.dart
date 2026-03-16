import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../data/models/reminder.dart';

class VoicePlaybackService {
  final AudioPlayer _player = AudioPlayer();

  /// Implementation of Part 8: Playback with local-first fallback
  Future<void> playReminderVoice(Reminder reminder) async {
    try {
      final localPath = reminder.localAudioPath;
      final remoteUrl = reminder.voiceAudioUrl;

      if (localPath != null &&
          localPath.isNotEmpty &&
          await File(localPath).exists()) {
        debugPrint('[VoicePlaybackService] Playing local file: $localPath');
        await _player.setFilePath(localPath);
      } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
        debugPrint('[VoicePlaybackService] Playing remote URL: $remoteUrl');
        await _player.setUrl(remoteUrl);
      } else {
        debugPrint(
            '[VoicePlaybackService] No audio source available for reminder ${reminder.id}');
        return;
      }

      await _player.play();
    } catch (e) {
      debugPrint('[VoicePlaybackService] Error in playReminderVoice: $e');
    }
  }

  /// Plays audio from a local file path
  Future<void> playLocalAudio(String filePath, {bool loop = false}) async {
    try {
      if (await File(filePath).exists()) {
        await _player.setFilePath(filePath);
        await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
        await _player.play();
      } else {
        print('Voice note file not found at: $filePath');
      }
    } catch (e) {
      print('Error playing local audio: $e');
    }
  }

  /// Plays audio from a remote URL
  Future<void> playRemoteAudio(String url, {bool loop = false}) async {
    try {
      await _player.setUrl(url);
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _player.play();
    } catch (e) {
      print('Error playing remote audio: $e');
    }
  }

  /// Plays a bundled asset (e.g. gentle tone)
  Future<void> playAsset(String assetPath, {bool loop = false}) async {
    try {
      await _player.setAsset(assetPath);
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
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
