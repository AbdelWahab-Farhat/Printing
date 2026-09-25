import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **كل زرٍّ على الشاشة `AppButton`، وكل حقل إدخالٍ `AppTextField`.**
///
/// الزرّ والحقل مكتوبان مرّةً واحدة في `core/widgets/`، وشكلهما يتغيّر هناك وحده. زرٌّ بُني من
/// `FilledButton` أو `OutlinedButton` مباشرةً لا يسمع بذلك التغيير: يبقى على الشكل القديم في
/// شاشةٍ لا يتذكّرها أحد، ولا يحمل انشغال `AppButton` ولا عرضه الكامل. القاعدة في RULES §7 منذ
/// البداية، ومع ذلك تسرّبت ثمانية أزرارٍ وحقلٌ واحد — فصار البناء يفرضها بدل الذاكرة، كما يفعل
/// `floating_action_button_hero_test.dart` لوسوم الـ Hero.
///
/// **ما يُستثنى، ولماذا:**
///   * `app_button.dart` و`app_text_field.dart` — هما التنفيذ نفسه.
///   * `app_dialog.dart` — `AlertDialog.actions` يرتّب أزراره بنفسه (RULES §7).
///   * `TextButton` كلّه — هو ما تنتظره `actions` في أي `AlertDialog`، ولا شاشة تستعمله خارج حوار.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// ملفاتٌ تبني الأدوات الخام عن قصد — انظر أعلاه.
  const exempt = {
    'lib/core/widgets/app_button.dart',
    'lib/core/widgets/app_text_field.dart',
    'lib/core/widgets/app_dialog.dart',
  };

  /// مواضع [pattern] في الكود نفسه دون التعليقات: سطرٌ في شرحٍ يذكر `TextField(` ليس حقلاً.
  ///
  /// تُقرأ الملفات من القرص لا من قائمة هنا، لأن القائمة يحدّثها الشخص نفسه الذي وُجد الاختبار
  /// ليمسكه.
  List<String> offendersOf(RegExp pattern) {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart') && !exempt.contains(file.path));

    final offenders = <String>[];

    for (final file in sources) {
      final lines = file.readAsLinesSync();

      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (pattern.hasMatch(lines[i])) offenders.add('${file.path}:${i + 1}');
      }
    }

    return offenders;
  }

  test('no screen builds a Material button of its own', () {
    // Arrange — المُنشئات وحدها لا `styleFrom`: الثيم يضبط الأزرار ولا يبني منها شيئاً.
    final raw = RegExp(
      r'\b(FilledButton|OutlinedButton|ElevatedButton)(\.(icon|tonal|tonalIcon))?\(',
    );

    // Act
    final offenders = offendersOf(raw);

    // Assert
    expect(
      offenders,
      isEmpty,
      reason:
          'These buttons skip AppButton, so they miss its look and its busy state — use '
          'AppButton / .tonal / .outlined: ${offenders.join(', ')}',
    );
  });

  test('no screen builds a text input of its own', () {
    // Arrange
    final raw = RegExp(r'\b(TextField|TextFormField)\(');

    // Act
    final offenders = offendersOf(raw);

    // Assert
    expect(
      offenders,
      isEmpty,
      reason:
          'These inputs skip AppTextField, so they miss its look, its error slot and its '
          'focus states: ${offenders.join(', ')}',
    );
  });
}
