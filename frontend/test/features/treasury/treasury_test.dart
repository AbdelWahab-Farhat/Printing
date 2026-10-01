import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/widgets/transition_field_input.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_operation_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/presentation/widgets/vendor_account_section.dart';
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
      // Arrange
      final json = {
        'key': 'settlement_account_id',
        'type': 'treasury_account',
        'label': 'استُلم المال في',
        'options': [
          {'value': '2', 'label': 'المصرف'},
        ],
      };

      // Act
      final field = TransitionField.fromJson(json);

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

      // Act — الحسابات قائمةٌ منسدلة الآن، و«تلقائي» أول صفوفها.
      await tester.tap(find.byType(AppDropdown<TransitionFieldOption>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مصرف علي').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppDropdown<TransitionFieldOption>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تلقائي').last);
      await tester.pumpAndSettle();

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
      expect(find.text('اختر طريقة الدفع لتظهر حساباتها'), findsNothing);
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
            suggestedName: 'الخزنة الرئيسية',
          ),
        ),
      );
      sl
        ..registerLazySingleton<GetAccountOptions>(() => GetAccountOptions(repository))
        ..registerLazySingleton<GetTreasuryAccounts>(() => GetTreasuryAccounts(repository));
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
      final automatic = find.text('تلقائي — الخزنة الرئيسية').evaluate().length;

      // Act
      await tester.tap(find.byType(AppDropdown<AccountOption>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('خزنة فرع مصراتة').last);
      await tester.pumpAndSettle();

      // Assert — no bank among them, and the pick still travels as the id the server reads
      expect(find.text('المصرف'), findsNothing);
      expect(automatic, 1);
      expect(reported, ['9']);
    });
  });

  group('the account picker on a payment form', () {
    testWidgets('it steps aside when the treasury is not there', (tester) async {
      // Arrange — nothing registered, as in every older test of the payment sheet.
      final picker = TreasuryAccountPicker(method: 'cash', value: null, onChanged: (_) {});

      // Act
      await tester.pumpWidget(host(picker));
      await tester.pump();

      // Assert
      expect(find.byType(AppDropdown<AccountOption>), findsNothing);
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
            suggestedName: 'مصرف علي',
          ),
        ),
      );
      sl
        ..registerLazySingleton<GetAccountOptions>(() => GetAccountOptions(repository))
        ..registerLazySingleton<GetTreasuryAccounts>(() => GetTreasuryAccounts(repository));
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
      final automatic = find.text('تلقائي — مصرف علي').evaluate().length;

      // Act
      await tester.tap(find.byType(AppDropdown<AccountOption>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('المصرف').last);
      await tester.pumpAndSettle();

      // Assert — the server's pick is named on «تلقائي», so nobody has to guess where it lands
      expect(automatic, 1);
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
      // الخادم يصرف من نقد المسجِّل أولاً، و`suggested_name` يسمّيه.
      when(() => repository.accountOptions(method: 'cash', incoming: false)).thenAnswer(
        (_) async => const Right<Failure, AccountOptions>(
          AccountOptions(accounts: [], suggestedId: 1, suggestedName: 'الخزنة الرئيسية'),
        ),
      );
      sl
        ..registerLazySingleton<GetTreasuryAccounts>(() => GetTreasuryAccounts(repository))
        ..registerLazySingleton<GetAccountOptions>(() => GetAccountOptions(repository));
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
      final automatic = find.text('تلقائي — الخزنة الرئيسية').evaluate().length;

      // Act
      await tester.tap(find.byType(AppDropdown<AccountOption>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('المصرف').last);
      await tester.pumpAndSettle();

      // Assert
      expect(automatic, 1);
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
      // Arrange
      const held = '1250.00';
      const overdrawn = '-8450.50';
      const moved = '50.00';

      // Act
      final heldText = treasuryMoney(held);
      final overdrawnText = treasuryMoney(overdrawn);
      final movedText = treasuryMoney(moved, signed: true);

      // Assert
      expect(heldText, '1,250 د.ل');
      expect(overdrawnText, '−8,450.5 د.ل');
      expect(movedText, '+50 د.ل');
    });
  });

  group('«علينا» — what is owed (§٢٠)', () {
    TreasuryAccount account({
      required int id,
      required String name,
      required AccountKind kind,
      String balance = '0.00',
      int? vendorId,
    }) => TreasuryAccount(
      id: id,
      name: name,
      kind: kind,
      kindLabel: kind.wire,
      isDefault: false,
      isActive: true,
      isSystem: false,
      isSpendable: kind == AccountKind.cash || kind == AccountKind.bank,
      isPayable: kind == AccountKind.payable,
      vendorId: vendorId,
      balance: balance,
    );

    test('a debt reads as what is owed, never as a red minus', () {
      // Act
      final loan = TreasuryAccount.fromJson({
        'id': 7,
        'name': 'قرض المالك',
        'kind': 'payable',
        'kind_label': 'التزام',
        'is_spendable': false,
        'is_payable': true,
        'vendor_id': null,
        'balance': '-1000.00',
      });
      final overpaid = account(id: 8, name: 'المؤجر', kind: AccountKind.payable, balance: '50.00');

      // Assert
      expect(loan.kind, AccountKind.payable);
      expect(loan.isVendorPayable, isFalse);
      expect(loan.owed, '1000.00');
      expect(loan.isOverdrawn, isFalse);
      expect(treasuryBalanceLabel(loan), 'علينا 1,000 د.ل');
      expect(overpaid.isOverdrawn, isTrue);
      expect(treasuryBalanceLabel(overpaid), 'لنا عنده 50 د.ل');
    });

    test('the totals keep what is owed apart from the money', () {
      // Act
      final accounts = TreasuryAccounts.fromJson({
        'accounts': const [],
        'total': '1000.00',
        'payables_total': '1000.00',
        'can_view_all': true,
      });
      final ownership = TreasuryOwnership.fromJson({
        'total_held': '1000.00',
        'investors': const [],
        'investors_total': '0.00',
        'fund_cash': '0.00',
        'payables_total': '1000.00',
        'company_own': '0.00',
      });

      // Assert
      expect(accounts.total, '1000.00');
      expect(accounts.payablesTotal, '1000.00');
      expect(ownership.payablesTotal, '1000.00');
      expect(ownership.companyOwn, '0.00');
    });

    test('a vendor\'s account reads what was ordered, paid and credited, and its statement', () {
      // Act
      final vendor = VendorAccount.fromJson({
        'summary': {
          'ordered': '1300.00',
          'opening_debt': '0.00',
          'paid': '600.00',
          'credited': '150.00',
          'owed': '550.00',
        },
        'treasury_account_id': 12,
        'payments': [
          {'id': 3, 'type': 'credit', 'type_label': 'خصم من المورد', 'amount': '150.00'},
        ],
      });

      // Assert
      expect(vendor.owed, '550.00');
      expect(vendor.credited, '150.00');
      expect(vendor.treasuryAccountId, 12);
      expect(vendor.payments.single.type, 'credit');
    });

    testWidgets('a transfer offers a loan to borrow from, never a vendor\'s account', (tester) async {
      // Arrange
      final accounts = [
        account(id: 1, name: 'الخزنة الرئيسية', kind: AccountKind.cash, balance: '500.00'),
        account(id: 7, name: 'قرض المالك', kind: AccountKind.payable, balance: '-1000.00'),
        account(id: 9, name: 'مطبعة النور', kind: AccountKind.payable, balance: '-300.00', vendorId: 4),
      ];

      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showTreasuryOperationSheet(
                context: context,
                kind: OperationKind.transfer,
                accounts: accounts,
                onSubmit:
                    ({
                      required kind,
                      amount,
                      fromAccountId,
                      toAccountId,
                      categoryId,
                      employeeId,
                      countedBalance,
                      notes,
                      clientToken,
                    }) async => null,
              ),
              child: const Text('افتح'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('من حساب'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('قرض المالك — علينا'), findsWidgets);
      expect(find.textContaining('مطبعة النور'), findsNothing);
    });

    testWidgets('opened from an account, a transfer leaves from it and asks only where to', (
      tester,
    ) async {
      // Arrange — opened from «المصرف»
      final bank = account(id: 2, name: 'المصرف', kind: AccountKind.bank, balance: '900.00');
      final accounts = [
        account(id: 1, name: 'الخزنة الرئيسية', kind: AccountKind.cash, balance: '500.00'),
        bank,
      ];
      int? sentFrom;
      int? sentTo;

      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showTreasuryOperationSheet(
                context: context,
                kind: OperationKind.transfer,
                accounts: accounts,
                account: bank,
                onSubmit:
                    ({
                      required kind,
                      amount,
                      fromAccountId,
                      toAccountId,
                      categoryId,
                      employeeId,
                      countedBalance,
                      notes,
                      clientToken,
                    }) async {
                      sentFrom = fromAccountId;
                      sentTo = toAccountId;
                      return null;
                    },
              ),
              child: const Text('افتح'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Act — the bank is fixed; pick the cash box as the destination and send
      await tester.tap(find.text('إلى حساب'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('الخزنة الرئيسية').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'المبلغ'), '100');
      await tester.tap(find.text('تسجيل تحويل'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const ValueKey('locked-account')), findsNothing); // the sheet closed
      expect(sentFrom, 2);
      expect(sentTo, 1);

      // The success snack holds a three-second timer: run it out, then let its exit settle —
      // the order purchase_order_form_funding_test.dart explains.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('the vendor\'s screen shows what is owed, and the statement only to the treasury', (
      tester,
    ) async {
      // Arrange — allowed the vendor's payments, not the treasury
      final repository = _MockTreasuryRepository();
      when(() => repository.vendorAccount(4)).thenAnswer(
        (_) async => const Right<Failure, VendorAccount>(
          VendorAccount(
            ordered: '1000.00',
            openingDebt: '0.00',
            paid: '400.00',
            credited: '0.00',
            owed: '600.00',
            payments: [],
            treasuryAccountId: 12,
          ),
        ),
      );
      sl
        ..registerLazySingleton<GetVendorAccount>(() => GetVendorAccount(repository))
        ..registerSingleton<Session>(
          Session()..adopt(
            const AuthUser(
              id: 1,
              name: 'علي',
              phone: '0911234567',
              permissions: ['vendors.payments.view'],
            ),
          ),
        );

      // Act
      await tester.pumpWidget(host(const VendorAccountSection(vendorId: 4)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('الحساب مع المورد'), findsOneWidget);
      expect(find.text('600 د.ل'), findsOneWidget);
      expect(find.text('كشف الحساب'), findsNothing);
    });
  });
}
