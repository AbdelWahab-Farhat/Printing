import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/access/presentation/viewmodel/users_cubit.dart';
import 'package:printing/features/access/presentation/widgets/assign_roles_sheet.dart';
import 'package:printing/features/access/presentation/widgets/employee_row_card.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// الموظفون — who works here and what each of them may do.
///
/// Three different answers to "who may?", and deliberately not the same one:
///
///   * **reading the list** needs `users.view`, or the route sends you away,
///   * **changing somebody's roles** needs `users.manage`, and without it the rows report
///     instead of opening,
///   * **registering a colleague** is the **administrator's alone**, so the button is drawn for
///     nobody else — see `Session.isAdmin` for why that one is a role and not a permission.
///
/// Editing an existing account — its name, its number, turning it off — is still absent, and
/// that is not an oversight: the API has no endpoint for it, and a button with nothing behind it
/// is a promise the screen cannot keep.
class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UsersCubit>(
      create: (_) => sl<UsersCubit>()..load(),
      child: const _EmployeesView(),
    );
  }
}

class _EmployeesView extends StatelessWidget {
  const _EmployeesView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();
    final session = sl<Session>();
    final canManage = session.can(AppPermission.manageUsers);

    return Scaffold(
      // A ternary rather than a gate widget, and deliberately: a `SizedBox.shrink()` in the FAB
      // slot still occupies it and shifts the Scaffold's bottom inset. And it is a courtesy —
      // `can:users.create` on the route is what actually refuses.
      floatingActionButton: session.isAdmin
          ? FloatingActionButton.extended(
              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
              heroTag: 'fab-employees',
              onPressed: () async {
                final created = await context.push(Routes.addEmployee);

                // Only when an account was actually created: a form the user backed out of has
                // changed nothing, and refreshing anyway would scroll a long list to the top.
                if (created != null) await cubit.refresh();
              },
              icon: Icon(AppIcons.addEmployee),
              label: const Text('موظف جديد'),
            )
          : null,
      appBar: AppBar(
        title: const Text('الموظفون'),
        actions: [
          // The roles screen is the other half of this one, and the person who assigns a role is
          // the person who wonders what is in it. Gated separately: `users.manage` and
          // `roles.manage` are different jobs.
          if (sl<Session>().can(AppPermission.manageRoles))
            IconButton(
              onPressed: () async {
                await context.push(Routes.roles);
                // Roles may have been renamed or deleted while over there, and every chip on
                // this list names one.
                await cubit.refresh();
              },
              icon: Icon(AppIcons.roles),
              tooltip: 'الأدوار والصلاحيات',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(
              hint: 'ابحث بالاسم أو الهاتف أو البريد',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<UsersCubit, UsersState>(
              builder: (context, state) => PagedListView<AuthUser>(
                state: state,
                emptyMessage: 'لا يوجد موظفون',
                // Two lines plus a row of role chips, measured.
                skeletonHeight: 104.h,
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                itemBuilder: (context, user, index) => EmployeeRowCard(
                  key: ValueKey(user.id),
                  user: user,
                  onTap: canManage
                      ? () async {
                          final updated = await showAssignRolesSheet(
                            context: context,
                            user: user,
                          );

                          // Only when something was actually saved: a dismissed sheet has
                          // changed nothing, and refreshing anyway would scroll a long list
                          // back to the top for no reason.
                          if (updated != null) await cubit.refresh();
                        }
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
