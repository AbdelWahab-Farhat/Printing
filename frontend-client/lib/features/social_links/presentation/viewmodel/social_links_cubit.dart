import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/social_links/models/social_link.dart';
import 'package:dayaa_client/features/social_links/usecases/list_social_links.dart';
import 'package:dayaa_client/features/social_links/usecases/save_social_links.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_links_cubit.freezed.dart';
part 'social_links_state.dart';

/// الـ ViewModel لـ«روابط التواصل».
///
/// **يملك ما على الخادم لا ما يُكتب.** السطور ومتحكّماتها في الشاشة، كنموذج العميل في تطبيق
/// الموظفين، وتصل إلى [save] مجموعةً واحدة — فالحفظ يرسل الروابط كلّها ويستبدل ما على الخادم بها.
class SocialLinksCubit extends Cubit<SocialLinksState> {
  SocialLinksCubit({required ListSocialLinks list, required SaveSocialLinks save})
    : _list = list,
      _save = save,
      super(const SocialLinksState.loading());

  final ListSocialLinks _list;
  final SaveSocialLinks _save;

  Future<void> load() async {
    emit(const SocialLinksState.loading());

    final result = await _list();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => SocialLinksState.failure(failure),
        (links) => SocialLinksState.loaded(links),
      ),
    );
  }

  /// يحفظ المجموعة ويعيدها كما حفظها الخادم، لتغادر الشاشة.
  ///
  /// `null` يعني أنها لم تُحفظ، و`lastFailure` يقول لماذا. ونقرةٌ ثانية أثناء الحفظ لا ترسل شيئاً.
  Future<List<SocialLink>?> save(List<SocialLinkInput> links) async {
    final loaded = _loaded;
    if (loaded == null || loaded.isSaving) return null;

    emit(loaded.copyWith(isSaving: true, lastFailure: null));

    final result = await _save(links);

    if (isClosed) return result.fold((_) => null, (saved) => saved);

    return result.fold(
      (failure) {
        emit(loaded.copyWith(isSaving: false, lastFailure: failure));

        return null;
      },
      (saved) {
        emit(SocialLinksState.loaded(saved));

        return saved;
      },
    );
  }

  /// يمسح رفضاً سابقاً حين يبدأ العميل تصحيحه، فلا تبقى الشكوى تحت سطرٍ تغيّر.
  void clearFailure() {
    final loaded = _loaded;
    if (loaded?.lastFailure == null) return;

    emit(loaded!.copyWith(lastFailure: null));
  }

  SocialLinksLoaded? get _loaded => switch (state) {
    final SocialLinksLoaded loaded => loaded,
    _ => null,
  };
}
