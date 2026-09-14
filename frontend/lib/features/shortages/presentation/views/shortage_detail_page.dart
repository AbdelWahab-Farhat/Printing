import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/changes.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/presentation/viewmodel/shortage_detail_cubit.dart';
import 'package:dayaa/features/shortages/presentation/widgets/assign_shortage_sheet.dart';
import 'package:dayaa/features/shortages/presentation/widgets/record_supply_sheet.dart';
import 'package:dayaa/features/shortages/presentation/widgets/shortage_status_pill.dart';
import 'package:dayaa/features/shortages/presentation/widgets/supplies_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One shortage: the four numbers, where it came from, who has it, and its ledger.
class ShortageDetailPage extends StatelessWidget {
  const ShortageDetailPage({required this.shortageId, super.key});

  final int shortageId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShortageDetailCubit>(
      create: (_) => sl<ShortageDetailCubit>(param1: shortageId)..load(),
      child: const _ShortageDetailView(),
    );
  }
}

class _ShortageDetailView extends StatefulWidget {
  const _ShortageDetailView();

  @override
  State<_ShortageDetailView> createState() => _ShortageDetailViewState();
}

class _ShortageDetailViewState extends State<_ShortageDetailView> {
  /// Every reading this screen saw, so the list behind is handed the row only when it is out of
  /// date — see [Changes].
  final _changes = Changes<Shortage>();

  /// Runs a write and prints whatever the server said, as it said it.
  ///
  /// **Every refusal here is a 422 with its own sentence** — an illegal move, a quantity above
  /// the remainder, an arrival from the order that may not be undone here — and each tells the
  /// person something different to do. None of them is re-worded in Dart.
  Future<void> _run(Future<Object?> Function() write) async {
    final failure = await write();

    if (!mounted || failure == null) return;

    context.showFailure(failure as dynamic);
  }

  Future<void> _assign(Shortage shortage) async {
    final cubit = context.read<ShortageDetailCubit>();

    final choice = await showAssignShortageSheet(
      context: context,
      currentUserId: shortage.assignedToUserId,
    );

    // Null is a dismissal; «غير مُسنَد» arrives as a choice carrying a null id, which is an
    // instruction — see `ShortageRepository.assign`.
    if (choice == null || !mounted) return;

    await _run(() => cubit.assign(choice.userId));
  }

  Future<void> _recordSupply(Shortage shortage) async {
    final cubit = context.read<ShortageDetailCubit>();

    final entry = await RecordSupplySheet.open(context, shortage: shortage);
    if (entry == null || !mounted) return;

    await _run(
      () => cubit.recordSupply(
        quantity: entry.quantity,
        amount: entry.amount,
        method: entry.method,
        warehouseId: entry.warehouseId,
        reference: entry.reference,
        occurredOn: entry.occurredOn,
        notes: entry.notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShortageDetailCubit>();
    final session = sl<Session>();

    return BlocConsumer<ShortageDetailCubit, ShortageDetailState>(
      // **Every reading goes past here**, whatever produced it — the first load, a status move,
      // an assignment, a supply and its undo. What differs from the first reading is what the
      // النواقص list behind is handed, and it travels **beside** the route rather than through
      // the pop, so the arrow, the Android button and the edge swipe all deliver it.
      //
      // This screen used to intercept the pop and hand the row over from there. That bought the
      // row and sold every way out: `PopScope(canPop: false)` switches the iOS edge gesture off
      // — `ModalRoute.popGestureEnabled` returns false for any route that says it might veto —
      // and the callback never popped, so the screen could not be left at all. It is the exact
      // trap [PopResult] was written to end; see its note.
      listener: (context, state) => context.handBack(_changes.saw(state.shortage)),
      builder: (context, state) {
        final shortage = state.shortage;

        return Scaffold(
          appBar: AppBar(
            title: Text(shortage == null ? 'النقص' : shortage.name),
            actions: [
              if (shortage != null && shortage.isEditable && session.can(AppPermission.manageShortages))
                IconButton(
                  onPressed: () => context.push(Routes.shortageForm, extra: shortage),
                  icon: Icon(AppIcons.edit),
                  tooltip: 'تعديل',
                ),
            ],
          ),
          floatingActionButton:
              shortage != null &&
                  shortage.isOutstanding &&
                  session.can(AppPermission.recordShortageSupplies)
              ? FloatingActionButton.extended(
                  heroTag: 'fab-shortage-supply',
                  onPressed: state.isWorking ? null : () => _recordSupply(shortage),
                  icon: Icon(AppIcons.add),
                  label: const Text('تسجيل توفير'),
                )
              : null,
          body: switch ((shortage, state)) {
            (null, ShortageDetailFailure(:final failure)) => _Failure(
              failure: failure,
              onRetry: cubit.load,
            ),
            (null, _) => const Center(child: CircularProgressIndicator()),
            (final loaded?, _) => RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
                children: [
                  // **The order it was born from, before anything else on the screen.** A نقص
                  // mirrored from a line of an order is not a thing the shop wants — it is the
                  // reason one order has stopped — so it is the context every figure below is
                  // read in, and it is a door: one tap to «لماذا لم تتحرّك هذه الطلبية؟».
                  //
                  // Absent on a shortage the shop wrote down for itself, which owes nobody an
                  // order and would draw an empty chip explaining nothing.
                  if (loaded.orderId case final orderId?) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _TappableChip(
                        icon: AppIcons.orders,
                        label: 'الطلبية #${loaded.orderCode}',
                        onTap: () => context.push(Routes.order(orderId)),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                  _Numbers(shortage: loaded),
                  SizedBox(height: 16.h),
                  _Facts(
                    shortage: loaded,
                    onAssign: session.can(AppPermission.assignShortages) && !state.isWorking
                        ? () => _assign(loaded)
                        : null,
                  ),
                  SizedBox(height: 16.h),
                  if (session.can(AppPermission.manageShortages))
                    _StatusActions(shortage: loaded, isWorking: state.isWorking),
                  SizedBox(height: 16.h),
                  SuppliesTable(
                    shortage: loaded,
                    onReverse: session.can(AppPermission.reverseShortageSupplies)
                        ? (supply) => _run(() => cubit.reverseSupply(supply.id))
                        : null,
                  ),
                ],
              ),
            ),
          },
        );
      },
    );
  }
}

/// The four figures §٩ of the brief asks for, together and in that order.
///
/// Together because they are one sentence: «طُلب ثلاثون، تَوفّر ثلاثون، لم يبقَ شيء، ودُفع
/// سبعمئة وستون». Split across the screen they would be four numbers to hunt for.
class _Numbers extends StatelessWidget {
  const _Numbers({required this.shortage});

