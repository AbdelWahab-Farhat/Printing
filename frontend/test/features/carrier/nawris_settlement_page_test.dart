import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/carrier/models/nawris_settlement.dart';
import 'package:dayaa/features/carrier/presentation/viewmodel/nawris_settlement_cubit.dart';
import 'package:dayaa/features/carrier/presentation/views/nawris_settlement_page.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';
import 'package:dayaa/features/carrier/usecases/nawris_settlement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCarrierRepository extends Mock implements CarrierRepository {}

class _FakePicker implements AttachmentPicker {
  @override
  Future<List<PickedFile>> pick(
    AttachmentSource source, {
    List<String> extensions = AttachmentPicker.defaultExtensions,
  }) async => const [PickedFile(path: '/tmp/report.xlsx', name: 'report.xlsx', sizeBytes: 100)];
}

/// الشاشة كما يراها الموظف: يرفع الملف، فيرى ما لن يتحرك ولماذا، ثم يقرر.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockCarrierRepository repository;

  Map<String, dynamic> line({
    required String code,
    required String outcome,
    String? reason,
    String held = '0.00',
  }) => {
    'row_number': 1,
    'raw_code': '4097115',
    'raw_receiver': code,
    'order_id': int.parse(code),
    'order_code': code,
    'outcome': outcome,
    'outcome_label': outcome,
    'reason': reason,
    'warnings': <Map<String, dynamic>>[],
    'held_amount': held,
    'fee_amount': '0.00',
  };

  final preview = NawrisSettlementPreview.fromJson({
    'summary': {
      'rows_count': 2,
      'orders_count': 2,
      'settled_count': 1,
      'skipped_count': 0,
      'rejected_count': 1,
      'warnings_count': 0,
    },
    'total_held': '700.00',
    'known_fees': '0.00',
    'expected_received': '700.00',
    'fingerprint': 'f' * 64,
    'lines': [
      line(code: '1201', outcome: 'settled', held: '700.00'),
      line(code: '1203', outcome: 'rejected', reason: 'باقٍ على الطلبية 20 د.ل.'),
    ],
  });

  final batch = NawrisSettlementImport.fromJson(const {
    'id': 12,
    'file_name': 'report.xlsx',
    'summary': {
      'rows_count': 2,
      'orders_count': 2,
      'settled_count': 1,
      'skipped_count': 0,
      'rejected_count': 1,
      'warnings_count': 0,
    },
    'total_held': '700.00',
    'received_amount': '700.00',
    'fee_total': '0.00',
  });

  setUpAll(() {
    registerFallbackValue(const NawrisSettlementSubmission(fingerprint: 'x', clientToken: 'y'));
  });

  setUp(() async {
    await Injector.reset();
    repository = _MockCarrierRepository();

    sl
      ..registerSingleton<AttachmentPicker>(_FakePicker())
      ..registerFactory<NawrisSettlementCubit>(
        () => NawrisSettlementCubit(
          preview: PreviewNawrisSettlement(repository),
          import: ImportNawrisSettlement(repository),
          newToken: () => 'token',
        ),
      );

    when(
      () => repository.previewSettlement(
        path: any(named: 'path'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => Right(preview));
  });

  tearDown(() async {
    resetSnackBars();
    await Injector.reset();
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: NawrisSettlementPage(),
        ),
      ),
    );

    await tester.pump();
  }

  Future<void> upload(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('settlement-pick')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  void importAnswers(Either<Failure, NawrisSettlementImport> answer) {
    when(
      () => repository.importSettlement(
        path: any(named: 'path'),
        fileName: any(named: 'fileName'),
        submission: any(named: 'submission'),
      ),
    ).thenAnswer((_) async => answer);
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('settlement-submit')));
    await tester.tap(find.byKey(const ValueKey('settlement-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('تنفيذ').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('تفتح المعاينة على ما لن يتحرك وسببه', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await upload(tester);

    // Assert
    expect(find.text('طلبية 1203'), findsOneWidget);
    expect(find.text('باقٍ على الطلبية 20 د.ل.'), findsOneWidget);
    expect(find.text('طلبية 1201'), findsNothing);
  });

  testWidgets('ما سيُسوّى في تبويبه بمبلغه', (tester) async {
    // Arrange
    await open(tester);
    await upload(tester);

    // Act
    await tester.tap(find.byKey(const ValueKey('settlement-filter-settling')));
    await tester.pump();

    // Assert
    expect(find.text('طلبية 1201'), findsOneWidget);
    expect(find.text('طلبية 1203'), findsNothing);
  });

  testWidgets('المبلغ الأقل يسأل عن الفرق قبل أي شيء', (tester) async {
    // Arrange
    await open(tester);
    await upload(tester);
    expect(find.textContaining('ما هو؟'), findsNothing);

    // Act
    await tester.enterText(find.byKey(const ValueKey('settlement-received')), '650');
    await tester.pump();

    // Assert
    expect(find.text('الفرق 50 د.ل — ما هو؟'), findsOneWidget);
    expect(find.byKey(const ValueKey('settlement-reason')), findsNothing);
  });

  testWidgets('الأجرة تسأل عن سببها', (tester) async {
    // Arrange
    await open(tester);
    await upload(tester);
    await tester.enterText(find.byKey(const ValueKey('settlement-received')), '650');
    await tester.pump();

    // Act
    await tester.tap(find.byKey(const ValueKey('settlement-difference-fee')));
    await tester.pump();

    // Assert
    expect(find.byKey(const ValueKey('settlement-reason')), findsOneWidget);
  });

  group('طلبيتان ومال إحداهما لم يصل', () {
    final twoOrders = NawrisSettlementPreview.fromJson({
      'summary': {
        'rows_count': 2,
        'orders_count': 2,
        'settled_count': 2,
        'skipped_count': 0,
        'rejected_count': 0,
        'warnings_count': 0,
      },
      'total_held': '700.00',
      'known_fees': '0.00',
      'expected_received': '700.00',
      'fingerprint': 'f' * 64,
      'lines': [
        line(code: '1201', outcome: 'settled', held: '400.00'),
        line(code: '1202', outcome: 'settled', held: '300.00'),
      ],
    });

    setUp(() {
      when(
        () => repository.previewSettlement(
          path: any(named: 'path'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => Right(twoOrders));
    });

    testWidgets('«ما زال عند النورس» يوقف الزرّ حتى تُترك طلبيته، ثم تُرسل متروكةً', (
      tester,
    ) async {
      // Arrange
      importAnswers(Right(batch));
      await open(tester);
      await upload(tester);
      await tester.enterText(find.byKey(const ValueKey('settlement-received')), '400');
      await tester.pump();

      // Act — الجواب أولاً: الزرّ موقوف، ومعروض ما يلزم فعله.
      await tester.tap(find.byKey(const ValueKey('settlement-difference-not-arrived')));
      await tester.pump();

      final stopped = tester
          .widget<AppButton>(find.byKey(const ValueKey('settlement-submit')))
          .onPressed;

      await tester.ensureVisible(find.byKey(const ValueKey('settlement-tick-1202')));
      await tester.tap(find.byKey(const ValueKey('settlement-tick-1202')));
      await tester.pump();

      final open_ = tester
          .widget<AppButton>(find.byKey(const ValueKey('settlement-submit')))
          .onPressed;

      await confirm(tester);

      // Assert
      expect(stopped, isNull);
      expect(open_, isNotNull);

      final sent =
          verify(
                () => repository.importSettlement(
                  path: any(named: 'path'),
                  fileName: any(named: 'fileName'),
                  submission: captureAny(named: 'submission'),
                ),
              ).captured.single
              as NawrisSettlementSubmission;

      expect(sent.leftOut, {1202});
      expect(sent.receivedAmount, '400');
      expect(sent.differenceReason, isNull);

      resetSnackBars();
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('الخانة تتبع العلامات ما لم يكتب الموظف مبلغاً', (tester) async {
      // Arrange
      await open(tester);
      await upload(tester);

      // Act
      await tester.tap(find.byKey(const ValueKey('settlement-tick-1202')));
      await tester.pump();

      // Assert
      final field = tester.widget<AppTextField>(find.byKey(const ValueKey('settlement-received')));
      expect(field.controller?.text, '400');
      expect(find.text('تنفيذ (1)'), findsOneWidget);
      expect(find.text('تبقى «تم الاستلام» ومالها عند النورس'), findsOneWidget);
    });

    testWidgets('لا تُمسّ مبلغاً كتبه الموظف', (tester) async {
      // Arrange
      await open(tester);
      await upload(tester);
      await tester.enterText(find.byKey(const ValueKey('settlement-received')), '350');
      await tester.pump();

      // Act
      await tester.tap(find.byKey(const ValueKey('settlement-tick-1202')));
      await tester.pump();

      // Assert
      final field = tester.widget<AppTextField>(find.byKey(const ValueKey('settlement-received')));
      expect(field.controller?.text, '350');
    });
  });

  testWidgets('مبلغ أكبر مما عنده يُقال تحت خانته', (tester) async {
    // Arrange
    await open(tester);
    await upload(tester);

    // Act
    await tester.enterText(find.byKey(const ValueKey('settlement-received')), '980');
    await tester.pump();

    // Assert
    expect(find.textContaining('أكبر مما عند النورس'), findsOneWidget);
  });

  testWidgets('لا شيء يُرسل قبل التأكيد، وبعده تظهر الدفعة', (tester) async {
    // Arrange
    importAnswers(Right(batch));
    await open(tester);
    await upload(tester);

    verifyNever(
      () => repository.importSettlement(
        path: any(named: 'path'),
        fileName: any(named: 'fileName'),
        submission: any(named: 'submission'),
      ),
    );

    // Act
    await confirm(tester);

    // Assert
    final sent =
        verify(
              () => repository.importSettlement(
                path: any(named: 'path'),
                fileName: any(named: 'fileName'),
                submission: captureAny(named: 'submission'),
              ),
            ).captured.single
            as NawrisSettlementSubmission;

    expect(sent.receivedAmount, '700');
    expect(sent.fingerprint, preview.fingerprint);
    expect(find.text('عرض الدفعة'), findsOneWidget);

    // توست النجاح يغلق نفسه بمؤقّت، والاختبار لا ينتهي ومؤقّت معلّق.
    resetSnackBars();
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('تغيّر شيء منذ المعاينة: زرّ يعيدها، وما كان باقٍ على الشاشة', (tester) async {
    // Arrange
    importAnswers(
      const Left(
        Failure.server(
          message: 'تغيّرت',
          fieldErrors: {
            'fingerprint': ['تغيّرت الطلبيات — أعد المعاينة.'],
          },
        ),
      ),
    );
    await open(tester);
    await upload(tester);

    // Act
    await confirm(tester);

    // Assert
    expect(find.text('تغيّرت الطلبيات — أعد المعاينة.'), findsOneWidget);
    expect(find.byKey(const ValueKey('settlement-read-again')), findsOneWidget);
  });

  testWidgets('إلغاء المعاينة يعود إلى الرفع ولا يرسل شيئاً', (tester) async {
    // Arrange
    await open(tester);
    await upload(tester);

    // Act
    await tester.tap(find.text('إلغاء'));
    await tester.pump();

    // Assert
    expect(find.byKey(const ValueKey('settlement-pick')), findsOneWidget);
    verifyNever(
      () => repository.importSettlement(
        path: any(named: 'path'),
        fileName: any(named: 'fileName'),
        submission: any(named: 'submission'),
      ),
    );
  });
}
