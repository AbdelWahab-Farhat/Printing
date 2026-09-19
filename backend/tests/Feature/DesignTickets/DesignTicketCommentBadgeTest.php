<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;

/**
 * شارةُ المحادثة — كم ردّاً لم يقرأه *هذا* القارئ على *هذه* التذكرة.
 *
 * **لا جدولَ جديد تحتها: الجواب هو صفوفُ الإشعارات نفسها.** كلُّ تعليقٍ يُنشئ صفَّ إشعارٍ واحداً،
 * و`read_at` فيه لكلِّ شخصٍ على حدة — فالشارةُ عدٌّ، وحالةُ «قرأتُ الخيط» هي عينُها حالةُ «قرأتُ
 * الجرس». ولهذا يؤكّد آخِرُ اختبارٍ هنا أنّ فتح المحادثة يُنزل رقمَ الجرس أيضاً: لو انفصلا لصار
 * الرقمُ فوق الجرس كذبةً صغيرةً تتكرّر.
 *
 * **ورقمٌ عن القارئ لا عن التذكرة.** التذكرةُ الواحدة تحمل ثلاثة أرقامٍ مختلفة في اللحظة نفسها —
 * لطالبها، ولمصمّمها، ولمديرٍ يقرأ التذاكر كلَّها ولم يُوجَّه إليه شيء — وأولُ اختبارَين هما ذلك.
 *
 * Arrange - Act - Assert في كل اختبار.
 */
class DesignTicketCommentBadgeTest extends DesignTicketTestCase
{
    public function test_the_badge_counts_what_the_other_side_wrote_and_nothing_else(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversation($employee, $designer);

        // Act — ردّان من المصمّم.
        $this->reply($ticket, 'جاري التعديل', $designerHeaders);
        $this->reply($ticket, 'رفعتُ النسخة', $designerHeaders);

        // Assert — اثنان للطالب، وصفرٌ للمصمّم الذي كتبهما.
        $this->getJson("/api/v1/design-tickets/{$ticket->id}", $employeeHeaders)
            ->assertOk()
            ->assertJsonPath('data.unread_comments_count', 2);

        $this->getJson("/api/v1/design-tickets/{$ticket->id}", $designerHeaders)
            ->assertOk()
            ->assertJsonPath('data.unread_comments_count', 0);
    }

    public function test_a_reader_who_is_neither_party_sees_no_badge(): void
    {
        // Arrange — مديرٌ يقرأ التذاكر كلَّها. لم يُوجَّه إليه شيء، فلا صفَّ بريدٍ له.
        [$employee] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        [, $manager] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
        );
        $ticket = $this->conversation($employee, $designer);

        // Act
        $this->reply($ticket, 'جاري التعديل', $designerHeaders);

