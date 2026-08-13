import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/features/audit/models/activity_log_entry.dart';
import 'package:printing/features/audit/models/audit_event.dart';
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
///
/// ## How it reads
///
/// Three things carry the whole design, and each replaced something that was on screen and
/// unreadable:
///
///   * **Arabic column names.** `page_url`, `latitude`, `customer_id` are this schema's words.
///     The names come from the server with each entry — see `ActivityLogEntry.attributeLabels`
///     — because a dictionary in the app is wrong the first morning somebody adds a column.
///   * **Grouped by the day it happened**, under a dated rule. A flat run of forty cards each
///     stamped `2026/8/1 — 21:09` makes the reader do the grouping in their head.
///   * **«قبل ← بعد» for an edit**, and a plain list of values for a creation or a deletion.
///     An arrow drawn on a creation would invent a value that never existed.
class ActivityLogPage extends StatelessWidget {
  const ActivityLogPage({required this.subject, required this.recordId, this.title, super.key});

  final AuditSubject subject;
  final int recordId;

  /// What the record is called — «مطبعة النور». Shown under the heading so the screen says
  /// whose history this is, not merely that it is one.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActivityLogCubit>(
      create: (_) =>
          ActivityLogCubit(subject: subject, recordId: recordId, getActivityLog: sl())..load(),
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
        builder: (context, state) => Column(
          children: [
            // Outside the list, so the control stays put while the list under it reloads. A
            // filter row that vanishes into a skeleton the moment it is used is a filter row
            // the thumb loses.
            _EventFilter(active: cubit.event, counts: cubit.eventCounts),
            Expanded(
              child: PagedListView<ActivityLogEntry>(
                state: state,
                emptyMessage: cubit.event == null
                    ? 'لا توجد تعديلات مسجّلة بعد'
                    // Says which filter found nothing, so nobody concludes the record has no
                    // history at all.
                    : 'لا توجد أحداث من نوع «${cubit.event!.label}»',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 118.h,
                itemBuilder: (context, entry, index) => _Entry(
                  key: ValueKey(entry.id),
                  entry: entry,
                  // The heading belongs to the first entry of its day rather than to a row of
                  // its own: the list is flat and paginated, and a separate header row would
                  // have to be spliced in at every page boundary.
                  day: _dayHeadingFor(state, index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The date rule to draw above this entry, or null when it is not the first of its day.
  ///
  /// Only [PagedLoaded] has neighbours to compare against.
  _Day? _dayHeadingFor(PagedState<ActivityLogEntry> state, int index) {
    if (state is! PagedLoaded<ActivityLogEntry>) return null;

    final items = state.page.items;
    final at = items[index].createdAt;
    if (at == null) return null;

    final key = _Day.keyOf(at);
    if (index > 0) {
      final previous = items[index - 1].createdAt;
      if (previous != null && _Day.keyOf(previous) == key) return null;
    }

    // Counted over the loaded run, and only forwards: a day split across a page boundary would
    // otherwise report a total that changes as the reader scrolls. The count is of what is on
    // screen under this heading, which is what it visibly labels.
    var count = 0;
    for (var i = index; i < items.length; i++) {
      final other = items[i].createdAt;
      if (other == null || _Day.keyOf(other) != key) break;
      count++;
    }

    return _Day(at: at, count: count);
  }
}

/// «الكل · إنشاء · تعديل · حذف · استرجاع», with how many of each.
///
/// The counts come from the server's `meta` and describe the whole trail, not the page in front
/// of the reader — see `ActivityLogCubit.eventCounts`. Filtering is server-side for the same
/// reason: narrowing the one page already downloaded would show a fraction of the history and
/// present it as all of it.
class _EventFilter extends StatelessWidget {
  const _EventFilter({required this.active, required this.counts});

  final AuditEvent? active;
  final Map<AuditEvent, int> counts;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ActivityLogCubit>();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: _Chip(
              // Keyed by the event it selects. «إنشاء» is also what the badge on a creation
              // card says, so without this a test tapping the chip by its words could tap a
              // card — and so could an accessibility tool driving the screen.
              key: const ValueKey('event-filter-all'),
              label: 'الكل',
              // The sum, not a separate number: one total that disagrees with the four beside
              // it is the kind of thing nobody reports and everybody notices.
              count: counts.isEmpty
                  ? null
                  : counts.values.fold<int>(0, (sum, value) => sum + value),
              isActive: active == null,
              tone: context.colorScheme.onSurface,
              onTone: context.colorScheme.surface,
              onTap: () => unawaited(cubit.filterBy(null)),
            ),
          ),
          for (final event in AuditEvent.values) ...[
            SizedBox(width: 6.w),
            Expanded(
              child: _Chip(
                key: ValueKey('event-filter-${event.wire}'),
                label: event.label,
                count: counts[event],
                isActive: active == event,
                tone: _toneOf(context, event).$1,
                onTone: _toneOf(context, event).$2,
                onTap: () => unawaited(cubit.filterBy(event)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.tone,
    required this.onTone,
    required this.onTap,
    super.key,
  });

  final String label;

  /// Null before the first page has arrived. No badge at all then — a zero that turns into a
  /// four a moment later is a number nobody can trust.
  final int? count;
  final bool isActive;
  final Color tone;
  final Color onTone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: isActive ? tone : scheme.surfaceContainerLowest,
      shape: StadiumBorder(
        side: isActive
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? onTone : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (count != null) ...[
                SizedBox(width: 4.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isActive
                        ? onTone.withValues(alpha: 0.22)
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    count!.grouped,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: isActive ? onTone : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A day, and how many of the loaded entries fall under it.
@immutable
class _Day {
  const _Day({required this.at, required this.count});

  final DateTime at;
  final int count;

  static String keyOf(DateTime at) => '${at.year}/${at.month}/${at.day}';

  /// «اليوم», «أمس», or the date. The two words are worth the special case: on the screen
  /// somebody opens after making a change, the top heading is the one they are looking for.
  String get label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final difference = today.difference(day).inDays;

    return switch (difference) {
      0 => 'اليوم',
      1 => 'أمس',
      _ => keyOf(at),
    };
  }

  /// Arabic counts its own way: one, two, a few, and many are four different words.
  String get countLabel => switch (count) {
    1 => 'حدث واحد',
    2 => 'حدثان',
    >= 3 && <= 10 => '${count.grouped} أحداث',
    _ => '${count.grouped} حدثاً',
  };
}

/// One change: who, when, and what moved.
class _Entry extends StatelessWidget {
  const _Entry({required this.entry, this.day, super.key});

  final ActivityLogEntry entry;

  /// Drawn above the card when this is the first entry of its day.
  final _Day? day;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = _toneOf(context, entry.kind).$1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (day case final day?) ...[
          Padding(
            padding: EdgeInsets.only(top: 6.h, bottom: 10.h),
            child: Row(
              children: [
                Text(
                  day.label,
                  style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 8.w),
                Text(
                  day.countLabel,
                  style: context.textTheme.labelSmall?.copyWith(color: scheme.outline),
                ),
                SizedBox(width: 8.w),
                // The rule runs to the far edge, which is what makes the heading read as a
                // divider rather than as another row of text.
                Expanded(child: Divider(height: 1, color: scheme.outlineVariant)),
              ],
            ),
          ),
        ],
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Rail(tone: tone),
              SizedBox(width: 10.w),
              Expanded(child: _Card(entry: entry)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The dot and the line under it, on the leading edge — the right, in Arabic.
class _Rail extends StatelessWidget {
  const _Rail({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16.h),
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        ),
        SizedBox(height: 4.h),
        // Stops at the bottom of its own card rather than running through the gap: a
        // continuous line would have to be drawn by the list, and the list is paginated.
        Expanded(
          child: Container(width: 2.w, color: context.colorScheme.outlineVariant),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.entry});

  final ActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final changes = entry.changes;

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
              Expanded(
                child: Text(
                  // The sentence the server stored at the time. Never one composed here — a
                  // history that rewords itself when the app changes is not a history.
                  entry.description ?? entry.eventLabel ?? entry.event,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(width: 8.w),
              _EventChip(entry: entry),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(AppIcons.person, size: 14.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  // «النظام» when nobody did it by hand — a seeder, a console command. Saying
                  // so beats a blank where a name should be.
                  entry.byWhom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              if (entry.createdAt case final at?) ...[
                Text(
                  ' · ',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
                Text(
                  '${at.hour.toString().padLeft(2, '0')}:'
                  '${at.minute.toString().padLeft(2, '0')}',
                  // A clock reads left to right even here. The date is in the heading above,
                  // so the row carries only the time.
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
              ],
            ],
          ),
          if (changes != null && !changes.isEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: changes.isMovement
                    ? [
                        for (final (field, before, after) in changes.fields)
                          _Movement(
                            label: entry.labelFor(field),
                            before: before,
                            after: after,
                            beforeLabel: entry.valueLabelFor(field, old: true),
                            afterLabel: entry.valueLabelFor(field, old: false),
                          ),
                      ]
                    : [
                        for (final (field, value) in changes.statedValues)
                          _Stated(
                            label: entry.labelFor(field),
                            value: value,
                            // A deletion states its values from `old`, a creation from
                            // `attributes` — the same half `statedValues` read them from.
                            valueLabel: entry.valueLabelFor(
                              field,
                              old: changes.attributes?.isEmpty ?? true,
                            ),
                          ),
                      ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A value an entry simply states — a creation's starting values, or the last ones a deleted
/// record had.
class _Stated extends StatelessWidget {
  const _Stated({required this.label, required this.value, this.valueLabel});

  final String label;
  final Object? value;

  /// The Arabic the server sent for this value, or null when it sent none — a name is already
  /// Arabic and a total is a number.
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _show(value, valueLabel),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// One field, and where it went.
class _Movement extends StatelessWidget {
  const _Movement({
    required this.label,
    required this.before,
    required this.after,
    this.beforeLabel,
    this.afterLabel,
  });

  final String label;
  final Object? before;
  final Object? after;

  /// What each half *says*, when the server had something to say about it. Null for the values
  /// that need no translating, which is most of them.
  final String? beforeLabel;
  final String? afterLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 2.h),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _show(before, beforeLabel),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    // Struck through rather than merely faded: on a crowded row, "before" and
                    // "after" have to be told apart at a glance and colour alone does not do
                    // it for everybody.
                    decoration: TextDecoration.lineThrough,
                    decorationColor: scheme.error,
                  ),
                ),
                TextSpan(
                  text: '  ←  ',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
                TextSpan(
                  text: _show(after, afterLabel),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.entry});

  final ActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final (_, _, background, foreground) = _tones(context, entry.kind);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8.r)),
      child: Text(
        // The server's own word for it, so an event this build has no case for still names
        // itself correctly.
        entry.eventLabel ?? entry.event,
        style: context.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A value as a person would read it.
///
/// **The server's translation wins whenever there is one.** It is the only side that knows
/// `printing` is a status and not a word — the enum that says «قيد الطباعة» lives beside the
/// column that stores it. What is left here is the part that needs no schema at all: the empty
/// cases, the two booleans, and a timestamp, which is formatted on the device because only the
/// device knows what time zone it is in.
String _show(Object? value, [String? label]) => switch (value) {
  _ when label != null && label.isNotEmpty => label,
  null => '—',
  true => 'نعم',
  false => 'لا',
  String() when _asDate(value) != null => _stamp(_asDate(value)!),
  // An empty string is a field that was cleared, and «فارغ» says that where a blank would look
  // like a rendering fault.
  '' => 'فارغ',
  _ => '$value',
};

/// A timestamp the trail stored, or null for a string that merely looks numeric.
///
/// Anchored to `yyyy-mm-dd` rather than handed straight to `DateTime.tryParse`, which is
/// generous enough to read a bare year out of something that was never a date.
DateTime? _asDate(String value) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value) ? DateTime.tryParse(value) : null;

/// `2026-08-02 · 14:30`, in the device's own local time — and the date alone when that is all
/// the column held.
///
/// The same shape the order timeline draws, and written out for the same reason: one that reads
/// identically in every locale is the honest choice for a workshop log, where the question is
/// "in what order, and how long apart". Latin digits, like every other number this app draws.
String _stamp(DateTime at) {
  final local = at.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');

  final day = '${local.year}-${two(local.month)}-${two(local.day)}';
  final midnight = local.hour == 0 && local.minute == 0 && local.second == 0;

  return midnight ? day : '$day · ${two(local.hour)}:${two(local.minute)}';
}

/// (strong, on-strong) for an event — the dot, and the active chip.
(Color, Color) _toneOf(BuildContext context, AuditEvent? event) {
  final (strong, onStrong, _, _) = _tones(context, event);

  return (strong, onStrong);
}

/// (strong, on-strong, soft, on-soft) for an event.
///
/// Four things happen to a record and each gets its own place in the palette: it appears, it
/// changes, it is taken out of use, or it comes back. Drawn from the scheme rather than from
/// literal colours, so a theme change carries them and dark mode is not a separate decision.
(Color, Color, Color, Color) _tones(BuildContext context, AuditEvent? event) {
  final scheme = context.colorScheme;

  return switch (event) {
    AuditEvent.created => (
      scheme.primary,
      scheme.onPrimary,
      scheme.primaryContainer,
      scheme.onPrimaryContainer,
    ),
    AuditEvent.updated => (
      scheme.secondary,
      scheme.onSecondary,
      scheme.secondaryContainer,
      scheme.onSecondaryContainer,
    ),
    AuditEvent.deleted => (
      scheme.error,
      scheme.onError,
      scheme.errorContainer,
      scheme.onErrorContainer,
    ),
    AuditEvent.restored => (
      scheme.tertiary,
      scheme.onTertiary,
      scheme.tertiaryContainer,
      scheme.onTertiaryContainer,
    ),
    // An event this build has no case for. Neutral rather than borrowed from one of the four:
    // painting an unknown thing in «حذف» red would be a guess with consequences.
    null => (
      scheme.onSurfaceVariant,
      scheme.surface,
      scheme.surfaceContainerHigh,
      scheme.onSurfaceVariant,
    ),
  };
}
