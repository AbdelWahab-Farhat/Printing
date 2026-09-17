import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/access/presentation/viewmodel/users_cubit.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Who this design request is addressed to — or nobody.
///
/// A sheet over the employees, the shape `showAssignShortageSheet` uses: a name is picked from a
/// searchable list rather than a dropdown that would have to hold every employee in the shop.
///
/// **«الطابور المشترك» is an option here, at the top.** It is a queue designers actually work
/// from, not the absence of an answer — which is why the server takes a null as an instruction
/// rather than as «leave it alone», and why this sheet offers it rather than making somebody
/// cancel out of it.
///
/// **Only the staff who can actually accept a ticket are listed**, and the filter is the
/// permission `design_tickets.accept` rather than the role «مصمم». A picker that filtered on the
/// role name would list the wrong people the day the business renames it, splits it in two, or
/// grants the same work to a second role — silently. The permission is what the code checks for,
/// so the list cannot drift from the thing it describes.
///
/// **An administrator is not in the list** unless they hold that permission for real: their
/// access comes from a rule rather than a granted row. That is the right answer for a picker —
/// an administrator who genuinely designs holds the role that says so.
///
/// Answers with a [DesignerChoice] rather than a bare `AuthUser?`, because null is already taken:
/// `showModalBottomSheet` returns null when the sheet is **dismissed**, and «أرجِعها إلى الطابور»
/// is a decision while swiping the sheet away is not.
Future<DesignerChoice?> showAssignDesignerSheet({
  required BuildContext context,
  required int? currentDesignerId,
}) {
  return showModalBottomSheet<DesignerChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider<UsersCubit>(
      create: (_) => sl<UsersCubit>()
        ..permission = AppPermission.acceptDesignTickets.wire
        ..load(),
      child: _AssignSheet(currentDesignerId: currentDesignerId),
    ),
  );
}

/// The sheet's answer: a user id and the name to write beside it, or null meaning the pool.
@immutable
class DesignerChoice {
  const DesignerChoice(this.userId, this.name);

  const DesignerChoice.sharedPool() : userId = null, name = null;

  final int? userId;
  final String? name;
}

class _AssignSheet extends StatelessWidget {
  const _AssignSheet({required this.currentDesignerId});

  final int? currentDesignerId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();
    final text = context.textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إسناد التذكرة', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          SizedBox(height: 12.h),
          SearchField(hint: 'ابحث عن موظف', onChanged: cubit.search),
          SizedBox(height: 8.h),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('الطابور المشترك'),
            subtitle: const Text('يراها كل المصممين، ويأخذها أوّل من يقبلها'),
            trailing: currentDesignerId == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop(const DesignerChoice.sharedPool()),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 360.h,
            child: BlocBuilder<UsersCubit, UsersState>(
              builder: (context, state) => PagedListView<AuthUser>(
                state: state,
                // Said precisely: the list is narrowed, so «لا يوجد موظفون» would be false.
                emptyMessage: 'لا يوجد مصممون — امنح صلاحية «قبول طلب التصميم» لموظف',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 56.h,
                itemBuilder: (context, user, index) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(user.name),
                  trailing: user.id == currentDesignerId ? const Icon(Icons.check) : null,
                  onTap: () =>
                      Navigator.of(context).pop(DesignerChoice(user.id, user.name)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
