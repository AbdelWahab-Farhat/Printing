import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/cart_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the floating basket actually lands.
///
/// **A regression test for the one thing nobody can check by reading the code.** This app is
/// `Locale('ar')` and nothing else, so it is laid out right to left — and Flutter's floating
/// button locations follow the text direction. `endFloat`, the name anybody reaches for when
/// they want the right-hand side, is the **trailing** edge, which in Arabic is the left. The
/// constant that puts this button where it was asked to go therefore reads `startFloat`, which
/// looks wrong to every reader and is right. A future tidy-up that "corrects" it would move the
/// button across the screen without a single test going red.
///
/// **Measured rather than eyeballed**, in the same spirit as `badged_tile_layout_test.dart`: the
/// failure would be a layout one, where nothing throws and nothing is red.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// A stand-in for the shell's five-tab bar, so "above the navigation bar" is a thing that can
  /// be measured rather than assumed.
  const navigationBarHeight = 80.0;

  OrderDraftLine line({int productId = 1}) => OrderDraftLine(
    line: NewOrderLine(productId: productId, productVariantId: 1, quantity: '1000'),
    title: 'منتج $productId',
  );

  setUp(() => sl.registerLazySingleton<CartCubit>(CartCubit.new));
  tearDown(() => sl.reset());

  /// The catalogue's shape: a branch of the shell, with the bar drawn beneath it.
  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SizedBox.expand(),
        bottomNavigationBar: SizedBox(height: navigationBarHeight),
        floatingActionButton: CartFab(),
        floatingActionButtonLocation: CartFab.location,
      ),
    ),
  );

  testWidgets('an empty basket floats nothing', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — a cart with no number is an invitation to tap it and find out it was empty.
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('it floats on the right, which in Arabic is the leading edge', (tester) async {
    // Arrange
    sl<CartCubit>().add(line());

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    final button = tester.getRect(find.byType(FloatingActionButton));
    final screen = tester.getRect(find.byType(Scaffold));

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(
      button.center.dx,
      greaterThan(screen.center.dx),
      reason: 'the basket belongs on the right; endFloat would have put it on the left',
    );
  });

  testWidgets('it floats above the navigation bar, not over it', (tester) async {
    // Arrange
    sl<CartCubit>().add(line());

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the bar is the bottom `navigationBarHeight` of the screen, and the button clears it.
    final button = tester.getRect(find.byType(FloatingActionButton));
    final screen = tester.getRect(find.byType(Scaffold));

    expect(button.bottom, lessThanOrEqualTo(screen.bottom - navigationBarHeight));
  });

  testWidgets('the count is drawn on it', (tester) async {
    // Arrange — two distinct products, so the number is not the «1» a bug would also produce.
    sl<CartCubit>()
      ..add(line())
      ..add(line(productId: 2));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('2'), findsOneWidget);
  });
}
