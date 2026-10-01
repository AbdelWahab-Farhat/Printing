import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/access/presentation/viewmodel/users_cubit.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Who a salary advance was handed to — the staff list the shortage assignment sheet already
/// searches, answering the person picked or null for a dismissal.
Future<AuthUser?> showEmployeePicker({
  required BuildContext context,
  String title = 'اختيار الموظف',
}) {
  return showModalBottomSheet<AuthUser>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider<UsersCubit>(
      create: (_) => sl<UsersCubit>()..load(),
      child: _EmployeePicker(title: title),
    ),
  );
}

class _EmployeePicker extends StatelessWidget {
  const _EmployeePicker({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: SearchField(hint: 'ابحث عن موظف', onChanged: cubit.search),
          ),
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
                  onTap: () => Navigator.of(context).pop(user),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
