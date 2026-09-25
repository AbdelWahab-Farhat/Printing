import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/attachment_store.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// ينفّذ [AttachmentStore] على مجلد الذاكرة المؤقتة للتطبيق.
///
/// **مجلد الذاكرة المؤقتة، لا «المستندات».** الملف نسخةٌ مما على الخادم، يُعاد تنزيله متى شاء
/// النظام أن يمسحه؛ ووضعه في «المستندات» كان سيجعله نسخةً احتياطية في iCloud لا يطلبها أحد.
///
/// **Dio مستقلٌّ بلا معترضات**، لا عميل الـAPI: الرابط موقَّع ولا يحتاج رمز الدخول، ورابطٌ موقَّع
/// من S3 يرفض الطلب الذي يحمل توقيعين — رأسَ `Authorization` وتوقيعَ الرابط معاً.
class AttachmentStoreImpl implements AttachmentStore {
  AttachmentStoreImpl({Dio? dio, Future<Directory> Function()? root})
    : _dio = dio ?? Dio(),
      _root = root ?? getApplicationCacheDirectory;

  final Dio _dio;
  final Future<Directory> Function() _root;

  @override
  Future<String?> localPath({required String key, required String fileName}) async {
    final file = File(await _pathFor(key, fileName));

    return file.existsSync() ? file.path : null;
  }

  @override
  Future<Either<Failure, String>> download({
    required String url,
    required String key,
    required String fileName,
    void Function(double progress)? onProgress,
    TransferCancel? cancel,
  }) async {
    final target = await _pathFor(key, fileName);
    final partial = '$target.part';
    final token = CancelToken();

    if (cancel != null) unawaited(cancel.whenCancelled.then((_) => token.cancel()));

    return safeTransfer(() async {
      await Directory(File(target).parent.path).create(recursive: true);

      await _dio.download(
        url,
        partial,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );

      await File(partial).rename(target);

      return target;
    });
  }

  /// `support/<key>/<الاسم>`: مجلدٌ لكل ملف، فيبقى اسمه كما سمّاه صاحبه — وهو ما يظهر في عارض
  /// الهاتف وورقة المشاركة — بلا تصادمٍ بين رسالتين أرسلتا «invoice.pdf».
  Future<String> _pathFor(String key, String fileName) async {
    final root = await _root();
    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

    return '${root.path}/support/$key/${safeName.isEmpty ? 'file' : safeName}';
  }
}
