import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_designs_cubit.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';
import 'package:dayaa/features/customers/usecases/delete_customer_design.dart';
import 'package:dayaa/features/customers/usecases/get_customer_designs.dart';
import 'package:dayaa/features/customers/usecases/rename_customer_design.dart';
import 'package:dayaa/features/customers/usecases/set_customer_design_colors.dart';
import 'package:dayaa/features/customers/usecases/upload_customer_design.dart';
import 'package:dayaa/features/orders/presentation/widgets/design_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDesignRepository extends Mock implements CustomerDesignRepository {}

/// «اختيار التصاميم» في الطلبية الجديدة — ألوان كل تصميم تحت اسمه.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockDesignRepository designs;

  const flyer = CustomerDesign(
    id: 2,
    customerId: 7,
    label: 'المنشور النهائي',
    kind: DesignKind.pdf,
    kindLabel: 'PDF',
    printColors: [
      PrintColor(name: 'أحمر الشعار', hex: '#E4002B'),
      // حُفظ بلا اسم، فكوده اسمه.
      PrintColor(name: '#000000', hex: '#000000'),
    ],
  );
  const plain = CustomerDesign(
    id: 3,
    customerId: 7,
    label: 'الشعار',
    kind: DesignKind.pdf,
    kindLabel: 'PDF',
  );

  setUp(() {
    designs = _MockDesignRepository();
    when(() => designs.designs(7)).thenAnswer((_) async => const Right([flyer, plain]));

    sl.registerFactoryParam<CustomerDesignsCubit, int, void>(
      (customerId, _) => CustomerDesignsCubit(
        customerId: customerId,
        getDesigns: GetCustomerDesigns(designs),
        uploadDesign: UploadCustomerDesign(designs),
        renameDesign: RenameCustomerDesign(designs),
        setDesignColors: SetCustomerDesignColors(designs),
        deleteDesign: DeleteCustomerDesign(designs),
      ),
    );
  });

  tearDown(Injector.reset);

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
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDesignPicker(context: context, customerId: 7, selected: const []),
            child: const Text('افتح'),
          ),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host());
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('each design shows its print colours under its name', (tester) async {
    // Arrange / Act
    await open(tester);

    // Assert
    final name = tester.getRect(find.text('المنشور النهائي'));
    final ink = tester.getRect(find.text('أحمر الشعار'));
    expect(ink.top, greaterThanOrEqualTo(name.bottom));
    expect(find.text('#000000'), findsOneWidget);
  });

  testWidgets('a colour named by its code reads left to right', (tester) async {
    // Arrange / Act
    await open(tester);

    // Assert — «#000000» laid out right to left would read «000000#».
    final code = tester.widget<Text>(find.text('#000000'));
    expect(code.textDirection, TextDirection.ltr);
  });
}
