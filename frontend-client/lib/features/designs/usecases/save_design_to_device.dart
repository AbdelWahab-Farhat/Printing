import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:path_provider/path_provider.dart';

/// يجلب التصميم ويكتبه حيث يستطيع الهاتف أن يسلّمه لورقة المشاركة.
///
/// **المجلد المؤقت لا «المستندات».** الملف ساعٍ لا نسخة: يعيش الثانيتين بين «تحميل» وورقة
/// النظام التي يختار فيها صاحبه الصور أو «الملفات» أو واتساب. ومكتبةٌ ثانية من كل تصميمٍ فُتح
/// تملأ الهاتف بنسخٍ من ملفاتٍ يحملها الخادم أصلاً.
///
/// واسم الملف هو ما سيراه صاحبه في تلك الورقة وفيما يحفظ إليه، فيُبنى من اسم التصميم لا من
/// رقمه — «شعار المخبز.png» يُعثر عليه بعدها و`design-41` لا.
///
/// منقولٌ عن الصنف نفسه في تطبيق الموظفين.
class SaveDesignToDevice {
  const SaveDesignToDevice(this._repository);

  final DesignRepository _repository;

  /// مسار الملف المكتوب، جاهزاً للمشاركة.
  Future<Either<Failure, String>> call(CustomerDesign design) async {
    final url = design.fileUrl;

    if (url == null || url.isEmpty) {
      // لا فشل شبكةٍ ولا خطأ منّا: الصف وصل بلا رابط، وهذا ما يحدث في ردٍّ لم يحمّله.
      return const Left(Failure.unexpected(message: 'لا يوجد رابط لهذا الملف'));
    }

    final result = await _repository.fileBytes(url);

    return result.fold<Future<Either<Failure, String>>>(
      (failure) async => Left(failure),
      (bytes) async {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/${fileNameFor(design)}');
        await file.writeAsBytes(bytes);

        return Right(file.path);
      },
    );
  }

  /// `شعار المخبز.png` — اسم التصميم صالحاً لنظام الملفات، بامتداده الصحيح.
  ///
  /// عامٌّ وثابت لأنه صافٍ، ولأنه القاعدة الوحيدة في اسم التصميم المحفوظ؛ فيختبره الاختبار
  /// مباشرةً لا عبر كتابة ملف.
  static String fileNameFor(CustomerDesign design) {
    // `/` و`\` تُنهيان جزءاً من المسار، واسمٌ كلّه علامات يترك اسم ملفٍ فارغاً — وكلاهما كتابةٌ
    // تفشل بخطأٍ لا يستطيع أحدٌ أن يفعل به شيئاً.
    final safe = design.label.replaceAll(RegExp(r'[/\\:*?"<>|]'), '-').trim();

    final base = safe.isEmpty || RegExp(r'^[-.\s]*$').hasMatch(safe)
        ? 'تصميم-${design.id}'
        : safe;
    final extension = _extensionFor(design);

    return base.toLowerCase().endsWith(extension) ? base : '$base$extension';
  }

  /// امتداد الملف الأصلي إن أرسله الخادم، ثم نوعه، ثم صنفه.
  ///
  /// والترتيب مقصود: الامتداد الذي كان لملف العميل هو ما تنتظره المطبعة، وتخمينُ `.png` لملف
  /// `.jpg` ينتج ملفاً ترفض بعضُ الأدوات فتحه.
  static String _extensionFor(CustomerDesign design) {
    final original = design.originalFilename;

    if (original != null && original.contains('.')) {
      final extension = original.substring(original.lastIndexOf('.'));
      if (extension.length <= 6) return extension.toLowerCase();
    }

    return switch (design.mimeType) {
      'image/png' => '.png',
      'image/jpeg' || 'image/jpg' => '.jpg',
      'image/webp' => '.webp',
      'application/pdf' => '.pdf',
      _ => design.kind == DesignKind.pdf ? '.pdf' : '.png',
    };
  }
}
