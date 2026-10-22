import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_internal_ticket_cubit.freezed.dart';

@freezed
sealed class NewInternalTicketState with _$NewInternalTicketState {
  const factory NewInternalTicketState.loading() = NewInternalTicketLoading;

  /// الزملاءُ والأنواعُ لم تصل — النموذجُ لا يُملأ بلا «مع مَن؟».
  const factory NewInternalTicketState.failure(Failure failure) = NewInternalTicketFailure;

  const factory NewInternalTicketState.ready({
    required List<Colleague> colleagues,
    required List<InternalCategory> categories,
    @Default(false) bool isSubmitting,

    /// رفضُ الخادم — رسائلُ حقوله تحت حقولها.
    Failure? lastFailure,

    /// فُتحت — الشاشةُ تنتقل إليها.
    InternalTicket? created,
  }) = NewInternalTicketReady;
}

/// «تذكرة جديدة» — نموذجُ بريمولا بحقوله: مع مَن، والعنوان، والتفاصيل، ونوعُ المشكلة، والأولوية،
/// والعميلُ أو الطلبية، وحتى أربع صور.
class NewInternalTicketCubit extends Cubit<NewInternalTicketState> {
  NewInternalTicketCubit({
    required GetColleagues colleagues,
    required GetInternalCategories categories,
    required OpenInternalTicket open,
  }) : _colleagues = colleagues,
       _categories = categories,
       _open = open,
       super(const NewInternalTicketState.loading());

  final GetColleagues _colleagues;
  final GetInternalCategories _categories;
  final OpenInternalTicket _open;

  /// حتى أربع، كبريمولا والخادم.
  static const int maxImages = 4;

  Future<void> load() async {
    emit(const NewInternalTicketState.loading());

    final people = await _colleagues();
    final kinds = await _categories();

    if (isClosed) return;

    // الأنواعُ اختيارية: قائمتُها التي لم تصل لا تمنع فتح التذكرة.
    emit(
      people.fold(
        (failure) => NewInternalTicketState.failure(failure),
        (colleagues) => NewInternalTicketState.ready(
          colleagues: colleagues,
          categories: kinds.fold((_) => const <InternalCategory>[], (list) => list),
        ),
      ),
    );
  }

  Future<void> submit(InternalTicketDraft draft, {List<PickedFile> images = const []}) async {
    final current = state;
    if (current is! NewInternalTicketReady || current.isSubmitting) return;

    emit(current.copyWith(isSubmitting: true, lastFailure: null));

    final result = await _open(draft, images: images.take(maxImages).toList());

    if (isClosed) return;

    final after = state;
    if (after is! NewInternalTicketReady) return;

    emit(
      result.fold(
        (failure) => after.copyWith(isSubmitting: false, lastFailure: failure),
        (ticket) => after.copyWith(isSubmitting: false, created: ticket),
      ),
    );
  }
}
