import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The basket, in the bar of every screen a product can be added from.
///
/// **It is not in the bottom navigation, and that is deliberate.** The design draws five tabs
/// and the basket is not one of them — nor should it be: a tab is a place you live in, and a
/// basket is a thing you pass through on the way out. It sits where the thing being collected
/// is, which is the catalogue and the product.
///
/// **Nothing when the basket is empty.** A cart icon with no number is an invitation to tap it
/// and find out it was empty; the affordance appears when there is something to see.
///
/// Reads the singleton [CartCubit] directly rather than through a provider: the basket has no
/// scope, and wrapping every screen that draws this in a `BlocProvider.value` would be
/// ceremony around a thing that is already global.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<CartCubit, CartState>(
      bloc: sl<CartCubit>(),
      builder: (context, state) {
        if (state.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsetsDirectional.only(end: 4.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(AppIcons.orders),
                tooltip: 'سلتك',
                onPressed: () => context.push(Routes.newOrder),
              ),
              PositionedDirectional(
                top: 6.h,
                end: 4.w,
                child: _CountBadge(
                  count: state.count,
                  background: scheme.primary,
                  foreground: scheme.onPrimary,
                  // A ring in the bar's own colour, so the badge reads as a badge rather than
                  // as a smudge where it overlaps the glyph.
                  ring: scheme.surface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The basket again, floating above the navigation bar.
///
/// **The same basket, in the one place the bar is.** [CartButton] lives in an `AppBar`, which is
/// where it belongs on a screen pushed over the shell — the product screen has no navigation bar
/// and its bottom edge is already the order bar's, so a floating button there would be a second
/// primary action arguing with «أضف إلى الطلبية». The catalogue is the opposite: it sits *inside*
/// the shell, the bar is drawn under it, and a basket filling up as you scroll is worth more than
/// an icon in a corner you have scrolled past.
///
/// **Nothing when the basket is empty**, exactly as [CartButton] does, and for the same reason.
class CartFab extends StatelessWidget {
  const CartFab({super.key});

  /// Where a `Scaffold` has to put this.
  ///
  /// **`startFloat`, and that is the bottom *right*.** This app is `Locale('ar')` and nothing
  /// else — see `app.dart` — so the whole of it is laid out right to left, and Flutter's floating
  /// button locations follow the text direction: `endFloat` is the trailing edge, which in Arabic
  /// is the **left**. Naming the side the reader sees would mean writing the one that is wrong,
  /// so the constant says `start` and this comment says right.
  static const FloatingActionButtonLocation location =
      FloatingActionButtonLocation.startFloat;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<CartCubit, CartState>(
      bloc: sl<CartCubit>(),
      builder: (context, state) {
        if (state.isEmpty) return const SizedBox.shrink();

        return FloatingActionButton(
          // Every floating button in this app names its own tag — the shell keeps all five tabs
          // mounted at once, so two default tags would be an assertion on every frame. Enforced
          // by `floating_action_button_hero_test.dart` rather than by remembering it.
          heroTag: 'fab-cart',
          tooltip: 'سلتك',
          onPressed: () => context.push(Routes.newOrder),
          child: Stack(
            // The badge sits over the button's own edge; clipped, it would be a half circle.
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(AppIcons.orders),
              PositionedDirectional(
                top: -10.h,
                end: -12.w,
                child: _CountBadge(
                  count: state.count,
                  // Inverted against the bar's badge: the button is already `primary` under the
                  // theme, and a `primary` badge on it would be invisible.
                  background: scheme.onPrimary,
                  foreground: scheme.primary,
                  ring: scheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// How many lines are in the basket — the pill alone, not the thing it sits on.
///
/// Shared by [CartButton] and [CartFab] so the two cannot drift into two different badges; the
/// colours are the caller's because what is behind them differs.
class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.background,
    required this.foreground,
    required this.ring,
  });

  final int count;
  final Color background;
  final Color foreground;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 17.w),
      height: 17.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: ring, width: 1.5.w),
      ),
      child: Text(
        '$count',
        style: context.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
