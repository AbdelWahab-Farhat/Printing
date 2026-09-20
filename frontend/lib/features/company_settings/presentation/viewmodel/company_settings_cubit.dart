import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/company_settings/models/company_settings.dart';
import 'package:dayaa/features/company_settings/usecases/company_settings_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'company_settings_cubit.freezed.dart';

/// إعدادات الشركة — read whole, saved whole.
class CompanySettingsCubit extends Cubit<CompanySettingsState> {
  CompanySettingsCubit({
    required GetCompanySettings getSettings,
    required UpdateCompanySettings updateSettings,
  }) : _getSettings = getSettings,
       _updateSettings = updateSettings,
       super(const CompanySettingsState.loading());

  final GetCompanySettings _getSettings;
  final UpdateCompanySettings _updateSettings;

  Future<void> load() async {
    final result = await _getSettings();

    if (isClosed) return;

    emit(
      result.fold(
        CompanySettingsState.failure,
        (settings) => CompanySettingsState.loaded(settings: settings),
      ),
    );
  }

  /// Saves all four. **Affects future periods only** — the open period's end date and the next
  /// settlement are derived from these, and a closed period is unreachable from here.
  Future<Failure?> save(CompanySettings settings) async {
    final result = await _updateSettings(settings);

    if (isClosed) return null;

    return result.fold((failure) => failure, (saved) {
      emit(CompanySettingsState.loaded(settings: saved));

      return null;
    });
  }
}

@freezed
sealed class CompanySettingsState with _$CompanySettingsState {
  const factory CompanySettingsState.loading() = CompanySettingsLoading;

  const factory CompanySettingsState.loaded({
    required CompanySettings settings,
  }) = CompanySettingsLoaded;

  const factory CompanySettingsState.failure(Failure failure) =
      CompanySettingsFailure;
}
