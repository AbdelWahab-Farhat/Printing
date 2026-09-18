import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The bell, in the bar of every signed-in screen.
///
/// **It is always drawn, unlike `CartButton`.** A basket with nothing in it is worth hiding —
/// the affordance appears when there is something to see. A bell is the opposite: it is the way
/// *in* to a screen the customer may want to check precisely when it is empty, and one that came
/// and went would be a control nobody could find on purpose.
///
/// **No badge yet, and that is not an oversight.** There is no notifications endpoint; a dot
/// drawn now would either be permanently absent — teaching people to ignore it — or fabricated.
/// When the count lands it comes from where `CustomerBadge` already comes from, and the badge
/// belongs here beside the icon exactly as the basket's does.
///
/// **Last in `actions`, which in Arabic is the far left.** An `AppBar` lays its actions out from
/// the trailing edge inward, and this app is right-to-left throughout — so the last entry is the
/// one nearest the screen's left edge. See `notifications_button_layout_test.dart`, which
/// measures it rather than trusting the sentence.
class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 4.w),
      child: IconButton(
        icon: Icon(AppIcons.notifications),
        tooltip: 'الإشعارات',
        // `push`, never `go`: the bell is opened from wherever you are and closed back to it.
        // `go` would replace the stack and leave the screen with nothing to go back to.
        onPressed: () => context.push(Routes.notifications),
      ),
    );
  }
}
