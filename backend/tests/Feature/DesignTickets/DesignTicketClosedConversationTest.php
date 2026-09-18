<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;

/**
 * «بعد الاعتماد لا يوجد مزيد» — المحادثة تنتهي بانتهاء التذكرة.
 *
 * **التذكرة التي انتهت سجلُّ ما اتُّفق عليه، والسجلُّ الذي يمكن أن يُضاف إليه ليس سجلّاً.**
 * و{@see DesignTicketStatus::isClosed()} تقولها صراحةً أصلاً — «لا شيء بعدهما يُرسم ولا يُراجع
 * ولا يُقال» — وكان ثلثا تلك الجملة مطبَّقَين من البداية والثالث لا: كان المصمّم يواصل الكتابة
 * تحت تصميمٍ معتمَد، وكان لكلا الطرفين أن يعيد كتابة ما وعد به صامتاً قبل الاعتماد.
 *
 * **النهايتان كلتاهما، والجميع.** «ملغى» تُغلقها للسبب الذي تُغلقها له «مكتمل»: الطلب انتهى.
 * والتجميد ليس صلاحية — فالمشرف يُرفض أيضاً، لأن المحميّ هنا حالُ التذكرة لا مِلكيّةُ جملة.
 *
 * والتطبيق يُخبَر قبل أن يرسم شيئاً: `meta.can_comment` على القائمة، و`can_edit` / `can_delete`
 * بـfalse على كل صفّ. وهذا الملف يؤكّد النصفين — الرايات التي تُخفي الأزرار، والرفض الذي هو
 * القاعدة فعلاً.
 *
 * Arrange - Act - Assert في كل اختبار.
 */
class DesignTicketClosedConversationTest extends DesignTicketTestCase
{
    public function test_an_open_ticket_takes_messages_and_says_so(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $ticket = $this->ticketFor($employee, $designerUser->id);

        // Act — تُكتب ثم يقرؤها كاتبها، وملاحظتُه له يعيد كتابتها ما دامت التذكرة مفتوحة.
        $written = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'الشعار في المرفقات'],
            $employee,
        );
        $list = $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $employee);

        // Assert — الحالة العادية، تُقال ليعني المغلقُ أدناه شيئاً.
        $written->assertCreated();
        $list->assertOk()
            ->assertJsonPath('meta.can_comment', true)
            ->assertJsonPath('meta.closed_note', null)
            ->assertJsonPath('data.0.can_edit', true);
    }

    public function test_an_approved_ticket_takes_no_more_messages(): void
    {
        // Arrange — المقصود كلّه: «اعتُمد التصميم» هو نهاية المحادثة، للمصمّم الذي رسمه وللموظف
        // الذي طلب.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->approvedTicket($employee, $designer);

        // Act
        $fromEmployee = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'وكمان غيّر اللون'],
            $employee,
        );
        $fromDesigner = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'تمام'],
            $designer,
        );

        // Assert — 422 وكلماتُ التذكرة نفسها، فيعرض التطبيق السبب بدل «حدث خطأ ما».
        $fromEmployee->assertStatus(422);
        $fromDesigner->assertStatus(422)
            ->assertJsonPath('message', 'اعتُمد التصميم وأُغلقت المحادثة');
    }

    public function test_a_cancelled_ticket_takes_no_more_messages(): void
    {
        // Arrange — النهاية الأخرى. ليست حكماً على عمل أحد، وهي تُنهي الطلب مع ذلك.
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $ticket = $this->ticketFor($employee, $designerUser->id);

        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/cancellation",
            ['reason' => 'الزبون غيّر رأيه'],
            $employee,
        )->assertOk();

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'ليش تلغى؟'],
            $employee,
        );

        // Assert
        $response->assertStatus(422)
            ->assertJsonPath('message', 'أُلغيت التذكرة وأُغلقت المحادثة');
    }

    public function test_the_messages_already_in_a_closed_ticket_freeze(): void
    {
        // Arrange — كُتبت والتذكرة مفتوحة، بيد كاتبها الذي كان يستطيع إعادة كتابتها بحريّةٍ قبل
        // ساعة.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->ticketFor($employee);

        $comment = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'اتفقنا على الأسود'],
            $employee,
        )->assertCreated()->json('data.id');

        $this->close($ticket, $employee, $designer);

        // Act
        $rewritten = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/comments/{$comment}",
            ['body' => 'لا، اتفقنا على الأبيض'],
            $employee,
        );
        $removed = $this->deleteJson(
            "/api/v1/design-tickets/{$ticket->id}/comments/{$comment}",
            [],
            $employee,
        );
        $list = $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $employee);

        // Assert — ما اتُّفق عليه قبل الاعتماد يبقى كما كُتب.
        $rewritten->assertStatus(422);
        $removed->assertStatus(422);
        $list->assertOk()
            ->assertJsonPath('meta.can_comment', false)
            ->assertJsonPath('meta.closed_note', 'اعتُمد التصميم وأُغلقت المحادثة')
            ->assertJsonPath('data.0.can_edit', false)
            ->assertJsonPath('data.0.can_delete', false);
    }

    public function test_even_a_moderator_is_refused_after_the_sign_off(): void
    {
        // Arrange — `comments.moderate` سلطةٌ على إعادة كتابة جملة زميل، لا على إعادة فتح تذكرةٍ
        // منتهية. والتجميد عن حال التذكرة.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        [, $moderator] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ModerateComments,
        );
        $ticket = $this->ticketFor($employee);

        $comment = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'اتفقنا على الأسود'],
            $employee,
        )->assertCreated()->json('data.id');

        $this->close($ticket, $employee, $designer);

        // Act
        $response = $this->deleteJson(
            "/api/v1/design-tickets/{$ticket->id}/comments/{$comment}",
            [],
            $moderator,
        );

        // Assert
        $response->assertStatus(422);
        $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $moderator)
            ->assertOk()
            ->assertJsonPath('data.0.can_delete', false);
    }

    /**
     * تذكرةٌ رفعها هذا الموظف، وقد تكون مُسنَدةً إلى مصمّمٍ أصلاً.
     *
     * @param  array<string, string>  $employee
     */
    private function ticketFor(array $employee, ?int $designerId = null): DesignTicket
    {
        $overrides = $designerId === null ? [] : ['assigned_designer_id' => $designerId];

        return DesignTicket::query()->findOrFail(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($this->customer(), $overrides),
                $employee,
            )->assertCreated()->json('data.id'),
        );
    }

    /**
     * @param  array<string, string>  $employee
     * @param  array<string, string>  $designer
     */
    private function approvedTicket(array $employee, array $designer): DesignTicket
    {
        $ticket = $this->ticketFor($employee);
        $this->close($ticket, $employee, $designer);

        return $ticket;
    }

    /**
     * تأخذ التذكرة إلى «مكتمل»: قُبلت، ورُفعت نسخة، واعتُمدت.
     *
     * @param  array<string, string>  $employee
     * @param  array<string, string>  $designer
     */
    private function close(DesignTicket $ticket, array $employee, array $designer): void
    {
        $this->ticketAwaitingReview($ticket, $designer);

        $version = $ticket->versions()->sole();
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        )->assertOk();
    }
}
