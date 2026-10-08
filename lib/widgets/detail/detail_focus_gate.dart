import 'package:flutter/widgets.dart';

/// Focus gate for Detail / Showcase (S2).
///
/// Complements upstream [DetailFocusCoordinator] (primaryEntry / focusEntry).
/// Use this gate to decide *whether* to call focusEntry / requestFocus on
/// primary — not to replace the coordinator's node ownership.
///
/// - Initial focus may land on Primary Play once.
/// - After the user moves focus, async metadata must not steal it.
/// - When Primary becomes enabled later, auto-focus only if the user never moved.
class DetailFocusGate {
  bool userMoved = false;
  bool didInitialFocus = false;

  void markUserMoved() {
    userMoved = true;
  }

  void resetForNewDetail() {
    userMoved = false;
    didInitialFocus = false;
  }

  bool get canApplyDefaultFocus => !userMoved && !didInitialFocus;

  /// Call on first frame or when entering Detail.
  void tryFocusPrimary(FocusNode primary) {
    if (!canApplyDefaultFocus) return;
    if (primary.context == null) return;
    primary.requestFocus();
    didInitialFocus = true;
  }

  /// Primary flipped from disabled → enabled (e.g. sources became ready).
  void onPrimaryBecameEnabled(FocusNode primary) {
    tryFocusPrimary(primary);
  }

  /// Async sections (cast, recommendations, images) finished loading.
  /// Intentionally does not request focus.
  void onAsyncSectionReady() {}
}
