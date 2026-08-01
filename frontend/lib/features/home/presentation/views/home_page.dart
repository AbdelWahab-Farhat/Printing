import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/home/presentation/viewmodel/home_cubit.dart';
import 'package:printing/features/home/presentation/widgets/employee_card.dart';
import 'package:printing/features/home/presentation/widgets/quick_actions.dart';
import 'package:printing/features/home/presentation/widgets/status_board.dart';
import 'package:printing/features/home/presentation/widgets/summary_tiles.dart';

/// The first screen of the signed-in app.
///
/// There is no `Scaffold` here and no app bar: this is a *body*. The frame around it — the bar,
/// the tabs, the drawer — belongs to the shell in `RootPage`, which is why switching tabs does
/// not rebuild it.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      // Screen-scoped and closed with the screen; `..load()` so the first frame is already
      // asking rather than waiting for someone to pull down.
      create: (_) => sl<HomeCubit>()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => switch (state) {
        HomeInitial() || HomeLoading() => const _HomeSkeleton(),
        HomeFailure(:final failure) => _FailureView(
          message: failure.message,
          onRetry: context.read<HomeCubit>().load,
        ),
        HomeLoaded(:final user, :final summary) => RefreshIndicator(
          onRefresh: context.read<HomeCubit>().refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: [
              EmployeeCard(user: user),
              SizedBox(height: 20.h),
              QuickActions(actions: _actionsFor(context)),
              SizedBox(height: 20.h),
              SummaryTiles(summary: summary),
              SizedBox(height: 24.h),
              StatusBoard(statuses: summary.statuses),
            ],
          ),
        ),
      },
    );
  }

  /// Both shortcuts push over the shell rather than switching tabs.
  ///
  /// إضافة عميل opens the form itself, not the العملاء tab: a shortcut that lands on a list the
  /// user then has to find an "add" button on has not saved them anything — it has just moved
  /// the tap. The tab is still there for browsing customers, which is a different errand.
  List<QuickAction> _actionsFor(BuildContext context) {
    return [
      QuickAction(
        label: 'إضافة عميل',
        icon: AppIcons.addCustomer,
        onTap: () => context.push(Routes.addCustomer),
      ),
      QuickAction(
        label: 'المخزن',
        icon: AppIcons.warehouse,
        onTap: () => context.push(Routes.warehouse),
      ),
    ];
  }
}

/// The shape of the page, drawn before its contents arrive.
///
/// A skeleton rather than a spinner: the layout does not jump when the data lands, and the wait
/// is spent looking at where the numbers will be rather than at a circle.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        _SkeletonBox(height: 108.h, radius: 24.r),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 76.h, radius: 20.r)),
            SizedBox(width: 12.w),
            Expanded(child: _SkeletonBox(height: 76.h, radius: 20.r)),
          ],
        ),
        SizedBox(height: 20.h),
        for (var row = 0; row < 2; row++) ...[
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 96.h, radius: 20.r)),
              SizedBox(width: 12.w),
              Expanded(child: _SkeletonBox(height: 96.h, radius: 20.r)),
            ],
          ),
          SizedBox(height: 12.h),
        ],
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              // The server's own Arabic, not a generic apology: it usually says what to do.
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tab whose screen has not been built yet.
///
/// Shipped on purpose: an empty tab that says so is honest, and the alternative — hiding the
/// destination until its screen exists — hides the shape of the app from the people testing it.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56.sp, color: context.colorScheme.outline),
          SizedBox(height: 16.h),
          Text(
            title,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'قريباً',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
