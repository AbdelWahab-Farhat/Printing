import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app's one dropdown, and the claim that makes it worth having: **it takes any model.**
///
/// So the tests below never mention a payment method or a city. They use a throwaway class
/// declared here, because a test that only proved the dropdown works for the one enum it was
/// written against would prove nothing about the next screen that reaches for it.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// A model of no consequence, deliberately: it has no `==` of its own, which is the case that
  /// [AppDropdown.keyOf] exists for.
  final tripoli = _Place(1, 'طرابلس');
  final benghazi = _Place(2, 'بنغازي');
  final misrata = _Place(3, 'مصراتة');

  final places = [tripoli, benghazi, misrata];

  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget child) {
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
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('it draws the label of whatever model it was handed', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        AppDropdown<_Place>(
          items: places,
          value: benghazi,
          labelOf: (place) => place.name,
          label: 'المدينة',
          onChanged: (_) {},
        ),
      ),
    );

    // Act - Assert — the closed field shows the selection, and the field's own label.
    expect(find.text('بنغازي'), findsOneWidget);
    expect(find.text('المدينة'), findsOneWidget);
  });

  testWidgets('opening it offers every item, and choosing one answers with the model', (
    tester,
  ) async {
    // Arrange
    _Place? chosen;
    await tester.pumpWidget(
      host(
        AppDropdown<_Place>(
          items: places,
          value: tripoli,
          labelOf: (place) => place.name,
          onChanged: (place) => chosen = place,
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(AppDropdown<_Place>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مصراتة').last);
    await tester.pumpAndSettle();

    // Assert — the model itself comes back, not an index and not an id.
    expect(chosen, same(misrata));
  });

  testWidgets('a value from a re-fetched list still shows, through keyOf', (tester) async {
    // Arrange — the same city rebuilt from JSON: equal by id, not by identity. Without `keyOf`
    // the field would render empty and the user would watch their answer vanish.
    final refetched = [_Place(1, 'طرابلس'), _Place(2, 'بنغازي')];

    await tester.pumpWidget(
      host(
        AppDropdown<_Place>(
          items: refetched,
          value: _Place(2, 'بنغازي'),
          keyOf: (place) => place.id,
          labelOf: (place) => place.name,
          onChanged: (_) {},
        ),
      ),
    );

    // Act - Assert
    expect(find.text('بنغازي'), findsOneWidget);
  });

  testWidgets('without keyOf a model that is not identical simply reads as unchosen', (
    tester,
  ) async {
    // Arrange — the honest failure mode, pinned so nobody is surprised by it: identity is the
    // default, and a model without value equality has to say how to compare itself.
    await tester.pumpWidget(
      host(
        AppDropdown<_Place>(
          items: places,
          value: _Place(2, 'بنغازي'),
          labelOf: (place) => place.name,
          onChanged: (_) {},
        ),
      ),
    );

    // Act - Assert
    expect(find.text('بنغازي'), findsNothing);
  });

  testWidgets('a subtitle is drawn under the label when one is asked for', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        AppDropdown<_Place>(
          items: places,
          value: tripoli,
          labelOf: (place) => place.name,
          subtitleOf: (place) => 'رقم ${place.id}',
          onChanged: (_) {},
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(AppDropdown<_Place>));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('رقم 3'), findsOneWidget);
  });

  testWidgets('there is no blank first row unless one was asked for', (tester) async {
    // Arrange — a picker that offers a blank on a required field teaches people to leave it
    // blank, so the placeholder is opt-in.
    await tester.pumpWidget(
      host(
        AppDropdown<_Place>(
          items: places,
          value: tripoli,
          labelOf: (place) => place.name,
          onChanged: (_) {},
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(AppDropdown<_Place>));
    await tester.pumpAndSettle();

    // Assert — three cities and nothing else. (Each is drawn twice while the menu is open: once
    // in the closed field's slot and once in the menu.)
    expect(find.text('غير محدد'), findsNothing);
  });

  testWidgets('a placeholder appears when the answer is genuinely optional', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        AppDropdown<_Place>(
          items: places,
          labelOf: (place) => place.name,
          placeholder: 'غير محدد',
          onChanged: (_) {},
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(AppDropdown<_Place>));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('غير محدد'), findsWidgets);
  });

  testWidgets('the server\'s own complaint renders where a validator\'s would', (tester) async {
    // Arrange — the user does not care which side said no, so both land in one slot.
    await tester.pumpWidget(
      host(
        AppDropdown<_Place>(
          items: places,
          value: tripoli,
          labelOf: (place) => place.name,
          errorText: 'المدينة غير مفعّلة',
          onChanged: (_) {},
        ),
      ),
    );

    // Act - Assert
    expect(find.text('المدينة غير مفعّلة'), findsOneWidget);
  });

  testWidgets('disabled means it cannot be opened, not that it looks the same', (tester) async {
    // Arrange
    var taps = 0;
    await tester.pumpWidget(
      host(
        AppDropdown<_Place>(
          items: places,
          value: tripoli,
          labelOf: (place) => place.name,
          enabled: false,
          onChanged: (_) => taps++,
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(AppDropdown<_Place>));
    await tester.pumpAndSettle();

    // Assert — no menu opened, so no other city is on screen to tap.
    expect(find.text('مصراتة'), findsNothing);
    expect(taps, 0);
  });
}

/// A model with no value equality, on purpose — see [AppDropdown.keyOf].
class _Place {
  _Place(this.id, this.name);

  final int id;
  final String name;
}
