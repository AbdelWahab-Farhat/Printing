<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;

/**
 * «بعد الاعتماد لا يوجد مزيد» — المحادثة تنتهي بانتهاء التذكرة.
 *
 * **التذكرة التي انتهت سجلُّ ما اتُّفق عليه، والسجلُّ الذي يمكن أن يُضاف إليه ليس سجلّاً.**
 * و{@see DesignTicketStatus::isClosed()} تقولها صراحةً أصلاً — «لا شيء بعدهما يُرسم ولا يُراجع
 * ولا يُقال».
 *
 * **النهايتان كلتاهما، والجميع.** «ملغى» تُغلقها للسبب الذي تُغلقها له «مكتمل»: الطلب انتهى.
 * والتجميد ليس صلاحية — فمَن يرى التذاكر كلّها يُرفض أيضاً، لأن المحميّ هنا حالُ التذكرة.
 *
 * والتطبيق يُخبَر قبل أن يرسم شيئاً: `can_reply` و`closed_note` على المحادثة، و`can_edit` /
 * `can_delete` بـfalse على كل رسالة. وهذا الملف يؤكّد النصفين — الأعلام التي تُخفي الصندوق
 * والأزرار، والرفض الذي هو القاعدة فعلاً. **ورفضُ الحال ٤٢٢ لا ٤٠٣**: لم يُرفض أحدٌ لِمن هو.
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

        // Act
        $written = $this->say($ticket, $employee, ['body' => 'الشعار في المرفقات']);
        $thread = $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $employee);

        // Assert — الحالة العادية، تُقال ليعني المغلقُ أدناه شيئاً.
        $written->assertCreated();
        $thread->assertOk()
            ->assertJsonPath('data.can_reply', true)
            ->assertJsonPath('data.closed_note', null)
            ->assertJsonPath('data.messages.0.can_edit', true);
    }

    public function test_an_approved_ticket_takes_no_more_messages(): void
    {
        // Arrange — «اعتُمد التصميم» هو نهاية المحادثة، للمصمّم الذي رسمه وللموظف الذي طلب.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->ticketFor($employee);
        $this->approveThroughTheFlow($ticket, $employee, $designer);

        // Act
        $fromEmployee = $this->say($ticket, $employee, ['body' => 'وكمان غيّر اللون']);
        $fromDesigner = $this->say($ticket, $designer, ['file' => $this->voice()]);
        $thread = $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $employee);

        // Assert — 422 وكلماتُ التذكرة نفسها، فيعرض التطبيق السبب بدل «حدث خطأ ما».
        $fromEmployee->assertStatus(422);
        $fromDesigner->assertStatus(422)
            ->assertJsonPath('message', 'اعتُمد التصميم وأُغلقت المحادثة');
        $thread->assertOk()
            ->assertJsonPath('data.can_reply', false)
            ->assertJsonPath('data.closed_note', 'اعتُمد التصميم وأُغلقت المحادثة');
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
        $response = $this->say($ticket, $employee, ['body' => 'ليش تلغى؟']);

        // Assert
        $response->assertStatus(422)
            ->assertJsonPath('message', 'أُلغيت التذكرة وأُغلقت المحادثة');
    }

    public function test_the_messages_already_in_a_closed_ticket_freeze(): void
    {
        // Arrange — كُتبت والتذكرة مفتوحة، بيد كاتبها، وما تزال في مهلة العشرين دقيقة.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->ticketFor($employee);

        $message = $this->say($ticket, $employee, ['body' => 'اتفقنا على الأسود'])
            ->assertCreated()->json('data.messages.0.id');

        $this->approveThroughTheFlow($ticket, $employee, $designer);

        // Act
        $rewritten = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/messages/{$message}",
            ['body' => 'لا، اتفقنا على الأبيض'],
            $employee,
        );
        $removed = $this->deleteJson(
            "/api/v1/design-tickets/{$ticket->id}/messages/{$message}",
            [],
            $employee,
        );
        $thread = $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $employee);

        // Assert — ما اتُّفق عليه قبل الاعتماد يبقى كما كُتب.
        $rewritten->assertStatus(422)->assertJsonPath('message', 'اعتُمد التصميم وأُغلقت المحادثة');
        $removed->assertStatus(422);
        $thread->assertOk()
            ->assertJsonPath('data.messages.0.body', 'اتفقنا على الأسود')
            ->assertJsonPath('data.messages.0.can_edit', false)
            ->assertJsonPath('data.messages.0.can_delete', false)
            ->assertJsonPath('data.messages.0.mutation_block_reason', 'اعتُمد التصميم وأُغلقت المحادثة');
    }

    public function test_even_a_reader_of_every_ticket_is_refused_after_the_sign_off(): void
    {
        // Arrange — رؤيةُ التذاكر كلّها ليست سلطةً على إعادة فتح تذكرةٍ منتهية.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        [, $manager] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ModerateComments,
        );
        $ticket = $this->ticketFor($employee);
        $this->approveThroughTheFlow($ticket, $employee, $designer);

        // Act
        $response = $this->say($ticket, $manager, ['body' => 'ملاحظة أخيرة']);

        // Assert
        $response->assertStatus(422);
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
}
