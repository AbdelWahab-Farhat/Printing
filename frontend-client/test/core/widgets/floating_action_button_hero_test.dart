import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Every floating action button names its own hero tag.**
///
/// The shell is a `StatefulShellRoute.indexedStack`, so every tab stays mounted while another
/// is on screen — the whole point of it, since a half-scrolled catalogue survives a trip to the
/// customers tab. What it also means is that the products tab's button and the customers tab's
/// button are in **one subtree at the same time**, and Flutter gives every FAB the same default
/// hero tag. Two of them is an assertion on every frame:
///
/// ```text
/// There are multiple heroes that share the same tag within a subtree.
/// In this case, multiple heroes had the following tag: <default FloatingActionButton tag>
/// ```
///
/// It is invisible in a debug run until somebody holds both permissions, which is exactly the
/// kind of bug that ships. So the rule is enforced by the build instead of by remembering it —
/// the same shape as the backend's `ModelConventionsTest`, and for the same reason.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('every FloatingActionButton in lib/ sets a heroTag', () {
    // Arrange — read from disk rather than from a list here: a list would need updating by the
    // very person this test exists to catch.
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();

    // Act
    final offenders = <String>[];

    for (final file in sources) {
      final text = file.readAsStringSync();

      for (final match in RegExp(r'FloatingActionButton(\.\w+)?\(').allMatches(text)) {
        // The tag has to be an argument of *this* call, so the window is the call itself —
        // wide enough for a comment above the argument, far short of the next widget.
        final window = text.substring(
          match.end,
          (match.end + 400).clamp(0, text.length),
        );

        if (!window.contains('heroTag:')) {
          final line = '\n'.allMatches(text.substring(0, match.start)).length + 1;
          offenders.add('${file.path}:$line');
        }
      }
    }

    // Assert
    expect(
      offenders,
      isEmpty,
      reason:
          'These floating action buttons would share the default hero tag with every other '
          'one alive at the same time — give each a `heroTag`: ${offenders.join(', ')}',
    );
  });

  test('no two of them share a tag', () {
    // Arrange
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    // Act
    final tags = <String, List<String>>{};

    for (final file in sources) {
      final text = file.readAsStringSync();

      for (final match in RegExp("heroTag: '([^']+)'").allMatches(text)) {
        tags.putIfAbsent(match.group(1)!, () => []).add(file.path);
      }
    }

    final shared = {
      for (final entry in tags.entries)
        if (entry.value.length > 1) entry.key: entry.value,
    };

    // Assert — a tag copy-pasted with the button it came from is the same bug wearing a name.
    expect(shared, isEmpty, reason: 'Duplicated hero tags: $shared');
  });
}
