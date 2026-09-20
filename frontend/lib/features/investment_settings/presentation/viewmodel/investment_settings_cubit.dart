import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_settings/models/investment_settings.dart';
import 'package:dayaa/features/investment_settings/usecases/investment_settings_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'investment_settings_cubit.freezed.dart';

/// قواعدُ الصندوق الأربع، تُقرأ وتُكتب.
///
/// **لا يُحسب هنا شيء.** الرفضُ الوحيد الذي تحمله هذه الشاشة — أن تكون مدةُ التسوية مضاعفاً
/// صحيحاً لمدة الفترة — يقوله الخادم برسالةٍ عربية، وتقوله القاعدةُ خلفه بقيدٍ لا يُتجاوَز مهما
/// كان الطريق. تكرارُه في Dart يعني تعريفَين للقاعدة نفسها يفترقان أوّلَ ما تتغيّر.
class InvestmentSettingsCubit extends Cubit<InvestmentSettingsState> {
  InvestmentSettingsCubit({
    required GetInvestmentSettings getSettings,
    required UpdateInvestmentSettings updateSettings,
  }) : _getSettings = getSettings,
       _updateSettings = updateSettings,
       super(const InvestmentSettingsState.loading());

  final GetInvestmentSettings _getSettings;
  final UpdateInvestmentSettings _updateSettings;

  Future<void> load() async {
    emit(const InvestmentSettingsState.loading());

    final result = await _getSettings();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => InvestmentSettingsState.failure(failure),
        (settings) => InvestmentSettingsState.loaded(settings: settings),
      ),
    );
  }

  /// يحفظ ويُبقي على ما ردّه الخادم.
  ///
  /// **ما يُعرَض بعد الحفظ هو جوابُ الخادم لا ما كُتب في الحقول** — فلو صحّح رقماً أو ردّ قيمةً
  /// لم تُلمس، رأى المستخدم ما صار عليه الأمر فعلاً لا ما ظنّه.
  ///
  /// تُعيد الفشلَ الذي يُعرض، وnull حين ينجح.
  Future<Failure?> save(InvestmentSettings settings) async {
    final result = await _updateSettings(settings);

    if (isClosed) return null;

    return result.fold((failure) => failure, (saved) {
      emit(InvestmentSettingsState.loaded(settings: saved));

      return null;
    });
  }
}

@freezed
sealed class InvestmentSettingsState with _$InvestmentSettingsState {
  const factory InvestmentSettingsState.loading() = InvestmentSettingsLoading;

  const factory InvestmentSettingsState.loaded({required InvestmentSettings settings}) =
      InvestmentSettingsLoaded;

  const factory InvestmentSettingsState.failure(Failure failure) = InvestmentSettingsFailure;
}
