import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/branches/branch_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@immutable
class BranchesState {
  const BranchesState({
    this.isLoading = true,
    this.list,
    this.failure,
    this.savingId,
    this.saveFailure,
  });

  final bool isLoading;
  final BranchList? list;
  final Failure? failure;

  /// The branch being saved right now, if any.
  final int? savingId;
  final Failure? saveFailure;
}

/// «إعدادات الفروع» — INSTANT-ORDERS-PLAN.md §8.
class BranchesCubit extends Cubit<BranchesState> {
  BranchesCubit(this._repository) : super(const BranchesState());

  final BranchRepository _repository;

  Future<void> load() async {
    emit(BranchesState(list: state.list));

    final result = await _repository.branches();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => BranchesState(isLoading: false, list: state.list, failure: failure),
        (list) => BranchesState(isLoading: false, list: list),
      ),
    );
  }

  /// Saves one branch; true when it went through.
  Future<bool> save(BranchSettings branch) async {
    final list = state.list;
    emit(BranchesState(isLoading: false, list: list, savingId: branch.id));

    final result = await _repository.save(branch);

    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(BranchesState(isLoading: false, list: list, saveFailure: failure));

        return false;
      },
      (saved) {
        emit(
          BranchesState(
            isLoading: false,
            list: list == null
                ? null
                : BranchList(
                    branches: [for (final b in list.branches) b.id == saved.id ? saved : b],
                    lateHours: list.lateHours,
                  ),
          ),
        );

        return true;
      },
    );
  }

  Future<bool> saveLateHours(int hours) async {
    final result = await _repository.saveLateHours(hours);

    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(BranchesState(isLoading: false, list: state.list, saveFailure: failure));

        return false;
      },
      (saved) {
        final list = state.list;
        emit(
          BranchesState(
            isLoading: false,
            list: list == null ? null : BranchList(branches: list.branches, lateHours: saved),
          ),
        );

        return true;
      },
    );
  }
}
