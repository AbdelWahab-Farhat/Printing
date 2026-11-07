import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/files/share_files.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/carrier/models/nawris_settlement.dart';
import 'package:dayaa/features/carrier/presentation/viewmodel/nawris_settlement_cubit.dart';
import 'package:dayaa/features/carrier/presentation/widgets/nawris_settlement_line_tile.dart';
import 'package:dayaa/features/carrier/usecases/nawris_settlement.dart';
import 'package:dayaa/features/orders/presentation/widgets/transition_field_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// «تسوية ملف النورس» — رفع التقرير، ثم معاينة كل طلبية، ثم التنفيذ.
///
/// **المعاينة لا تغيّر شيئاً، والموظف يقرر بعدها.** تُفتح على ما لن يتحرك إن وُجد: هذا ما جاء ليراه.
/// وحين يضغط «تنفيذ» يُسوَّى ما يصلح ويُتخطّى الباقي. Docs/nawris/NAWRIS-SETTLEMENT-IMPORT.md.
class NawrisSettlementPage extends StatelessWidget {
  const NawrisSettlementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NawrisSettlementCubit>(
      create: (_) => sl<NawrisSettlementCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تسوية ملف النورس'),
          actions: [
            IconButton(
              tooltip: 'الدفعات السابقة',
              icon: Icon(AppIcons.history),
              onPressed: () => context.push(Routes.nawrisSettlementImports),
            ),
          ],
        ),
        body: BlocConsumer<NawrisSettlementCubit, NawrisSettlementState>(
          listener: _listen,
          builder: (context, state) => switch (state) {
            NawrisSettlementIdle() => const _Start(),
            NawrisSettlementUnreadable(:final failure) => _Start(failure: failure),
            NawrisSettlementReading(:final file) => _Busy(message: 'يُقرأ ${file.name}…'),
            NawrisSettlementReady(:final preview) => _Review(
              key: ValueKey(preview.fingerprint),
              preview: preview,
            ),
            NawrisSettlementRefused(:final preview, :final failure) => _Review(
              key: ValueKey(preview.fingerprint),
              preview: preview,
              failure: failure,
            ),
            NawrisSettlementSubmitting(:final preview) => _Review(
              key: ValueKey(preview.fingerprint),
              preview: preview,
              isSubmitting: true,
            ),
            NawrisSettlementSettled(:final batch) => _Done(batch: batch),
          },
        ),
      ),
    );
  }

  void _listen(BuildContext context, NawrisSettlementState state) {
    switch (state) {
      case NawrisSettlementSettled(:final batch):
        context.showSuccess('سُوّيت ${batch.summary.settledCount.grouped} طلبية');
      // ما له خانة يُعرض تحتها؛ والباقي لا يضيع.
      case NawrisSettlementRefused(:final preview, :final failure)
          when failure.hasErrorsBeyond({
            'received_amount',
            'difference_reason',
            'fingerprint',
            for (final field in preview.fields) 'fields.${field.key}',
          }):
        context.showFailure(failure);
      default:
        break;
    }
  }
}

/// رفع الملف.
class _Start extends StatelessWidget {
  const _Start({this.failure});

  final Failure? failure;

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<NawrisSettlementCubit>();
    final files = await sl<AttachmentPicker>().pick(
      AttachmentSource.documents,
      extensions: const ['xlsx', 'xls'],
    );

    if (files.isEmpty) return;

    await cubit.read(files.first);
  }

  Future<void> _template(BuildContext context) async {
    const name = 'قالب-تسوية-النورس.xlsx';
    const type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    final result = await sl<DownloadNawrisSettlementTemplate>()();

    if (!context.mounted) return;

    await result.fold((failure) async => context.showFailure(failure), (bytes) async {
      final path = await LocalFiles.writeTemporary(name, bytes, mimeType: type);

      await shareFiles(
        ShareParams(
          files: [XFile(path, mimeType: type)],
          fileNameOverrides: const [name],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Text(
          'ارفع تقرير النورس كما هو. ستظهر لك كل طلبية: ما سيُسوّى، وما لن يتحرك ولماذا — '
          'ولا يتغيّر شيء حتى تضغط «تنفيذ».',
          style: context.textTheme.bodyLarge,
        ),
        if (failure case final failure?) ...[
          SizedBox(height: 12.h),
          Text(failure.message, style: TextStyle(color: scheme.error)),
        ],
        SizedBox(height: 20.h),
        AppButton(
          key: const ValueKey('settlement-pick'),
          label: 'اختر تقرير النورس',
          icon: AppIcons.document,
          onPressed: () => _pick(context),
        ),
        SizedBox(height: 10.h),
        AppButton.outlined(
          label: 'تحميل القالب للإدخال اليدوي',
          icon: AppIcons.download,
          onPressed: () => _template(context),
        ),
      ],
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 12.h),
          Text(message),
        ],
      ),
    );
  }
}

