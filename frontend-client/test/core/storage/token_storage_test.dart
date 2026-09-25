import 'package:dayaa_client/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// الرمزُ وجلستُه: [TokenStorage.revision] يرتفع مع كل دخولٍ وخروج.
///
/// **به تتبع شارةُ «الدعم» الحيّة الجلسة** — تفتح قناة العميل حين يدخل وتغلقها حين يخرج. رقمٌ لا
/// يرتفع عند الخروج يُبقي قناةَ العميل السابق مفتوحةً على هاتفٍ صار في يد غيره.
///
/// Arrange - Act - Assert في كل حالة.
class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage secure;

  setUp(() {
    secure = _MockSecureStorage();

    when(
      () => secure.write(key: any(named: 'key'), value: any(named: 'value')),
    ).thenAnswer((_) async {});
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  test('signing in and signing out each move the revision', () async {
    // Arrange
    final tokens = TokenStorage(secure);
    final start = tokens.revision.value;

    // Act
    await tokens.write('1|abc');
    final afterSignIn = tokens.revision.value;
    await tokens.clear();
    final afterSignOut = tokens.revision.value;

    // Assert
    expect(afterSignIn, start + 1);
    expect(afterSignOut, start + 2);
    expect(tokens.hasTokenInMemory, isFalse);
  });

  test('a listener hears the change after the token is in place', () async {
    // Arrange
    final tokens = TokenStorage(secure);
    bool? signedInWhenHeard;
    tokens.revision.addListener(() => signedInWhenHeard = tokens.hasTokenInMemory);

    // Act
    await tokens.write('1|abc');

    // Assert — من يسمع يجد الرمز حاضراً، فيفتح القناة باسم الجلسة الجديدة.
    expect(signedInWhenHeard, isTrue);
  });
}
