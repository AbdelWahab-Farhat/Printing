import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_link.freezed.dart';
part 'social_link.g.dart';

/// رابطُ تواصلٍ من روابط العميل — صفحته على فيسبوك أو حسابه على إنستغرام أو أيّ رابطٍ آخر.
///
/// الحقلان اللذان يرسلهما الخادم وحدهما: المنصّة لا تُرسل، يعرفها التطبيق من الرابط —
/// `SocialPlatform.of`.
@freezed
abstract class SocialLink with _$SocialLink {
  const factory SocialLink({required int id, required String url}) = _SocialLink;

  factory SocialLink.fromJson(Map<String, dynamic> json) => _$SocialLinkFromJson(json);
}

/// سطرٌ كما يُحفظ: مُعرِّفه حين يكون رابطاً قائماً، و`null` لرابطٍ أُضيف للتوّ.
///
/// سجلٌّ لا نموذج، كمدخلات المتجر عند الموظفين: لا يُقرأ من الخادم أبداً، ويعيش بين الشاشة والجسم.
typedef SocialLinkInput = ({int? id, String url});
