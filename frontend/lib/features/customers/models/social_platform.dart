/// منصّةُ رابطِ تواصل، تُعرف من نطاقه — فيسبوك من `facebook.com`، وواتساب من `wa.me`.
///
/// **التطبيق هو من يعرفها، لا الخادم.** الخادم يحفظ الرابط وحده، وهنا تُقرأ المنصّة ليُرسم شعارها
/// واسمها والمستخدم يكتب. وتطبيق العميل يحمل الجدول نفسه حرفاً بحرف — انظر
/// Docs/customers/CUSTOMER-SOCIAL-LINKS.md §٥ — فمنصّةٌ تُضاف هنا تُضاف هناك.
enum SocialPlatform {
  facebook('فيسبوك', ['facebook.com', 'fb.com', 'fb.me', 'fb.watch'], 'facebook'),
  instagram('إنستغرام', ['instagram.com', 'instagr.am'], 'instagram'),
  tiktok('تيك توك', ['tiktok.com'], 'tiktok'),
  whatsapp('واتساب', ['wa.me', 'whatsapp.com'], 'whatsapp'),
  snapchat('سناب شات', ['snapchat.com'], 'snapchat'),
  telegram('تيليجرام', ['t.me', 'telegram.me', 'telegram.org'], 'telegram'),
  x('X', ['x.com', 'twitter.com'], 'x'),
  youtube('يوتيوب', ['youtube.com', 'youtu.be'], 'youtube'),

  /// أيُّ رابطٍ غير ما سبق، وخانةٌ فارغة بعد: «رابط» بأيقونة الرابط العامة.
  other('رابط', [], null);

  const SocialPlatform(this.label, this._domains, this._logo);

  /// الاسم كما يُكتب فوق الخانة وفوق الرابط في صفحة العميل.
  final String label;

  final List<String> _domains;
  final String? _logo;

  /// شعار المنصّة من Simple Icons، أو null لـ[other] الذي يُرسم بأيقونة الرابط.
  String? get asset => _logo == null ? null : 'assets/icons/social/$_logo.svg';

  /// المنصّة التي يذهب إليها [url]، مكتوباً بـ`https://` أو بدونه.
  ///
  /// بالنطاق كاملاً أو بنطاقٍ فرعيٍّ منه — `vm.tiktok.com` تيك توك — لا بما ينتهي به اسمه:
  /// `notfacebook.com` موقعُ غيره.
  static SocialPlatform of(String url) {
    final normalized = normalizeSocialLink(url);
    if (normalized.isEmpty) return other;

    final host = Uri.tryParse(normalized)?.host.toLowerCase();
    if (host == null || host.isEmpty) return other;

    for (final platform in values) {
      for (final domain in platform._domains) {
        if (host == domain || host.endsWith('.$domain')) return platform;
      }
    }

    return other;
  }
}

final _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');

/// الرابط كما يُرسل إلى الخادم: بلا فراغٍ حوله، وبـ`https://` حين كُتب بدونه.
///
/// «instagram.com/alnoor» هو ما يكتبه الناس، والخادم لا يقبل إلا رابط ويبٍ كاملاً. وخانةٌ فارغة
/// تبقى فارغة، ليقول عنها المدقّق «مطلوب» لا «غير صحيح».
String normalizeSocialLink(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;

  return _scheme.hasMatch(trimmed) ? trimmed : 'https://$trimmed';
}

/// الرابط كما يُقرأ في صفحة العميل: «facebook.com/alnoor.print» بلا `https://www.` ولا `/` أخيرة.
String displaySocialLink(String url) =>
    url.replaceFirst(_scheme, '').replaceFirst(RegExp(r'^www\.'), '').replaceFirst(RegExp(r'/$'), '');
