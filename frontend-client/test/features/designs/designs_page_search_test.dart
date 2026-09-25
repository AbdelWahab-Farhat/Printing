import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/widgets/dismiss_keyboard.dart';
import 'package:dayaa_client/core/widgets/search_field.dart';
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

/// البحث بالاسم في «تصاميمي».
///
/// **في الهاتف لا على الخادم**: المكتبة خمسون تصميماً على الأكثر وكلها في يد الشاشة، فطلبٌ مع
/// كل حرفٍ رحلةٌ لجلب ما هو هنا أصلاً. ما يطابق وما لا يطابق مختبَرٌ حرفاً حرفاً في
/// `design_search_test.dart`؛ هنا ما تفعله الشاشة بالجواب.
///
/// Arrange - Act - Assert throughout.
class _MockDesignRepository extends Mock implements DesignRepository {}

void main() {
  late _MockDesignRepository repository;

  const library = [
    CustomerDesign(id: 1, label: 'شعار المتجر', kind: DesignKind.image),
    CustomerDesign(id: 2, label: 'كيس العيد', kind: DesignKind.pdf),
    CustomerDesign(id: 3, label: 'إعلان الافتتاح', kind: DesignKind.image),
  ];

  Future<void> arrange(
    WidgetTester tester, {
    List<CustomerDesign> designs = library,
  }) async {
    await Injector.reset();

    // هاتفٌ حقيقي، كي تُبنى البطاقات الثلاث كلها في الشبكة.
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    repository = _MockDesignRepository();
    when(() => repository.list()).thenAnswer((_) async => Right(designs));

    sl.registerFactory<DesignsCubit>(
      () => DesignsCubit(
        list: ListDesigns(repository),
        upload: UploadDesign(repository),
        rename: RenameDesign(repository),
        remove: RemoveDesign(repository),
      ),
    );
  }

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

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String term) async {
    await tester.enterText(
      find.descendant(of: find.byType(SearchField), matching: find.byType(EditableText)),
      term,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('حقل البحث فوق المكتبة', (tester) async {
    // Arrange
    await arrange(tester);

    // Act
    await openPage(tester);

    // Assert
    expect(find.byType(SearchField), findsOneWidget);
    expect(find.text('شعار المتجر'), findsOneWidget);
    expect(find.text('كيس العيد'), findsOneWidget);
    expect(find.text('إعلان الافتتاح'), findsOneWidget);
  });

  testWidgets('البحث بالاسم يُبقي ما يطابق وحده', (tester) async {
    // Arrange
    await arrange(tester);
    await openPage(tester);

    // Act
    await search(tester, 'كيس');

    // Assert
    expect(find.text('كيس العيد'), findsOneWidget);
    expect(find.text('شعار المتجر'), findsNothing);
    expect(find.text('إعلان الافتتاح'), findsNothing);
  });

  testWidgets('الهمزة لا تُخفي تصميماً: «اعلان» تجد «إعلان الافتتاح»', (tester) async {
    // Arrange
    await arrange(tester);
    await openPage(tester);

    // Act
    await search(tester, 'اعلان');

    // Assert
    expect(find.text('إعلان الافتتاح'), findsOneWidget);
    expect(find.text('شعار المتجر'), findsNothing);
  });

  testWidgets('بحثٌ لا يطابق شيئاً يقول ذلك', (tester) async {
    // Arrange
    await arrange(tester);
    await openPage(tester);

    // Act
    await search(tester, 'حقيبة');

    // Assert
    expect(find.text('لا توجد نتائج لـ «حقيبة»'), findsOneWidget);
    expect(find.text('شعار المتجر'), findsNothing);
  });

  testWidgets('مسح البحث يعيد المكتبة كلها', (tester) async {
    // Arrange
    await arrange(tester);
    await openPage(tester);
    await search(tester, 'كيس');

    // Act
    await tester.tap(find.byTooltip('مسح البحث'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شعار المتجر'), findsOneWidget);
    expect(find.text('كيس العيد'), findsOneWidget);
    expect(find.text('إعلان الافتتاح'), findsOneWidget);
  });

  testWidgets('لا بحث في مكتبةٍ فارغة', (tester) async {
    // Arrange — لا شيء يُبحث فيه، وحقلٌ فوق «لا توجد تصاميم بعد» وعدٌ بما ليس موجوداً.
    await arrange(tester, designs: const []);

    // Act
    await openPage(tester);

    // Assert
    expect(find.byType(SearchField), findsNothing);
    expect(find.text('لا توجد تصاميم بعد'), findsOneWidget);
  });
}
