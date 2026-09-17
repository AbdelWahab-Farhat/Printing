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
                child: Container(
                  constraints: BoxConstraints(minWidth: 17.w),
                  height: 17.w,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(999.r),
                    // A ring in the bar's own colour, so the badge reads as a badge rather than
                    // as a smudge where it overlaps the glyph.
                    border: Border.all(color: scheme.surface, width: 1.5.w),
                  ),
                  child: Text(
                    '${state.count}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
