import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// ملفٌّ على هذا الجهاز يُعرف بمساره — والمسارُ على الويب رابطُ `blob:` في ذاكرة الصفحة.
///
/// **التطبيق كلُّه يتداول الملفات مساراتٍ**: ما يختاره الموظف (`PickedFile`)، وما يُكتب ليُحفظ أو
/// يُشارك (الفاتورة، رمز QR، معاينة الكيس، التصميم)، وما يُرفع. على الهاتف المسار ملفٌّ على القرص،
/// وعلى الويب لا قرص: `dart:io` يُبنى هناك ويرمي `UnsupportedError` عند أول قراءة، و`path_provider`
/// بلا تنفيذٍ أصلاً. فبدل أن يسأل كلُّ موضعٍ «أأنا على الويب؟»، يمرّ كلُّ ما يلمس الملف من هنا،
/// والمسارُ نفسه يبقى العملةَ بين الطبقات كما كان — على الويب رابطُ blob تصنعه [writeTemporary]
/// أو يعيده منتقي الصور.
///
/// **على الهاتف لا يتغيّر شيء**: الفروع غير الويب هي ما كان مكتوباً في كلّ موضعٍ قبل هذا الملف —
/// `MultipartFile.fromFile` يقرأ من القرص دفعاتٍ ولا يحمل تصميماً من ٢٥ ميجابايت في الذاكرة.
abstract final class LocalFiles {
  /// أسماءُ الملفات على الويب، لأن رابط blob لا يحمل اسماً. يُقرأ في [nameOf].
  static final Map<String, String> _webNames = {};

  /// يكتب [bytes] ملفاً مؤقتاً اسمُه [fileName] ويُرجع مساره.
  ///
  /// على الهاتف في مجلّد النظام المؤقّت؛ وعلى الويب رابطُ blob يبقى ما بقيت الصفحة.
  static Future<String> writeTemporary(
    String fileName,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    if (kIsWeb) {
      final path = XFile.fromData(bytes, name: fileName, mimeType: mimeType).path;
      _webNames[path] = fileName;

      return path;
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    return file.path;
  }

  /// يسجّل اسمَ ملفٍ اختاره الموظف على الويب، حيث يصل رابطاً بلا اسم.
  static void rememberName(String path, String fileName) {
    if (kIsWeb) _webNames[path] = fileName;
  }

  /// اسمُ الملف كما يُحفظ: آخر جزءٍ من المسار، أو على الويب الاسمُ الذي كُتب به.
  static String nameOf(String path) =>
      _webNames[path] ?? path.substring(path.lastIndexOf('/') + 1);

  static Future<Uint8List> readBytes(String path) =>
      kIsWeb ? XFile(path).readAsBytes() : File(path).readAsBytes();

  static Future<int> length(String path) => kIsWeb ? XFile(path).length() : File(path).length();

  /// هل ما زال الملف موجوداً. على الويب ما صُنع في هذه الصفحة موجودٌ ما بقيت.
  static bool exists(String path) => kIsWeb ? path.startsWith('blob:') : File(path).existsSync();

  /// يحذف الملف بلا شكوى إن لم يكن. على الويب يُحرَّر رابط الـblob حين تُغلق الصفحة.
  static void delete(String path) {
    if (kIsWeb) {
      _webNames.remove(path);
      return;
    }

    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  /// جزءُ رفعٍ من الملف. على الهاتف يُقرأ من القرص دفعاتٍ؛ وعلى الويب تُقرأ بايتاته من الـblob.
  static Future<MultipartFile> multipart(
    String path, {
    required String filename,
    DioMediaType? contentType,
  }) async {
    if (kIsWeb) {
      return MultipartFile.fromBytes(
        await XFile(path).readAsBytes(),
        filename: filename,
        contentType: contentType,
      );
    }

    return MultipartFile.fromFile(path, filename: filename, contentType: contentType);
  }

  /// صورةُ الملف للعرض: من القرص على الهاتف، ومن رابط الـblob على الويب.
  static ImageProvider image(String path) {
    if (kIsWeb) return NetworkImage(path);

    return FileImage(File(path));
  }
}
