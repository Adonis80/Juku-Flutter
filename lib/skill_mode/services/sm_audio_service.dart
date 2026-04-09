import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/sm_card.dart';
import 'sm_r2_service.dart';

/// Audio playback + preloading service for Skill Mode (SM-2.3).
///
/// Plays native speaker reference audio on card reveal and after magnet
/// transform. Preloads next 3 cards' audio for seamless transitions.
class SmAudioService {
  SmAudioService._();
  static final instance = SmAudioService._();

  final _player = AudioPlayer();
  final _preloadPlayers = <String, AudioPlayer>{};
  final _r2 = SmR2Service.instance;

  /// Play audio for a card. Falls back silently if URL is null or fails.
  Future<void> playCardAudio(SmCard card) async {
    final url = card.audioUrl;
    if (url == null || url.isEmpty) {
      // Try R2 URL convention.
      final r2Url = _r2.getAudioUrl(card.id, card.language);
      await _playUrl(r2Url);
      return;
    }
    await _playUrl(url);
  }

  /// Play from a specific URL.
  Future<void> _playUrl(String url) async {
    try {
      // Check if we have a preloaded player for this URL.
      final preloaded = _preloadPlayers.remove(url);
      if (preloaded != null) {
        await preloaded.resume();
        // Return player to pool after playback.
        preloaded.onPlayerComplete.first.then((_) {
          preloaded.dispose();
        });
        return;
      }

      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('SmAudioService: playback failed for $url — $e');
    }
  }

  /// Preload audio for upcoming cards (next 3 in queue).
  ///
  /// Called when entering a new card to warm up the next batch.
  Future<void> preloadCards(List<SmCard> upcomingCards) async {
    // Only preload up to 3.
    final toPreload = upcomingCards.take(3);
    for (final card in toPreload) {
      final url = card.audioUrl?.isNotEmpty == true
          ? card.audioUrl!
          : _r2.getAudioUrl(card.id, card.language);

      if (_preloadPlayers.containsKey(url)) continue;

      try {
        final player = AudioPlayer();
        await player.setSource(UrlSource(url));
        _preloadPlayers[url] = player;
      } catch (e) {
        debugPrint('SmAudioService: preload failed for $url — $e');
      }
    }
  }

  /// Stop any current playback.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Clean up all preloaded players.
  Future<void> disposePreloads() async {
    for (final player in _preloadPlayers.values) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    _preloadPlayers.clear();
  }

  /// Full cleanup.
  Future<void> dispose() async {
    await stop();
    await disposePreloads();
    await _player.dispose();
  }
}
