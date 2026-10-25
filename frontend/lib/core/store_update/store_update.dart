import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// التطبيقُ المثبّت على هذا الهاتف: معرّفُ حزمته ونسختُه كما كتبها Xcode.
typedef InstalledApp = ({String bundleId, String version});

/// نسخةٌ على App Store أحدثُ مما على الهاتف.
@immutable
class StoreRelease {
  const StoreRelease({required this.version, required this.url});

  /// كما يكتبها App Store — `1.6` لا `1.6.0` أحياناً، ولذلك تُقارن بـ[compareVersions].
  final String version;

  /// صفحةُ التطبيق في المتجر.
  final Uri url;

  @override
  bool operator ==(Object other) =>
      other is StoreRelease && other.version == version && other.url == url;

  @override
  int get hashCode => Object.hash(version, url);
}

/// «تحديث جديد» لمستخدمي آيفون: يسأل App Store عن آخر نسخةٍ منشورة ويقارنها بالمثبّتة.
///
/// **من Apple مباشرةً، لا من خادمنا.** `itunes.apple.com/lookup` يجيب بالنسخة المنشورة فعلاً
/// لحظةَ تنشرها Apple، فلا رقمَ يُحدَّث يدوياً بعد كل إصدار ولا نشرَ للخادم. ولا يحمل توكن
/// الموظف — ولهذا الـDio هنا غيرُ المشترك.
///
/// **آيفون وحده** ([appliesHere]): أندرويد والويب لا يمرّان من هنا أصلاً. ونسخةُ التطوير
/// `ly.dayaa.app.dev` لا يعرفها المتجر فلا يظهر لها شيء، بلا شرطٍ على النكهة.
class StoreUpdate {
  StoreUpdate({
    required Dio dio,
    required SharedPreferences prefs,
    required Future<InstalledApp> Function() installed,
    required String osVersion,
    Future<bool> Function(Uri url)? open,
    DateTime Function()? now,
  }) : _dio = dio,
       _prefs = prefs,
       _installed = installed,
       _osVersion = osVersion,
       _open = open ?? _openStore,
       _now = now ?? DateTime.now;

  static const String _lookupUrl = 'https://itunes.apple.com/lookup';

  /// متجرُ ليبيا: التطبيق منشورٌ فيه، والنسخةُ واحدةٌ في كل المتاجر.
  static const String _country = 'ly';

  /// بين سؤالين لـApple. التطبيق يعود من الخلفية مراراً في اليوم، والجوابُ لا يتغيّر كل دقيقة.
  static const Duration _lookupGap = Duration(hours: 1);

  /// «لاحقاً» تُخفي النسخةَ نفسها هذه المدّة، ثم تعود. نسخةٌ أحدثُ منها تظهر فوراً.
  static const Duration _snoozeFor = Duration(days: 1);

  static const String _snoozedVersionKey = 'store_update.snoozed_version';
  static const String _snoozedAtKey = 'store_update.snoozed_at';

  final Dio _dio;
  final SharedPreferences _prefs;
  final Future<InstalledApp> Function() _installed;
  final String _osVersion;
  final Future<bool> Function(Uri url) _open;
  final DateTime Function() _now;

  DateTime? _lastLookup;

  /// هل يعني هذا الهاتفَ أصلاً. `Platform` لا يُقرأ على الويب، فيُسأل `kIsWeb` أولاً — ونسخةُ
  /// المتصفّح على آيفون ليست تطبيقاً يُحدَّث من المتجر.
  static bool get appliesHere => !kIsWeb && Platform.isIOS;

