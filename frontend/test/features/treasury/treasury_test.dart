import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/widgets/transition_field_input.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTreasuryRepository extends Mock implements TreasuryRepository {}

/// الحسابات والخزائن on the phone — TREASURY-DESIGN §٥, §٦, §٩.
///
/// Arrange - Act - Assert throughout.
void main() {
  setUp(() async {
    await sl.reset();
  });

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
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  group('the status screen', () {
    test('a treasury_account field from the server is drawn, not called unknown', () {
      // Act
      final field = TransitionField.fromJson({
        'key': 'settlement_account_id',
        'type': 'treasury_account',
        'label': 'استُلم المال في',
        'options': [
          {'value': '2', 'label': 'المصرف'},
        ],
      });

      // Assert
      expect(field.type, TransitionFieldType.treasuryAccount);
      expect(field.isRenderable, isTrue);
    });

    testWidgets('«تلقائي» is a real answer and a picked account travels as its id', (tester) async {
      // Arrange
      const field = TransitionField(
        key: 'settlement_account_id',
        type: TransitionFieldType.treasuryAccount,
        label: 'استُلم المال في',
        hint: 'في العهدة: 100 (النورس)',
        options: [
          TransitionFieldOption(value: '2', label: 'المصرف'),
          TransitionFieldOption(value: '7', label: 'مصرف علي'),
        ],
      );
      final reported = <Object?>[];

      await tester.pumpWidget(
        host(
          TransitionFieldInput(
            field: field,
            value: null,
            customerId: 1,
            onChanged: reported.add,
          ),
        ),
      );
      await tester.pump();

      // Act
      await tester.tap(find.text('مصرف علي'));
      await tester.tap(find.text('تلقائي'));

      // Assert
      expect(find.text('استُلم المال في (اختياري)'), findsOneWidget);
      expect(find.text('في العهدة: 100 (النورس)'), findsOneWidget);
      expect(reported, ['7', null]);
    });

    const paymentAccount = TransitionField(
      key: 'payment_account_id',
      type: TransitionFieldType.treasuryAccount,
      label: 'الحساب',
      options: [
        TransitionFieldOption(value: '1', label: 'الخزنة الرئيسية'),
        TransitionFieldOption(value: '2', label: 'المصرف'),
      ],
    );

    testWidgets('before a method is picked, a payment offers only «تلقائي»', (tester) async {
      // Act
      await tester.pumpWidget(
        host(
          TransitionFieldInput(
            field: paymentAccount,
            value: null,
            customerId: 1,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text('تلقائي'), findsOneWidget);
      expect(find.text('المصرف'), findsNothing);
      expect(find.text('اختر طريقة الدفع لتظهر حساباتها'), findsOneWidget);
    });

    testWidgets('with cash picked, a payment offers only the accounts cash fits', (tester) async {
      // Arrange
      final repository = _MockTreasuryRepository();
      when(() => repository.accountOptions(method: 'cash', incoming: true)).thenAnswer(
        (_) async => const Right<Failure, AccountOptions>(
          AccountOptions(
            accounts: [
              AccountOption(id: 1, name: 'الخزنة الرئيسية', kindLabel: 'خزنة', isDefault: true),
              AccountOption(id: 9, name: 'خزنة فرع مصراتة', kindLabel: 'خزنة', isDefault: false),
            ],
            suggestedId: 1,
          ),
        ),
      );
      sl.registerLazySingleton<GetAccountOptions>(() => GetAccountOptions(repository));
      final reported = <Object?>[];

      await tester.pumpWidget(
        host(
          TransitionFieldInput(
            field: paymentAccount,
            value: null,
            customerId: 1,
            paymentMethod: 'cash',
            onChanged: reported.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('خزنة فرع مصراتة'));

      // Assert — no bank among them, and the pick still travels as the id the server reads
      expect(find.text('المصرف'), findsNothing);
      expect(find.text('تلقائي — الخزنة الرئيسية'), findsOneWidget);
      expect(reported, ['9']);
    });
  });

  group('the account picker on a payment form', () {
    testWidgets('it steps aside when the treasury is not there', (tester) async {
      // Arrange — nothing registered, as in every older test of the payment sheet.
      await tester.pumpWidget(
        host(TreasuryAccountPicker(method: 'cash', value: null, onChanged: (_) {})),
      );
      await tester.pump();

      // Assert
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('it offers the accounts the method fits and names the automatic one', (
      tester,
    ) async {
      // Arrange
      final repository = _MockTreasuryRepository();
      when(() => repository.accountOptions(method: 'bank_transfer', incoming: true)).thenAnswer(
        (_) async => const Right<Failure, AccountOptions>(
          AccountOptions(
            accounts: [
              AccountOption(id: 2, name: 'المصرف', kindLabel: 'مصرف', isDefault: true),
              AccountOption(id: 7, name: 'مصرف علي', kindLabel: 'مصرف', isDefault: false),
            ],
            suggestedId: 7,
          ),
        ),
      );
      sl.registerLazySingleton<GetAccountOptions>(() => GetAccountOptions(repository));
      int? picked = -1;

      await tester.pumpWidget(
        host(
          TreasuryAccountPicker(
            method: 'bank_transfer',
            value: null,
            onChanged: (id) => picked = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('المصرف'));

      // Assert — the server's pick is named on «تلقائي», so nobody has to guess where it lands
      expect(find.text('تلقائي — مصرف علي'), findsOneWidget);
      expect(picked, 2);
    });
  });

  group('the drawer picker on a form with no method', () {
    testWidgets('it offers every account money can leave, never custody, and names the cash box', (
      tester,
    ) async {
      // Arrange — a fund expense asks which drawer paid, not how.
      final repository = _MockTreasuryRepository();
      when(() => repository.accounts(activeOnly: true)).thenAnswer(
        (_) async => const Right<Failure, TreasuryAccounts>(
          TreasuryAccounts(
            accounts: [
              TreasuryAccount(
                id: 1,
                name: 'الخزنة الرئيسية',
                kind: AccountKind.cash,
                kindLabel: 'خزنة',
                isDefault: true,
                isActive: true,
                isSystem: false,
                isSpendable: true,
              ),
              TreasuryAccount(
                id: 2,
                name: 'المصرف',
                kind: AccountKind.bank,
                kindLabel: 'مصرف',
                isDefault: true,
                isActive: true,
                isSystem: false,
                isSpendable: true,
              ),
              TreasuryAccount(
                id: 4,
                name: 'النورس',
                kind: AccountKind.custody,
                kindLabel: 'عهدة',
                isDefault: false,
                isActive: true,
                isSystem: true,
                isSpendable: false,
              ),
            ],
            total: '0.00',
            canViewAll: true,
          ),
        ),
      );
      sl.registerLazySingleton<GetTreasuryAccounts>(() => GetTreasuryAccounts(repository));
      int? picked = -1;

      await tester.pumpWidget(
        host(
          TreasuryAccountPicker(
            method: null,
            incoming: false,
            value: null,
            onChanged: (id) => picked = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('المصرف'));

      // Assert
      expect(find.text('تلقائي — الخزنة الرئيسية'), findsOneWidget);
      expect(find.text('النورس'), findsNothing);
      expect(picked, 2);
    });
  });

  group('what the endpoints send', () {
    test('the dashboard reads every account and the server\'s own total', () {
      // Act
      final accounts = TreasuryAccounts.fromJson({
        'accounts': [
          {
            'id': 1,
            'name': 'الخزنة الرئيسية',
            'kind': 'cash',
            'kind_label': 'خزنة',
            'is_default': true,
            'is_active': true,
            'is_system': false,
            'is_spendable': true,
            'balance': '-80.00',
            'holder': null,
          },
          {
            'id': 4,
            'name': 'النورس',
            'kind': 'custody',
            'kind_label': 'عهدة',
            'is_spendable': false,
            'is_system': true,
            'balance': '100.00',
          },
        ],
        'total': '20.00',
        'can_view_all': true,
      });

      // Assert
      expect(accounts.accounts, hasLength(2));
      expect(accounts.accounts.first.isOverdrawn, isTrue);
      expect(accounts.accounts.last.kind, AccountKind.custody);
      expect(accounts.accounts.last.isSpendable, isFalse);
      expect(accounts.total, '20.00');
    });

    test('a history line keeps its sign, its balance after, its order and who did it', () {
      // Act
      final movement = TreasuryMovement.fromJson({
        'id': 9,
        'direction': 'out',
        'kind': 'settlement',
        'kind_label': 'تسوية طلبية',
        'signed_amount': '-100.00',
        'balance_after': '0.00',
        'occurred_at': '2026-09-30T10:00:00+00:00',
        'order_id': 1260,
        'counterpart_account': {'id': 2, 'name': 'المصرف'},
        'recorder': {'id': 3, 'name': 'علي'},
        'is_reversal': false,
      });

      // Assert
      expect(movement.isIn, isFalse);
      expect(movement.signedAmount, '-100.00');
      expect(movement.balanceAfter, '0.00');
      expect(movement.orderId, 1260);
      expect(movement.counterpartName, 'المصرف');
      expect(movement.recorderName, 'علي');
    });

    test('money reads with its sign outside the digits', () {
      // Assert
      expect(treasuryMoney('1250.00'), '1,250 د.ل');
      expect(treasuryMoney('-8450.50'), '−8,450.5 د.ل');
      expect(treasuryMoney('50.00', signed: true), '+50 د.ل');
    });
  });
}
