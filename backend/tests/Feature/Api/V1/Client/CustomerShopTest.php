<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Customer\Models\BusinessField;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerShop;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * «متاجري» — متاجر العميل يضيفها ويعدّلها ويحذفها من التطبيق، وعددُها ما يشاء.
 *
 * **لا مُعرِّفَ عميلٍ في أيّ مسارٍ هنا، وذلك هو الأمان.** المُعرِّف الوحيد في المسار مُعرِّفُ المتجر،
 * ويُبحث عنه من خلال متاجر صاحب التوكن لا في الجدول كلّه — فمتجرُ غيره 404 لا صفٌّ يُفحص بعد
 * جلبه. الاختبارات التي تحمل «another_customers» في أسمائها هي ما يقوم مقام `scoped()` هنا.
 *
 * Arrange - Act - Assert throughout.
 */
class CustomerShopTest extends TestCase
{
    use RefreshDatabase;

    private function customer(string $phone = '0911111111'): Customer
    {
        return Customer::factory()->registered()->create(['phone' => $phone]);
    }

    /**
     * @return array<string, string>
     */
    private function bearerFor(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    // ─────────────────────────── القائمة ───────────────────────────

    public function test_the_list_shows_only_my_own_shops(): void
    {
        // Arrange
        $me = $this->customer();
        CustomerShop::factory()->count(2)->create(['customer_id' => $me->id]);
        $theirs = CustomerShop::factory()->create([
            'customer_id' => $this->customer('0922222222')->id,
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/shops');

        // Assert
        $response->assertOk()->assertJsonPath('status', true)->assertJsonCount(2, 'data');
        $this->assertNotContains($theirs->id, array_column((array) $response->json('data'), 'id'));
    }

    /**
     * الأول هو الذي فُتح به الحساب، و«حسابي» تسمّيه في بطاقتها — فالقائمة لا تقلب ترتيبه.
     */
    public function test_the_list_keeps_the_order_the_shops_were_added_in(): void
    {
        // Arrange
        $me = $this->customer();
        $first = CustomerShop::factory()->create(['customer_id' => $me->id]);
        $second = CustomerShop::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/shops');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.id', $first->id)
            ->assertJsonPath('data.1.id', $second->id);
    }

    public function test_each_shop_carries_the_names_of_its_city_and_region(): void
    {
        // Arrange
        $me = $this->customer();
        $city = City::factory()->create(['name' => 'بنغازي']);
        $region = Region::factory()->create(['city_id' => $city->id, 'name' => 'الكيش']);
        CustomerShop::factory()->inRegion($region)->create([
            'customer_id' => $me->id,
            'name' => 'متجر النور',
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/shops');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.name', 'متجر النور')
            ->assertJsonPath('data.0.city_id', $city->id)
            ->assertJsonPath('data.0.city_name', 'بنغازي')
            ->assertJsonPath('data.0.region_id', $region->id)
            ->assertJsonPath('data.0.region_name', 'الكيش');
    }

    public function test_an_account_with_no_shops_gets_an_empty_list_not_an_error(): void
    {
        // Act
        $response = $this->withHeaders($this->bearerFor($this->customer()))
            ->getJson('/api/v1/client/shops');

        // Assert
        $response->assertOk()->assertJsonPath('status', true)->assertJsonCount(0, 'data');
    }

    /**
     * الحقول الأربعة التي في نموذج الموظفين: الاسم، ومجال العمل، والمكان، ورابط الصفحة.
     */
    public function test_each_shop_carries_its_trade_and_its_page(): void
    {
        // Arrange
        $me = $this->customer();
        $field = BusinessField::factory()->named('ملابس وأحذية')->create();
        CustomerShop::factory()->create([
            'customer_id' => $me->id,
            'page_url' => 'https://facebook.com/alnoor',
            'business_field_id' => $field->id,
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/shops');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.business_field_id', $field->id)
            ->assertJsonPath('data.0.business_field_name', 'ملابس وأحذية')
            ->assertJsonPath('data.0.page_url', 'https://facebook.com/alnoor');
    }

    /**
     * الإحداثيات مكانُ أحدٍ على الأرض ولا خريطة في التطبيق، و`customer_id` هو صاحب التوكن نفسه —
     * فلا يغادر أيٌّ منهما الخادم إليه.
     */
    public function test_the_list_never_carries_the_map_pin_or_the_owner(): void
    {
        // Arrange
        $me = $this->customer();
        CustomerShop::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/shops');

        // Assert
        $response->assertOk()
            ->assertJsonMissingPath('data.0.latitude')
            ->assertJsonMissingPath('data.0.longitude')
            ->assertJsonMissingPath('data.0.customer_id');
    }

    // ─────────────────────────── الإضافة ───────────────────────────

    public function test_a_customer_can_add_a_shop(): void
    {
        // Arrange
        $me = $this->customer();
        $city = City::factory()->create(['name' => 'طرابلس']);
        $region = Region::factory()->create(['city_id' => $city->id, 'name' => 'قرجي']);
        $field = BusinessField::factory()->named('عطور')->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/shops', [
            'name' => 'متجر الأمل',
            'business_field_id' => $field->id,
            'city_id' => $city->id,
            'region_id' => $region->id,
            'page_url' => 'https://instagram.com/alamal',
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.name', 'متجر الأمل')
            ->assertJsonPath('data.business_field_name', 'عطور')
            ->assertJsonPath('data.city_name', 'طرابلس')
            ->assertJsonPath('data.region_name', 'قرجي')
            ->assertJsonPath('data.page_url', 'https://instagram.com/alamal');
        $this->assertDatabaseHas('customer_shops', [
            'id' => $response->json('data.id'),
            'customer_id' => $me->id,
            'business_field_id' => $field->id,
            'city_id' => $city->id,
            'region_id' => $region->id,
            'page_url' => 'https://instagram.com/alamal',
        ]);
    }

    /**
     * مجال العمل ورابط الصفحة اختياريان كما في نموذج الموظفين: متجرٌ سُجّل بلا أيٍّ منهما متجرٌ حقيقي.
     */
    public function test_the_trade_and_the_page_are_optional(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/shops', [
            'name' => 'متجر النور',
            'city_id' => City::factory()->create()->id,
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.business_field_id', null)
            ->assertJsonPath('data.business_field_name', null)
            ->assertJsonPath('data.page_url', null);
    }

    /**
     * «أكثر من واحد» — المتجر الجديد يُضاف إلى ما عند العميل، ولا يحلّ محلّه كما تفعل مزامنة
     * نموذج الموظفين.
     */
    public function test_a_second_shop_joins_the_first_rather_than_replacing_it(): void
    {
        // Arrange
        $me = $this->customer();
        $first = CustomerShop::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/shops', [
            'name' => 'الفرع الثاني',
            'city_id' => City::factory()->create()->id,
        ]);

        // Assert
        $response->assertCreated();
        $this->assertSame(2, $me->shops()->count());
        $this->assertNotSoftDeleted('customer_shops', ['id' => $first->id]);
    }

    public function test_a_shop_may_be_added_without_a_region(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/shops', [
            'name' => 'متجر النور',
            'city_id' => City::factory()->create()->id,
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.region_id', null)
            ->assertJsonPath('data.region_name', null);
    }

    public function test_the_new_shop_belongs_to_the_token_not_to_anything_in_the_body(): void
    {
        // Arrange
        $me = $this->customer();
        $someoneElse = $this->customer('0922222222');

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/shops', [
            'customer_id' => $someoneElse->id,
            'name' => 'متجر النور',
            'city_id' => City::factory()->create()->id,
        ]);

        // Assert
        $response->assertCreated();
        $this->assertSame(1, $me->shops()->count());
        $this->assertSame(0, $someoneElse->shops()->count());
    }

