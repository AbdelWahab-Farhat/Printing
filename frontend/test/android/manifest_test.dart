import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ما يحمله البيان الذي يُشحن من أذونات — ما لا يظهر إلا في البيان المدموج يُحرس من المصدر.
///
/// منقولٌ عن `frontend-client/test/android/manifest_test.dart`.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  test('القراءة من التخزين محدودةٌ بأندرويد ١٢ ولا تُفترض بلا حدّ', () {
    // Arrange — `file_saver` يطلب `WRITE_EXTERNAL_STORAGE` حتى أندرويد ٩ ليحفظ التصميم، ودامجُ
    // البيان يفترض معه `READ_EXTERNAL_STORAGE` **بلا حدٍّ أعلى** — إذنٌ يسأل عنه متجر Play. وورقةُ
    // صور المحادثة (`photo_manager`) تقرأ المكتبة به حتى أندرويد ١٢ وحده، فيُستبدل بحدّه.
    final xml = manifest.readAsStringSync();

    // Act
    final bounded = RegExp(
      r'<uses-permission\s+android:name\s*=\s*"android\.permission\.READ_EXTERNAL_STORAGE"'
      r'\s+android:maxSdkVersion\s*=\s*"32"\s+tools:node\s*=\s*"replace"\s*/?>',
    ).hasMatch(xml);
    final declarations = RegExp(r'android\.permission\.READ_EXTERNAL_STORAGE').allMatches(xml);

    // Assert
    expect(bounded, isTrue);
    expect(declarations, hasLength(1));
  });

  test('صور المحادثة تُقرأ على أندرويد ١٣ فما فوق بإذن الصور وحده', () {
    // Arrange — الصورُ لا الفيديو ولا الصوت: الورقةُ لا تعرض غيرها.
    final xml = manifest.readAsStringSync();

    // Act
    final images = xml.contains('android:name="android.permission.READ_MEDIA_IMAGES"');
    final video = xml.contains('android.permission.READ_MEDIA_VIDEO');

    // Assert
    expect(images, isTrue);
    expect(video, isFalse);
  });
}
