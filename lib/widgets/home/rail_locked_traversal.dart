import 'package:flutter/widgets.dart';

/// Focus traversal that keeps left/right movement inside a single Home rail.
///
/// Up/down still use the default ordered policy so the parent Column / board
/// can move between rails. Left/right never escape this group's descendants.
///
/// Wrap each horizontal rail content (cards + optional See All) with:
/// ```dart
/// FocusTraversalGroup(
///   policy: const RailLockedTraversalPolicy(),
///   child: rowOrList,
/// )
/// ```
class RailLockedTraversalPolicy extends OrderedTraversalPolicy {
  RailLockedTraversalPolicy({super.requestFocusCallback});

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    if (direction == TraversalDirection.left ||
        direction == TraversalDirection.right) {
      final scope = currentNode.nearestScope;
      if (scope == null) return false;

      final members = <FocusNode>[];
      for (final node in scope.traversalDescendants) {
        if (node.skipTraversal || !node.canRequestFocus) continue;
        if (node.context == null) continue;
        members.add(node);
      }
      if (members.isEmpty) return false;

      members.sort((a, b) {
        final ax = _offset(a)?.dx ?? 0;
        final bx = _offset(b)?.dx ?? 0;
        return ax.compareTo(bx);
      });

      final index = members.indexOf(currentNode);
      if (index < 0) {
        // Current not in group list — fall back to first/last by direction.
        final target = direction == TraversalDirection.right
            ? members.first
            : members.last;
        return _request(target);
      }

      if (direction == TraversalDirection.right) {
        if (index >= members.length - 1) return true; // stop at edge
        return _request(members[index + 1]);
      }
      if (index <= 0) return true; // stop at edge
      return _request(members[index - 1]);
    }

    // Vertical: allow parent policy / default ordered behavior.
    return super.inDirection(currentNode, direction);
  }

  Offset? _offset(FocusNode node) {
    final ro = node.context?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;
    return ro.localToGlobal(Offset.zero);
  }

  bool _request(FocusNode node) {
    requestFocusCallback(
      node,
      alignment: 0.0,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
    return true;
  }
}
