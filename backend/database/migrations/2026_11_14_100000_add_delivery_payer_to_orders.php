<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Who pays the courier's fee, per order — and, when we do, what it costs us.
 *
 * **Every existing order becomes `recipient` with a cost of 0**, which is exactly what they were:
 * delivery has been the customer's alone since 2026-09-08. See Docs/orders/DELIVERY-PAYER.md.
 *
 * **One exception, by the owner's decision (2026-11-14):** an order still on the road whose
 * open Nawris parcel someone at Nawris already switched to "we pay" (`shipment_on_sender = 2`)
 * becomes `us`. From now on the order says who pays and every edit we send repeats it; left as
 * `recipient`, the next payment on such an order would quietly put the fee back on the customer.
 * Their profit now carries the fee (option B). Delivered, settled and cancelled orders are not
 * touched, whatever their parcel says.
 *
 * The parcel columns record what *we* told Nawris and when — the starting point and our own
 * changes that `ReadNawrisParcelTerms` reads their webhook history against. Null on every parcel
 * dispatched before today, which reads as "the customer pays", as it always did.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('delivery_paid_by', 16)->default('recipient')->after('delivery_price');

            // What delivery costs us: 0 while the recipient pays; the city's fee when we do,
            // until settlement shows what the carrier really kept.
            $table->decimal('delivery_cost', 12, 2)->default(0)->after('delivery_paid_by');
        });

        Schema::table('nawris_parcels', function (Blueprint $table) {
            // Their webhook numbering (1 the customer, 2 us), like `shipment_on_sender`.
            $table->smallInteger('payer_at_dispatch')->nullable()->after('shipment_on_sender');
            $table->smallInteger('payer_sent')->nullable()->after('payer_at_dispatch');
            $table->timestamp('payer_sent_at')->nullable()->after('payer_sent');
        });

        $this->adoptWhatNawrisAlreadyHas();
    }

    public function down(): void
    {
        Schema::table('nawris_parcels', function (Blueprint $table) {
            $table->dropColumn(['payer_at_dispatch', 'payer_sent', 'payer_sent_at']);
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['delivery_paid_by', 'delivery_cost']);
        });
    }

    /**
     * Plain SQL rather than the models: a migration must keep running after the models move on,
     * and no model event belongs in a schema step. The audit trail is skipped for the same
     * reason; the doc names this step as where these orders turned `us`.
     */
    private function adoptWhatNawrisAlreadyHas(): void
    {
        $ids = DB::table('orders as o')
            ->join('nawris_parcel_orders as l', 'l.order_id', '=', 'o.id')
            ->join('nawris_parcels as p', 'p.id', '=', 'l.nawris_parcel_id')
            ->whereNull('l.deleted_at')
            ->whereNull('p.deleted_at')
            ->whereNull('p.closed_at')
            ->whereNull('o.deleted_at')
            ->where('p.shipment_on_sender', 2)
            ->whereNotIn('o.status', ['delivered', 'settled', 'cancelled', 'request_rejected'])
            ->pluck('o.id')
            ->unique()
            ->values()
            ->all();

        if ($ids === []) {
            return;
        }

        DB::table('orders')->whereIn('id', $ids)->update([
            'delivery_paid_by' => 'us',
            'delivery_cost' => DB::raw('delivery_price'),
        ]);
    }
};
