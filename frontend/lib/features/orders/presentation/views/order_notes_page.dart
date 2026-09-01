import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Everything written on the order, each note beside the status it was written at.
///
/// **A note belongs to a step, not to a corner of the delivery card.** «ملاحظات» used to be one
/// row inside «التوصيل», between the address and the tracking number, which put a sentence about
/// the *job* among facts about the *parcel* — and it could only ever show one note, the order's
/// own. Every other note the shop writes is typed when the order is moved: «ناقص ٤٠ كيس» on the
/// way into «نواقص», «العميل غيّر رأيه» on the way into «ملغاة». Those were readable only inside
/// the timeline, mixed with names and timestamps.
///
/// So this page is the answer to one question — «ماذا كُتب على هذه الطلبية؟» — and it shows the
/// two things that question wants: the words, and which status they were written at. Who wrote
/// them and when is the timeline's job, and «سجل الحالات» is still on the order screen.
///
/// **It fetches nothing when it does not have to.** The screen that opens it already holds the
/// order, so it hands it over; a cold deep link arrives with nothing and loads it the same way
/// the order screen does.
class OrderNotesPage extends StatelessWidget {
  const OrderNotesPage({required this.orderId, this.order, super.key});

  final int orderId;

  /// The order as the screen behind already has it. Null on a deep link.
  final Order? order;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderDetailCubit>(
      create: (_) {
        final cubit = sl<OrderDetailCubit>(param1: orderId);

        if (order case final known?) {
          cubit.replace(known);
        } else {
          cubit.load();
        }

        return cubit;
      },
      child: const _NotesView(),
    );
  }
}

class _NotesView extends StatelessWidget {
  const _NotesView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderDetailCubit>();

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) => Text(
            state.order == null ? 'الملاحظات' : 'ملاحظات طلبية #${state.order!.code}',
          ),
        ),
      ),
      body: BlocBuilder<OrderDetailCubit, OrderDetailState>(
        builder: (context, state) => switch (state) {
          OrderDetailLoading() => const Center(child: CircularProgressIndicator()),
          OrderDetailFailure(:final failure) when state.order == null => _Failure(
            message: failure.message,
            onRetry: cubit.load,
          ),
          _ => _Notes(order: state.order!),
        },
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final notes = OrderNote.on(order);

    if (notes.isEmpty) return const _Nothing();

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      itemCount: notes.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) => _Note(note: notes[index]),
    );
  }
}

/// One thing written on the order, and where it was written.
///
/// [status] is null for the order's own note alone: it is edited from «تعديل الطلبية» at any
/// point in the job, so pinning it to a status would be claiming something nobody recorded.
class OrderNote {
  const OrderNote({required this.text, this.status, this.statusLabel});

  final String text;
  final OrderStatus? status;

  /// The server's Arabic for that status — rendered as-is, like everywhere else.
  final String? statusLabel;

  /// Everything written on one order: its own note first, then one per move that carried words.
  ///
  /// **Oldest first**, for the reason the timeline is: this reads as what happened to a job, and
  /// a story told backwards has to be re-assembled by the reader.
  ///
  /// A note of nothing but spaces is not a note — the server keeps what was typed, and a card
  /// drawn around a blank is a row that says something was written when nothing was.
  static List<OrderNote> on(Order order) => [
    if (order.notes?.trim() case final note? when note.isNotEmpty) OrderNote(text: note),
    for (final record in order.transitions ?? const <OrderTransitionRecord>[])
      if (record.reason?.trim() case final reason? when reason.isNotEmpty)
        OrderNote(text: reason, status: record.toStatus, statusLabel: record.toStatusLabel),
  ];
}

class _Note extends StatelessWidget {
  const _Note({required this.note});

  final OrderNote note;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
        // **Drawn, not just tinted.** A card of `surfaceContainerLow` on a surface barely
        // paler than it left a short note floating in a wide grey rectangle with no edge to
        // it — the shorter the note, the less card there was to see.
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The status wears the legend it wears on the list card and in the header — one
          // status, one look, wherever it is drawn — and at full size, because on this page it
          // is half of what the row says rather than a badge in a corner.
          if (note.status case final status?)
            OrderStatusChip(status: status, label: note.statusLabel ?? '', showIcon: true)
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.notes, size: 17.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 6.w),
                  Text(
                    'ملاحظة الطلبية',
                    style: context.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 12.h),
          // Prose, so it wraps and is never cut: a note nobody can read the end of is worse
          // than no note.
          Text(note.text, style: context.textTheme.titleSmall?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _Nothing extends StatelessWidget {
  const _Nothing();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.notes, size: 44.sp, color: scheme.onSurfaceVariant),
            SizedBox(height: 14.h),
            Text(
              'لا توجد ملاحظات على هذه الطلبية',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8.h),
            // Where notes come from, said once here rather than left to be discovered: the
            // page is empty for a reason, and the reason is that nobody has written one yet.
            Text(
              'تُكتب الملاحظة عند تغيير حالة الطلبية، أو على الطلبية نفسها من «تعديل الطلبية»',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: scheme.error),
            SizedBox(height: 16.h),
            // The server's own Arabic: it usually says what to do about it.
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 20.h),
            AppButton.tonal(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
