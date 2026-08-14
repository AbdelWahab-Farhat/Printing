import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the app believes the signed-in person may do.
///
/// Pure Dart — no binding, no GetIt, no widget. That is a property of the design, not of the
/// test: the answer is a set lookup, so it can be asserted directly.
///
/// Arrange - Act - Assert throughout.
void main() {
  AuthUser userWith(List<String>? permissions) => AuthUser(
    id: 1,
    name: 'عبدالوهاب',
    phone: '0911234567',
    permissions: permissions,
  );

  test('an unfilled session permits nothing', () {
    // Arrange
    final session = Session();

    // Act
    final signedIn = session.isSignedIn;

    // Assert — fail closed. "Not loaded yet" and "not allowed" must give the same answer, or a
    // control flashes onto the screen before the truth arrives.
    expect(signedIn, isFalse);
    expect(session.can(AppPermission.manageProducts), isFalse);
    expect(session.can(AppPermission.viewProducts), isFalse);
  });

  test('a grant opens exactly one door', () {
    // Arrange
    final session = Session();

    // Act
    session.adopt(userWith(['products.view']));

    // Assert — the second half is the one that matters: it is what catches an `|| isAdmin`
    // creeping into `can()`, or a view permission being read as a manage one.
    expect(session.can(AppPermission.viewProducts), isTrue);
    expect(session.can(AppPermission.manageProducts), isFalse);
  });

  test('an administrator is told every permission, and holds every one', () {
    // Arrange — the server expands the catalogue for an admin, so the app needs no admin
    // concept of its own and never ORs `isAdmin` into the answer.
    final session = Session();

    // Act
    session.adopt(
      userWith([for (final permission in AppPermission.values) permission.wire]),
    );

    // Assert — looped over the enum, so a case added here with no grant behind it goes red.
    for (final permission in AppPermission.values) {
      expect(session.can(permission), isTrue, reason: '${permission.wire} was refused');
    }
  });

  test('a permission this build has no case for is inert, and visible', () {
    // Arrange
    final session = Session();

    // Act — the server is ahead of the app. `orders.manage` used to stand in for this and
    // stopped working the day orders shipped, which is the hazard: the example has to be a
    // permission nobody is about to build.
    session.adopt(userWith(['products.view', 'invoices.manage']));

    // Assert — it neither throws nor is silently dropped: kept, so a developer can find out
    // the app is behind the API.
    expect(session.can(AppPermission.viewProducts), isTrue);
    expect(session.unrecognised, {'invoices.manage'});
  });

  test('a response that did not mention permissions is a bug, not an empty answer', () {
    // Arrange
    final session = Session();

    // Act & Assert — null means the backend omitted the key, which would hide everything from
    // everybody. Better to fail loudly in debug than to look like a permissions problem.
    expect(() => session.adopt(userWith(null)), throwsA(isA<AssertionError>()));
  });

  test('an account allowed nothing is a real answer, not a missing one', () {
    // Arrange
    final session = Session();

    // Act
    session.adopt(userWith([]));

    // Assert
    expect(session.isSignedIn, isTrue);
    expect(session.can(AppPermission.viewProducts), isFalse);
    expect(session.unrecognised, isEmpty);
  });

  test('clearing leaves nothing behind', () {
    // Arrange
    final session = Session()..adopt(userWith(['products.manage']));

    // Act
    session.clear();

    // Assert — these phones are shared between staff.
    expect(session.user, isNull);
    expect(session.isSignedIn, isFalse);
    expect(session.can(AppPermission.manageProducts), isFalse);
  });

  test('adopting and clearing each announce themselves', () {
    // Arrange — this is what lets a gate rebuild when the set changes with the tree mounted,
    // which happens on every pull-to-refresh and after every healed 403.
    final session = Session();
    final seen = <int>[];
    session.revision.addListener(() => seen.add(session.revision.value));

    // Act
    session
      ..adopt(userWith(['products.view']))
      ..clear();

    // Assert
    expect(seen, hasLength(2));
  });
}
