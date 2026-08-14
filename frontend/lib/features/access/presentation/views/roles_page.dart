import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/appear.dart';
import 'package:dayaa/features/access/presentation/viewmodel/roles_cubit.dart';
import 'package:dayaa/features/access/presentation/widgets/role_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// الأدوار — the jobs this business has, and what each one may do.
///
/// **Not paginated, and that is not an omission.** `GET /roles` answers a bare list because the
/// whole point of a role is that there are a handful of them. A scroll listener and a page
/// counter to page through five rows would be machinery around a problem nobody has.
///
/// Tapping one opens it. Creating, editing and deleting all need `roles.manage`, which is also
/// what this whole screen needs — so there is nothing here to gate a second time.
class RolesPage extends StatelessWidget {
  const RolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RolesCubit>(
      create: (_) => sl<RolesCubit>()..load(),
      child: const _RolesView(),
    );
  }
}

class _RolesView extends StatelessWidget {
  const _RolesView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RolesCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('الأدوار والصلاحيات')),
      floatingActionButton: FloatingActionButton.extended(
                              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
                              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
                              heroTag: 'fab-roles',
        onPressed: () async {
          // Whatever the form returns, the list is stale: a created role is not on it, and the
          // form is also where an existing one gets renamed.
          await context.push(Routes.newRole);
          await cubit.refresh();
        },
        icon: Icon(AppIcons.add),
        label: const Text('دور جديد'),
      ),
      body: BlocBuilder<RolesCubit, RolesState>(
        builder: (context, state) => switch (state) {
          RolesLoading() => const Center(child: CircularProgressIndicator()),
          RolesFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: cubit.refresh,
          ),
          RolesLoaded(:final roles) => roles.isEmpty
              ? const _EmptyView()
              : RefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 96.h),
                    itemCount: roles.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) => Appear(
                      index: index,
                      child: RoleCard(
                        key: ValueKey(roles[index].id),
                        role: roles[index],
                        onTap: () async {
                          await context.push(Routes.role(roles[index].id));
                          // The role screen can rename, re-permission or delete — a list still
                          // showing the old row is a list nobody trusts.
                          await cubit.refresh();
                        },
                      ),
                    ),
                  ),
                ),
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.roles, size: 52.sp, color: context.colorScheme.outline),
            SizedBox(height: 14.h),
            Text(
              'لا توجد أدوار بعد',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              'الدور حزمة صلاحيات باسم. أنشئ واحداً، ثم امنحه لمن يقوم بذلك العمل.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: context.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              // The server's own Arabic: it usually says what to do about it.
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
