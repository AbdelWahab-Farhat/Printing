import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_pools/models/returned_goods_question.dart';
import 'package:dayaa/features/investment_pools/presentation/viewmodel/pool_detail_cubit.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «صالحة أم تالفة» — the two answers, and nothing else.
///
/// **`open` is not offered**, because it is not an answer: it is the state the question starts
/// in, and a form that could set it back would let somebody reopen a verdict whose write-off the
/// shelf has already been counted against.
enum _Verdict {
  good('good', 'صالحة', 'ترجع إلى المخزون كما هي — لا يُكتب شيء'),
  damaged('damaged', 'تالفة', 'تُخصم من المخزون وتُحمَّل تكلفتها على الصندوق');

  const _Verdict(this.wire, this.label, this.consequence);

  final String wire;
  final String label;

  /// Said on the form, not after. «تالفة» posts a real stock movement, and a person who finds
  /// that out from the balance afterwards has been surprised by their own answer.
  final String consequence;
}

Future<void> showReturnedGoodsSheet({
  required BuildContext context,
  required ReturnedGoodsQuestion question,
  required int poolId,
}) {
  final cubit = context.read<PoolDetailCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<PoolDetailCubit>.value(
      value: cubit,
      child: _ReturnedGoodsForm(question: question, poolId: poolId),
    ),
  );
}

class _ReturnedGoodsForm extends StatefulWidget {
  const _ReturnedGoodsForm({required this.question, required this.poolId});

  final ReturnedGoodsQuestion question;
  final int poolId;

  @override
  State<_ReturnedGoodsForm> createState() => _ReturnedGoodsFormState();
}

class _ReturnedGoodsFormState extends State<_ReturnedGoodsForm> {
  final _notes = TextEditingController();

  _Verdict _verdict = _Verdict.good;
  Warehouse? _warehouse;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final warehouse = _warehouse;

    if (warehouse == null) {
      context.showError('اختر المخزن الذي رجعت إليه البضاعة');

      return;
    }

    setState(() => _saving = true);

    final failure = await context.read<PoolDetailCubit>().answerReturnedGoods(
      poolId: widget.poolId,
      questionId: widget.question.id,
      verdict: _verdict.wire,
      warehouseId: warehouse.id,
      notes: _notes.text,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure != null) {
      // The server's own words — it refuses a question that has already been answered, and
      // restating that rule here would be a second copy to keep in step.
      context.showError(failure.message);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess(
      _verdict == _Verdict.damaged
          ? 'سُجّلت البضاعة تالفة وخُصمت من المخزون'
          : 'سُجّلت البضاعة صالحة',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final question = widget.question;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: context.keyboardInset + 16.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'بضاعة راجعة من طلبية ملغاة',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              question.stockItemName ?? 'مادة ${question.stockItemId}',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),

            // **What the answer is worth.** The quantity and the cost were read off the
            // credit-back the day the question was raised, not today — the shelf has moved on
            // since, and the answer has to be about what actually came back.
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الكمية الراجعة: ${question.quantity.grouped}'),
                  SizedBox(height: 4.h),
                  Text('تكلفتها: ${question.cost.grouped}'),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            AppDropdown<_Verdict>(
              value: _verdict,
              items: _Verdict.values,
              labelOf: (verdict) => verdict.label,
              label: 'النتيجة',
              onChanged: (verdict) {
                if (verdict == null) return;
                setState(() => _verdict = verdict);
              },
            ),
            SizedBox(height: 6.h),
            Text(
              _verdict.consequence,
              style: context.textTheme.bodySmall?.copyWith(
                color: _verdict == _Verdict.damaged
                    ? scheme.error
                    : scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),

            // Asked for both answers though only «تالفة» writes a movement: the shelf the goods
            // came back to is a fact the person is looking at either way, and a field that
            // appears and disappears as the answer changes is a field people mis-fill.
            _WarehousePicker(
              value: _warehouse,
              onChanged: (warehouse) => setState(() => _warehouse = warehouse),
            ),
            SizedBox(height: 16.h),

            AppTextField(
              controller: _notes,
              label: 'ملاحظات',
              maxLines: 2,
            ),
            SizedBox(height: 20.h),

            AppButton(
              label: 'سجّل الفحص',
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Which shelf the goods came back to.
///
/// Opens the app's own [showWarehousePicker] rather than a dropdown of its own: a warehouse is
/// chosen by name from a searchable list everywhere else in this app, and a second way of
/// choosing one is a second list to keep in step.
class _WarehousePicker extends StatelessWidget {
  const _WarehousePicker({required this.value, required this.onChanged});

  final Warehouse? value;
  final ValueChanged<Warehouse?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final chosen = value;

    return InkWell(
      onTap: () async {
        final warehouse = await showWarehousePicker(context: context);
        if (warehouse != null) onChanged(warehouse);
      },
      borderRadius: BorderRadius.circular(14.r),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'المخزن',
          prefixIcon: Icon(Icons.warehouse_outlined),
        ),
        child: Text(
          chosen?.name ?? 'اختر المخزن',
          style: context.textTheme.bodyMedium?.copyWith(
            color: chosen == null ? scheme.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }
}
