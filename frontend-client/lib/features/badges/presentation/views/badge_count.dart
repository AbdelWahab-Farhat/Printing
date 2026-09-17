import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The number on a tile, or nothing at all.
///
/// **Draws nothing at zero**, which is why callers can wrap anything in it without asking first:
/// a badge is the presence of something waiting, and «٠» is an empty answer taking up the space
/// of a real one.
///
/// Placed by [BadgedTile] rather than by each caller, so every badge in the app sits in the same
/// corner at the same size — the same reason `AppTextField` owns its own decoration.
class BadgeCount extends StatelessWidget {
  const BadgeCount({required this.badge, super.key});

  final CustomerBadge badge;

  /// Above nine hundred and ninety-nine nobody reads the digits, and the pill stops fitting.
  static String _label(int count) => count > 99 ? '+٩٩' : '$count';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BadgesCubit, Map<CustomerBadge, int>>(
      // Rebuilt only when *this* badge moves. Another badge changing must not repaint a tile
      // that did not change — and once there are several, it would repaint all of them.
      buildWhen: (previous, current) =>
          previous.countOf(badge) != current.countOf(badge),
      builder: (context, counts) {
        final count = counts.countOf(badge);

        if (count == 0) return const SizedBox.shrink();

        final scheme = context.colorScheme;

        return Container(
          constraints: BoxConstraints(minWidth: 20.w),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: scheme.error,
            borderRadius: BorderRadius.circular(999.r),
            // A ring in the surface colour, so the pill reads as sitting *on* the tile rather
            // than being part of it wherever the two colours are close.
            border: Border.all(color: scheme.surface, width: 1.5),
          ),
          child: Text(
            _label(count),
            textAlign: TextAlign.center,
            style: context.textTheme.labelSmall?.copyWith(
              color: scheme.onError,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        );
      },
    );
  }
}

/// Anything, with its badge hung on the corner the eye lands on.
///
/// **Top-start**, which in this right-to-left app is the top *left*. The tiles put their label
/// bottom-centre and their icon in the middle, so the opposite corner is the one piece of a tile
/// nothing else is using.
class BadgedTile extends StatelessWidget {
  const BadgedTile({required this.badge, required this.child, super.key});

  final CustomerBadge badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // The pill overhangs the tile's rounded corner slightly, so `clipBehavior` has to let it.
      clipBehavior: Clip.none,

      // **`passthrough`, and the default cost a visibly wrong screen.**
      //
      // A `Stack` hands its non-positioned children *loose* constraints by default. The tiles
      // this wraps carry no width of their own — they fill whatever they are given — so under
      // `StackFit.loose` the badged one collapsed to the width of its own icon and label while
      // its unbadged neighbours kept filling their third of the row. A decorator that changes
      // the size of what it decorates is not a decorator.
      //
      // `passthrough` forwards the parent's constraints untouched, so the child is laid out
      // exactly as it would be with nothing wrapped around it at all.
      fit: StackFit.passthrough,
      children: [
        child,
        PositionedDirectional(
          top: -4.h,
          start: -4.w,
          child: BadgeCount(badge: badge),
        ),
      ],
    );
  }
}
