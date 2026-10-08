import 'package:flutter/widgets.dart';

/// Search UI phases for TV focus routing (S4).
enum SearchPhase {
  idle,
  typing,
  results,
  empty,
  error,
}

/// Coordinates suggestion-first focus, keyboard↔results bridges, and result restore.
class SearchFocusController {
  SearchFocusController({
    FocusNode? field,
  }) : field = field ?? FocusNode(debugLabel: 'search_field');

  final FocusNode field;

  SearchPhase phase = SearchPhase.idle;
  bool userMoved = false;
  bool didInitialFocus = false;

  /// Result itemId to restore after returning from Detail.
  String? restoreResultId;

  final List<FocusNode> suggestionNodes = [];
  final List<FocusNode> resultNodes = [];
  final Map<String, FocusNode> resultById = {};

  void markUserMoved() => userMoved = true;

  void resetForEntry() {
    userMoved = false;
    didInitialFocus = false;
  }

  bool get canApplyDefaultFocus => !userMoved && !didInitialFocus;

  void setPhase(SearchPhase next) {
    phase = next;
  }

  void registerSuggestions(List<FocusNode> nodes) {
    suggestionNodes
      ..clear()
      ..addAll(nodes);
  }

  void registerResults(List<({String id, FocusNode node})> items) {
    resultNodes.clear();
    resultById.clear();
    for (final item in items) {
      resultNodes.add(item.node);
      resultById[item.id] = item.node;
    }
  }

  /// Prefer first suggestion; else field.
  void applyInitialFocus() {
    if (!canApplyDefaultFocus) return;
    if (suggestionNodes.isNotEmpty &&
        suggestionNodes.first.context != null &&
        suggestionNodes.first.canRequestFocus) {
      suggestionNodes.first.requestFocus();
      didInitialFocus = true;
      return;
    }
    if (field.context != null && field.canRequestFocus) {
      field.requestFocus();
      didInitialFocus = true;
    }
  }

  void saveResultBeforeLeave(String itemId) {
    restoreResultId = itemId;
  }

  /// After Detail pop: restore result card or fall back.
  bool restoreResultFocus() {
    final id = restoreResultId;
    restoreResultId = null;
    if (id != null) {
      final node = resultById[id];
      if (node != null &&
          node.context != null &&
          node.canRequestFocus) {
        node.requestFocus();
        return true;
      }
    }
    if (resultNodes.isNotEmpty &&
        resultNodes.first.context != null &&
        resultNodes.first.canRequestFocus) {
      resultNodes.first.requestFocus();
      return true;
    }
    return false;
  }

  /// Keyboard edge: move into first result when available.
  bool focusFirstResult() {
    for (final node in resultNodes) {
      if (node.context != null && node.canRequestFocus) {
        node.requestFocus();
        return true;
      }
    }
    return false;
  }

  /// Result top edge: prefer chips/suggestions/field (caller supplies order).
  bool focusUpFromResults(List<FocusNode?> preferred) {
    for (final node in preferred) {
      if (node != null &&
          node.context != null &&
          node.canRequestFocus) {
        node.requestFocus();
        return true;
      }
    }
    return false;
  }

  void dispose() {
    // Only dispose field if we created it — callers owning external nodes
    // should not pass them here or should dispose themselves.
    field.dispose();
    suggestionNodes.clear();
    resultNodes.clear();
    resultById.clear();
  }
}