/// ما تعرضه قائمة المعاينة.
enum _Filter {
  problems('لن تتحرك'),
  settling('تُسوّى'),
  warnings('تنبيهات'),
  skipped('مسوّاة سلفاً');

  const _Filter(this.label);

  final String label;

  bool shows(NawrisSettlementLine line) => switch (this) {
    _Filter.problems => line.outcome == NawrisSettlementOutcome.rejected,
    _Filter.settling => line.outcome == NawrisSettlementOutcome.settled,
    _Filter.warnings => line.hasWarnings,
    _Filter.skipped => line.outcome == NawrisSettlementOutcome.alreadySettled,
  };
}

/// المعاينة، وما يكتبه الموظف قبل التنفيذ.
class _Review extends StatefulWidget {
  const _Review({required this.preview, this.failure, this.isSubmitting = false, super.key});

  final NawrisSettlementPreview preview;
  final Failure? failure;
  final bool isSubmitting;

  @override
  State<_Review> createState() => _ReviewState();
}

class _ReviewState extends State<_Review> {
  late final TextEditingController _received;
  late final TextEditingController _reason;
  late final Map<String, String?> _accounts;
  late _Filter _filter;

  /// طلبيات تركها الموظف لأن مالها لم يصل.
  final Set<int> _leftOut = {};

  NawrisSettlementDifference? _difference;

  /// ما دام الموظف لم يكتب مبلغاً فالخانة تتبع ما يبقى بعد كل علامة تُزال.
  bool _amountTyped = false;

  NawrisSettlementPreview get _preview => widget.preview;

  @override
  void initState() {
    super.initState();

    _received = TextEditingController(text: trimDecimals(_preview.expectedReceived));
    _reason = TextEditingController();
    _accounts = {for (final field in _preview.fields) field.key: field.value};

    // ما جاء ليراه أولاً: ما لن يتحرك.
    _filter = _preview.summary.rejectedCount > 0 ? _Filter.problems : _Filter.settling;
  }

  @override
  void dispose() {
    _received.dispose();
    _reason.dispose();
    super.dispose();
  }

  int _count(_Filter filter) => _preview.lines.where(filter.shows).length;

  void _toggle(int orderId) {
    setState(() {
      if (!_leftOut.remove(orderId)) _leftOut.add(orderId);

      if (!_amountTyped) _received.text = trimDecimals(_preview.expectedFor(_leftOut));
    });
  }

  void _answer(NawrisSettlementDifference difference) {
    setState(() {
      _difference = difference;

      // ما لم يصل يُترك من هنا، فالتبويب الذي فيه العلامات هو الخطوة التالية.
      if (difference == NawrisSettlementDifference.notArrived) _filter = _Filter.settling;
    });
  }

