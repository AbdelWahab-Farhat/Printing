import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart' show Currency;
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «الحساب مع المورد» on a vendor's screen — what the company owes them across every order, and
/// a way into the statement. TREASURY-DESIGN §٢٠.
///
/// **Its own request, its own grant**, like the purchase order's payments: it draws nothing for
/// somebody without `vendors.payments.view`, and «كشف الحساب» only for `treasury.view`, which the
/// statement page asks for.
class VendorAccountSection extends StatefulWidget {
  const VendorAccountSection({required this.vendorId, super.key});

  final int vendorId;

  @override
  State<VendorAccountSection> createState() => _VendorAccountSectionState();
}

class _VendorAccountSectionState extends State<VendorAccountSection> {
  VendorAccount? _account;

  bool get _canView =>
      sl.isRegistered<Session>() && sl<Session>().can(AppPermission.viewVendorPayments);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!_canView || !sl.isRegistered<GetVendorAccount>()) return;

    final result = await sl<GetVendorAccount>()(widget.vendorId);

    if (!mounted) return;

    result.fold((_) {}, (account) => setState(() => _account = account));
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;

    if (account == null) return const SizedBox.shrink();

    final statement = account.treasuryAccountId;
    final canReadStatement = sl<Session>().can(AppPermission.viewTreasury);

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TreasuryFiguresCard(
            title: 'الحساب مع المورد',
            icon: AppIcons.payable,
            lines: [
              ('أوامر الشراء', account.ordered),
              if (account.openingDebt != '0.00') ('دَين افتتاحي', account.openingDebt),
              ('المدفوع', account.paid),
              if (account.credited != '0.00') ('خصم من المورد', account.credited),
              if (account.paidOnOldOrders != '0.00')
                ('مدفوع على أوامر قبل النظام', account.paidOnOldOrders),
            ],
            emphasis: ('المستحق له', account.owed),
          ),
          if (statement != null && canReadStatement) ...[
            SizedBox(height: 8.h),
            AppButton.tonal(
              label: 'كشف الحساب',
              icon: AppIcons.treasury,
              onPressed: () => _open(statement),
            ),
          ],
          // The dollar «علينا» apart — added to the card above it would read dollars as dinars.
          // USD-ACCOUNTS.md §٤.
          if (account.dollarTreasuryAccountId case final dollars?) ...[
            SizedBox(height: 14.h),
            TreasuryFiguresCard(
              key: const ValueKey('vendor-dollar-account'),
              title: 'الحساب مع المورد بالدولار',
              icon: AppIcons.exchange,
              currency: Currency.usd,
              lines: [
                ('أوامر الشراء', account.dollars.ordered),
                if (account.dollars.openingDebt != '0.00')
                  ('دَين افتتاحي', account.dollars.openingDebt),
                ('المدفوع', account.dollars.paid),
                if (account.dollars.credited != '0.00')
                  ('خصم من المورد', account.dollars.credited),
              ],
              emphasis: ('المستحق له', account.dollarsOwed),
            ),
            if (canReadStatement) ...[
              SizedBox(height: 8.h),
              AppButton.tonal(
                label: 'كشف الحساب بالدولار',
                icon: AppIcons.treasury,
                onPressed: () => _open(dollars),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _open(int accountId) async {
    await context.push(Routes.treasuryAccount(accountId));

    unawaited(_load());
  }
}
