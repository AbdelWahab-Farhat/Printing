import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/access/presentation/viewmodel/users_cubit.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Who is chasing this shortage — or nobody.
///
/// A sheet over the employees, the same shape `showWarehousePicker` uses: a name is picked from a
/// searchable list, not from a dropdown that would have to hold every employee in the shop.
///
/// **«غير مُسنَد» is an option here, at the top.** It is a queue a supervisor actually works
/// from, not the absence of an answer — which is why the server takes a null as an instruction
/// rather than as «leave it alone», and why this sheet offers it rather than making somebody
/// cancel out of it.
///
/// Answers with an [AssignChoice] rather than a bare `AuthUser?`, because null is already taken:
/// `showModalBottomSheet` returns null when the sheet is **dismissed**, and «خُذها من صاحبها» is
/// a decision while swiping the sheet away is not.
Future<AssignChoice?> showAssignShortageSheet({
  required BuildContext context,
  required int? currentUserId,
}) {
  return showModalBottomSheet<AssignChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider<UsersCubit>(
      create: (_) => sl<UsersCubit>()..load(),
      child: _AssignSheet(currentUserId: currentUserId),
    ),
  );
}

/// The sheet's answer: a user id and the name to write beside it, or null meaning «غير مُسنَد».
///
/// The name travels with the id because the screen that opened the sheet has to *print* it — on
/// the form, before anything is saved, there is no payload to read an assignee off.
@immutable
class AssignChoice {
  const AssignChoice(this.userId, this.name);

  const AssignChoice.unassigned() : userId = null, name = null;

  final int? userId;
  final String? name;
}

class _AssignSheet extends StatelessWidget {
  const _AssignSheet({required this.currentUserId});

  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();
    final scheme = context.colorScheme;

    return SafeArea(
      key: const Key('assign_shortage_sheet'),
      // The drag handle above already clears the top.
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
            child: Text(
              'إسناد النقص',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: SearchField(hint: 'ابحث عن موظف', onChanged: cubit.search),
          ),
          // First, and always — taking a shortage back into the unassigned queue is as ordinary
          // an act as handing it to somebody.
          ListTile(
            leading: Icon(Icons.person_off_outlined, color: scheme.onSurfaceVariant),
            title: const Text('غير مُسنَد'),
            selected: currentUserId == null,
            onTap: () => Navigator.of(context).pop(const AssignChoice.unassigned()),
          ),
          const Divider(height: 1),
          Flexible(
            child: BlocBuilder<UsersCubit, UsersState>(
              builder: (context, state) => PagedListView<AuthUser>(
                state: state,
                emptyMessage: 'لا يوجد موظفون',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 64.h,
                itemBuilder: (context, user, index) => ListTile(
                  title: Text(user.name),
                  subtitle: user.phone.isEmpty ? null : Text(user.phone),
                  selected: user.id == currentUserId,
                  onTap: () => Navigator.of(context).pop(AssignChoice(user.id, user.name)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
