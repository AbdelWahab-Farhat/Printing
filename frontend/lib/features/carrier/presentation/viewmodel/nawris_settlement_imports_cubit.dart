import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/features/carrier/models/nawris_settlement.dart';
import 'package:dayaa/features/carrier/usecases/nawris_settlement.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'nawris_settlement_imports_cubit.freezed.dart';

/// الدفعات السابقة، الأحدث أولاً.
class NawrisSettlementImportsCubit extends PagedCubit<NawrisSettlementImport> {
  NawrisSettlementImportsCubit({required GetNawrisSettlementImports getImports})
    : _getImports = getImports;

  final GetNawrisSettlementImports _getImports;

  @override
  Object identityOf(NawrisSettlementImport item) => item.id;

  @override
  Future<Either<Failure, Paginated<NawrisSettlementImport>>> fetchPage({
    required int page,
    String? search,
  }) => _getImports(page: page);
}

@freezed
sealed class NawrisSettlementImportState with _$NawrisSettlementImportState {
  const factory NawrisSettlementImportState.loading() = NawrisSettlementImportLoading;

  const factory NawrisSettlementImportState.loaded(NawrisSettlementImport batch) =
      NawrisSettlementImportLoaded;

  const factory NawrisSettlementImportState.failure(Failure failure) =
      NawrisSettlementImportFailure;
}

/// دفعة واحدة بأسطرها — ما يجيب بعد أشهر: لماذا لم تتحرك هذه الطلبية؟
class NawrisSettlementImportCubit extends Cubit<NawrisSettlementImportState> {
  NawrisSettlementImportCubit({required GetNawrisSettlementImport getImport})
    : _getImport = getImport,
      super(const NawrisSettlementImportState.loading());

  final GetNawrisSettlementImport _getImport;

  Future<void> load(int id) async {
    emit(const NawrisSettlementImportState.loading());

    final result = await _getImport(id);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => NawrisSettlementImportState.failure(failure),
        (batch) => NawrisSettlementImportState.loaded(batch),
      ),
    );
  }
}
