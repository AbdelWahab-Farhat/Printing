<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerSocialLink;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * «روابط التواصل» من جهة الموظفين: تُرسَل مع العميل في `POST` و`PUT /customers` كما تُرسَل
 * محلاته، وتُزامَن بالطريقة نفسها — رابطٌ بمُعرِّفه يُعدَّل، وبلا مُعرِّف يُضاف، والغائب يُحذف.
 * والمفتاح الغائب كلّه يُبقي الروابط كما هي.
 *
 * المواصفة في Docs/customers/CUSTOMER-SOCIAL-LINKS.md. Arrange - Act - Assert throughout.
 */
class CustomerSocialLinksTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<string, string>
     */
    private function auth(): array
    {
        $user = User::factory()->create();

        // مديرٌ، كما في CustomerTest: الصلاحيات لها اختباراتها، وهذه عن الروابط.
        Role::findOrCreate(RoleName::Admin->value, 'web');
        $user->syncRoles([RoleName::Admin->value]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'مطبعة النور',
            'phone' => '0912345678',
        ], $overrides);
    }

    // ─────────────────────────── الإنشاء ───────────────────────────

    public function test_a_new_customer_is_stored_with_the_links_sent_with_it(): void
    {
        // Arrange
        $headers = $this->auth();
        $payload = $this->payload(['social_links' => [
            ['url' => 'https://facebook.com/alnoor.print'],
            ['url' => 'https://instagram.com/alnoor.print'],
        ]]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $payload);

        // Assert
        $response->assertCreated()
            ->assertJsonCount(2, 'data.social_links')
            ->assertJsonPath('data.social_links.0.url', 'https://facebook.com/alnoor.print')
            ->assertJsonPath('data.social_links.1.url', 'https://instagram.com/alnoor.print');
        $this->assertSame(2, CustomerSocialLink::query()->where('customer_id', $response->json('data.id'))->count());
    }

    /**
     * فارغةً لا غائبة: العميل الجديد بلا روابط حقيقةٌ يعرفها الخادم، لا سؤالٌ لم يُسأل.
     */
    public function test_a_customer_created_without_links_answers_with_an_empty_list(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $this->payload());

        // Assert
        $response->assertCreated()->assertJsonPath('data.social_links', []);
    }

    // ─────────────────────────── القراءة ───────────────────────────

    public function test_the_customer_page_carries_the_links_in_the_order_they_were_added(): void
    {
        // Arrange
        $headers = $this->auth();
        $customer = Customer::factory()->create();
        $first = CustomerSocialLink::factory()->create(['customer_id' => $customer->id]);
        $second = CustomerSocialLink::factory()->create(['customer_id' => $customer->id]);

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/customers/{$customer->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.social_links.0.id', $first->id)
            ->assertJsonPath('data.social_links.0.url', $first->url)
            ->assertJsonPath('data.social_links.1.id', $second->id);
    }

    public function test_a_removed_link_is_not_shown(): void
    {
        // Arrange
        $headers = $this->auth();
        $customer = Customer::factory()->create();
        CustomerSocialLink::factory()->create(['customer_id' => $customer->id])->delete();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/customers/{$customer->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.social_links', []);
    }

    // ─────────────────────────── التعديل ───────────────────────────

    public function test_an_update_edits_adds_and_removes_links_to_match_the_set_sent(): void
    {
        // Arrange
        $headers = $this->auth();
        $customer = Customer::factory()->create(['phone' => '0912345678']);
        $kept = CustomerSocialLink::factory()->create([
            'customer_id' => $customer->id,
            'url' => 'https://facebook.com/old',
        ]);
        $dropped = CustomerSocialLink::factory()->create(['customer_id' => $customer->id]);

        // Act
        $response = $this->withHeaders($headers)->putJson("/api/v1/customers/{$customer->id}", $this->payload([
            'social_links' => [
                ['id' => $kept->id, 'url' => 'https://facebook.com/alnoor.print'],
                ['url' => 'https://tiktok.com/@alnoor'],
            ],
        ]));

        // Assert
        $response->assertOk()
            ->assertJsonCount(2, 'data.social_links')
            ->assertJsonPath('data.social_links.0.id', $kept->id)
            ->assertJsonPath('data.social_links.0.url', 'https://facebook.com/alnoor.print')
            ->assertJsonPath('data.social_links.1.url', 'https://tiktok.com/@alnoor');
        // حذفٌ ناعم: الرابط المحذوف يبقى في الجدول، ويبقى في سجل التعديلات.
        $this->assertSoftDeleted($dropped);
    }

    /**
     * نسخة تطبيق الموظفين التي لا تعرف الروابط تحفظ العميل بلا هذا المفتاح، ويجب ألّا تمسحها.
     */
    public function test_an_update_that_does_not_mention_links_keeps_them(): void
    {
        // Arrange
        $headers = $this->auth();
        $customer = Customer::factory()->create(['phone' => '0912345678']);
        $link = CustomerSocialLink::factory()->create(['customer_id' => $customer->id]);

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/customers/{$customer->id}",
            $this->payload(['name' => 'مطبعة النور الجديدة']),
        );

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data.social_links')
            ->assertJsonPath('data.social_links.0.id', $link->id);
        $this->assertNotSoftDeleted($link);
    }

    public function test_an_update_with_an_empty_list_removes_every_link(): void
    {
        // Arrange
        $headers = $this->auth();
        $customer = Customer::factory()->create(['phone' => '0912345678']);
        $links = CustomerSocialLink::factory()->count(2)->create(['customer_id' => $customer->id]);

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/customers/{$customer->id}",
            $this->payload(['social_links' => []]),
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.social_links', []);
        foreach ($links as $link) {
            $this->assertSoftDeleted($link);
        }
    }

    public function test_an_update_refuses_a_link_id_belonging_to_another_customer(): void
    {
        // Arrange
        $headers = $this->auth();
        $customer = Customer::factory()->create(['phone' => '0912345678']);
        $theirs = CustomerSocialLink::factory()->create([
            'customer_id' => Customer::factory()->create(['phone' => '0922222222'])->id,
            'url' => 'https://facebook.com/theirs',
        ]);

        // Act
        $response = $this->withHeaders($headers)->putJson("/api/v1/customers/{$customer->id}", $this->payload([
            'social_links' => [['id' => $theirs->id, 'url' => 'https://facebook.com/mine']],
        ]));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('social_links.0.id');
        $this->assertSame('الرابط المحدد لا ينتمي لهذا العميل', $response->json('errors')['social_links.0.id'][0]);
        $this->assertSame('https://facebook.com/theirs', $theirs->fresh()?->url);
    }

    // ─────────────────────────── التحقق ───────────────────────────

    /**
     * @return array<string, array{0: string}>
     */
    public static function notALink(): array
    {
        return [
            'no scheme' => ['facebook.com/alnoor'],
            'not the web' => ['ftp://files.example.com/alnoor'],
            'a script' => ['javascript:alert(1)'],
            'plain words' => ['صفحة النور'],
        ];
    }

    #[DataProvider('notALink')]
    public function test_a_link_must_be_a_web_address(string $url): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $this->payload([
            'social_links' => [['url' => $url]],
        ]));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('social_links.0.url');
        $this->assertSame('الرابط غير صحيح', $response->json('errors')['social_links.0.url'][0]);
    }

    public function test_a_link_cannot_be_empty(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $this->payload([
            'social_links' => [['url' => '']],
        ]));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('social_links.0.url');
    }

    /**
     * والحالة لا تفرق: «Facebook.com/Alnoor» و«facebook.com/alnoor» صفحةٌ واحدة.
     */
    public function test_the_same_link_cannot_be_sent_twice(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $this->payload([
            'social_links' => [
                ['url' => 'https://facebook.com/alnoor'],
                ['url' => 'https://Facebook.com/Alnoor'],
            ],
        ]));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('social_links.1.url');
        $this->assertSame('الرابط مكرر', $response->json('errors')['social_links.1.url'][0]);
    }

    public function test_a_customer_has_at_most_ten_links(): void
    {
        // Arrange
        $headers = $this->auth();
        $links = array_map(
            fn (int $n): array => ['url' => "https://facebook.com/page{$n}"],
            range(1, 11),
        );

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $this->payload([
            'social_links' => $links,
        ]));

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors('social_links')
            ->assertJsonPath('errors.social_links.0', 'لا يمكن إضافة أكثر من 10 روابط');
    }

    // ─────────────────────────── السجل ───────────────────────────

    /**
     * رابطٌ أُضيف أو حُذف جزءٌ من قصة العميل، فيُقرأ في سجلّه كما تُقرأ محلاته.
     */
    public function test_a_link_change_is_read_in_the_customers_history_in_arabic(): void
    {
        // Arrange
        $headers = $this->auth();
        $customer = Customer::factory()->create();
        CustomerSocialLink::factory()->create(['customer_id' => $customer->id]);

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/customers/{$customer->id}/logs");

        // Assert
        $response->assertOk();
        $entry = collect($response->json('data'))->firstWhere('subject_type', 'customer_social_link');
        $this->assertNotNull($entry);
        $this->assertSame('رابط تواصل', $entry['subject_type_label']);
        $this->assertSame('رابط التواصل', $entry['attribute_labels']['url']);
    }
}
