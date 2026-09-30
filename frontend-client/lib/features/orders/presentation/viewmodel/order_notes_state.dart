part of 'order_notes_cubit.dart';

/// ما تكونه شاشة «الملاحظات».
@freezed
sealed class OrderNotesState with _$OrderNotesState {
  const factory OrderNotesState.loading() = OrderNotesLoading;

  /// الملاحظات من الأقدم، كما رتّبها الخادم. فارغةٌ حين لم يُكتب شيء.
  const factory OrderNotesState.loaded(List<OrderNote> notes) = OrderNotesLoaded;

  const factory OrderNotesState.failure(Failure failure) = OrderNotesFailure;
}
