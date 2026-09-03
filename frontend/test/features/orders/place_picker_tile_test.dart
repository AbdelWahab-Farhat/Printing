import 'package:dayaa/features/orders/presentation/widgets/place_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The city and the region on the edit screen: one address, one row.
///
/// They were two full-width buttons stacked — 54 pixels each plus a gap, for a fact that reads
/// as «زليتن، وسط المدينة» — so the geometry is what these tests are about.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget child, {double width = 430}) {
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
            child: Center(child: SizedBox(width: width, child: child)),
          ),
        ),
      ),
    );
  }

  /// The pair exactly as the edit screen builds it.
  Widget pair({
    String city = 'زليتن',
    String? region,
    VoidCallback? onCity,
    VoidCallback? onRegion,
  }) {
    return Row(
      children: [
        Expanded(
          child: PlacePickerTile(
            caption: 'المدينة',
            value: city,
            isChosen: true,
            onTap: onCity ?? () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PlacePickerTile(
            caption: 'المنطقة',
            value: region ?? 'اختياري',
            isChosen: region != null,
            onTap: onRegion ?? () {},
          ),
        ),
      ],
    );
  }

  testWidgets('the two sit on one line, city first in reading order', (tester) async {
    // Arrange
    await tester.pumpWidget(host(pair(region: 'وسط المدينة')));

    // Act
    await tester.pump();
    final cityTile = tester.getRect(find.ancestor(
      of: find.text('زليتن'),
      matching: find.byType(PlacePickerTile),
    ));
    final regionTile = tester.getRect(find.ancestor(
      of: find.text('وسط المدينة'),
      matching: find.byType(PlacePickerTile),
    ));

    // Assert — same band, and the city is on the right because the screen is right-to-left.
    expect(cityTile.center.dy, moreOrLessEquals(regionTile.center.dy, epsilon: 1));
    expect(cityTile.right, greaterThan(regionTile.right));
  });

  testWidgets('the pair is shorter than the two stacked buttons it replaced', (tester) async {
    // Arrange — 54 each plus an 8 gap was 116; the whole point of the change was the height.
    await tester.pumpWidget(host(pair(region: 'وسط المدينة')));

    // Act
    await tester.pump();
    final height = tester.getSize(find.byType(PlacePickerTile).first).height;

    // Assert
    expect(height, lessThan(60));
  });

  testWidgets('an unpicked region invites rather than reads as empty', (tester) async {
    // Arrange
    await tester.pumpWidget(host(pair()));

    // Act
    await tester.pump();

    // Assert — «بلا منطقة» would read as a decision somebody made.
    expect(find.text('اختياري'), findsOneWidget);
    expect(find.text('المنطقة'), findsOneWidget);
  });

  testWidgets('each half opens its own picker', (tester) async {
    // Arrange
    var cityTaps = 0;
    var regionTaps = 0;
    await tester.pumpWidget(
      host(pair(onCity: () => cityTaps++, onRegion: () => regionTaps++)),
    );

    // Act
    await tester.tap(find.text('زليتن'));
    await tester.tap(find.text('اختياري'));
    await tester.pump();

    // Assert
    expect(cityTaps, 1);
    expect(regionTaps, 1);
  });

  testWidgets('a long name is cut with a mark, not with a different place', (tester) async {
    // Arrange — «إستلام مكتب(قرجي)» does not fit half a row at this width.
    await tester.pumpWidget(host(pair(city: 'إستلام مكتب(قرجي)'), width: 320));

    // Act
    await tester.pump();
    final text = tester.widget<Text>(find.text('إستلام مكتب(قرجي)'));

    // Assert
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('a figure at the far end wears the primary colour', (tester) async {
    // Arrange — the delivery price, inside the box of the city it comes from, rather than on a
    // line of prose under the pair that has to say where it came from.
    await tester.pumpWidget(
      host(
        PlacePickerTile(
          caption: 'المدينة',
          value: 'طرابلس',
          isChosen: true,
          trailing: '15 د.ل',
          onTap: () {},
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    final figure = find.text('15 د.ل');
    expect(figure, findsOneWidget);
    final context = tester.element(figure);
    expect(tester.widget<Text>(figure).style?.color, Theme.of(context).colorScheme.primary);
    // At the far end: past the value in reading order.
    expect(tester.getCenter(figure).dx, lessThan(tester.getCenter(find.text('طرابلس')).dx));
  });

  testWidgets('a tile with nothing to add says nothing at the end', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(PlacePickerTile(caption: 'المدينة', value: 'مطلوبة', isChosen: false, onTap: () {})),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.textContaining('د.ل'), findsNothing);
  });
}
