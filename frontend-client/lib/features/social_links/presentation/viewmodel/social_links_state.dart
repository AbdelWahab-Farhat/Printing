part of 'social_links_cubit.dart';

/// كلُّ ما يمكن أن تكونه «روابط التواصل».
///
/// **`isSaving` و`lastFailure` على الحالة المحمَّلة لا بدلاً منها**، كما في «متاجري»: حفظٌ رُفض لا
/// يأخذ القائمة معه، والسطور تبقى كما كتبها العميل.
@freezed
sealed class SocialLinksState with _$SocialLinksState {
  const factory SocialLinksState.loading() = SocialLinksLoading;

  const factory SocialLinksState.loaded(
    /// ما على الخادم، كما قرأه آخر تحميلٍ أو آخر حفظ. السطور التي تُكتب يملكها متحكّمو الشاشة.
    List<SocialLink> links, {

    /// حفظٌ في الطريق: الشاشة مقفلة، و«حفظ» يدور.
    @Default(false) bool isSaving,

    /// آخر حفظٍ رُفض، ويُمسح مع الحالة التالية.
    Failure? lastFailure,
  }) = SocialLinksLoaded;

  /// التحميل وحده — بعده توجد قائمةٌ تبقى معروضة.
  const factory SocialLinksState.failure(Failure failure) = SocialLinksFailure;
}

extension SocialLinksStateX on SocialLinksState {
  bool get isSaving => switch (this) {
    SocialLinksLoaded(:final isSaving) => isSaving,
    _ => false,
  };

  /// شكوى الخادم عن سطرٍ واحد، بموضعه: «الرابط مكرر» عن `social_links.1.url` تحت السطر الثاني.
  /// والمُعرِّف شكواه شكوى سطره أيضاً — رابطٌ حُذف من جهازٍ آخر ثم حُفظ من هنا.
  String? rowError(int index) =>
      _fieldError('social_links.$index.url') ?? _fieldError('social_links.$index.id');

  /// رفضٌ لا سطر له — حدّ العشرة، أو انقطاع الاتصال — فيُقال في رسالة بدل أن يضيع.
  bool get hasUnplacedFailure => switch (this) {
    SocialLinksLoaded(:final lastFailure?) => switch (lastFailure) {
      ServerFailure(:final fieldErrors?) => !fieldErrors.keys.any(_rowKey.hasMatch),
      _ => true,
    },
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    SocialLinksLoaded(lastFailure: ServerFailure(:final fieldErrors)) =>
      fieldErrors?[field]?.firstOrNull,
    _ => null,
  };
}

/// مفتاح خطأٍ يخصّ سطراً بعينه: `social_links.3.url` لا `social_links`.
final _rowKey = RegExp(r'^social_links\.\d+\.');
