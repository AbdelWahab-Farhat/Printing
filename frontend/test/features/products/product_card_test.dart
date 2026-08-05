import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/widgets/product_card.dart';
import 'package:printing/features/products/presentation/widgets/product_category_badge.dart';

/// What one product row tells somebody quoting a customer over the phone.
///
/// The card never animates, so nothing here needs `pumpAndSettle` — and nothing here may
/// introduce a reason for it.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget card) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(child: card),
          ),
        ),
      ),
    );
  }

  ProductVariant variant(
    String label,
    List<(String, String)> tiers, {
    bool isActive = true,
    int? widthCm,
    int? heightCm,
  }) {
    return ProductVariant(
      id: label.hashCode,
      label: label,
      isActive: isActive,
      widthCm: widthCm,
      heightCm: heightCm,
      priceTiers: [
        for (final (minQuantity, unitPrice) in tiers)
          ProductPriceTier(
            id: '$label$minQuantity'.hashCode,
            minQuantity: minQuantity,
            unitPrice: unitPrice,
          ),
      ],
    );
  }

  Product product({
    String code = 'P1',
    String name = 'أكياس الشحن',
    String category = 'printed',
    String categoryLabel = 'مطبوعة',
    String pricingUnitLabel = 'قطعة',
    String minOrderQuantity = '100.000',
    bool hasListedPrices = true,
    bool isActive = true,
    List<String> features = const [],
    List<ProductVariant> variants = const [],
  }) {
    return Product(
      id: 1,
      code: code,
      slug: 'shipping-bag',
      name: name,
      features: features,
      category: category,
      categoryLabel: categoryLabel,
      pricingUnit: 'piece',
      pricingUnitLabel: pricingUnitLabel,
      pricingMode: 'tiered',
      pricingModeLabel: 'حسب الكمية',
      hasListedPrices: hasListedPrices,
      minOrderQuantity: minOrderQuantity,
      isActive: isActive,
      variants: variants,
    );
  }

  /// أكياس الشحن exactly as the catalogue has it: four sizes, three breaks each.
  Product shippingBag() => product(
    features: const ['مقاومة للماء والتمزق', 'لاصق قوي واحترافي'],
    variants: [
      variant('25*35', const [('1.000', '1.10'), ('300.000', '0.95'), ('1000.000', '0.85')],
          widthCm: 25, heightCm: 35),
      variant('35*40', const [('1.000', '1.20'), ('300.000', '1.05'), ('1000.000', '0.95')]),
      variant('45*50', const [('1.000', '1.65'), ('300.000', '1.55'), ('1000.000', '1.40')]),
      variant('50*60', const [('1.000', '1.99'), ('300.000', '1.90'), ('1000.000', '1.80')]),
    ],
  );

  group('the price grid', () {
    testWidgets('every price of every size is on the card, with no tap', (tester) async {
      // Arrange
      await tester.pumpWidget(host(ProductCard(product: shippingBag())));

      // Act
      await tester.pump();

      // Assert — all twelve, because that is the whole point of the redesign.
      for (final price in const [
        '1.10', '0.95', '0.85', //
        '1.20', '1.05', '0.95', //
        '1.65', '1.55', '1.40', //
        '1.99', '1.90', '1.80', //
      ]) {
        expect(find.text(price), findsWidgets, reason: '$price is missing from the card');
      }

      // And every size names itself.
      for (final size in const ['25*35', '35*40', '45*50', '50*60']) {
        expect(find.text(size), findsOneWidget);
      }
    });

    testWidgets('a threshold is named once, not once per size', (tester) async {
      // Arrange
      await tester.pumpWidget(host(ProductCard(product: shippingBag())));

      // Act
      await tester.pump();

      // Assert — four size rows share one header, which is what makes the card readable.
      expect(find.text('300+'), findsOneWidget);
      expect(find.text('1000+'), findsOneWidget);
    });

    testWidgets('the entry column is headed by the minimum order, not the tier floor', (
      tester,
    ) async {
      // Arrange — the catalogue's first tier starts at 1, but the shop will not sell under 100.
      await tester.pumpWidget(host(ProductCard(product: shippingBag())));

      // Act
      await tester.pump();

      // Assert
      expect(find.text('100+'), findsOneWidget);
      expect(find.text('1+'), findsNothing);
    });

    testWidgets('the currency and the unit are said once, in the corner', (tester) async {
      // Arrange
      await tester.pumpWidget(host(ProductCard(product: shippingBag())));

      // Act
      await tester.pump();

      // Assert — twelve cells carry bare numbers because this line carries their unit.
      expect(find.text('د.ل / قطعة'), findsOneWidget);
    });

    testWidgets('a size missing a break shows a gap, never a neighbour\'s price', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          ProductCard(
            product: product(
              variants: [
                variant('25*35', const [
                  ('1.000', '1.10'),
                  ('300.000', '0.95'),
                  ('1000.000', '0.85'),
                ]),
                // No 1000 break of its own.
                variant('35*40', const [('1.000', '1.20'), ('300.000', '1.05')]),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert — a wrong number under a heading is how a quote goes out wrong; a dash is not.
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('the columns are the union across sizes, not the first size\'s', (tester) async {
      // Arrange — the first variant is the one that lacks the deepest break.
      await tester.pumpWidget(
        host(
          ProductCard(
            product: product(
              variants: [
                variant('25*35', const [('1.000', '1.10')]),
                variant('35*40', const [('1.000', '1.20'), ('1000.000', '0.95')]),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert — trusting `variants.first` would have hidden this column entirely.
      expect(find.text('1000+'), findsOneWidget);
      expect(find.text('0.95'), findsOneWidget);
    });
  });

  group('the shapes that are not a grid', () {
    testWidgets('a quote-on-request product shows no number at all', (tester) async {
      // Arrange — أكياس ورقية 3D: one variant, no tiers.
      await tester.pumpWidget(
        host(
          ProductCard(
            product: product(
              name: 'أكياس ورقية 3D (مقواة)',
              hasListedPrices: false,
              minOrderQuantity: '200.000',
              variants: [variant('حسب الطلب', const [])],
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('السعر حسب الطلب'), findsOneWidget);
      expect(find.text('أقل كمية 200 قطعة'), findsOneWidget);
      expect(find.text('د.ل / قطعة'), findsNothing);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('a per-kilo product with one price gets no invented breaks', (tester) async {
      // Arrange — أكياس الشحن السادة.
      await tester.pumpWidget(
        host(
          ProductCard(
            product: product(
              name: 'أكياس الشحن السادة',
              category: 'general',
              categoryLabel: 'سادة',
              pricingUnitLabel: 'كيلوغرام',
              minOrderQuantity: '1.000',
              variants: [variant('سادة', const [('1.000', '32.000')])],
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert — absence of a discount is shown as absence.
      expect(find.text('32.000'), findsOneWidget);
      expect(find.text('300+'), findsNothing);
      expect(find.text('1000+'), findsNothing);
      expect(find.text('أقل كمية 1 كيلوغرام'), findsOneWidget);
      // The variant label only repeats the product name, so it is not printed. The one «سادة»
      // on the card is the category badge — check it is the badge and not the size row.
      expect(
        find.descendant(
          of: find.byType(ProductCategoryBadge),
          matching: find.text('سادة'),
        ),
        findsOneWidget,
      );
      expect(find.text('سادة'), findsOneWidget);
    });
  });

  group('identity', () {
    testWidgets('the category is a badge and the unit is what is left of the sentence', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(host(ProductCard(product: shippingBag())));

      // Act
      await tester.pump();

      // Assert — the category is the first question a customer asks, so it is a thing to look
      // at rather than the first half of a subtitle. What it leaves behind is the billing unit.
      expect(find.text('مطبوعة'), findsOneWidget);
      expect(find.text('بالقطعة'), findsOneWidget);
      expect(find.text('مطبوعة · بالقطعة'), findsNothing);
    });

    testWidgets('the badge sits at the far top edge of the card', (tester) async {
      // Arrange
      await tester.pumpWidget(host(ProductCard(product: shippingBag())));

      // Act
      await tester.pump();
      final badge = tester.getRect(find.byType(ProductCategoryBadge));
      final code = tester.getRect(find.text('P1'));
      final prices = tester.getRect(find.text('0.85'));

      // Assert — the screen is right-to-left, so the far edge is the left one; and it belongs to
      // the name line, above every number.
      expect(badge.left, lessThan(code.left));
      expect(badge.center.dy, lessThan(prices.top));
    });

    testWidgets('printed and plain are told apart by glyph, not only by word', (tester) async {
      // Arrange
      Future<IconData> glyphOf(String category) async {
        await tester.pumpWidget(
          host(
            ProductCard(
              product: product(
                category: category,
                variants: [
                  variant('25*35', const [('1.000', '1.10')]),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        return tester
            .widget<Icon>(
              find.descendant(
                of: find.byType(ProductCategoryBadge),
                matching: find.byType(Icon),
              ),
            )
            .icon!;
      }

      // Act
      final printed = await glyphOf('printed');
      final plain = await glyphOf('general');

      // Assert — a badge that carries the same icon either way is a colour swatch with a word
      // on it, and the word was already there.
      expect(printed, isNot(plain));
    });

    testWidgets('a category this build has never heard of still shows its label', (tester) async {
      // Arrange — the server may add a third category; its Arabic arrived with it.
      await tester.pumpWidget(
        host(
          ProductCard(
            product: product(
              category: 'laminated',
              categoryLabel: 'مغلّفة',
              variants: [
                variant('25*35', const [('1.000', '1.10')]),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert — no invented translation, and no card lost to an unknown value.
      expect(find.text('مغلّفة'), findsOneWidget);
    });

    testWidgets('the code leads the name line, where the eye lands first', (tester) async {
      // Arrange
      await tester.pumpWidget(host(ProductCard(product: shippingBag())));

      // Act
      await tester.pump();
      final code = tester.getRect(find.text('P1'));
      final name = tester.getRect(find.text('أكياس الشحن'));

      // Assert — the screen is right-to-left, so "first" is the right edge. Comparing the two
      // rectangles is what makes this a placement test and not just a "does it render" one.
      expect(code.right, greaterThan(name.right));
      expect(code.center.dy, moreOrLessEquals(name.center.dy, epsilon: 2));
    });

    testWidgets('a long name yields to the code rather than pushing it off', (tester) async {
      // Arrange — the name has to give way, because a truncated code is a wrong code.
      await tester.pumpWidget(
        host(
          ProductCard(
            product: product(
              code: 'P12',
              name: 'أكياس ورقية عادية بمقاسات كبيرة للمحلات والصيدليات والمخابز',
              variants: [
                variant('25*35', const [('1.000', '1.10'), ('300.000', '0.95')]),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('P12'), findsOneWidget);
      expect(tester.getSize(find.text('P12')).width, greaterThan(0));
    });

    testWidgets('a stopped product says so beside its name', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(ProductCard(product: product(isActive: false, variants: [
          variant('25*35', const [('1.000', '1.10')]),
        ]))),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('· موقوف'), findsOneWidget);
    });

    testWidgets('a running product says nothing about being running', (tester) async {
      // Arrange
      await tester.pumpWidget(host(ProductCard(product: shippingBag())));

      // Act
      await tester.pump();

      // Assert — a badge on every row is a badge nobody reads.
      expect(find.text('· موقوف'), findsNothing);
    });

    testWidgets('the selling points are deliberately not on the card', (tester) async {
      // Arrange — the product carries two of them.
      await tester.pumpWidget(host(ProductCard(product: shippingBag())));

      // Act
      await tester.pump();

      // Assert — a selling point is what a salesperson says *after* the number; on a row whose
      // job is the number it is a line the eye skips on every card. They stay on the model.
      expect(find.textContaining('مقاومة للماء'), findsNothing);
      expect(find.textContaining('لاصق قوي'), findsNothing);
    });

    testWidgets('a tap reaches the caller', (tester) async {
      // Arrange
      var taps = 0;
      await tester.pumpWidget(
        host(ProductCard(product: shippingBag(), onTap: () => taps++)),
      );

      // Act
      await tester.tap(find.byType(ProductCard));
      await tester.pump();

      // Assert
      expect(taps, 1);
    });
  });
}
