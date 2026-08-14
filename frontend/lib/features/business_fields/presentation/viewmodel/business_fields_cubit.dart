import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/business_fields/models/business_field.dart';
import 'package:dayaa/features/business_fields/usecases/delete_business_field.dart';
import 'package:dayaa/features/business_fields/usecases/get_business_fields.dart';
import 'package:dayaa/features/business_fields/usecases/set_business_field_activation.dart';

/// مجالات العمل — the management screen's ViewModel.
///
/// The debounce, the out-of-order guard, appending pages and keeping the list when a page fails
/// all come from [PagedCubit]. What is added here is the two things the list itself can do to a
/// row — stop offering it, or remove it — because both change the list under the user and the
/// screen must not be left guessing what it now holds.
///
/// **Both reload rather than patch the row in place.** Deactivating changes what a filtered
/// list should contain, and deleting changes the paging; a locally edited copy would disagree
/// with the server the moment either happened. The list is short and the request is cheap.
class BusinessFieldsCubit extends PagedCubit<BusinessField> {
  BusinessFieldsCubit({
    required GetBusinessFields getBusinessFields,
    required SetBusinessFieldActivation setActivation,
    required DeleteBusinessField deleteBusinessField,
  }) : _getBusinessFields = getBusinessFields,
       _setActivation = setActivation,
       _deleteBusinessField = deleteBusinessField;

  final GetBusinessFields _getBusinessFields;
  final SetBusinessFieldActivation _setActivation;
  final DeleteBusinessField _deleteBusinessField;

  /// Which fields the list is narrowed to. `null` — the default — shows the stopped ones too,
  /// which is what a screen for *curating* the list has to do.
  bool? isActive;

  @override
  Future<Either<Failure, Paginated<BusinessField>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The filter rides along with every page, including the ones `loadMore` asks for.
    return _getBusinessFields(search: search, isActive: isActive, page: page);
  }

  /// Narrows the list to the offered fields, or widens it back.
  ///
  /// The search term survives: somebody who typed a word and then tapped a chip is asking a
  /// narrower question, not starting a new one.
  Future<void> filterByActivity(bool? next) async {
    if (next == isActive) return;

    isActive = next;
    await load(search: currentSearch);
  }

  /// Stops offering a field, or offers it again.
  ///
  /// Answers with the failure so the screen can say why nothing changed; `null` means it did.
  Future<Failure?> setActivation(BusinessField field, {required bool isActive}) async {
    final result = await _setActivation(field.id, isActive: isActive);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }

  /// Removes a field from the list.
  ///
  /// Refused by the server with a readable 422 once any shop is recorded under it — that
  /// message is the [Failure] handed back here, and it is the one the screen shows.
  Future<Failure?> remove(BusinessField field) async {
    final result = await _deleteBusinessField(field.id);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }
}

/// The state this screen switches on. A name for `PagedState<BusinessField>`, so the view reads
/// as a business-fields screen while there is one implementation behind every list in the app.
typedef BusinessFieldsState = PagedState<BusinessField>;
typedef BusinessFieldsInitial = PagedInitial<BusinessField>;
typedef BusinessFieldsLoading = PagedLoading<BusinessField>;
typedef BusinessFieldsLoaded = PagedLoaded<BusinessField>;
typedef BusinessFieldsFailure = PagedFailure<BusinessField>;