        // Assert — يرى التذكرة ولا يرى شارة. وهذا هو المقصود: الشارة تقول «هنا شيءٌ لك».
        $this->getJson("/api/v1/design-tickets/{$ticket->id}", $manager)
            ->assertOk()
            ->assertJsonPath('data.unread_comments_count', 0);
    }

    public function test_the_list_carries_a_count_on_every_row(): void
    {
        // Arrange — الشارةُ تُرى وأنت تمسح القائمة، قبل أن تفتح شيئاً.
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $quiet = $this->conversation($employee, $designer);
        $busy = $this->conversation($employee, $designer);

        // Act
        $this->reply($busy, 'سؤال عن المقاس', $designerHeaders);

        // Assert — الأحدث أولاً، والصفرُ مكتوبٌ صراحةً: مفتاحٌ غائب يترك التطبيق يختار بين
        // الفراغ والصفر، وهما شيئان مختلفان.
        $this->getJson('/api/v1/design-tickets', $employeeHeaders)
            ->assertOk()
            ->assertJsonPath('data.0.id', $busy->id)
            ->assertJsonPath('data.0.unread_comments_count', 1)
            ->assertJsonPath('data.1.id', $quiet->id)
            ->assertJsonPath('data.1.unread_comments_count', 0);
    }

    public function test_opening_the_conversation_clears_the_badge_and_the_bell_with_it(): void
    {
        // Arrange — النصف الثاني هو المقصود: الصفوف واحدة، فلا يبقى في الجرس خبرُ محادثةٍ قُرئت.
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversation($employee, $designer);

        $this->reply($ticket, 'جاري التعديل', $designerHeaders);
        $this->reply($ticket, 'رفعتُ النسخة', $designerHeaders);

        $this->getJson('/api/v1/notifications/unread-count', $employeeHeaders)
            ->assertOk()
            ->assertJsonPath('data.count', 2);

        // Act
        $cleared = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments/read",
            [],
            $employeeHeaders,
        );

        // Assert
        $cleared->assertOk()
            ->assertJsonPath('data.unread_comments_count', 0)
            ->assertJsonPath('data.unread_total', 0);

        $this->getJson("/api/v1/design-tickets/{$ticket->id}", $employeeHeaders)
            ->assertOk()
            ->assertJsonPath('data.unread_comments_count', 0);
    }

    public function test_clearing_one_conversation_leaves_the_others_alone(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $read = $this->conversation($employee, $designer);
        $untouched = $this->conversation($employee, $designer);

        $this->reply($read, 'عن الأولى', $designerHeaders);
        $this->reply($untouched, 'عن الثانية', $designerHeaders);

        // Act
        $this->postJson("/api/v1/design-tickets/{$read->id}/comments/read", [], $employeeHeaders)
            ->assertOk();

        // Assert — والجرسُ ما يزال يحمل خبرَ التذكرة التي لم تُفتح.
        $this->getJson("/api/v1/design-tickets/{$untouched->id}", $employeeHeaders)
            ->assertOk()
            ->assertJsonPath('data.unread_comments_count', 1);

        $this->getJson('/api/v1/notifications/unread-count', $employeeHeaders)
            ->assertOk()
            ->assertJsonPath('data.count', 1);
    }

    public function test_clearing_is_idempotent_and_an_empty_conversation_answers_the_same(): void
    {
        // Arrange — لا ردَّ فيها أصلاً.
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversation($employee, $designer);

        // Act
        $first = $this->postJson("/api/v1/design-tickets/{$ticket->id}/comments/read", [], $employeeHeaders);
        $second = $this->postJson("/api/v1/design-tickets/{$ticket->id}/comments/read", [], $employeeHeaders);

        // Assert
        $first->assertOk()->assertJsonPath('data.unread_comments_count', 0);
        $second->assertOk()->assertJsonPath('data.unread_comments_count', 0);
    }

    public function test_a_colleagues_conversation_cannot_be_marked_read(): void
    {
        // Arrange — التذكرة مأخوذة، فليست في الصفّ المشترك ولا يراها غريب.
        [$employee] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        [, $stranger] = $this->actor(PermissionName::ViewDesignTickets);
        $ticket = $this->conversation($employee, $designer);

        $this->reply($ticket, 'جاري التعديل', $designerHeaders);

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments/read",
            [],
            $stranger,
        );

        // Assert — ٤٠٤ لا ٤٠٣: مَن لا يرى التذكرة لا يُقال له إنها موجودة.
        $response->assertNotFound();
    }

    /**
     * تذكرةٌ طرفاها معروفان: طلبها الموظف، وأخذها المصمّم.
     */
    private function conversation(User $employee, User $designer): DesignTicket
    {
        return DesignTicket::factory()
            ->acceptedBy((int) $designer->getKey())
            ->create(['requested_by_user_id' => $employee->getKey()]);
    }

    /**
     * ردٌّ يُكتب من نقطة النهاية الحقيقيّة — فالمستمِع وحده هو ما يصنع صفَّ الإشعار الذي تعدّه
     * الشارة، وكتابةُ الصفّ باليد كانت ستختبر الحسابَ دون الأسلاك.
     *
     * @param  array<string, string>  $headers
     */
    private function reply(DesignTicket $ticket, string $body, array $headers): void
    {
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => $body],
            $headers,
        )->assertCreated();
    }
}
