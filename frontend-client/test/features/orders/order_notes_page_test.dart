import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_note.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_notes_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_notes_page.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:dayaa_client/features/orders/repositories/order_notes_repository.dart';
import 'package:dayaa_client/features/orders/usecases/read_order_notes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderNotesRepository extends Mock implements OrderNotesRepository {}

/// «الملاحظات» على شكل شاشة ملاحظات الطلبية في تطبيق الموظفين (طلب المستخدم، 2026-09-25):
/// بطاقةٌ لكل ملاحظة، أعلاها المرحلة التي كُتبت عندها، ثم ما كُتب، ثم متى — بلا اسم من كتب.
///
/// Arrange - Act - Assert throughout.
void main() {
  final refusedAt = DateTime(2026, 9, 25, 11, 20);
  final reopenedAt = DateTime(2026, 9, 25, 14, 5);

  final refused = OrderNote(
    id: 41,
    stage: OrderStage.rejected,
    stageLabel: 'مرفوضة',
    text: 'التصميم غير واضح، أرسل الشعار بدقة أعلى',
    writtenAt: refusedAt,
  );
  final reopened = OrderNote(
    id: 44,
    stage: OrderStage.underReview,
    stageLabel: 'بانتظار المراجعة',
    text: 'وصل الشعار الجديد، نراجعه الآن',
    writtenAt: reopenedAt,
  );

  late _MockOrderNotesRepository repository;

  setUp(() {
    repository = _MockOrderNotesRepository();
    sl.registerFactoryParam<OrderNotesCubit, int, void>(
      (orderId, _) => OrderNotesCubit(orderId: orderId, read: ReadOrderNotes(repository)),
    );
  });

  tearDown(() async => sl.reset());

  Future<void> open(WidgetTester tester, {VoidCallback? onRead}) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: OrderNotesPage(orderId: 1309, onRead: onRead),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('each note is a card: the stage it was written at, the words, then when', (
    tester,
  ) async {
    // Arrange
    when(() => repository.notes(1309)).thenAnswer((_) async => Right([refused, reopened]));

    // Act
    await open(tester);

    // Assert
    expect(find.text('الملاحظات'), findsOneWidget);
    final pills = tester.widgetList<StagePill>(find.byType(StagePill)).toList();
    expect(pills.map((pill) => pill.stage), [OrderStage.rejected, OrderStage.underReview]);
    expect(find.text('مرفوضة'), findsOneWidget);
    expect(find.text('التصميم غير واضح، أرسل الشعار بدقة أعلى'), findsOneWidget);
    expect(find.text(refusedAt.stampLabel), findsOneWidget);
    expect(find.text(reopenedAt.stampLabel), findsOneWidget);
  });

  testWidgets('oldest first: the refusal above what came after it', (tester) async {
    // Arrange
    when(() => repository.notes(1309)).thenAnswer((_) async => Right([refused, reopened]));

    // Act
    await open(tester);

    // Assert
    expect(
      tester.getTopLeft(find.text(refused.text)).dy,
      lessThan(tester.getTopLeft(find.text(reopened.text)).dy),
    );
  });

  /// «مفيش داعي توضحله»: لا جملة تشرح من أين تأتي الملاحظات ولا لماذا لا يرى غيرها.
  testWidgets('with nothing written, it says so and explains nothing', (tester) async {
    // Arrange
    when(() => repository.notes(1309)).thenAnswer((_) async => const Right([]));

    // Act
    await open(tester);

    // Assert
    expect(find.text('لا توجد ملاحظات'), findsOneWidget);
    // العنوان وجملة الفراغ، ولا شيء غيرهما.
    expect(find.byType(Text), findsNWidgets(2));
  });

  testWidgets('a failed load says why and tries again on request', (tester) async {
    // Arrange
    var calls = 0;
    when(() => repository.notes(1309)).thenAnswer((_) async {
      calls++;
      return calls == 1 ? const Left(Failure.network(message: 'لا اتصال')) : Right([refused]);
    });
    await open(tester);
    expect(find.text('لا اتصال'), findsOneWidget);

    // Act
    await tester.tap(find.text('أعد المحاولة'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text(refused.text), findsOneWidget);
  });

  testWidgets('once the notes are on screen, the order behind is told they were read', (
    tester,
  ) async {
    // Arrange
    var told = 0;
    when(() => repository.notes(1309)).thenAnswer((_) async => Right([refused]));

    // Act
    await open(tester, onRead: () => told++);

    // Assert
    expect(told, 1);
  });

  testWidgets('a load that failed marks nothing read', (tester) async {
    // Arrange
    var told = 0;
    when(
      () => repository.notes(1309),
    ).thenAnswer((_) async => const Left(Failure.network(message: 'لا اتصال')));

    // Act
    await open(tester, onRead: () => told++);

    // Assert
    expect(told, 0);
  });
}
