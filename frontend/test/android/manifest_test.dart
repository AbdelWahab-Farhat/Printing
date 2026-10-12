import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ما يحمله البيان الذي يُشحن من أذونات — ما لا يظهر إلا في البيان المدموج يُحرس من المصدر.
///
/// منقولٌ عن `frontend-client/test/android/manifest_test.dart`.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  test('القراءة من التخزين التي يفترضها الدمج تُنزع', () {
    // Arrange — `file_saver` يطلب `WRITE_EXTERNAL_STORAGE` حتى أندرويد ٩ ليحفظ التصميم، ودامجُ
    // البيان يفترض معه `READ_EXTERNAL_STORAGE` **بلا حدٍّ أعلى** — إذنٌ يسأل عنه متجر Play ولا
    // يحتاجه شيءٌ هنا.
    final xml = manifest.readAsStringSync();

    // Act
    final removes = RegExp(
      r'<uses-permission\s+android:name\s*=\s*"android\.permission\.READ_EXTERNAL_STORAGE"'
      r'\s+tools:node\s*=\s*"remove"\s*/?>',
    ).hasMatch(xml);

    // Assert
    expect(removes, isTrue);
  });
}
