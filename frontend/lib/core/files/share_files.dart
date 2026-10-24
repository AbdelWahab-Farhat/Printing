import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// يسلّم الملفات لورقة المشاركة في الهاتف — **وعلى الويب ينزّلها**.
///
/// على الهاتف ورقةُ المشاركة هي الطريق إلى واتساب وإلى «حفظ في الملفات» معاً، ولذلك اختيرت للفاتورة
/// ورمز QR ومعاينة الكيس. على الحاسوب ورقةُ النظام (AirDrop والبريد في ماك، «المشاركة القريبة» في
/// ويندوز) لا تحفظ شيئاً، والموظف الذي يضغط الزرّ يريد الملف في التنزيلات ليرسله أو يطبعه. فيُنزَّل
/// كلُّ ملفٍّ باسمه من [ShareParams.fileNameOverrides] إن وُجد.
Future<void> shareFiles(ShareParams params) async {
  if (!kIsWeb) {
    await SharePlus.instance.share(params);
    return;
  }

  final files = params.files ?? const <XFile>[];

  for (final (index, file) in files.indexed) {
    final names = params.fileNameOverrides;

    await FileSaver.instance.saveFile(
      name: names != null && index < names.length ? names[index] : file.name,
      bytes: await file.readAsBytes(),
      includeExtension: false,
      mimeType: MimeType.custom,
      customMimeType: file.mimeType ?? 'application/octet-stream',
    );
  }
}
