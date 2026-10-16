<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\Queries\WalletBalances;
use Illuminate\Console\Command;

/**
 * Proves the wallets and the treasury agree — Docs/payments/CUSTOMER-WALLET.md §٣.
 *
 * Two facts, each of which every path is built to keep:
 *
 * 1. «أرصدة محافظ الزبائن» equals minus the sum of every wallet — what the books say the shop owes
 *    its customers is what the wallets say they hold.
 * 2. No wallet is below zero — a wallet never holds debt.
 *
 * Read-only. Fails (exit 1) and names the gap when either is broken, so a scheduler or a person
 * notices the day it happens rather than the day a customer asks.
 */
class CheckWallets extends Command
{
    protected $signature = 'wallets:check';

    protected $description = 'Check that customer wallets and «أرصدة محافظ الزبائن» agree, and no wallet is negative';

    public function handle(WalletBalances $balances, TreasuryService $treasury): int
    {
        $wallets = $balances->total();

        $payableId = TreasuryAccount::query()->where('system_code', TreasuryAccount::CUSTOMER_WALLETS)->value('id');
        $payable = $payableId === null ? '0.00' : $treasury->balanceOf(TreasuryAccount::query()->findOrFail($payableId));

        $owed = bcmul($payable, '-1', 2);
        $ok = true;

        if (bccomp($wallets, $owed, 2) !== 0) {
            $ok = false;
            $this->error("المحافظ تحمل {$wallets} و«أرصدة محافظ الزبائن» تقول {$owed} — الفرق ".bcsub($wallets, $owed, 2));
        }

        foreach ($balances->negative() as $customerId => $balance) {
            $ok = false;
            $this->error("محفظة العميل #{$customerId} تحت الصفر: {$balance}");
        }

        if ($ok) {
            $this->info("المحافظ والحسابات متطابقة: {$wallets}");
        }

        return $ok ? self::SUCCESS : self::FAILURE;
    }
}
