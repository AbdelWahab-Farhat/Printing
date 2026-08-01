import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/widgets/search_field.dart';

/// The shared search box — the clear button in particular, which is the detail every
/// hand-rolled search field forgets.
///
/// Arrange - Act - Assert throughout.
void main() {
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
          body: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      ),
    );
  }

  testWidgets('starts with a magnifier and no clear button', (tester) async {
    // Arrange
    await tester.pumpWidget(host(SearchField(onChanged: (_) {})));

    // Act
    await tester.pump();

    // Assert
    expect(find.byIcon(AppIcons.search), findsOneWidget);
    expect(find.byIcon(AppIcons.clear), findsNothing);
  });

  testWidgets('every keystroke reaches the caller', (tester) async {
    // Arrange
    final typed = <String>[];
    await tester.pumpWidget(host(SearchField(onChanged: typed.add)));

    // Act
    await tester.enterText(find.byType(TextField), 'مطبعة');

    // Assert — no debounce here: that belongs to the ViewModel, next to the request.
    expect(typed, ['مطبعة']);
  });

  testWidgets('the clear button appears once there is something to clear', (tester) async {
    // Arrange
    await tester.pumpWidget(host(SearchField(onChanged: (_) {})));

    // Act
    await tester.enterText(find.byType(TextField), 'م');
    await tester.pump();

    // Assert
    expect(find.byIcon(AppIcons.clear), findsOneWidget);
  });

  testWidgets('clearing empties the box and asks for everything again', (tester) async {
    // Arrange
    final typed = <String>[];
    await tester.pumpWidget(host(SearchField(onChanged: typed.add)));
    await tester.enterText(find.byType(TextField), 'مطبعة');
    await tester.pump();

    // Act
    await tester.tap(find.byIcon(AppIcons.clear));
    await tester.pump();

    // Assert — the empty term is reported, or the list would stay filtered by a box that now
    // looks empty.
    expect(typed.last, '');
    expect(find.text('مطبعة'), findsNothing);
    expect(find.byIcon(AppIcons.clear), findsNothing);
  });

  testWidgets('a controller supplied from outside is not disposed by this widget', (
    tester,
  ) async {
    // Arrange
    final controller = TextEditingController(text: 'مطبعة');
    await tester.pumpWidget(host(SearchField(controller: controller, onChanged: (_) {})));

    // Act — the field goes away, its owner does not.
    await tester.pumpWidget(host(const SizedBox.shrink()));

    // Assert — still usable; disposing someone else's controller throws on the next read.
    expect(controller.text, 'مطبعة');
    controller.dispose();
  });
}
