<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Carrier\Actions\ApplyNawrisStatus;
use App\Domain\Carrier\Actions\ReadNawrisParcelTerms;
use App\Domain\Carrier\Models\NawrisParcel;
use Illuminate\Console\Command;
use Illuminate\Console\ConfirmableTrait;

/**
 * Fills `carrier_fee` and `shipment_on_sender` on parcels from the webhooks they already stored.
 *
 * **Only a reading, and only for the record.** {@see ApplyNawrisStatus} reads both facts afresh
 * from the history on every event, so payments never depend on this having run. What it fills is
 * what the parcel shows for the ones that will hear nothing more — those already delivered or
 * returned.
 *
 * **Reports by default and writes nothing.** `--write` saves; outside local it asks first, like
 * every command here that touches rows. Past payments are left exactly as they are — by the owner's
 * decision, 2026-10-22 — so this never touches an order. Re-running it changes nothing.
 */
class ReadNawrisCarrierTerms extends Command
{
    use ConfirmableTrait;

    protected $signature = 'nawris:read-carrier-terms
                            {--write : Save what was read; without it nothing is written}
                            {--force : Skip the confirmation prompt outside local}';

    protected $description = 'Read each Nawris parcel\'s fee and who pays it from its stored webhooks';

    public function handle(ReadNawrisParcelTerms $read): int
    {
        $write = (bool) $this->option('write');

        if ($write && ! $this->confirmToProceed()) {
            return self::FAILURE;
        }

        $rows = [];
        $changed = 0;
        $unknown = 0;

        NawrisParcel::query()->orderBy('id')->each(function (NawrisParcel $parcel) use ($read, $write, &$rows, &$changed, &$unknown): void {
            $terms = $read($parcel);

            if ($terms->fee === null) {
                $unknown++;
            }

            $differs = $this->differs($parcel->carrier_fee, $terms->fee)
                || $parcel->shipment_on_sender !== $terms->shipmentOnSender;

            if ($differs) {
                $changed++;

                if ($write) {
                    $parcel->forceFill([
                        'carrier_fee' => $terms->fee,
                        'shipment_on_sender' => $terms->shipmentOnSender,
                    ])->save();
                }
            }

            $rows[] = [
                $parcel->code,
                (string) $parcel->amount_to_collect,
                $terms->fee ?? '—',
                $terms->shipmentOnSender,
                $parcel->remote_status_text ?? '—',
            ];
        });

        $this->table(['الطرد', 'المطلوب', 'أجرة نورس', 'من يدفعها', 'حالة نورس'], $rows);

        $this->info($write
            ? "تم: {$changed} طرد كُتبت قيمه"
            : "تجربة: {$changed} طرد ستُكتب قيمه — أعد التشغيل مع --write للحفظ");

        if ($unknown > 0) {
            $this->warn("{$unknown} طرد بلا أجرة معروفة — دفعة تسليمه تُدخل يدوياً");
        }

        return self::SUCCESS;
    }

    private function differs(mixed $stored, ?string $read): bool
    {
        if ($stored === null || $read === null) {
            return $stored !== $read;
        }

        return bccomp((string) $stored, $read, 2) !== 0;
    }
}
