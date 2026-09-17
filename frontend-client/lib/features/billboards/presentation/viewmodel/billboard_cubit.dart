import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/usecases/get_billboards.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'billboard_cubit.freezed.dart';
part 'billboard_state.dart';

/// The ViewModel for the carousel at the top of the home screen.
///
/// **A banner that will not load is not an error the customer should be shown.** The home
/// screen's job is the shortcuts underneath it; a carousel that failed simply is not drawn, and
/// [BillboardState.failure] exists so a retry can be offered *silently* — never as a red box
/// across the first thing somebody sees when they open the app.
class BillboardCubit extends Cubit<BillboardState> {
  BillboardCubit({required GetBillboards get})
    : _get = get,
      super(const BillboardState.loading());

  final GetBillboards _get;

  Future<void> load() async {
    emit(const BillboardState.loading());

    final result = await _get();

    if (isClosed) return;

    emit(result.fold(BillboardState.failure, BillboardState.loaded));
  }
}
