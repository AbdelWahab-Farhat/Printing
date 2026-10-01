import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:mocktail/mocktail.dart';

/// ما تتقاسمه اختبارات الخزينة: المستودع المزيّف، والحسابات الأربعة التي تزرعها الـ migration
/// ومعها «مصرف علي».
class MockTreasuryRepository extends Mock implements TreasuryRepository {}

const cashBox = TreasuryAccount(
  id: 1,
  name: 'الخزنة الرئيسية',
  kind: AccountKind.cash,
  kindLabel: 'خزنة',
  isDefault: true,
  isActive: true,
  isSystem: false,
  isSpendable: true,
  balance: '100.00',
);

const bank = TreasuryAccount(
  id: 2,
  name: 'المصرف',
  kind: AccountKind.bank,
  kindLabel: 'مصرف',
  isDefault: true,
  isActive: true,
  isSystem: false,
  isSpendable: true,
  balance: '0.00',
);

const nawris = TreasuryAccount(
  id: 4,
  name: 'النورس',
  kind: AccountKind.custody,
  kindLabel: 'عهدة',
  isDefault: false,
  isActive: true,
  isSystem: true,
  isSpendable: false,
  balance: '0.00',
);

const alisBank = TreasuryAccount(
  id: 5,
  name: 'مصرف علي',
  kind: AccountKind.bank,
  kindLabel: 'مصرف',
  isDefault: false,
  isActive: true,
  isSystem: false,
  isSpendable: true,
  balance: '300.00',
);

const everyAccount = TreasuryAccounts(
  accounts: [cashBox, bank, alisBank, nawris],
  total: '400.00',
  canViewAll: true,
);

const ownership = TreasuryOwnership(
  totalHeld: '400.00',
  investors: [InvestorHolding(id: 1, name: 'سالم', capital: '100.00', profit: '20.50')],
  investorsTotal: '120.50',
  fundCash: '50.00',
  companyOwn: '229.50',
);

const inventory = InventoryValue(
  total: '900.00',
  company: '600.00',
  fund: '300.00',
  byWarehouse: [ValueLine(name: 'المخزن الرئيسي', value: '900.00')],
  topItems: [ValueLine(name: 'كيس 25*35', value: '450.00')],
);

/// سطرٌ من سجلّ حساب، بما يكفي الاختبار أن يقوله.
TreasuryMovement movement({
  required int id,
  String kind = 'deposit',
  String kindLabel = 'إيداع',
  bool isIn = true,
  String signedAmount = '50.00',
  String? balanceAfter = '150.00',
  int? operationId = 30,
  int? orderId,
  bool isReversal = false,
  bool isReversible = true,
  int? reversesMovementId,
  DateTime? occurredAt,
}) => TreasuryMovement(
  id: id,
  kind: kind,
  kindLabel: kindLabel,
  isIn: isIn,
  signedAmount: signedAmount,
  isReversal: isReversal,
  isReversible: isReversible,
  reversesMovementId: reversesMovementId,
  balanceAfter: balanceAfter,
  occurredAt: occurredAt ?? DateTime(2026, 9, 30, 10),
  orderId: orderId,
  operationId: operationId,
);

/// صفحةٌ واحدة من [items].
Paginated<T> pageOf<T>(List<T> items, {int currentPage = 1, int lastPage = 1}) => Paginated<T>(
  items: items,
  meta: PageMeta(
    currentPage: currentPage,
    perPage: 20,
    lastPage: lastPage,
    total: items.length,
  ),
);
