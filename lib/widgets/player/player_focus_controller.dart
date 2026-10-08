import 'package:flutter/widgets.dart';

/// Player overlay chrome (S3).
enum PlayerChrome {
  /// No controls; arrows/OK show chrome or toggle play.
  hidden,

  /// Transport / options / next visible.
  controls,

  /// Subtitle, audio, or quality list.
  subPanel,
}

enum PlayerSubPanelKind {
  subtitle,
  audio,
  quality,
}

/// Owns chrome visibility and focus targets for TV remote operation.
///
/// Back layers (mandatory):
/// 1. [subPanel] → close panel, return to controls
/// 2. [controls] → hide chrome
/// 3. [hidden] → exit player (caller pops route)
class PlayerFocusController {
  PlayerFocusController({
    FocusNode? playPause,
    FocusNode? progress,
    FocusNode? subtitle,
    FocusNode? audio,
    FocusNode? quality,
    FocusNode? nextEpisode,
  })  : playPause = playPause ?? FocusNode(debugLabel: 'player_play'),
        progress = progress ?? FocusNode(debugLabel: 'player_progress'),
        subtitle = subtitle ?? FocusNode(debugLabel: 'player_subtitle'),
        audio = audio ?? FocusNode(debugLabel: 'player_audio'),
        quality = quality ?? FocusNode(debugLabel: 'player_quality'),
        nextEpisode = nextEpisode ?? FocusNode(debugLabel: 'player_next');

  PlayerChrome chrome = PlayerChrome.hidden;
  PlayerSubPanelKind? openPanelKind;

  final FocusNode playPause;
  final FocusNode progress;
  final FocusNode subtitle;
  final FocusNode audio;
  final FocusNode quality;
  final FocusNode nextEpisode;

  FocusNode? lastControlsNode;
  FocusNode? panelEntryNode;

  bool get isControlsVisible =>
      chrome == PlayerChrome.controls || chrome == PlayerChrome.subPanel;

  void dispose() {
    playPause.dispose();
    progress.dispose();
    subtitle.dispose();
    audio.dispose();
    quality.dispose();
    nextEpisode.dispose();
  }

  void showControls({FocusNode? prefer}) {
    chrome = PlayerChrome.controls;
    openPanelKind = null;
    final target = prefer ?? lastControlsNode ?? playPause;
    _scheduleRequest(target);
  }

  void hideControls() {
    try {
      lastControlsNode = FocusManager.instance.primaryFocus;
    } catch (_) {
      // Binding may be absent in unit tests.
    }
    chrome = PlayerChrome.hidden;
    openPanelKind = null;
  }

  void openPanel(PlayerSubPanelKind kind, {FocusNode? listEntry}) {
    lastControlsNode = switch (kind) {
      PlayerSubPanelKind.subtitle => subtitle,
      PlayerSubPanelKind.audio => audio,
      PlayerSubPanelKind.quality => quality,
    };
    chrome = PlayerChrome.subPanel;
    openPanelKind = kind;
    panelEntryNode = listEntry;
    if (listEntry != null) {
      _scheduleRequest(listEntry);
    }
  }

  void closePanel() {
    chrome = PlayerChrome.controls;
    openPanelKind = null;
    final back = lastControlsNode ?? subtitle;
    _scheduleRequest(back);
  }

  /// Returns true if the back key was fully handled inside the player chrome.
  /// Returns false when chrome is already hidden — caller should exit to Detail.
  bool handleBack() {
    switch (chrome) {
      case PlayerChrome.subPanel:
        closePanel();
        return true;
      case PlayerChrome.controls:
        hideControls();
        return true;
      case PlayerChrome.hidden:
        return false;
    }
  }

  void _scheduleRequest(FocusNode node) {
    void request() {
      if (node.context != null) {
        node.requestFocus();
      }
    }

    // Avoid requiring a binding in pure unit tests; fall back to sync request.
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) => request());
    } catch (_) {
      request();
    }
  }
}
