import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/device_saver.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

/// ينفّذ [DeviceSaver] بـ`file_saver`، ويجرّب مكاناً بعد مكان حتى يقبل الهاتف الملف.
///
/// **الترتيب هو كل ما هنا:**
/// - الصورة إلى «الصور». فإن رفضتها (إذنٌ مُنع على آيفون، صيغةٌ لا تقبلها المكتبة، أو أندرويد ٩ بلا
///   إذن تخزين) ذهبت إلى حيث تذهب الملفات — ما دام للملف مكانٌ لا يصل صاحبَه خطأ.
/// - الملف على آيفون إلى «المستندات»، وهي مجلد التطبيق في «الملفات» لأن `Info.plist` يفتحها
///   (`UIFileSharingEnabled`). على أندرويد إلى «التنزيلات» عبر MediaStore بلا إذن من أندرويد ١٠.
/// - وأندرويد ٩ وما قبله بلا إذن تخزين: نافذة النظام «حفظ باسم» — لا تحتاج إذناً، وهي حفظٌ لا
///   مشاركة. لا نسأل الإذن نفسه: ذلك كودٌ أصليّ لهواتف قليلة، والنافذة تكفيها.
///
/// - **وعلى الويب لا ترتيب**: لا «صور» ولا «ملفات» يصلها المتصفّح، فكلُّ ملفٍّ تنزيلٌ إلى مجلّد
///   التنزيلات باسمه — وهو «الحفظ» الذي يعرفه من يعمل على حاسوب.
///
/// [isIOS] و[isWeb] و[plugin] يُمرَّرون ليُختبر الترتيب على المنصّات من جهازٍ واحد.
class DeviceSaverImpl implements DeviceSaver {
  DeviceSaverImpl({FileSaver? plugin, bool? isIOS, bool? isWeb})
    : _plugin = plugin ?? FileSaver.instance,
      _isWeb = isWeb ?? kIsWeb,
      _isIOS = isIOS ?? (!kIsWeb && Platform.isIOS);

  final FileSaver _plugin;
  final bool _isIOS;
  final bool _isWeb;

  static const _refused = Failure.unexpected(message: 'تعذّر حفظ الملف على الهاتف');

  @override
  Future<Either<Failure, SavePlace?>> toPhotos({
    required String path,
    required String mimeType,
  }) async {
    if (_isWeb) return _download(path: path, mimeType: mimeType);

    final saved = await safePlatformCall(
      () => _plugin.saveToGallery(
        name: _nameOf(path),
        filePath: path,
        // الاسم يحمل امتداده؛ بدون هذا تضيف الإضافة امتداداً ثانياً.
        includeExtension: false,
        mimeType: MimeType.custom,
        customMimeType: mimeType,
      ),
    );

    if (saved.isRight()) return const Right(SavePlace.photos);

    return toFiles(path: path, mimeType: mimeType);
  }

  @override
  Future<Either<Failure, SavePlace?>> toFiles({
    required String path,
    required String mimeType,
  }) async {
    if (_isWeb) return _download(path: path, mimeType: mimeType);

    if (_isIOS) {
      final saved = await safePlatformCall(
        () => _plugin.saveFile(
          name: _nameOf(path),
          filePath: path,
          includeExtension: false,
          mimeType: MimeType.custom,
          customMimeType: mimeType,
        ),
      );

      return saved.bimap((_) => _refused, (_) => SavePlace.files);
    }

    final downloaded = await safePlatformCall(
      () => _plugin.saveToDownloads(
        name: _nameOf(path),
        filePath: path,
        includeExtension: false,
        mimeType: MimeType.custom,
        customMimeType: mimeType,
      ),
    );

    if (downloaded.isRight()) return const Right(SavePlace.downloads);

    final chosen = await safePlatformCall(
      () => _plugin.saveAs(
        name: _nameOf(path),
        filePath: path,
        includeExtension: false,
        mimeType: MimeType.custom,
        customMimeType: mimeType,
      ),
    );

    return chosen.bimap((_) => _refused, (uri) => uri == null ? null : SavePlace.chosen);
  }

  /// تنزيلٌ من المتصفّح. [path] رابط blob صنعه [LocalFiles]، فالبايتات تُقرأ منه والاسم من سجلّه.
  Future<Either<Failure, SavePlace?>> _download({
    required String path,
    required String mimeType,
  }) async {
    final saved = await safePlatformCall(
      () async => _plugin.saveFile(
        name: LocalFiles.nameOf(path),
        bytes: await LocalFiles.readBytes(path),
        includeExtension: false,
        mimeType: MimeType.custom,
        customMimeType: mimeType,
      ),
    );

    return saved.bimap((_) => _refused, (_) => SavePlace.downloads);
  }

  /// `شعار المخبز.png` من `/tmp/…/شعار المخبز.png` — الاسم الذي سيراه صاحبه.
  static String _nameOf(String path) => path.substring(path.lastIndexOf('/') + 1);
}
