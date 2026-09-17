import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/dismiss_keyboard.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/presentation/views/designs_page.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/designs/usecases/remove_design.dart';
import 'package:dayaa_client/features/designs/usecases/rename_design.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «تسمية التصميم» — opening the dialog and leaving it, both ways.
///
/// **A regression test for a crash the user hit twice.** The first fix addressed a disposed
/// `TextEditingController`, which was a real defect but not this one: the assertion thrown is
/// `'_dependents.isEmpty': is not true` from `InheritedElement.debugDeactivated`, which fires
/// when an inherited widget is deactivated while elements still depend on it — nothing to do
/// with a controller.
///
/// Arrange - Act - Assert throughout.
class _MockDesignRepository extends Mock implements DesignRepository {}

void main() {
  late _MockDesignRepository repository;

  const logo = CustomerDesign(id: 1, label: 'شعار المتجر', kind: DesignKind.image);

  Future<void> arrange() async {
    await Injector.reset();

    repository = _MockDesignRepository();

    when(() => repository.list()).thenAnswer((_) async => const Right([logo]));
    when(
      () => repository.rename(id: any(named: 'id'), label: any(named: 'label')),
    ).thenAnswer(
      (_) async => const Right(CustomerDesign(id: 1, label: 'شعار', kind: DesignKind.image)),
    );

    sl.registerFactory<DesignsCubit>(
      () => DesignsCubit(
        list: ListDesigns(repository),
        upload: UploadDesign(repository),
        rename: RenameDesign(repository),
        remove: RemoveDesign(repository),
      ),
    );
  }

  /// The app as `DayaaApp` actually assembles it.
  ///
  /// **`builder` is not decoration here.** [DismissKeyboard] is wrapped around every route in
  /// `app.dart` precisely so it covers dialogs and sheets too, and a harness that leaves it out
  /// is testing a screen this app never renders. The first version of this file did leave it
  /// out, and all three tests passed while the real screen crashed.
  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          DismissKeyboard(child: child ?? const SizedBox.shrink()),
      home: const DesignsPage(),
    ),
  );

  tearDown(Injector.reset);

  Future<void> openRenameDialog(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Tapping the card *is* the rename — `_DesignCard` wires `onTap: onRename` on its
    // [AppCard]. Reached through the label rather than by position: the screen draws a second
    // [AppCard] for the «ارفع شعارك مرة واحدة» hint, and it is the one that comes first.
    await tester.tap(
      find.ancestor(of: find.text('شعار المتجر'), matching: find.byType(AppCard)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the current name', (tester) async {
    // Arrange
    await arrange();

    // Act
    await openRenameDialog(tester);

    // Assert
    expect(find.text('تسمية التصميم'), findsOneWidget);
    expect(find.text('شعار المتجر'), findsWidgets);
  });

  testWidgets('cancelling closes it and leaves the name alone', (tester) async {
    // Arrange
    await arrange();
    await openRenameDialog(tester);

    // Act — the press that used to throw.
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Assert — gone, with no rename sent and, crucially, no assertion on the way out.
    expect(find.text('تسمية التصميم'), findsNothing);
    verifyNever(() => repository.rename(id: any(named: 'id'), label: any(named: 'label')));
  });

  testWidgets('saving a new name sends it', (tester) async {
    // Arrange
    await arrange();
    await openRenameDialog(tester);

    // Act
    await tester.enterText(find.byType(TextFormField), 'شعار');
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.rename(id: 1, label: 'شعار')).called(1);
    expect(find.text('تسمية التصميم'), findsNothing);
  });
}
