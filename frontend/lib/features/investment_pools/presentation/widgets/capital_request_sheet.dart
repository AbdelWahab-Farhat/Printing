import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_pools/models/investment_pool.dart';
import 'package:dayaa/features/investment_pools/presentation/viewmodel/pool_detail_cubit.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Money into the pool, or money asked back out of it.
enum _Direction {
  inward('in', 'إدخال رأس مال'),
  outward('out', 'سحب رأس مال');

  const _Direction(this.wire, this.label);

  final String wire;
  final String label;
}

Future<void> showCapitalRequestSheet({
  required BuildContext context,
  required int poolId,
  required CapitalTiming? timing,
}) {
  final cubit = context.read<PoolDetailCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<PoolDetailCubit>.value(
      value: cubit,
      child: _CapitalRequestForm(poolId: poolId, timing: timing),
    ),
  );
}

class _CapitalRequestForm extends StatefulWidget {
  const _CapitalRequestForm({required this.poolId, required this.timing});

  final int poolId;
  final CapitalTiming? timing;

  @override
  State<_CapitalRequestForm> createState() => _CapitalRequestFormState();
}

class _CapitalRequestFormState extends State<_CapitalRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  _Direction _direction = _Direction.inward;
  Investor? _investor;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// **Whether the money is actually there is the server's answer**, because it depends on rows
  /// this screen may not have seen. This checks the shape and nothing else.
  String? _validateAmount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'المبلغ مطلوب';

    final amount = double.tryParse(Validators.toWesternDigits(text));

    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final investor = _investor;

    if (investor == null) {
      context.showError('اختر المستثمر');

      return;
    }

    setState(() => _saving = true);

    final failure = await context.read<PoolDetailCubit>().requestCapital(
      poolId: widget.poolId,
      investorId: investor.id,
      direction: _direction.wire,
      amount: _amount.text,
      notes: _notes.text,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure != null) {
      context.showError(failure.message);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess(
      _queues ? 'سُجّل الطلب — ينفَّذ مع بداية الفترة القادمة' : 'تم تنفيذ الطلب',
    );
  }

  /// Whether this request will **wait** rather than take effect today.
  ///
  /// **A withdrawal always waits**, window or no window: it executes at the close, after that
  /// period's profit has been divided, so a man who says in September that he wants out is still
  /// paid his September share. Money coming in waits only outside the grace window.
  bool get _queues {
    if (_direction == _Direction.outward) return true;

    return !(widget.timing?.isInsideGraceWindow ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: context.keyboardInset + 16.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                'حركة رأس مال',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 20.h),

              AppDropdown<_Direction>(
                value: _direction,
                items: _Direction.values,
                labelOf: (direction) => direction.label,
                label: 'نوع الحركة',
                onChanged: (direction) {
                  if (direction == null) return;
                  setState(() => _direction = direction);
                },
              ),
              SizedBox(height: 16.h),

              _InvestorPicker(
                value: _investor,
                onChanged: (investor) => setState(() => _investor = investor),
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _amount,
                label: 'المبلغ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validateAmount,
              ),
              SizedBox(height: 16.h),

              // **Before the button, not after it.** This is the whole point of `capital_timing`:
              // a person who offers money on the 9th and is told nothing will believe it is
              // working today, and will be owed a month's profit nobody promised him.
              _TimingNotice(
                timing: widget.timing,
                direction: _direction,
                queues: _queues,
              ),
              SizedBox(height: 16.h),

              AppTextField(controller: _notes, label: 'ملاحظات', maxLines: 2),
              SizedBox(height: 20.h),

              AppButton(
                label: _queues ? 'سجّل الطلب' : 'نفّذ الآن',
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What will actually happen, in one sentence, before anybody presses anything.
///
/// The dates come from the server's own answer — the same function that then acts on the request
/// — so the warning and the behaviour cannot drift apart. The app computes none of it.
class _TimingNotice extends StatelessWidget {
  const _TimingNotice({
    required this.timing,
    required this.direction,
    required this.queues,
  });

  final CapitalTiming? timing;
  final _Direction direction;
  final bool queues;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final value = timing;

    if (value == null) {
      return const SizedBox.shrink();
    }

    final message = switch (direction) {
      _Direction.outward =>
        'السحب ينفَّذ عند إقفال الفترة، بعد توزيع أرباحها — فيأخذ الشريك حصته عن هذه الفترة أولاً.',
      _Direction.inward when !queues =>
        'داخل مهلة الدخول: المال يُحتسب من بداية الفترة الجارية'
            '${value.graceWindowEndsOn == null ? '' : ' (تنتهي المهلة ${value.graceWindowEndsOn})'}.',
      _Direction.inward =>
        'انتهت مهلة الدخول لهذه الفترة. المال يبقى في محفظة المستثمر ويبدأ عمله'
            '${value.capitalTakesEffectOn == null ? ' مع الفترة القادمة' : ' في ${value.capitalTakesEffectOn}'}.',
    };

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: queues
            ? scheme.tertiaryContainer.withValues(alpha: 0.6)
            : scheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            queues ? Icons.schedule_outlined : Icons.check_circle_outline,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(message, style: context.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _InvestorPicker extends StatelessWidget {
  const _InvestorPicker({required this.value, required this.onChanged});

  final Investor? value;
  final ValueChanged<Investor?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final chosen = value;

    return InkWell(
      onTap: () async {
        final investor = await showInvestorPicker(context: context);
        if (investor != null) onChanged(investor);
      },
      borderRadius: BorderRadius.circular(14.r),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'المستثمر',
          prefixIcon: Icon(Icons.person_outline),
        ),
        child: Text(
          chosen?.name ?? 'اختر المستثمر',
          style: context.textTheme.bodyMedium?.copyWith(
            color: chosen == null ? scheme.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }
}
