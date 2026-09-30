<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Queries;

use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * The figures on top of an account's page: what came in and went out, by kind.
 *
 * Reversals carry their original's kind with the direction flipped, so each row here is already
 * net — a deposit undone shows as that much less deposited, with nothing special-cased.
 */
final class AccountTotals
{
    /**
     * @return array{
     *     balance: string,
     *     total_in: string,
     *     total_out: string,
     *     by_kind: list<array{kind: string, label: string, in: string, out: string, net: string}>
     * }
     */
    public function of(int $accountId): array
    {
        $rows = DB::table('treasury_movements')
            ->whereNull('deleted_at')
            ->where('account_id', $accountId)
            ->groupBy('kind', 'direction')
            ->selectRaw('kind, direction, SUM(amount) AS total')
            ->get();

        $byKind = [];
        $in = '0';
        $out = '0';

        foreach ($rows as $row) {
            $kind = (string) $row->kind;
            $byKind[$kind] ??= ['in' => '0', 'out' => '0'];
            $byKind[$kind][$row->direction] = bcadd($byKind[$kind][$row->direction], (string) $row->total, 2);

            if ($row->direction === 'in') {
                $in = bcadd($in, (string) $row->total, 2);
            } else {
                $out = bcadd($out, (string) $row->total, 2);
            }
        }

        $list = [];

        // In the enum's order, so the screen reads the same way every time.
        foreach (MovementKind::cases() as $kind) {
            if (! isset($byKind[$kind->value])) {
                continue;
            }

            $list[] = [
                'kind' => $kind->value,
                'label' => $kind->label(),
                'in' => Money::round($byKind[$kind->value]['in']),
                'out' => Money::round($byKind[$kind->value]['out']),
                'net' => Money::round(bcsub($byKind[$kind->value]['in'], $byKind[$kind->value]['out'], 2)),
            ];
        }

        return [
            'balance' => Money::round(bcsub($in, $out, 2)),
            'total_in' => Money::round($in),
            'total_out' => Money::round($out),
            'by_kind' => $list,
        ];
    }
}
