import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/device_saver.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:path_provider/path_provider.dart';

/// «تحميل»: يجلب التصميم ويحفظه على الهاتف حيث يجده صاحبه — **بلا ورقة مشاركة**.
///
/// الصورة إلى «الصور»، والـPDF إلى «التنزيلات» على أندرويد و«الملفات» على آيفون. كان الزرّ
/// يسلّم الملف لورقة المشاركة، ورُفض ذلك (٢٠٢٦-١٠-١٢): من يضغط «تحميل» يريد الملف على هاتفه.
///
/// **يُكتب أولاً في المجلد المؤقت** ثم يُنسخ منه إلى مكانه: [DeviceSaver] يأخذ مساراً لا
/// بايتات، فلا يُحمل الملف في الذاكرة مرتين.
///
/// واسم الملف هو ما سيراه صاحبه في «الصور» و«الملفات»، فيُبنى من اسم التصميم لا من رقمه —
/// «شعار المخبز.png» يُعثر عليه بعدها و`design-41` لا.
///
/// منقولٌ عن الصنف نفسه في تطبيق الموظفين.
class SaveDesignToDevice {
  SaveDesignToDevice(
    this._repository,
    this._saver, {
    Future<Directory> Function()? temporaryDirectory,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final DesignRepository _repository;
  final DeviceSaver _saver;
  final Future<Directory> Function() _temporaryDirectory;

  /// أين حُفظ — أو `null` حين أغلق صاحبه نافذة «حفظ باسم».
  Future<Either<Failure, SavePlace?>> call(CustomerDesign design) async {
    final fetched = await _fetch(design);

    return fetched.fold<Future<Either<Failure, SavePlace?>>>(
      (failure) async => Left(failure),
      (path) {
        final mimeType = mimeTypeFor(design);

        return mimeType.startsWith('image/')
            ? _saver.toPhotos(path: path, mimeType: mimeType)
            : _saver.toFiles(path: path, mimeType: mimeType);
      },
    );
  }

  /// الملف في المجلد المؤقت ومساره.
  ///
  /// والرابط الموقَّع تنتهي صلاحيته، فيُجلب بما تحمله الشاشة **الآن** — ولذلك يُمرَّر التصميم لا
  /// عنوانٌ محفوظ.
  Future<Either<Failure, String>> _fetch(CustomerDesign design) async {
    final url = design.fileUrl;

    if (url == null || url.isEmpty) {
      // لا فشل شبكةٍ ولا خطأ منّا: الصف وصل بلا رابط، وهذا ما يحدث في ردٍّ لم يحمّله.
      return const Left(Failure.unexpected(message: 'لا يوجد رابط لهذا الملف'));
    }

    final result = await _repository.fileBytes(url);

    return result.fold<Future<Either<Failure, String>>>(
      (failure) async => Left(failure),
      (bytes) async {
        final directory = await _temporaryDirectory();
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

  /// النوع الذي يُحفظ به الملف، **من امتداد اسمه** لا مما قاله الخادم.
  ///
  /// «الصور» والمعرض يقرآن الملف بنوعه، ويعرضه «الملفات» بامتداده؛ فإن اختلفا كان ملفاً `.jpg`
  /// يُعامَل كـPNG. والامتداد هو ما يبقى مع الملف، فهو الحَكَم. وهو أيضاً ما يقرّر «الصور» أم
  /// «التنزيلات»: كل `image/*` صورة.
  static String mimeTypeFor(CustomerDesign design) {
    final name = fileNameFor(design).toLowerCase();

    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.pdf')) return 'application/pdf';

    return design.mimeType ?? 'application/octet-stream';
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
