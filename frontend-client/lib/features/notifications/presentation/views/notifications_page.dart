import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «الإشعارات» — the screen, ahead of the thing it will show.
///
/// **Deliberately empty, and honestly so.** There is no notifications endpoint yet; this screen
/// exists so the bell in the bar has somewhere to go and so the shape of the feature is settled
/// before the data arrives. What it must not do is pretend: no placeholder rows, no greyed
/// shimmer suggesting something is loading, no «قريباً» toast that makes the bell feel broken.
/// An empty library reads as empty, which is the truth.
///
/// **What lands here when the backend exists** is a list and a read/unread mark, and this screen
/// becomes the `loaded` branch of a Cubit alongside the empty one already written. The bell gets
/// its count from the same place `BadgeRefresher` already asks — see `CustomerBadge`, which is
/// the pattern a notifications count should follow rather than inventing a second one.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.notifications,
                  size: 48.sp,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(height: 14.h),
                Text(
                  'لا توجد إشعارات',
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleSmall,
                ),
                SizedBox(height: 6.h),
                Text(
                  'سنخبرك هنا بكل جديد في طلبياتك.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
