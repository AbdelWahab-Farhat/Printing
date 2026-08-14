import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:dayaa/features/manufacturing_cost_rates/repositories/manufacturing_cost_rate_repository.dart';

/// One page of معدلات تكلفة التصنيع.
class GetManufacturingCostRates {
  const GetManufacturingCostRates(this._repository);

  final ManufacturingCostRateRepository _repository;

  Future<Either<Failure, Paginated<ManufacturingCostRate>>> call({
    int? productId,
    int? productVariantId,
    ManufacturingCostType? costType,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.rates(
      productId: productId,
      productVariantId: productVariantId,
      costType: costType,
      isActive: isActive,
      page: page,
      perPage: perPage,
    );
  }
}

/// One rate, on its own.
class GetManufacturingCostRate {
  const GetManufacturingCostRate(this._repository);

  final ManufacturingCostRateRepository _repository;

  Future<Either<Failure, ManufacturingCostRate>> call(int rateId) => _repository.rate(rateId);
}

/// Adds a rate, or corrects one.
///
/// **One use case for both, because the form is one form.** It is also the layer that turns what
/// was typed into what the API accepts, and there are two conversions worth naming:
///
///   * `٣٫٥٠٠` is what a Libyan keyboard produces and every numeric rule on the server is
///     ASCII-only — see [_number];
///   * the rung decides which id travels. The form holds a chosen product *and* a chosen size at
///     once, so that narrowing from «منتج بأكمله» to «مقاس واحد» and back does not lose either
///     answer — and **exactly one of them is put on the wire here**, in the one layer a test can
///     reach without a widget tree. Sending both is refused by a database CHECK constraint; the
///     shape of this call is what makes that unreachable.
class SaveManufacturingCostRate {
  const SaveManufacturingCostRate(this._repository);

  final ManufacturingCostRateRepository _repository;

  /// [id] null adds a rate; anything else corrects that one.
  ///
  /// [scopeId] is the product's id on [RateScope.product], the size's on [RateScope.variant], and
  /// **ignored on [RateScope.standard]** — a default rate is the one with neither.
  Future<Either<Failure, ManufacturingCostRate>> call({
    int? id,
    required RateScope scope,
    int? scopeId,
    required ManufacturingCostType costType,
    required String ratePerUnit,
    String? notes,
    bool isActive = true,
  }) {
    final productId = scope == RateScope.product ? scopeId : null;
    final productVariantId = scope == RateScope.variant ? scopeId : null;
    final rate = _number(ratePerUnit);
    final trimmedNotes = _blankToNull(notes);

    if (id == null) {
      return _repository.create(
        costType: costType,
        ratePerUnit: rate,
        productId: productId,
        productVariantId: productVariantId,
        notes: trimmedNotes,
        isActive: isActive,
      );
    }

    return _repository.update(
      id,
      costType: costType,
      ratePerUnit: rate,
      productId: productId,
      productVariantId: productVariantId,
      notes: trimmedNotes,
      isActive: isActive,
    );
  }
}

/// Stops a rate applying, or starts it again.
///
/// The ordinary way to retire one. Orders that already went through printing keep the amounts it
/// produced — those were snapshotted onto their cost entries — and the rung below takes over from
/// here on, because a stopped rate is filtered out before the ladder is walked rather than
/// shadowing what is under it.
class SetManufacturingCostRateActivation {
  const SetManufacturingCostRateActivation(this._repository);

  final ManufacturingCostRateRepository _repository;

  Future<Either<Failure, ManufacturingCostRate>> call(int rateId, {required bool isActive}) =>
      _repository.setActivation(rateId, isActive: isActive);
}

/// Removes a rate for good.
///
/// **Only for a rung that should never have existed** — a typo, a duplicate somebody worked
/// around. Retiring a rate that was ever used is [SetManufacturingCostRateActivation]'s job: the
/// delete is soft on the server and nothing refuses it, so there is no message to warn with and
/// no way for the screen to tell the two intentions apart on the user's behalf.
class DeleteManufacturingCostRate {
  const DeleteManufacturingCostRate(this._repository);

  final ManufacturingCostRateRepository _repository;

  Future<Either<Failure, String>> call(int rateId) => _repository.delete(rateId);
}

/// Arabic-Indic digits to ASCII, and a comma to a decimal point.
///
/// `٣٫٥` is what a Libyan keyboard produces and `numeric` on the server reads ASCII only.
/// Converted here, in the one layer a test can reach without a widget tree.
String _number(String input) =>
    Validators.toWesternDigits(input.trim()).replaceAll(',', '.');

/// An empty box means "there is no note", not "the note is an empty string".
String? _blankToNull(String? value) {
  final trimmed = value?.trim();

  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
