import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/device_saver.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:file_saver/file_saver.dart';

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
/// [isIOS] و[plugin] يُمرَّران ليُختبر الترتيب على المنصّتين من جهازٍ واحد. منقولٌ عن تطبيق
/// الموظفين.
class DeviceSaverImpl implements DeviceSaver {
  DeviceSaverImpl({FileSaver? plugin, bool? isIOS})
    : _plugin = plugin ?? FileSaver.instance,
      _isIOS = isIOS ?? Platform.isIOS;

  final FileSaver _plugin;
  final bool _isIOS;

  static const _refused = Failure.unexpected(message: 'تعذّر حفظ الملف على الهاتف');

  @override
  Future<Either<Failure, SavePlace?>> toPhotos({
    required String path,
    required String mimeType,
  }) async {
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

  /// `شعار المخبز.png` من `/tmp/…/شعار المخبز.png` — الاسم الذي سيراه صاحبه.
  static String _nameOf(String path) => path.substring(path.lastIndexOf('/') + 1);
}
