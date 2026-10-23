import 'package:flutter/services.dart' show Brightness, Color;

/// منصّة رابط التواصل، كما تُعرف من نطاقه — ليُرسم السطر باسمها وشعارها والعميل يكتب.
///
/// **الخادم لا يعرف المنصّة؛ يحفظ الرابط وحده.** التطبيقان يعرفانها بهذا الجدول نفسه حرفاً بحرف —
/// تطبيق الموظفين يحمل نسخته — وإضافة منصّةٍ تعديلٌ في الاثنين. Docs/customers/CUSTOMER-SOCIAL-LINKS.md.
///
/// **ألوانها ألوان المنصّات لا ألواننا**، فهي هنا لا في الثيم: الأزرق أزرق فيسبوك في الوضعين، ولا
/// يتبدّل مع لوحة التطبيق. `null` يعني «بحبر الثيم» — للشعارين الأسودين، ولأصفر سناب شات على الفاتح.
enum SocialPlatform {
  facebook('فيسبوك', ['facebook.com', 'fb.com', 'fb.me', 'fb.watch'], Color(0xFF0866FF)),
  instagram('إنستغرام', ['instagram.com', 'instagr.am'], Color(0xFFE4405F)),
  tiktok('تيك توك', ['tiktok.com'], null),
  whatsapp('واتساب', ['wa.me', 'whatsapp.com'], Color(0xFF25D366)),
  snapchat('سناب شات', ['snapchat.com'], Color(0xFFFFFC00), legibleOnLight: false),
  telegram('تيليجرام', ['t.me', 'telegram.me', 'telegram.org'], Color(0xFF26A5E4)),
  x('X', ['x.com', 'twitter.com'], null),
  youtube('يوتيوب', ['youtube.com', 'youtu.be'], Color(0xFFFF0000)),

  /// أيُّ رابطٍ لا نعرف منصّته، وخانةٌ لم يُكتب فيها شيء بعد. بلا شعار: أيقونة رابطٍ من `AppIcons`.
  other('رابط', [], null);

  const SocialPlatform(this.label, this.domains, this._brand, {this.legibleOnLight = true});

  /// ما يُكتب فوق الخانة وعلى السطر.
  final String label;

  /// النطاقات التي تُعرف بها، بلا `www.`. نطاقٌ فرعيّ منها منها أيضاً: `vm.tiktok.com` تيك توك.
  final List<String> domains;

  final Color? _brand;

  /// أصفر سناب شات لا يُقرأ على خلفيةٍ فاتحة، فيأخذ حبر الثيم هناك.
  final bool legibleOnLight;

  /// الشعار، من Simple Icons (CC0) — مسارٌ واحد يُصبغ بـ[brandColor]. `null` لـ[other].
  String? get asset => this == other ? null : 'assets/icons/social/$name.svg';

  /// لون الشعار على خلفيةٍ بهذا السطوع، أو `null` ليُرسم بحبر الثيم.
  Color? brandColor(Brightness brightness) =>
      brightness == Brightness.light && !legibleOnLight ? null : _brand;

  /// السوابق التي لا تغيّر المنصّة: `m.facebook.com` فيسبوك كـ`facebook.com`.
  static const _hostPrefixes = ['www.', 'm.', 'mobile.', 'web.'];

  /// المنصّة التي يدلّ عليها [url]، بعد [normalizeSocialLink] — فـ«instagram.com/x» إنستغرام وإن
  /// كُتب بلا `https://`. وما لا يُقرأ رابطاً، أو لا نعرف نطاقه، [other].
  static SocialPlatform of(String url) {
    final normalized = normalizeSocialLink(url);
    if (normalized.isEmpty) return other;

    var host = (Uri.tryParse(normalized)?.host ?? '').toLowerCase();
    for (final prefix in _hostPrefixes) {
      if (host.startsWith(prefix)) {
        host = host.substring(prefix.length);
        break;
      }
    }

    if (host.isEmpty) return other;

    for (final platform in values) {
      // النطاق كلّه أو ما تحته، لا ما ينتهي بحروفه: `notfacebook.com` ليس فيسبوك.
      if (platform.domains.any((domain) => host == domain || host.endsWith('.$domain'))) {
        return platform;
      }
    }

    return other;
  }
}

final _scheme = RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*://');

/// الرابط كما يُرسل: بلا مسافاتٍ حوله، و`https://` أمامه إن كُتب بدونها — الخادم يقبل روابط الويب
/// وحدها، و«instagram.com/alnoor» ما يكتبه الناس فعلاً. الفارغ يبقى فارغاً.
String normalizeSocialLink(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || _scheme.hasMatch(trimmed)) return trimmed;

  return 'https://$trimmed';
}

/// الرابط كما يُقرأ على السطر: بلا البروتوكول ولا `www.` ولا الشرطة الأخيرة —
/// «facebook.com/alnoor.print».
String displaySocialLink(String url) {
  var shown = url.trim().replaceFirst(_scheme, '');
  if (shown.toLowerCase().startsWith('www.')) shown = shown.substring(4);
  while (shown.endsWith('/')) {
    shown = shown.substring(0, shown.length - 1);
  }

  return shown;
}
