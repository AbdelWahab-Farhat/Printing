<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Queries;

use App\Domain\EmployeeWallet\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * ما تحمله كل محفظة — مجموعُ سطورها، لا رقماً محفوظاً.
 *
 * العكسُ لا اتجاه له من نفسه، فالاستعلام يقرأ نوع السطر الذي يعكسه بربطٍ على الجدول نفسه. استعلامٌ
 * مجمَّعٌ واحد لأيّ عددٍ من الموظفين.
 */
final class EmployeeWalletBalances
{
    private const CREDITS = "('deposit', 'credit', 'adjustment_credit')";

    private const DEBITS = "('withdrawal', 'adjustment_debit')";

    /**
     * @param  list<int>  $userIds
     * @return array<int, string> رقم الموظف => الرصيد، وكلُّ من سُئل عنه موجود
     */
    public function forUsers(array $userIds): array
    {
        if ($userIds === []) {
            return [];
        }

        $rows = DB::table('employee_wallet_entries as e')
            ->leftJoin('employee_wallet_entries as o', 'o.id', '=', 'e.reverses_entry_id')
            ->whereNull('e.deleted_at')
            ->whereIn('e.user_id', $userIds)
            ->groupBy('e.user_id')
            ->selectRaw('e.user_id, '.self::signedSum().' AS balance')
            ->pluck('balance', 'user_id');

        $balances = [];

        foreach ($userIds as $id) {
            $balances[$id] = Money::round((string) ($rows[$id] ?? '0'));
        }

        return $balances;
    }

    public function of(int $userId): string
    {
        return $this->forUsers([$userId])[$userId];
    }

    /** كلُّ المحافظ معاً — ما على الشركة لموظفيها. لـ`wallets:check`. */
    public function total(): string
    {
        $total = DB::table('employee_wallet_entries as e')
            ->leftJoin('employee_wallet_entries as o', 'o.id', '=', 'e.reverses_entry_id')
            ->whereNull('e.deleted_at')
            ->selectRaw(self::signedSum().' AS total')
            ->value('total');

        return Money::round((string) ($total ?? '0'));
    }

    /**
     * الموظفون الذين رصيدهم تحت الصفر — ولا طريق يصنع ذلك. لـ`wallets:check`.
     *
     * @return array<int, string> رقم الموظف => الرصيد
     */
    public function negative(): array
    {
        return DB::table('employee_wallet_entries as e')
            ->leftJoin('employee_wallet_entries as o', 'o.id', '=', 'e.reverses_entry_id')
            ->whereNull('e.deleted_at')
            ->groupBy('e.user_id')
            ->havingRaw(self::signedSum().' < 0')
            ->selectRaw('e.user_id, '.self::signedSum().' AS balance')
            ->pluck('balance', 'user_id')
            ->map(fn ($balance) => Money::round((string) $balance))
            ->all();
    }

    private static function signedSum(): string
    {
        return 'COALESCE(SUM(CASE'
            .' WHEN e.type IN '.self::CREDITS.' THEN e.amount'
            .' WHEN e.type IN '.self::DEBITS.' THEN -e.amount'
            .' WHEN o.type IN '.self::CREDITS.' THEN -e.amount'
            .' ELSE e.amount END), 0)';
    }
}
