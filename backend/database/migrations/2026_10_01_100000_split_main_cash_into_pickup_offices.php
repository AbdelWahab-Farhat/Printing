<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * حسابا كاش بدل «الخزنة الرئيسية»: «بريمولا قرجي» و«بريمولا ولي العهد»، كلٌّ مربوطٌ بمكتب
 * استلامه (TREASURY-DESIGN §١٩) — طلب صاحب العمل، ٢٠٢٦-١٠-٠١. و«خزنة» صارت «كاش» على الشاشة،
 * فالاسم القديم يذهب معها.
 *
 * - **قرجي هو «الخزنة الرئيسية» نفسُها** بعد إعادة التسمية: حركاتُها وحاملُها وكونُها افتراضيةَ
 *   الكاش تبقى. قرجي لأنه الفرع الذي سمّاه صاحب العمل افتراضياً (CustomerSeeder::OFFICE_FALLBACK).
 * - **ولي العهد حسابٌ جديد** غير افتراضي — افتراضيٌّ واحدٌ لكل نوع (فهرس فريد).
 * - **الربط بالمكتب باسمه في خريطة التوصيل**، ما لم يُربط بالمكتب حسابٌ آخر. قاعدةٌ جديدة تُرحَّل
 *   قبل أن تُزرع الخريطة فلا تجد المكتب، ويُربط عندها من «إعدادات المالية».
 */
return new class extends Migration
{
    private const OLD_MAIN = 'الخزنة الرئيسية';

    private const GURJI = 'بريمولا قرجي';

    private const WALI_AL_AHD = 'بريمولا ولي العهد';

    /** @var array<string, string> the account => the pickup office it serves */
    private const OFFICES = [
        self::GURJI => 'إستلام مكتب(قرجي)',
        self::WALI_AL_AHD => 'إستلام مكتب(ولي العهد)',
    ];

    public function up(): void
    {
        $now = now();

        $this->cash()->where('name', self::OLD_MAIN)->update(['name' => self::GURJI, 'updated_at' => $now]);

        foreach (self::OFFICES as $account => $office) {
            if (! $this->cash()->where('name', $account)->exists()) {
                DB::table('treasury_accounts')->insert([
                    'name' => $account,
                    'kind' => 'cash',
                    'currency' => 'LYD',
                    // Gurji inserted here means the main account was renamed by hand and keeps
                    // being the default; one default per kind.
                    'is_default' => false,
                    'is_active' => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }

            $this->link($account, $office, $now);
        }
    }

    public function down(): void
    {
        $now = now();

        // ولي العهد يذهب ما لم يتحرّك؛ حسابٌ عليه حركاتٌ سجلٌّ لا يُطوى بترحيل.
        $this->cash()->where('name', self::WALI_AL_AHD)
            ->whereNotExists(fn ($q) => $q->selectRaw('1')->from('treasury_movements')
                ->whereColumn('treasury_movements.account_id', 'treasury_accounts.id'))
            ->update(['pickup_city_id' => null, 'is_active' => false, 'deleted_at' => $now, 'updated_at' => $now]);

        $this->cash()->where('name', self::GURJI)
            ->update(['name' => self::OLD_MAIN, 'pickup_city_id' => null, 'updated_at' => $now]);
    }

    private function cash(): Builder
    {
        return DB::table('treasury_accounts')->where('kind', 'cash')->whereNull('deleted_at');
    }

    private function link(string $account, string $office, DateTimeInterface $now): void
    {
        $cityId = DB::table('cities')
            ->where('name', $office)
            ->where('fulfilment_type', 'office_pickup')
            ->whereNull('deleted_at')
            ->value('id');

        // مكتبٌ له كاشُه من قبل يبقى عليه: «تلقائي» لا يكون له جوابان.
        if ($cityId === null || DB::table('treasury_accounts')->where('pickup_city_id', $cityId)->whereNull('deleted_at')->exists()) {
            return;
        }

        $this->cash()->where('name', $account)->whereNull('pickup_city_id')
            ->update(['pickup_city_id' => $cityId, 'updated_at' => $now]);
    }
};
