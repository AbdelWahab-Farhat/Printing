import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/features/audit/models/activity_log_entry.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/audit/presentation/viewmodel/activity_log_cubit.dart';

/// The history of one record — **any** record.
///
/// Every model in this system keeps a complete change log; that is a standing rule rather than
/// something each feature decides. So this is one screen, not one per model: the API hangs every
/// history off its own record at `/{resource}/{id}/logs`, and [AuditSubject] carries the two
/// things that differ — the path segment and the Arabic noun.
///
/// Adding a model to it is one enum case. No new screen, no new Cubit, no second design that
/// slowly stops matching this one.
///
/// It sits behind `logs.view`, which is deliberately not the permission that guards the record:
/// reading a history exposes what *everyone* has done, including people and prices the reader
/// may have no other way to see. Somebody who may edit a customer is not automatically somebody
/// who may audit their colleagues — so the gate is the server's, and this screen simply shows
/// whatever it is given.
class ActivityLogPage extends StatelessWidget {
  const ActivityLogPage({
    required this.subject,
    required this.recordId,
    this.title,
    super.key,
  });

  final AuditSubject subject;
  final int recordId;

  /// What the record is called — «مطبعة النور». Shown under the heading so the screen says
  /// whose history this is, not merely that it is one.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActivityLogCubit>(
      create: (_) => ActivityLogCubit(
        subject: subject,
        recordId: recordId,
        getActivityLog: sl(),
      )..load(),
      child: _ActivityLogView(subject: subject, title: title),
    );
  }
}

class _ActivityLogView extends StatelessWidget {
  const _ActivityLogView({required this.subject, this.title});

  final AuditSubject subject;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ActivityLogCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('سجل ${subject.noun}'),
            if (title != null)
              Text(
                title!,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: BlocBuilder<ActivityLogCubit, PagedState<ActivityLogEntry>>(
        builder: (context, state) => PagedListView<ActivityLogEntry>(
          state: state,
          emptyMessage: 'لا توجد تعديلات مسجّلة بعد',
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.refresh,
          skeletonHeight: 96.h,
          itemBuilder: (context, entry, index) =>
              _Entry(key: ValueKey(entry.id), entry: entry),
        ),
      ),
    );
  }
}

/// One change: who, when, and what moved.
class _Entry extends StatelessWidget {
  const _Entry({required this.entry, super.key});

  final ActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fields = entry.changes?.fields ?? const <(String, Object?, Object?)>[];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _EventChip(entry: entry),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  // The sentence the server stored at the time. Never one composed here — a
                  // history that rewords itself when the app changes is not a history.
                  entry.description ?? entry.eventLabel ?? entry.event,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(AppIcons.person, size: 15.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  // «النظام» when nobody did it by hand — a seeder, a console command. Saying
                  // so beats a blank where a name should be.
                  entry.byWhom,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (entry.createdAt case final at?)
                Text(
                  '${at.year}/${at.month}/${at.day} — '
                  '${at.hour.toString().padLeft(2, '0')}:'
                  '${at.minute.toString().padLeft(2, '0')}',
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.labelSmall?.copyWith(color: scheme.outline),
                ),
            ],
          ),
          if (fields.isNotEmpty) ...[
            SizedBox(height: 10.h),
            for (final (field, before, after) in fields)
              _FieldChange(field: field, before: before, after: after),
          ],
        ],
      ),
    );
  }
}

/// What one field went from, and to.
class _FieldChange extends StatelessWidget {
  const _FieldChange({required this.field, required this.before, required this.after});

  final String field;
  final Object? before;
  final Object? after;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96.w,
            child: Text(
              // The column name as the server records it. Not translated: a made-up Arabic
              // label per column would be a second dictionary to keep in step, and it would be
              // wrong the first time somebody adds a column without telling the app.
              field,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (before != null) ...[
                    TextSpan(
                      text: _show(before),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        // The old value is struck through rather than merely faded: on a
                        // crowded row "before" and "after" have to be told apart at a glance.
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    TextSpan(
                      text: '  ←  ',
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.outline),
                    ),
                  ],
                  TextSpan(
                    text: _show(after),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// A value as a person would read it.
  static String _show(Object? value) => switch (value) {
    null => '—',
    true => 'نعم',
    false => 'لا',
    // An empty string is a field that was cleared, and «فارغ» says that where a blank would
    // look like a rendering fault.
    '' => 'فارغ',
    _ => '$value',
  };
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.entry});

  final ActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // Three tones, because there are three things that happen to a record: it appears, it
    // changes, or it is taken out of use.
    final (background, foreground) = switch (entry.event) {
      'created' => (scheme.primaryContainer, scheme.onPrimaryContainer),
      'deleted' => (scheme.errorContainer, scheme.onErrorContainer),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        entry.eventLabel ?? entry.event,
        style: context.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
