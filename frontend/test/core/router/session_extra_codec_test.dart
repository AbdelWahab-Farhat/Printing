import 'package:dayaa/core/router/session_extra_codec.dart';
import 'package:flutter_test/flutter_test.dart';

/// على الويب يكتب المتصفّح `extra` في سجلّه، والكائن نفسه يجب أن يعود عند الرجوع إليه.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  test('الكائن يعود هو نفسه، لا نسخةً منه', () {
    // Arrange
    final codec = SessionExtraCodec();
    final filter = _Filter('الجاهزة');

    // Act
    final restored = codec.decode(codec.encode(filter));

    // Assert
    expect(restored, same(filter));
  });

  test('ما يُكتب بـJSON يمرّ بنفسه', () {
    // Arrange
    final codec = SessionExtraCodec();
    const values = <Object?>[null, 'طلبية #52', 52, 1.5, true];

    // Act
    final restored = values.map((value) => codec.decode(codec.encode(value)));

    // Assert
    expect(restored, values);
  });

  test('الكائن نفسه يُكتب بالرقم نفسه في كل خطوة، فلا تمتلئ الذاكرة بتكراره', () {
    // Arrange
    final codec = SessionExtraCodec();
    final filter = _Filter('الكل');

    // Act
    final first = codec.encode(filter);
    final second = codec.encode(filter);

    // Assert
    expect(second, first);
  });

  test('ما لا يُعرف — سجلٌّ من صفحةٍ سابقة أو قيمةٌ غريبة — يعود null كرابطٍ بلا extra', () {
    // Arrange
    final codec = SessionExtraCodec();
    final stale = SessionExtraCodec().encode(_Filter('من صفحةٍ أُغلقت'));

    // Act
    final restored = [codec.decode(stale), codec.decode('غريب'), codec.decode(const [1, 2, 3])];

    // Assert
    expect(restored, everyElement(isNull));
  });

  test('الأقدم يُرمى بعد الحدّ، والأحدث يبقى', () {
    // Arrange
    final codec = SessionExtraCodec();
    final oldest = _Filter('أول');
    final encodedOldest = codec.encode(oldest);
    final rest = [for (var i = 0; i < 600; i++) _Filter('$i')];
    final encodedRest = rest.map(codec.encode).toList();

    // Act
    final oldestBack = codec.decode(encodedOldest);
    final newestBack = codec.decode(encodedRest.last);

    // Assert
    expect(oldestBack, isNull);
    expect(newestBack, same(rest.last));
  });
}

class _Filter {
  _Filter(this.title);

  final String title;
}
