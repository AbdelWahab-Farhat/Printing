import 'dart:async';

import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'investment_fund_cubit.freezed.dart';

/// وضعُ الصندوق: قيمتُه وفترتُه.
class InvestmentFundCubit extends Cubit<InvestmentFundState> {
  InvestmentFundCubit({
    required GetFundStanding getStanding,
    required OpenFundPeriod openPeriod,
    required CloseFundPeriod closePeriod,
    required DepositCapital deposit,
    required WithdrawCapital withdraw,
    required RecordFundExpense recordExpense,
  }) : _getStanding = getStanding,
       _openPeriod = openPeriod,
       _closePeriod = closePeriod,
       _deposit = deposit,
       _withdraw = withdraw,
       _recordExpense = recordExpense,
       super(const InvestmentFundState.loading());

  final GetFundStanding _getStanding;
  final OpenFundPeriod _openPeriod;
  final CloseFundPeriod _closePeriod;
  final DepositCapital _deposit;
  final WithdrawCapital _withdraw;
  final RecordFundExpense _recordExpense;

  Future<void> load() async {
    emit(const InvestmentFundState.loading());

    final result = await _getStanding();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => InvestmentFundState.failure(failure),
        (standing) => InvestmentFundState.loaded(standing: standing),
      ),
    );
  }

  /// يفتح فترةً ثم **يُعيد القراءة** بدل أن يرقّع الحالة.
  ///
  /// القيمةُ تتغيّر بفتح الفترة — يصير لها رصيدٌ افتتاحي ويُحتمل أن تكون الحدودُ غير ما توقّعه
  /// الحاسبُ هنا — وعميلٌ يعيد حسابها يصير تنفيذاً ثانياً للقواعد: ذاك الذي يخالفها يوم تتغيّر.
  ///
  /// تُعيد الفشلَ الذي يُعرض، وnull حين ينجح.
  Future<Failure?> open() async {
    final result = await _openPeriod();

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      unawaited(load());

      return null;
    });
  }

  /// يُقفل الفترة ثم يُعيد القراءة — الأرباحُ انتقلت والقيمةُ تغيّرت، فلا تُرقَّع.
  ///
  /// **`closePeriod` لا `close`**: الثانيةُ اسمٌ مشغولٌ في `Cubit` نفسه — تهدم الـcubit — وكانت
  /// ستُغلقه بدل أن تُقفل فترة.
  ///
  /// تُعيد الفترةَ كما صارت حين ينجح — **«مغلقة» أو «قيد الإغلاق»**، وهما خبران مختلفان: الثانية
  /// انتهت في موعدها وبقيت لها طلبيات، فلا يُقال عنها «أُفرج عن الأرباح» — والفشلَ الذي يُعرض.
  Future<(FundPeriod?, Failure?)> closePeriod({String? overrideReason}) async {
    final result = await _closePeriod(overrideReason: overrideReason);

    if (isClosed) return (null, null);

    return result.fold((failure) => (null, failure), (period) {
      unawaited(load());

      return (period, null);
    });
  }

  /// يودع رأسَ مالٍ ثم **يُعيد القراءة**: سعرُ الوحدة تغيّر، والنسبُ كلُّها معه.
  ///
  /// تُعيد الإيصال حين ينجح — الوحداتُ والسعرُ وموعدُ فكّ الحبس، وهي ما لا يمكن للشاشة أن
  /// تحسبه بنفسها — والفشلَ الذي يُعرض.
  Future<(DepositReceipt?, Failure?)> deposit({
    required int investorId,
    required String amount,
    String? notes,
  }) async {
    final result = await _deposit(
      investorId: investorId,
      amount: amount,
      notes: notes,
    );

    if (isClosed) return (null, null);

    return result.fold((failure) => (null, failure), (receipt) {
      unawaited(load());

      return (receipt, null);
    });
  }

  Future<Failure?> withdraw({
    required int investorId,
    required String amount,
    String? notes,
  }) async {
    final result = await _withdraw(
      investorId: investorId,
      amount: amount,
      notes: notes,
    );

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      unawaited(load());

      return null;
    });
  }

  Future<Failure?> recordExpense({
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) async {
    final result = await _recordExpense(
      kind: kind,
      name: name,
      amount: amount,
      incurredOn: incurredOn,
      notes: notes,
    );

    if (isClosed) return null;

    return result.fold((failure) => failure, (_) {
      unawaited(load());

      return null;
    });
  }
}

@freezed
sealed class InvestmentFundState with _$InvestmentFundState {
  const factory InvestmentFundState.loading() = InvestmentFundLoading;

  const factory InvestmentFundState.loaded({required FundStanding standing}) =
      InvestmentFundLoaded;

  const factory InvestmentFundState.failure(Failure failure) = InvestmentFundFailure;
}
