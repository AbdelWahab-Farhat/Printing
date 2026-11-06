<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\EmployeeWallet\Queries\EmployeeWalletBalances;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\Queries\WalletBalances;
use Illuminate\Console\Command;

/**
 * Proves the wallets and the treasury agree — Docs/payments/CUSTOMER-WALLET.md §٣ and
 * Docs/employees/EMPLOYEE-WALLET-DESIGN.md §٤.
 *
 * Two facts, for the customers' wallets and for the employees', each of which every path is built
 * to keep:
 *
 * 1. The payable equals minus the sum of its wallets — what the books say is owed is what the
 *    wallets say they hold.
 * 2. No wallet is below zero — a wallet never holds debt.
 *
 * Read-only. Fails (exit 1) and names the gap when either is broken, so a scheduler or a person
 * notices the day it happens rather than the day a customer asks.
 */
class CheckWallets extends Command
{
    protected $signature = 'wallets:check';

    protected $description = 'Check that customer and employee wallets agree with their payables, and no wallet is negative';

    public function handle(WalletBalances $customers, EmployeeWalletBalances $employees, TreasuryService $treasury): int
    {
        $customersAgree = $this->check(
            $treasury,
            TreasuryAccount::CUSTOMER_WALLETS,
            'أرصدة محافظ الزبائن',
            $customers->total(),
            $customers->negative(),
            'محفظة العميل',
        );

        $employeesAgree = $this->check(
            $treasury,
            TreasuryAccount::EMPLOYEE_WALLETS,
            'أرصدة محافظ الموظفين',
            $employees->total(),
            $employees->negative(),
            'محفظة الموظف',
        );

        return $customersAgree && $employeesAgree ? self::SUCCESS : self::FAILURE;
    }

    /**
     * @param  array<int, string>  $negative  owner id => balance
     */
    private function check(
        TreasuryService $treasury,
        string $systemCode,
        string $payableName,
        string $wallets,
        array $negative,
        string $walletName,
    ): bool {
        $payableId = TreasuryAccount::query()->where('system_code', $systemCode)->value('id');
        $payable = $payableId === null ? '0.00' : $treasury->balanceOf(TreasuryAccount::query()->findOrFail($payableId));

        $owed = bcmul($payable, '-1', 2);
        $ok = true;

        if (bccomp($wallets, $owed, 2) !== 0) {
            $ok = false;
            $this->error("المحافظ تحمل {$wallets} و«{$payableName}» تقول {$owed} — الفرق ".bcsub($wallets, $owed, 2));
        }

        foreach ($negative as $ownerId => $balance) {
            $ok = false;
            $this->error("{$walletName} #{$ownerId} تحت الصفر: {$balance}");
        }

        if ($ok) {
            $this->info("«{$payableName}» والمحافظ متطابقان: {$wallets}");
        }

        return $ok;
    }
}
