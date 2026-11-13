import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/notifications/models/push_preference.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/push_preferences_cubit.dart';
import 'package:dayaa/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «إشعارات الهاتف» — which group notifications wake one employee's phone.
/// Docs/notifications/PUSH-PREFERENCES.md.
///
/// **Set by an administrator, from the employee's screen.** The employee does not see this page
/// for themselves; their own «تفعيل الإشعارات» switch on the settings page is a different thing —
/// that one is about this device, this one is about the account on every device.
///
/// **The bell is never switched off**, and the page says so first: a switch that reads like
/// «stop telling them» would make an administrator afraid to touch it.
class PushPreferencesPage extends StatelessWidget {
  const PushPreferencesPage({required this.userId, this.employeeName, super.key});

  final int userId;

  /// Carried from the employee screen for the subtitle. A deep link has none and reads without.
  final String? employeeName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PushPreferencesCubit>(
      create: (_) => sl<PushPreferencesCubit>(param1: userId)..load(),
      child: _PushPreferencesView(employeeName: employeeName),
    );
  }
}

class _PushPreferencesView extends StatelessWidget {
  const _PushPreferencesView({required this.employeeName});

  final String? employeeName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PushPreferencesCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إشعارات الهاتف'),
            if (employeeName case final name?)
              Text(
                name,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: BlocConsumer<PushPreferencesCubit, PushPreferencesState>(
        listener: (context, state) {
          if (state case PushPreferencesLoaded(:final failure?)) {
            context.showFailure(failure);
          }
        },
        builder: (context, state) => switch (state) {
          PushPreferencesLoading() => const Center(child: CircularProgressIndicator()),
          PushPreferencesFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: cubit.load,
          ),
          PushPreferencesLoaded(:final groups) => RefreshIndicator(
            onRefresh: cubit.load,
            child: _Body(groups: groups),
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.groups});

  final List<PushPreferenceGroup> groups;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        const _Note(),
        SizedBox(height: 14.h),
        if (groups.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32.h),
            child: Text(
              'لا تصل هذا الموظف إشعاراتٌ جماعية — كل ما يصله موجَّه إليه باسمه.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final group in groups) ...[_GroupCard(group: group), SizedBox(height: 12.h)],
      ],
    );
  }
}

/// What a switch here does and does not do — read before anybody touches one.
class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.notifications, size: 20.sp, color: scheme.onSecondaryContainer),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'كل الإشعارات تصل إلى الجرس داخل التطبيق دائماً، والإطفاء هنا يمنع تنبيه '
              'الهاتف فقط. وما يُسنَد إلى الموظف باسمه يصل إلى هاتفه دائماً، ولذلك لا يظهر هنا.',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// One notification type: a single switch, or a heading over one switch per status.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final PushPreferenceGroup group;

  void _toggle(BuildContext context, PushSwitch item, bool push) {
    context.read<PushPreferencesCubit>().toggle(type: group.type, scope: item.scope, push: push);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final icon = Icon(NotificationTile.iconFor(group.icon), color: scheme.primary);

    // A Material rather than a decorated box: the switch rows paint their ripple on the nearest
    // Material, and a coloured box between them would hide it.
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: group.isSingle
          ? SwitchListTile.adaptive(
              key: ValueKey('push-${group.type}'),
              secondary: icon,
              title: Text(group.label, style: context.textTheme.titleSmall),
              value: group.switches.single.push,
              onChanged: (push) => _toggle(context, group.switches.single, push),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: icon,
                  title: Text(
                    group.label,
                    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final item in group.switches)
                  SwitchListTile.adaptive(
                    key: ValueKey('push-${group.type}-${item.scope}'),
                    dense: true,
                    contentPadding: EdgeInsetsDirectional.only(start: 56.w, end: 16.w),
                    title: Text(item.label),
                    value: item.push,
                    onChanged: (push) => _toggle(context, item, push),
                  ),
              ],
            ),
    );
  }
}

/// The first read failed and there is nothing to show. Retry, rather than a dead end.
class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 44.sp, color: context.colorScheme.error),
            SizedBox(height: 12.h),
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyLarge),
            SizedBox(height: 16.h),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
