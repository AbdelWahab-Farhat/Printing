import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// الرسائلُ الصوتية على هذا الهاتف بعد أوّل تنزيل، كما يحفظها تيليغرام وبريمولا: الرسالةُ تعبر
/// الشبكة مرّةً، وكلُّ تشغيلٍ بعدها — في هذه الجلسة أو بعد أسبوع — يبدأ من الملف بلا انتظار.
///
/// **بمفتاح المرفق لا بالرابط**: الخادم يوقّع رابطاً جديداً في كل جواب، فمفتاحٌ من الرابط لا يُصيب
/// أبداً. **والتشغيلُ من ملفٍّ لا من رابط** يتجنّب أيضاً بثَّ الصوت من قرص الخادم الخاص عبر رابطٍ
/// موقّع، وهو ما لا يُضمن أن يحتمل طلبات المدى التي يرسلها المشغّل.
///
/// المجلّدُ محدودٌ بـ[maxBytes]، ويُحذف الأقدمُ تشغيلاً أوّلاً. **بلا تنزيلٍ مسبق** خلافاً لبريمولا:
/// الرسالة عشراتُ الكيلوبايتات، فتنزل عند أوّل ضغطةٍ وحلقتُها حول الزرّ.
class VoiceNoteCache {
  VoiceNoteCache({Dio? dio, Future<Directory> Function()? root, this.maxBytes = defaultMaxBytes})
    : _dio = dio ?? _plainDio(),
      _root = root ?? getApplicationCacheDirectory;

  /// نحو يومٍ من الكلام بـ48 kbps.
  static const int defaultMaxBytes = 60 * 1024 * 1024;

  static const String _folder = 'voice_notes';

  final int maxBytes;
  final Dio _dio;
  final Future<Directory> Function() _root;
  Directory? _directory;

  final Map<String, Future<File>> _running = {};

  /// اسمُ الملف: رقمُ المرفق، بامتدادٍ يعرف المشغّلُ الصيغةَ منه.
  static String keyFor(int attachmentId) => 'a$attachmentId.m4a';

  /// الملفُّ إن كان على الهاتف — بلا شبكة.
  Future<File?> cached(String key) async {
    final file = File('${(await _dir()).path}/$key');

    if (!file.existsSync() || file.lengthSync() == 0) return null;

    // شُغّل الآن: آخرُ ما يُحذف حين يُقصّ المجلّد.
    file.setLastModifiedSync(DateTime.now());

    return file;
  }

  /// يحفظ تسجيلاً صُنع على هذا الهاتف تحت مفتاحه — فيشغّله صاحبه بلا أن ينزّله ثانيةً.
  Future<void> keep(String key, String localPath) async {
    final source = File(localPath);
    if (!source.existsSync()) return;

    await source.copy('${(await _dir()).path}/$key');
    unawaited(_trim());
  }

  /// ينزّل [url] باسم [key] — أو ينضمّ إلى تنزيلٍ قائمٍ له. [onProgress] يسمع ٠–١، أو `null`
  /// ما دام الحجمُ مجهولاً. **يرمي إن فشل**، والمشغّلُ هو من يلتقط ويقول ذلك على الزرّ.
  Future<File> fetch(String key, String url, {ValueChanged<double?>? onProgress}) {
    return _running[key] ??= _download(
      key,
      url,
      onProgress,
    ).whenComplete(() => _running.remove(key));
  }

  /// إلى ملف `.part` أوّلاً، ويُعاد تسميته حين يكتمل: تنزيلٌ قُطع لا يمرّ أبداً على أنه الرسالة.
  Future<File> _download(String key, String url, ValueChanged<double?>? onProgress) async {
    final target = File('${(await _dir()).path}/$key');
    final part = File('${target.path}.part');

    await _dio.download(
      url,
      part.path,
      onReceiveProgress: (received, total) =>
          onProgress?.call(total > 0 ? (received / total).clamp(0.0, 1.0) : null),
    );

    if (!part.existsSync() || part.lengthSync() == 0) {
      throw const FileSystemException('رسالةٌ صوتيةٌ فارغة');
    }

    final file = part.renameSync(target.path);
    unawaited(_trim());

    return file;
  }

  /// الأقدمُ تشغيلاً أوّلاً، حتى أربعة أخماس الحدّ — فلا يحين القصُّ ثانيةً بعد الرسالة التالية.
  Future<void> _trim() async {
    final entries = <(File, FileStat)>[];
    var total = 0;

    for (final entry in (await _dir()).listSync()) {
      if (entry is! File || entry.path.endsWith('.part')) continue;

      final stat = entry.statSync();
      entries.add((entry, stat));
      total += stat.size;
    }

    if (total <= maxBytes) return;

    entries.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));

    for (final (file, stat) in entries) {
      if (total <= maxBytes * 0.8) break;

      file.deleteSync();
      total -= stat.size;
    }
  }

  Future<Directory> _dir() async {
    final existing = _directory;
    if (existing != null) return existing;

    final directory = Directory('${(await _root()).path}/$_folder');
    if (!directory.existsSync()) directory.createSync(recursive: true);

    return _directory = directory;
  }

  /// **بلا الـDio المشترك**: الرابطُ يحمل توقيعه، وتوكنُ الموظف لا شأن له به — ولا يُرسل إلى
  /// مضيفٍ قد لا يكون مضيفَ الـAPI يوماً (قرصٌ سحابيّ).
  static Dio _plainDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 1),
    ),
  );
}