  final Shortage shortage;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line(label: 'إجمالي المطلوب', value: shortage.withUnit(shortage.requiredQuantity)),
          SizedBox(height: 10.h),
          _Line(label: 'إجمالي المتوفر', value: shortage.withUnit(shortage.suppliedQuantity)),
          SizedBox(height: 10.h),
          _Line(
            label: 'المتبقي',
            value: shortage.withUnit(shortage.remainingQuantity),
            tone: shortage.isOutstanding ? scheme.error : scheme.paid,
          ),
          SizedBox(height: 10.h),
          _Line(label: 'إجمالي المدفوع', value: '${shortage.totalPaid.grouped} د.ل'),
        ],
      ),
    );
  }
}

/// How loud a [_TappableChip] is.
enum _ChipTone {
  /// A door worth seeing: the order, and a shortage somebody already has.
  named,

  /// A blank worth filling, and no louder than that — «غير مُسنَد» is a queue, not a problem.
  quiet,
}

/// A pill that opens something.
///
/// **It borrows [ShortageStatusPill]'s shape on purpose.** The status is the one thing on this
/// screen a reader has already learnt to read as «a small box that means something», so a control
/// wearing the same shape reads as tappable without a sentence explaining that it is. The pencil
/// is what separates the two: the status pill states, this one invites.
class _TappableChip extends StatelessWidget {
  const _TappableChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = _ChipTone.named,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (background, foreground) = switch (tone) {
      _ChipTone.named => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _ChipTone.quiet => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsetsDirectional.only(start: 10.w, end: 8.w, top: 5.h, bottom: 5.h),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: foreground),
            SizedBox(width: 6.w),
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Text(label, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const Spacer(),
        Text(
          value,
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: tone ?? scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Where it came from, who has it, and what it is called — with the way through to the order.
class _Facts extends StatelessWidget {
  const _Facts({required this.shortage, this.onAssign});

  final Shortage shortage;

  /// Null for a reader without `shortages.assign`.
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'الحالة',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              ShortageStatusPill(shortage: shortage),
            ],
          ),
          SizedBox(height: 12.h),
          // The way through to the order is not here but at the top of the screen — it is the
          // context this card's facts are read in, not one of them.
          _Line(label: 'المصدر', value: shortage.sourceLabel),
          SizedBox(height: 10.h),
          // **Its own grant, `shortages.assign`.** Routing work and doing it are different jobs:
          // a supervisor hands a shortage to somebody without being trusted to spend money on
          // it. A reader without the grant still sees who has it — the row simply does not tap.
          if (onAssign case final assign?)
            Row(
              children: [
                Text(
                  'المسؤول',
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const Spacer(),
                // **A chip, because the row is a control.** It used to be plain text with an
                // InkWell behind it, indistinguishable from the three facts around it — and the
                // question that came back from the floor was «كيف أعيّن مسؤولاً؟». It wears the
                // shape of the status pill directly above it, which is the one thing on this
                // card a reader already knows opens something.
                _TappableChip(
                  key: const ValueKey('assign-shortage'),
                  icon: AppIcons.edit,
                  label: shortage.assignee?.name ?? 'غير مُسنَد',
                  tone: shortage.assignee == null ? _ChipTone.quiet : _ChipTone.named,
                  onTap: assign,
                ),
              ],
            )
          else
            _Line(label: 'المسؤول', value: shortage.assignee?.name ?? 'غير مُسنَد'),
          if (shortage.customer case final customer?) ...[
            SizedBox(height: 10.h),
            _Line(label: 'العميل', value: customer.name),
          ],
          if (shortage.description case final note? when note.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(note, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// The moves, drawn from `available_transitions` and from nothing else.
///
/// **So «مكتمل» is never offered**: it is written by arithmetic when the remainder reaches zero,
/// the API refuses it by name, and a button for it would be a screen teaching people to distrust
/// their screens.
class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.shortage, required this.isWorking});

  final Shortage shortage;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    if (!shortage.canChangeStatus) return const SizedBox.shrink();

    final cubit = context.read<ShortageDetailCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final move in shortage.availableTransitions) ...[
          // Full width, like every other action button in this app.
          FilledButton.tonal(
            onPressed: isWorking
                ? null
                : () async {
                    final failure = await cubit.changeStatus(move.value);

                    if (failure != null && context.mounted) context.showFailure(failure);
                  },
            child: Text('تحويل إلى «${move.label}»'),
          ),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.failure, required this.onRetry});

  final Object failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The server's own sentence — including «هذا النقص يخصّ طلبية في الأرشيف…», which is
            // deliberately not the blanket «ليس لديك صلاحية»: the reader holds the grant the
            // endpoint asks for and is being refused by a fact about this row.
            Text(
              (failure as dynamic).message as String? ?? 'تعذّر فتح النقص',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