    /**
     * @return array<string, array{0: array<string, mixed>, 1: string}>
     */
    public static function invalidShops(): array
    {
        return [
            'no name' => [['name' => ''], 'name'],
            'a name past 255' => [['name' => str_repeat('م', 256)], 'name'],
            'no city' => [['city_id' => null], 'city_id'],
            'a city that does not exist' => [['city_id' => 999999], 'city_id'],
            'a region that does not exist' => [['region_id' => 999999], 'region_id'],
            'a trade that does not exist' => [['business_field_id' => 999999], 'business_field_id'],
            'a page link that is not a link' => [['page_url' => 'صفحتنا على فيسبوك'], 'page_url'],
        ];
    }

    /**
     * @param  array<string, mixed>  $override
     */
    #[DataProvider('invalidShops')]
    public function test_an_incomplete_shop_is_refused(array $override, string $field): void
    {
        // Arrange
        $me = $this->customer();
        $payload = array_merge([
            'name' => 'متجر النور',
            'city_id' => City::factory()->create()->id,
        ], $override);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->postJson('/api/v1/client/shops', $payload);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors($field);
        $this->assertSame(0, $me->shops()->count());
    }

    public function test_the_region_must_be_inside_the_chosen_city(): void
    {
        // Arrange
        $me = $this->customer();
        $city = City::factory()->create();
        $elsewhere = Region::factory()->create(['city_id' => City::factory()->create()->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/shops', [
            'name' => 'متجر النور',
            'city_id' => $city->id,
            'region_id' => $elsewhere->id,
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('region_id');
    }

    public function test_a_city_taken_off_the_map_cannot_be_chosen(): void
    {
        // Arrange
        $me = $this->customer();
        $retired = City::factory()->create();
        $retired->delete();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/shops', [
            'name' => 'متجر النور',
            'city_id' => $retired->id,
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('city_id');
    }

    // ─────────────────────────── التعديل ───────────────────────────

    public function test_a_customer_can_rename_and_move_their_shop(): void
    {
        // Arrange
        $me = $this->customer();
        $shop = CustomerShop::factory()->create(['customer_id' => $me->id, 'name' => 'قديم']);
        $city = City::factory()->create(['name' => 'مصراتة']);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->putJson("/api/v1/client/shops/{$shop->id}", [
                'name' => 'جديد',
                'city_id' => $city->id,
            ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.id', $shop->id)
            ->assertJsonPath('data.name', 'جديد')
            ->assertJsonPath('data.city_name', 'مصراتة');
        $this->assertDatabaseHas('customer_shops', [
            'id' => $shop->id,
            'name' => 'جديد',
            'city_id' => $city->id,
            'region_id' => null,
        ]);
    }

    /**
     * التعديل يرسل المتجر كاملاً كما يعرضه النموذج، فمجال العمل ورابط الصفحة يُستبدلان بما أُرسل —
     * وما أُفرغ في النموذج يُفرغ هنا.
     */
    public function test_an_edit_replaces_the_trade_and_the_page(): void
    {
        // Arrange
        $me = $this->customer();
        $shop = CustomerShop::factory()->create([
            'customer_id' => $me->id,
            'page_url' => 'https://facebook.com/alnoor',
            'business_field_id' => BusinessField::factory()->create()->id,
        ]);
        $perfume = BusinessField::factory()->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->putJson("/api/v1/client/shops/{$shop->id}", [
                'name' => 'متجر النور',
                'business_field_id' => $perfume->id,
                'city_id' => $shop->city_id,
                'page_url' => null,
            ]);

        // Assert
        $response->assertOk();
        $this->assertDatabaseHas('customer_shops', [
            'id' => $shop->id,
            'business_field_id' => $perfume->id,
            'page_url' => null,
        ]);
    }

    /**
     * **الإحداثيات وحدها لا يمسّها تعديلٌ من الهاتف.** لا خريطة في التطبيق فلا يرسلها، وغيابها يعني
     * «لم يُرسَل» لا «امسحه» — القاعدة نفسها التي في `SyncCustomerShops`.
     */
    public function test_editing_from_the_app_keeps_the_map_pin(): void
    {
        // Arrange
        $me = $this->customer();
        $shop = CustomerShop::factory()->create([
            'customer_id' => $me->id,
            'latitude' => 32.8872,
            'longitude' => 13.1913,
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->putJson("/api/v1/client/shops/{$shop->id}", [
                'name' => 'متجر النور',
                'city_id' => $shop->city_id,
            ]);

        // Assert
        $response->assertOk();
        $this->assertDatabaseHas('customer_shops', [
            'id' => $shop->id,
            'latitude' => 32.8872,
            'longitude' => 13.1913,
        ]);
    }

    public function test_another_customers_shop_cannot_be_edited(): void
    {
        // Arrange
        $me = $this->customer();
        $theirs = CustomerShop::factory()->create([
            'customer_id' => $this->customer('0922222222')->id,
            'name' => 'متجرهم',
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->putJson("/api/v1/client/shops/{$theirs->id}", [
                'name' => 'استولى عليه',
                'city_id' => $theirs->city_id,
            ]);

        // Assert — ولا يتغيّر شيءٌ في سجلّ صاحبه.
        $response->assertNotFound();
        $this->assertDatabaseHas('customer_shops', ['id' => $theirs->id, 'name' => 'متجرهم']);
    }

    public function test_an_edit_is_validated_like_an_addition(): void
    {
        // Arrange
        $me = $this->customer();
        $shop = CustomerShop::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->putJson("/api/v1/client/shops/{$shop->id}", ['name' => '']);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['name', 'city_id']);
    }

    // ─────────────────────────── الحذف ───────────────────────────

    public function test_a_customer_can_remove_their_shop(): void
    {
        // Arrange
        $me = $this->customer();
        $shop = CustomerShop::factory()->create(['customer_id' => $me->id]);
        $headers = $this->bearerFor($me);

        // Act
        $response = $this->withHeaders($headers)->deleteJson("/api/v1/client/shops/{$shop->id}");

        // Assert — يُخفى ولا يُمحى: طلبيةٌ ذهبت إليه ما زالت تحمل اسمه.
        $response->assertOk()->assertJsonPath('status', true);
        $this->assertSoftDeleted('customer_shops', ['id' => $shop->id]);
        $this->withHeaders($headers)->getJson('/api/v1/client/shops')->assertJsonCount(0, 'data');
    }

    public function test_another_customers_shop_cannot_be_removed(): void
    {
        // Arrange
        $me = $this->customer();
        $theirs = CustomerShop::factory()->create([
            'customer_id' => $this->customer('0922222222')->id,
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->deleteJson("/api/v1/client/shops/{$theirs->id}");

        // Assert
        $response->assertNotFound();
        $this->assertNotSoftDeleted('customer_shops', ['id' => $theirs->id]);
    }

    // ─────────────────────────── مجالات العمل ───────────────────────────

    /**
     * ما يُعرض في منتقي «مجال العمل»: المجالات المعروضة وحدها، بترتيب المتجر ثم بالاسم — كما
     * يرتّبها منتقي الموظفين.
     */
    public function test_the_trades_on_offer_are_listed_in_the_shops_order(): void
    {
        // Arrange
        $me = $this->customer();
        BusinessField::factory()->named('مطاعم')->create(['sort_order' => 2]);
        BusinessField::factory()->named('ملابس')->create(['sort_order' => 1]);
        BusinessField::factory()->named('عطور')->create(['sort_order' => 1]);
        BusinessField::factory()->named('مقاهي')->inactive()->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->getJson('/api/v1/client/business-fields');

        // Assert
        $response->assertOk()->assertJsonPath('status', true);
        $this->assertSame(['عطور', 'ملابس', 'مطاعم'], array_column((array) $response->json('data'), 'name'));
    }

    public function test_a_trade_carries_its_id_and_name_and_nothing_else(): void
    {
        // Arrange
        $me = $this->customer();
        BusinessField::factory()->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->getJson('/api/v1/client/business-fields');

        // Assert
        $this->assertSame(['id', 'name'], array_keys((array) $response->json('data.0')));
    }

    public function test_the_trades_need_a_customer_token(): void
    {
        // Act
        $response = $this->getJson('/api/v1/client/business-fields');

        // Assert
        $response->assertUnauthorized();
    }

    // ─────────────────────────── الدخول ───────────────────────────

    public function test_shops_need_a_customer_token(): void
    {
        // Act
        $response = $this->getJson('/api/v1/client/shops');

        // Assert
        $response->assertUnauthorized();
    }

    public function test_a_staff_token_cannot_reach_a_customers_shops(): void
    {
        // Arrange
        $staff = ['Authorization' => 'Bearer '.User::factory()->create()->createToken('s')->plainTextToken];

        // Act
        $response = $this->withHeaders($staff)->getJson('/api/v1/client/shops');

        // Assert
        $response->assertUnauthorized();
    }
}
