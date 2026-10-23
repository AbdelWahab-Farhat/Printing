<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerSocialLink;
use App\Domain\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * «روابط التواصل» من «حسابي»: العميل يقرأ روابطه ويحفظها كلّها دفعةً واحدة.
 *
 * **لا مُعرِّفَ عميلٍ في المسار.** الروابط روابطُ صاحب التوكن، ومُعرِّف رابطٍ لعميلٍ آخر في الطلب
 * يُرفض بـ422 لا يُعدَّل. الاختبارات التي تحمل «another_customers» في أسمائها هي هذا الضمان.
 *
 * المواصفة في Docs/customers/CUSTOMER-SOCIAL-LINKS.md. Arrange - Act - Assert throughout.
 */
class CustomerSocialLinksTest extends TestCase
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

    // ─────────────────────────── القراءة ───────────────────────────

    public function test_the_list_shows_only_my_own_links_in_the_order_they_were_added(): void
    {
        // Arrange
        $me = $this->customer();
        $first = CustomerSocialLink::factory()->create(['customer_id' => $me->id]);
        $second = CustomerSocialLink::factory()->create(['customer_id' => $me->id]);
        $theirs = CustomerSocialLink::factory()->create([
            'customer_id' => $this->customer('0922222222')->id,
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/social-links');

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $first->id)
            ->assertJsonPath('data.0.url', $first->url)
            ->assertJsonPath('data.1.id', $second->id);
        $this->assertNotContains($theirs->id, array_column((array) $response->json('data'), 'id'));
    }

    public function test_the_list_needs_a_signed_in_customer(): void
    {
        // Arrange — توكن موظف: الحارس `customer` لا يعرفه.
        $staff = ['Authorization' => 'Bearer '.User::factory()->create()->createToken('test')->plainTextToken];

        // Act
        $response = $this->withHeaders($staff)->getJson('/api/v1/client/social-links');

        // Assert
        $response->assertUnauthorized();
    }

    // ─────────────────────────── الحفظ ───────────────────────────

    public function test_saving_edits_adds_and_removes_links_to_match_the_set_sent(): void
    {
        // Arrange
        $me = $this->customer();
        $kept = CustomerSocialLink::factory()->create([
            'customer_id' => $me->id,
            'url' => 'https://facebook.com/old',
        ]);
        $dropped = CustomerSocialLink::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->putJson('/api/v1/client/social-links', [
            'social_links' => [
                ['id' => $kept->id, 'url' => 'https://facebook.com/alnoor.print'],
                ['url' => 'https://instagram.com/alnoor.print'],
            ],
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('message', 'تم حفظ الروابط')
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $kept->id)
            ->assertJsonPath('data.0.url', 'https://facebook.com/alnoor.print')
            ->assertJsonPath('data.1.url', 'https://instagram.com/alnoor.print');
        $this->assertSoftDeleted($dropped);
    }

    public function test_saving_an_empty_list_removes_every_link(): void
    {
        // Arrange
        $me = $this->customer();
        $link = CustomerSocialLink::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->putJson('/api/v1/client/social-links', [
            'social_links' => [],
        ]);

        // Assert
        $response->assertOk()->assertJsonPath('data', []);
        $this->assertSoftDeleted($link);
    }

    /**
     * طلبٌ بلا المفتاح ليس «احذفها كلّها»: الحذف الكامل يُقال بقائمةٍ فارغة صريحة.
     */
    public function test_saving_without_the_list_is_refused(): void
    {
        // Arrange
        $me = $this->customer();
        $link = CustomerSocialLink::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->putJson('/api/v1/client/social-links', []);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('social_links');
        $this->assertNotSoftDeleted($link);
    }

    public function test_saving_cannot_touch_another_customers_link(): void
    {
        // Arrange
        $me = $this->customer();
        $theirs = CustomerSocialLink::factory()->create([
            'customer_id' => $this->customer('0922222222')->id,
            'url' => 'https://facebook.com/theirs',
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->putJson('/api/v1/client/social-links', [
            'social_links' => [['id' => $theirs->id, 'url' => 'https://facebook.com/mine']],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('social_links.0.id');
        $this->assertSame('https://facebook.com/theirs', $theirs->fresh()?->url);
        $this->assertSame(0, CustomerSocialLink::query()->where('customer_id', $me->id)->count());
    }

    public function test_saving_refuses_what_is_not_a_web_address(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->putJson('/api/v1/client/social-links', [
            'social_links' => [['url' => 'javascript:alert(1)']],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('social_links.0.url');
        $this->assertSame('الرابط غير صحيح', $response->json('errors')['social_links.0.url'][0]);
    }

    public function test_saving_refuses_the_same_link_twice(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->putJson('/api/v1/client/social-links', [
            'social_links' => [
                ['url' => 'https://tiktok.com/@alnoor'],
                ['url' => 'https://tiktok.com/@alnoor'],
            ],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('social_links.1.url');
    }

    public function test_saving_refuses_more_than_ten_links(): void
    {
        // Arrange
        $me = $this->customer();
        $links = array_map(
            fn (int $n): array => ['url' => "https://facebook.com/page{$n}"],
            range(1, 11),
        );

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->putJson('/api/v1/client/social-links', [
            'social_links' => $links,
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('social_links');
        $this->assertSame(0, CustomerSocialLink::query()->where('customer_id', $me->id)->count());
    }
}
