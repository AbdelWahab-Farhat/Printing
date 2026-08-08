import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/business_fields/models/business_field.dart';
import 'package:printing/features/business_fields/usecases/save_business_field.dart';

part 'save_business_field_state.dart';
part 'save_business_field_cubit.freezed.dart';

/// The ViewModel for the sheet that adds or renames a trade.
///
/// It talks to a use case, never to a repository or to Dio, and it holds no `BuildContext`.
class SaveBusinessFieldCubit extends Cubit<SaveBusinessFieldState> {
  SaveBusinessFieldCubit({required SaveBusinessField saveBusinessField})
    : _saveBusinessField = saveBusinessField,
      super(const SaveBusinessFieldState.initial());

  final SaveBusinessField _saveBusinessField;

  /// Adds when [fieldId] is null, renames when it is not.
  ///
  /// One method for both, because the form, the validation and the 422 mapping are identical —
  /// the only difference is which request goes out.
  ///
  /// **Retrying after a [Failure.network] is safe here**, which is not true of every create:
  /// the name is unique in the database, so a request that did land before the connection
  /// dropped turns the retry into a readable 422 rather than a second «شحن».
  Future<void> submit({
    int? fieldId,
    required String name,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    // Ignored rather than queued: a second tap while the first request is in flight would be a
    // second POST, and the sheet has already moved on by the time it answers.
    if (state.isSubmitting) return;

    emit(const SaveBusinessFieldState.submitting());

    final result = await _saveBusinessField(
      fieldId: fieldId,
      name: name,
      sortOrder: sortOrder,
      isActive: isActive,
    );

    // The sheet may have been closed while the request was in flight, and emitting into a
    // closed Cubit throws.
    if (isClosed) return;

    emit(result.fold((f) => SaveBusinessFieldState.failure(f), (b) => SaveBusinessFieldState.success(b)));
  }

  /// Clears a previous failure so the error under the field disappears as soon as the user
  /// starts correcting it, rather than lingering until the next submit.
  void clearFailure() {
    if (state is SaveBusinessFieldFailure) emit(const SaveBusinessFieldState.initial());
  }
}
