import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/svg_icon.dart';
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
  const CartButton({super.key, this.backdrop});

  /// مربّعٌ ملوّن خلف الأيقونة، لبارٍ يمرّ فوق صورة — صفحة المنتج — حيث أيقونةٌ عارية تضيع في
  /// الصورة. بدونه يُرسم الزر كما يُرسم في أي `AppBar`.
  final Color? backdrop;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<CartCubit, CartState>(
      bloc: sl<CartCubit>(),
      builder: (context, state) {
        if (state.isEmpty) return const SizedBox.shrink();

        final backdrop = this.backdrop;

        return Padding(
          padding: backdrop == null ? EdgeInsetsDirectional.only(end: 4.w) : EdgeInsets.zero,
          child: IconButton(
            icon: Stack(
              // الشارة تتدلّى خارج حدود الرسم، فلا يُقصّ ما تجاوزها.
              clipBehavior: Clip.none,
              children: [
                const SvgIcon(SvgIcon.cart),
                // **معلّقةٌ على الرسم نفسه لا على زاوية الزرّ**، كما يعلّق `BadgedIcon` شارة الدعم،
                // فتقع على كتف السلّة في الشريط وفوق صورة المنتج معاً. و`right` لا `start`: الرسم
                // لا ينقلب مع اتجاه النص — مقبضه يساراً كما في المثال — فالشارة تتبعه هو.
                Positioned(
                  top: -6.h,
                  right: -8.w,
                  child: _CountBadge(
                    count: state.count,
                    // أحمر كشارة الدعم وكالمثال الذي أرسله المستخدم، لا برتقالي العلامة.
                    background: scheme.error,
                    foreground: scheme.onError,
                    // حلقةٌ بلون الشريط، لتُقرأ الشارةُ شارةً لا لطخةً حيث تغطّي الرسم.
                    ring: scheme.surface,
                  ),
                ),
              ],
            ),
            tooltip: 'سلتك',
            style: backdrop == null
                ? null
                : IconButton.styleFrom(
                    backgroundColor: backdrop,
                    fixedSize: Size.square(44.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
            onPressed: () => context.push(Routes.newOrder),
          ),
        );
      },
    );
  }
}

/// عدد سطور السلة: الحبّة وحدها، لا ما تجلس عليه.
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