  Future<void> _submit() async {
    final cubit = context.read<NawrisSettlementCubit>();
    final summary = _preview.summary;
    final isFee = _preview.hasUnexplainedDifference(_received.text, _leftOut);

    final confirmed = await showCustomDialog(
      context: context,
      title: 'تسوية ${_preview.settlingCount(_leftOut).grouped} طلبية؟',
      description: [
        if (_preview.holdsMoney(_leftOut)) 'يُسجَّل استلام ${_received.text} د.ل من النورس.',
        if (isFee)
          'يُقيَّد ${_preview.differenceFor(_received.text, _leftOut).grouped} د.ل أجرةً للنورس.',
        if (_leftOut.isNotEmpty)
          '${_leftOut.length.grouped} طلبية تبقى «تم الاستلام» ومالها عند النورس.',
        if (summary.rejectedCount > 0)
          '${summary.rejectedCount.grouped} طلبية لن تتحرك وتبقى كما هي.',
      ].join('\n'),
      confirmLabel: 'تنفيذ',
    );

    if (confirmed != true) return;

    await cubit.submit(
      receivedAmount: _received.text,
      differenceReason: isFee ? _reason.text : null,
      accounts: {for (final answer in _accounts.entries) answer.key: ?answer.value},
      leftOut: _leftOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final failure = widget.failure;
    final lines = preview.lines.where(_filter.shows).toList();
    final canSubmit =
        !widget.isSubmitting &&
        preview.canSubmit(
          received: _received.text,
          reason: _reason.text,
          accounts: _accounts,
          difference: _difference,
          leftOut: _leftOut,
        );

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
            itemCount: lines.length + 1,
            separatorBuilder: (_, _) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              if (index > 0) {
                final line = lines[index - 1];
                final orderId = line.orderId;

                return NawrisSettlementLineTile(
                  line: line,
                  isLeftOut: _leftOut.contains(orderId),
                  onToggle: line.isSettling && orderId != null && !widget.isSubmitting
                      ? () => _toggle(orderId)
                      : null,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Summary(preview: preview, leftOut: _leftOut),
                  if (failure?.fieldError('fingerprint') case final stale?) ...[
                    SizedBox(height: 12.h),
                    _Stale(message: stale),
                  ],
                  if (preview.canSettle) ...[
                    SizedBox(height: 12.h),
                    _Money(
                      preview: preview,
                      received: _received,
                      reason: _reason,
                      accounts: _accounts,
                      leftOut: _leftOut,
                      difference: _difference,
                      failure: failure,
                      onAnswer: _answer,
                      onAmountTyped: () => setState(() => _amountTyped = true),
                      onChanged: () => setState(() {}),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      for (final filter in _Filter.values)
                        FilterOptionChip(
                          key: ValueKey('settlement-filter-${filter.name}'),
                          label: filter.label,
                          count: _count(filter),
                          isSelected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    label: 'إلغاء',
                    onPressed: widget.isSubmitting
                        ? null
                        : () => context.read<NawrisSettlementCubit>().reset(),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    key: const ValueKey('settlement-submit'),
                    label: 'تنفيذ (${preview.settlingCount(_leftOut).grouped})',
                    isLoading: widget.isSubmitting,
                    onPressed: canSubmit ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// رفض التنفيذ لأن الملف لم يعد يطابق النظام. لا شيء نُفّذ، ولا بد من معاينة جديدة.
class _Stale extends StatelessWidget {
  const _Stale({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: TextStyle(color: scheme.onErrorContainer)),
          SizedBox(height: 8.h),
          AppButton.tonal(
            key: const ValueKey('settlement-read-again'),
            label: 'إعادة المعاينة',
            onPressed: () => context.read<NawrisSettlementCubit>().readAgain(),
          ),
        ],
      ),
    );
  }
}

/// كم طلبية في كل نتيجة، وكم عند النورس للتي ستُسوّى.
class _Summary extends StatelessWidget {
  const _Summary({required this.preview, required this.leftOut});

  final NawrisSettlementPreview preview;
  final Set<int> leftOut;

  @override
  Widget build(BuildContext context) {
    final summary = preview.summary;
    final text = context.textTheme;
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${summary.rowsCount.grouped} صف — ${summary.ordersCount.grouped} طلبية',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8.h),
          _Figure(
            label: 'تُسوّى',
            value: preview.settlingCount(leftOut).grouped,
            tone: scheme.primary,
          ),
          if (leftOut.isNotEmpty)
            _Figure(label: 'تُركت لتحويل لاحق', value: leftOut.length.grouped),
          _Figure(label: 'لن تتحرك', value: summary.rejectedCount.grouped, tone: scheme.error),
          _Figure(label: 'مسوّاة سلفاً', value: summary.skippedCount.grouped),
          _Figure(label: 'بتنبيه', value: summary.warningsCount.grouped, tone: scheme.tertiary),
          Divider(height: 20.h),
          _Figure(
            label: 'عند النورس لما سيُسوّى',
            value: '${preview.heldFor(leftOut).grouped} د.ل',
          ),
          if (preview.feesFor(leftOut).grouped != '0')
            _Figure(label: 'أجرته المعروفة', value: '${preview.feesFor(leftOut).grouped} د.ل'),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          // يأخذ ما بقي ويلتفّ: الرقم لا يُقصّ، والعنوان الطويل كان يفيض على شاشة هاتف.
          Expanded(
            child: Text(label, style: text.bodyMedium?.copyWith(color: tone)),
          ),
          SizedBox(width: 8.w),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: text.bodyMedium?.copyWith(color: tone, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// كم وصل، ولماذا أقل إن كان أقل، وأين نزل.
class _Money extends StatelessWidget {
  const _Money({
    required this.preview,
    required this.received,
    required this.reason,
    required this.accounts,
    required this.leftOut,
    required this.difference,
    required this.failure,
    required this.onAnswer,
    required this.onAmountTyped,
    required this.onChanged,
  });

  final NawrisSettlementPreview preview;
  final TextEditingController received;
  final TextEditingController reason;
  final Map<String, String?> accounts;
  final Set<int> leftOut;
  final NawrisSettlementDifference? difference;
  final Failure? failure;
  final ValueChanged<NawrisSettlementDifference> onAnswer;
  final VoidCallback onAmountTyped;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final tooMuch = preview.exceedsHeld(received.text, leftOut);
    final asks = preview.hasUnexplainedDifference(received.text, leftOut);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (preview.holdsMoney(leftOut)) ...[
          AppTextField(
            key: const ValueKey('settlement-received'),
            controller: received,
            label: 'المبلغ المستلم من النورس',
            helperText: 'نصيب الطلبيات التي ستُسوّى وحدها — لا كامل التحويل',
            errorText: tooMuch
                ? 'أكبر مما عند النورس لهذه الطلبيات (${preview.heldFor(leftOut).grouped})'
                : failure?.fieldError('received_amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.]'))],
            onChanged: (_) => onAmountTyped(),
          ),
          if (asks) ...[
            SizedBox(height: 10.h),
            Text(
              'الفرق ${preview.differenceFor(received.text, leftOut).grouped} د.ل — ما هو؟',
              style: context.textTheme.titleSmall,
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                FilterOptionChip(
                  key: const ValueKey('settlement-difference-fee'),
                  label: 'أجرة النورس',
                  isSelected: difference == NawrisSettlementDifference.fee,
                  onTap: () => onAnswer(NawrisSettlementDifference.fee),
                ),
                FilterOptionChip(
                  key: const ValueKey('settlement-difference-not-arrived'),
                  label: 'ما زال عند النورس',
                  isSelected: difference == NawrisSettlementDifference.notArrived,
                  onTap: () => onAnswer(NawrisSettlementDifference.notArrived),
                ),
              ],
            ),
            if (difference == NawrisSettlementDifference.fee) ...[
              SizedBox(height: 10.h),
              AppTextField(
                key: const ValueKey('settlement-reason'),
                controller: reason,
                label: 'سبب الفرق',
                helperText: 'يُقيَّد مصروفاً ويُقسم على الطلبيات بنسبة مبالغها',
                errorText: failure?.fieldError('difference_reason'),
                maxLength: 500,
                onChanged: (_) => onChanged(),
              ),
            ],
            if (difference == NawrisSettlementDifference.notArrived) ...[
              SizedBox(height: 8.h),
              Text(
                'أزل العلامة عن الطلبيات التي لم يصل مالها، حتى يساوي ما عند النورس لما سيُسوّى '
                'المبلغ المستلم. تبقى «تم الاستلام» ومالها عند النورس، وترفع الملف نفسه حين يصل.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
          SizedBox(height: 10.h),
        ],
        for (final field in preview.fields) ...[
          TransitionFieldInput(
            field: field,
            value: accounts[field.key],
            customerId: 0,
            errorText: failure?.fieldError('fields.${field.key}'),
            onChanged: (value) {
              accounts[field.key] = value as String?;
              onChanged();
            },
          ),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }
}

/// الدفعة بعد التنفيذ.
class _Done extends StatelessWidget {
  const _Done({required this.batch});

  final NawrisSettlementImport batch;

  @override
  Widget build(BuildContext context) {
    final summary = batch.summary;
    final scheme = context.colorScheme;

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Icon(AppIcons.settled, size: 48.sp, color: scheme.primary),
        SizedBox(height: 12.h),
        Text(
          'سُوّيت ${summary.settledCount.grouped} طلبية',
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge,
        ),
        SizedBox(height: 16.h),
        _Figure(label: 'المبلغ المستلم', value: '${batch.receivedAmount.grouped} د.ل'),
        if (batch.feeTotal.grouped != '0')
          _Figure(label: 'ما احتفظ به النورس', value: '${batch.feeTotal.grouped} د.ل'),
        if (summary.leftOutCount > 0)
          _Figure(label: 'تُركت لتحويل لاحق', value: summary.leftOutCount.grouped),
        _Figure(label: 'لم تتحرك', value: summary.rejectedCount.grouped, tone: scheme.error),
        _Figure(label: 'مسوّاة سلفاً', value: summary.skippedCount.grouped),
        SizedBox(height: 20.h),
        AppButton(
          label: 'عرض الدفعة',
          onPressed: () => context.push(Routes.nawrisSettlementImport(batch.id)),
        ),
        SizedBox(height: 10.h),
        AppButton.outlined(
          label: 'رفع ملف آخر',
          onPressed: () => context.read<NawrisSettlementCubit>().reset(),
        ),
      ],
    );
  }
}