  /// النسخةُ التي تستحقّ الإعلان، أو `null`.
  ///
  /// **لا يرمي أبداً**: إعلانُ تحديثٍ لا يُعطّل شيئاً، فشبكةٌ مقطوعة أو جوابٌ غريب صمتٌ لا خطأ.
  Future<StoreRelease?> pending() async {
    final now = _now();
    final last = _lastLookup;
    if (last != null && now.difference(last) < _lookupGap) return null;
    // قبل الانتظار لا بعده: سؤالان متلاحقان — فتحُ الشاشة ثم العودةُ من الخلفية — لا يطلبان مرتين.
    _lastLookup = now;

    try {
      final installed = await _installed();
      final response = await _dio.get<String>(
        _lookupUrl,
        queryParameters: {
          'bundleId': installed.bundleId,
          'country': _country,
          // جوابُ Apple يُخزَّن يوماً كاملاً (`max-age=86400`)، فيبقى يقول النسخةَ القديمة بعد
          // نشر الجديدة. قيمةٌ تتغيّر كل مرّة تتخطّى ذلك.
          '_cb': now.microsecondsSinceEpoch.toString(),
        },
        // Apple ترسله `text/javascript` لا `application/json`، فلا يفكّه Dio وحده.
        options: Options(responseType: ResponseType.plain),
      );

      final results = (jsonDecode(response.data ?? '') as Map<String, dynamic>)['results'];
      if (results is! List || results.isEmpty) return null;
      final listing = results.first as Map<String, dynamic>;

      final version = listing['version'] as String?;
      final url = Uri.tryParse(listing['trackViewUrl'] as String? ?? '');
      if (version == null || url == null) return null;
      if (compareVersions(version, installed.version) <= 0) return null;

      // نسخةٌ تطلب iOS أحدثَ من هذا الهاتف لا يعرضها المتجر عليه، فلا يُطلب منه ما لا يقدر عليه.
      final minimumOs = listing['minimumOsVersion'] as String?;
      final deviceOs = _numericVersion(_osVersion);
      if (minimumOs != null && deviceOs != null && compareVersions(deviceOs, minimumOs) < 0) {
        return null;
      }

      if (_isSnoozed(version, now)) return null;

      return StoreRelease(version: version, url: url);
    } on Object catch (error) {
      debugPrint('store update lookup failed: $error');

      return null;
    }
  }

  /// «لاحقاً».
  Future<void> snooze(StoreRelease release) async {
    await _prefs.setString(_snoozedVersionKey, release.version);
    await _prefs.setInt(_snoozedAtKey, _now().millisecondsSinceEpoch);
  }

  /// «تحديث» — صفحةُ التطبيق في App Store نفسه، لا في متصفّح.
  Future<bool> open(StoreRelease release) => _open(release.url);

  bool _isSnoozed(String version, DateTime now) {
    if (_prefs.getString(_snoozedVersionKey) != version) return false;
    final at = _prefs.getInt(_snoozedAtKey);
    if (at == null) return false;

    return now.difference(DateTime.fromMillisecondsSinceEpoch(at)) < _snoozeFor;
  }

  static Future<bool> _openStore(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}

/// سالبٌ إن كانت [a] أقدم، صفرٌ إن تساوتا، موجبٌ إن كانت أحدث.
///
/// **أرقاماً لا نصاً**: `1.12` أحدثُ من `1.6`، والنصُّ يقول العكس. والجزءُ الغائب صفر، فـ`1.6`
/// كما يكتبها المتجر هي `1.6.0` التي في pubspec.
int compareVersions(String a, String b) {
  List<int> parts(String version) =>
      version.split('.').map((part) => int.tryParse(part.trim()) ?? 0).toList();

  final left = parts(a);
  final right = parts(b);
  final length = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < length; i++) {
    final x = i < left.length ? left[i] : 0;
    final y = i < right.length ? right[i] : 0;
    if (x != y) return x.compareTo(y);
  }

  return 0;
}

/// `17.5` من `Version 17.5 (Build 21F79)` — ما يعطيه `Platform.operatingSystemVersion` على آيفون.
String? _numericVersion(String text) => RegExp(r'\d+(\.\d+)*').firstMatch(text)?.group(0);
