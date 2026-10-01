<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Delivery\Models\City;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * حسابا كاش بدل «الخزنة الرئيسية»: «بريمولا قرجي» و«بريمولا ولي العهد»، كلٌّ مربوطٌ بمكتب استلامه.
 * قرجي هو الافتراضي — الفرعُ الذي سمّاه صاحب العمل افتراضياً (CustomerSeeder::OFFICE_FALLBACK).
 *
 * الترحيل بلا مخطَّط، فيُعاد بـ `down()` ثم `up()` داخل معاملة الاختبار — كما يراه خادمٌ حقيقي.
 *
 * Arrange - Act - Assert throughout.
 */
class BranchCashAccountsMigrationTest extends TestCase
{
    use RefreshDatabase;

    private const MIGRATION = '2026_10_01_100000_split_main_cash_into_pickup_offices';

    private function migration(): object
    {
        return require database_path('migrations/'.self::MIGRATION.'.php');
    }

    private function account(string $name): TreasuryAccount
    {
        return TreasuryAccount::query()->where('name', $name)->firstOrFail();
    }

    /** @return array{0: City, 1: City} */
    private function offices(): array
    {
        return [
            City::factory()->officePickup()->create(['name' => 'إستلام مكتب(قرجي)']),
            City::factory()->officePickup()->create(['name' => 'إستلام مكتب(ولي العهد)']),
        ];
    }

    public function test_a_new_database_has_two_cash_accounts_and_gurji_is_the_default(): void
    {
        // Act
        $cash = TreasuryAccount::query()->where('kind', AccountKind::Cash->value)->orderBy('id')->get();

        // Assert
        $this->assertSame(['بريمولا قرجي', 'بريمولا ولي العهد'], $cash->pluck('name')->all());
        $this->assertSame([true, false], $cash->pluck('is_default')->map(fn ($v) => (bool) $v)->all());
        $this->assertSame('كاش', AccountKind::Cash->label());
    }

    public function test_each_account_is_linked_to_its_pickup_office(): void
    {
        // Arrange — قاعدةٌ فيها خريطة التوصيل قبل الترحيل، كالخادم وجهاز المطوّر.
        $this->migration()->down();
        [$gurji, $waliAlAhd] = $this->offices();

        // Act
        $this->migration()->up();

        // Assert
        $this->assertSame((int) $gurji->id, (int) $this->account('بريمولا قرجي')->pickup_city_id);
        $this->assertSame((int) $waliAlAhd->id, (int) $this->account('بريمولا ولي العهد')->pickup_city_id);
    }

    public function test_the_main_cash_account_becomes_gurji_and_keeps_its_history(): void
    {
        // Arrange
        $this->migration()->down();
        $main = $this->account('الخزنة الرئيسية');

        // Act
        $this->migration()->up();

        // Assert — الحسابُ نفسُه بحركاته، لا حسابٌ جديد بجانبه.
        $this->assertSame((int) $main->id, (int) $this->account('بريمولا قرجي')->id);
        $this->assertTrue((bool) $this->account('بريمولا قرجي')->is_default);
        $this->assertSame(0, TreasuryAccount::query()->where('name', 'الخزنة الرئيسية')->count());
    }

    public function test_an_office_that_already_has_its_cash_is_left_alone(): void
    {
        // Arrange
        $this->migration()->down();
        [$gurji] = $this->offices();
        $existing = TreasuryAccount::factory()->kind(AccountKind::Cash)->create([
            'name' => 'درج المكتب', 'pickup_city_id' => $gurji->id,
        ]);

        // Act
        $this->migration()->up();

        // Assert
        $this->assertSame((int) $gurji->id, (int) $existing->fresh()->pickup_city_id);
        $this->assertNull($this->account('بريمولا قرجي')->pickup_city_id);
    }

    public function test_down_puts_the_single_main_cash_back(): void
    {
        // Arrange
        $this->offices();

        // Act
        $this->migration()->down();

        // Assert
        $cash = DB::table('treasury_accounts')->where('kind', 'cash')->whereNull('deleted_at')->get();
        $this->assertSame(['الخزنة الرئيسية'], $cash->pluck('name')->all());
        $this->assertNull($cash->first()->pickup_city_id);
    }
}
