import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/models/pricing_unit.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/presentation/viewmodel/save_shortage_cubit.dart';
import 'package:dayaa/features/shortages/presentation/views/shortage_form_page.dart';
import 'package:dayaa/features/shortages/repositories/shortage_repository.dart';
import 'package:dayaa/features/shortages/usecases/shortage_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the form handed over, and a refusal so the page stays where it is.
///
/// **Refused on purpose.** A success pops the route, taking the screen — and every payload
/// assertion below is about what left the form, not about what came back. The complaint is put
/// on `required_quantity`, a key the form paints under its own box, so nothing is swallowed.
class _RecordingRepository implements ShortageRepository {
  Map<String, Object?>? created;
  Map<String, Object?>? updated;

  static const _refusal = Left<Failure, Shortage>(
    Failure.server(
      message: 'البيانات غير صحيحة',
      fieldErrors: {
        'required_quantity': ['الكمية الناقصة مطلوبة'],
      },
    ),
  );

  @override
  Future<Either<Failure, Shortage>> create({
    required String name,
    required String quantity,
    int? productId,
    int? productVariantId,
    String? unit,
    String? type,
    int? assignedToUserId,
    String? description,
  }) async {
    created = {
      'name': name,
      'quantity': quantity,
      'product_id': productId,
      'product_variant_id': productVariantId,
      'unit': unit,
      'type': type,
      'assigned_to_user_id': assignedToUserId,
      'description': description,
    };

    return _refusal;
  }

  @override
  Future<Either<Failure, Shortage>> update(
    int shortageId, {
    required String name,
    required String quantity,
    int? productId,
    int? productVariantId,
    String? unit,
    String? type,
    int? assignedToUserId,
    String? description,
  }) async {
    updated = {
      'id': shortageId,
      'name': name,
      'quantity': quantity,
      'product_id': productId,
      'product_variant_id': productVariantId,
      'unit': unit,
      'type': type,
      'description': description,
    };

    return _refusal;
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// «نقص جديد» — the form, and the fork at the top of it.
///
/// **The first question is what kind of thing is short**, and it decides the rest of the screen:
/// a catalogue row has a name and a unit of its own, so neither is asked; a consumable has
/// neither, so its category is asked and stands in for the name.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _RecordingRepository repository;

  setUp(() {
    repository = _RecordingRepository();
    sl.registerFactory<SaveShortageCubit>(
      () => SaveShortageCubit(
        createShortage: CreateShortage(repository),
        updateShortage: UpdateShortage(repository),
      ),
    );
  });

  tearDown(() => sl.reset());

  Widget host(Widget child) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(textDirection: TextDirection.rtl, child: child),
    ),
  );

  /// Picks a value out of an [AppDropdown] by the words on its row.
  Future<void> choose(WidgetTester tester, Finder dropdown, String option) async {
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    // The chosen row is drawn twice while the menu is open — in the field and in the list.
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> switchTo(WidgetTester tester, String kind) async {
    await tester.tap(find.text(kind));
    await tester.pumpAndSettle();
  }

  /// Taps «إضافة»/«حفظ» and waits out the snackbar the refusal raises.
  ///
  /// `AppSnackBar` dismisses itself on a three-second timer, and a timer still running when the
  /// tree is torn down fails the test on an invariant that has nothing to do with the payload.
  Future<void> save(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('the form opens on منتج, and asks nothing a product answers', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const ShortageFormPage()));
    await tester.pumpAndSettle();

    // Act - Assert — the catalogue carries the name and the unit, so neither is a question, and
    // «نوع النقص» is not one either: the product *is* the category.
    expect(find.text('المنتج'), findsOneWidget);
    expect(find.text('ما النقص؟'), findsNothing);
    expect(find.text('الوحدة'), findsNothing);
    expect(find.text('نوع النقص'), findsNothing);
  });

  testWidgets('مستلزمات asks the category instead of the product', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const ShortageFormPage()));
    await tester.pumpAndSettle();

    // Act
    await switchTo(tester, 'مستلزمات');

    // Assert — nothing in the catalogue is a roll of tape, so the picker goes and the category
    // arrives. The unit stays: paper is bought by the kilo and a blade by the piece.
    expect(find.text('المنتج'), findsNothing);
    expect(find.text('نوع النقص'), findsOneWidget);
    expect(find.text('الوحدة'), findsOneWidget);
  });

  testWidgets('a named category needs no name, and «أخرى» asks for one', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const ShortageFormPage()));
    await tester.pumpAndSettle();
    await switchTo(tester, 'مستلزمات');

    // Act - Assert — «حبر» is the whole of what the row is called.
    await choose(tester, find.byType(DropdownButtonFormField<ShortageType>), 'حبر');
    expect(find.text('ما النقص؟'), findsNothing);

    // Act - Assert — «أخرى» names nothing, so there is nobody to read the name off but the
    // person writing it down.
    await choose(tester, find.byType(DropdownButtonFormField<ShortageType>), 'أخرى');
    expect(find.text('ما النقص؟'), findsOneWidget);
  });

  testWidgets('a مستلزمات shortage is named by its category', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const ShortageFormPage()));
    await tester.pumpAndSettle();
    await switchTo(tester, 'مستلزمات');
    await choose(tester, find.byType(DropdownButtonFormField<ShortageType>), 'ورق طباعة');
    await tester.enterText(find.byType(TextFormField).first, '30');
    await choose(tester, find.byType(DropdownButtonFormField<PricingUnit>), 'بالكجم');

    // Act
    await save(tester, 'إضافة');

    // Assert — the server requires a name and the list prints it; the category is it.
    expect(repository.created?['name'], 'ورق طباعة');
    expect(repository.created?['type'], 'printing_paper');
    expect(repository.created?['unit'], 'kilogram');
    expect(repository.created?['product_id'], isNull);
  });

  testWidgets('منتج without a product is refused before it is sent', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const ShortageFormPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '10');

    // Act
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    // Assert — the segment promised a catalogue row, and nothing else can name this one.
    expect(repository.created, isNull);
    expect(find.text('اختر المنتج'), findsOneWidget);
  });

  testWidgets('editing a product shortage keeps its product and its unit', (tester) async {
    // Arrange — the bug this replaces: the update carried neither, so the server nulled the
    // product link and refused the whole edit for want of «الوحدة».
    const shortage = Shortage(
      id: 7,
      code: 'N7',
      source: ShortageSource.manual,
      sourceLabel: 'يدوي',
      name: 'كيس شحن — 25*35',
      unit: 'kilogram',
      unitLabel: 'كجم',
      requiredQuantity: '30.000',
      suppliedQuantity: '0.000',
      remainingQuantity: '30.000',
      totalPaid: '0.00',
      status: ShortageStatus.fresh,
      statusLabel: 'جديد',
      isEditable: true,
      productId: 3,
      productVariantId: 12,
      product: ShortageProductRef(id: 3, name: 'كيس شحن'),
      variant: ShortageVariantRef(id: 12, label: '25*35'),
    );
    await tester.pumpWidget(host(const ShortageFormPage(shortage: shortage)));
    await tester.pumpAndSettle();

    // Act
    await tester.enterText(find.byType(TextFormField).first, '40');
    await save(tester, 'حفظ');

    // Assert
    expect(repository.updated?['product_id'], 3);
    expect(repository.updated?['product_variant_id'], 12);
    expect(repository.updated?['unit'], 'kilogram');
    expect(repository.updated?['name'], 'كيس شحن — 25*35');
    expect(repository.updated?['quantity'], '40');
  });

  testWidgets('a hand-written مستلزمات shortage opens on its own category', (tester) async {
    // Arrange — «شريط لاصق عريض»: no catalogue row, so the form opens on the other side of the
    // fork, and «أخرى» brings its name back with it rather than losing it to the category.
    const shortage = Shortage(
      id: 9,
      code: 'N9',
      source: ShortageSource.manual,
      sourceLabel: 'يدوي',
      name: 'شريط لاصق عريض',
      unit: 'piece',
      unitLabel: 'قطعة',
      requiredQuantity: '3.000',
      suppliedQuantity: '0.000',
      remainingQuantity: '3.000',
      totalPaid: '0.00',
      status: ShortageStatus.fresh,
      statusLabel: 'جديد',
      isEditable: true,
    );
    await tester.pumpWidget(host(const ShortageFormPage(shortage: shortage)));
    await tester.pumpAndSettle();

    // Act
    await save(tester, 'حفظ');

    // Assert
    expect(find.text('نوع النقص'), findsOneWidget);
    expect(repository.updated?['name'], 'شريط لاصق عريض');
    // Left out rather than sent: «أخرى» is the server's own default, and a client that spelled
    // it would make one decision in two places.
    expect(repository.updated?['type'], isNull);
    expect(repository.updated?['unit'], 'piece');
  });
}
