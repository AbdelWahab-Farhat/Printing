<?php

declare(strict_types=1);

namespace Tests\Feature\Notifications;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Comment\Actions\PostComment;
use App\Domain\Comment\Events\CommentPosted;
use App\Domain\Comment\Models\Comment;
use App\Domain\Customer\Models\Customer;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Definitions\DesignTicketCommentPosted;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Listeners\NotifyWhenDesignTicketIsCommentedOn;
use App\Domain\Notification\Models\Notification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «الردّ داخل التذكرة» يصل إلى الطرف الآخر.
 *
 * **المُختبَر هو أنّ الجمهور طرفان دائماً، ومَن كتب يخرج منهما.** ثلاث حالاتٍ تُغطّيها جملةٌ
 * واحدة في التعريفة: يكتب الطالبُ فيسمع المصمّم، ويكتب المصمّمُ فيسمع الطالب، ويكتب ثالثٌ من
 * خارجهما فيسمعان معاً. ولو كُتب الحكمُ بسؤال «مَن الكاتب؟» لسقط الفرعُ الثالثُ صامتاً — ولهذا
 * له اختبارٌ باسمه.
 *
 * **والحدثُ عامٌّ والغربلةُ في المستمِع**، فاختبارُ الملاحظة على عميلٍ يؤكّد أن شيئاً لم يُعلَن.
 * وهو الاختبارُ الذي يسقط أولَ مرّةٍ يُنقل فيها الرأيُ من المستمِع إلى سياق الملاحظات.
 *
 * Arrange - Act - Assert في كل اختبار.
 */
class DesignTicketCommentNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_designers_reply_reaches_the_employee_who_raised_the_ticket(): void
    {
        // Arrange
        [$ticket, $requester] = $this->conversation();

        // Act
        $this->reply($ticket, $this->designerOf($ticket));

        // Assert — الطالبُ وحده: المصمّمُ قرأ ردَّه وهو يكتبه.
        $notification = Notification::query()->firstOrFail();
        $this->assertSame(NotificationType::DesignTicketComment, $notification->type);
        $this->assertSame('design_ticket', $notification->subject_type);
        $this->assertSame((int) $ticket->getKey(), $notification->subject_id);
        $this->assertSame([(int) $requester->getKey()], $this->recipientsOf($notification));
    }

    public function test_an_employees_reply_reaches_the_designer_doing_the_work(): void
    {
        // Arrange
        [$ticket, $requester, $designer] = $this->conversation();

        // Act
        $this->reply($ticket, $requester);

        // Assert
        $this->assertSame(
            [(int) $designer->getKey()],
            $this->recipientsOf(Notification::query()->firstOrFail()),
        );
    }

    public function test_a_reply_from_outside_the_two_parties_reaches_them_both(): void
    {
        // Arrange — مديرٌ يقرأ التذاكر كلَّها ويكتب على واحدةٍ ليست له. لا هو الطالبُ ولا
        // المصمّم، فلا أحدَ يخرج من الاثنين.
        [$ticket, $requester, $designer] = $this->conversation();
        $manager = User::factory()->create(['is_active' => true]);

        // Act
        $this->reply($ticket, $manager);

        // Assert
        $recipients = $this->recipientsOf(Notification::query()->firstOrFail());
        $this->assertEqualsCanonicalizing(
            [(int) $requester->getKey(), (int) $designer->getKey()],
            $recipients,
        );
        $this->assertNotContains((int) $manager->getKey(), $recipients);
    }

    public function test_a_ticket_nobody_has_taken_yet_is_not_a_conversation(): void
    {
        // Arrange — تذكرةٌ في الصفّ المشترك: طرفُها الوحيد هو الطالب.
        $requester = User::factory()->create(['is_active' => true]);
        $ticket = DesignTicket::factory()->create([
            'requested_by_user_id' => $requester->getKey(),
        ]);

        // Act
        $this->reply($ticket, $requester);

        // Assert — يُكتب صفُّ الإشعار لأن الشيء حدث، ولا يُبلَّغ أحد. والمصمّمون لا يُوقَظون
        // لأجل سطرٍ أضافه الطالبُ إلى طلبه.
        $this->assertSame([], $this->recipientsOf(Notification::query()->firstOrFail()));
    }

    public function test_two_replies_are_two_notifications(): void
    {
        // Arrange — المحادثةُ ليست حالةَ سجلّ: رسالتان متتاليتان رسالتان، ونافذةُ الستّ ساعات
        // لا تطوي الثانيةَ منهما.
        [$ticket, , $designer] = $this->conversation();

        // Act
        $this->reply($ticket, $designer);
        $this->reply($ticket, $designer);

        // Assert
        $this->assertSame(2, Notification::query()->count());
    }

    public function test_the_same_reply_announced_twice_is_one_notification(): void
    {
        // Arrange — مهمّةٌ في الطابور أُعيدت محاولتُها. المفتاحُ معرِّفُ التعليق، وهذا كلُّ ما
        // يمنعه.
        [$ticket, , $designer] = $this->conversation();

        // Act — ردٌّ واحد، ثم إعلانُه ثانيةً بمعرِّفه نفسه كما تفعل مهمّةٌ أُعيدت محاولتُها.
        $comment = $this->reply($ticket, $designer);

        app(NotifyWhenDesignTicketIsCommentedOn::class)->handle(new CommentPosted(
            commentId: (int) $comment->getKey(),
            commentableType: AuditSubject::DesignTicket->value,
            commentableId: (int) $ticket->getKey(),
            authorId: (int) $designer->getKey(),
        ));

        // Assert
        $this->assertSame(1, Notification::query()->count());
    }

    public function test_the_sentence_shows_nothing_a_lock_screen_may_not_show(): void
    {
        // Arrange — §٦٫٤: الدفعُ يُقرأ على شاشةٍ مقفلة، و`render()` واحدةٌ تخدمه وتخدم البريد.
        [$ticket, , $designer] = $this->conversation();

        // Act
        $this->reply($ticket, $designer, body: 'الزبون رفض السعر، خفّضه إلى ٤٥٠');

        // Assert
        $notification = Notification::query()->firstOrFail();
        $rendered = app(DesignTicketCommentPosted::class)->render($notification->payload);

        $this->assertSame('ردٌّ جديد على تذكرة التصميم', $rendered->title);
        $this->assertSame('/design-tickets/'.$ticket->getKey().'/comments', $rendered->route);

        $sentence = $rendered->title.' '.$rendered->body;
        $this->assertStringNotContainsString('٤٥٠', $sentence);
        $this->assertStringNotContainsString('متجر إكس', $sentence);
        // ولا نصَّ الردّ في الحمولة أصلاً، فلا سبيل إلى تسريبه بجملةٍ تُكتب لاحقاً.
        $this->assertArrayNotHasKey('body', $notification->payload);
        $this->assertArrayNotHasKey('customer_name', $notification->payload);
    }

    public function test_a_note_on_a_customer_announces_nothing(): void
    {
        // Arrange — الحدثُ عامٌّ عن كلِّ ما يُعلَّق عليه، والرأيُ في المستمِع. هذا الاختبار هو
        // الذي يسقط يوم يُنقل الرأيُ إلى سياق الملاحظات.
        $customer = Customer::factory()->create();
        $author = User::factory()->create(['is_active' => true]);

        // Act
        app(PostComment::class)->handle($customer, 'لا يردّ إلا على واتساب', $author);

        // Assert
        $this->assertSame(0, Notification::query()->count());
    }

    public function test_the_endpoint_carries_a_reply_all_the_way_to_the_other_side(): void
    {
        // Arrange — الطريقُ كاملاً: المتحكّم ← الباب ← الفعل ← الحدث ← المستمِع. وبقيّةُ هذا
        // الملف تُشغّل المستمِعَ بيدها، فهذا وحده يثبت أن الأسلاك موصولة.
        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        [$ticket, $requester, $designer] = $this->conversation();
        $requester->givePermissionTo(PermissionName::ViewDesignTickets->value);

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->getKey()}/comments",
            ['body' => 'الشعار في المرفقات'],
            ['Authorization' => 'Bearer '.$requester->createToken('test')->plainTextToken],
        );

        // Assert
        $response->assertCreated();
        $this->assertSame(
            [(int) $designer->getKey()],
            $this->recipientsOf(Notification::query()->firstOrFail()),
        );
    }

    /**
     * تذكرةٌ أخذها مصمّم: طرفاها موجودان ومعروفان.
     *
     * @return array{0: DesignTicket, 1: User, 2: User}
     */
    private function conversation(): array
    {
        $requester = User::factory()->create(['is_active' => true]);
        $designer = User::factory()->create(['is_active' => true]);

        $ticket = DesignTicket::factory()
            ->acceptedBy((int) $designer->getKey())
            ->create(['requested_by_user_id' => $requester->getKey()]);

        return [$ticket, $requester, $designer];
    }

    private function designerOf(DesignTicket $ticket): User
    {
        return User::query()->findOrFail($ticket->accepted_by_user_id);
    }

    /**
     * ردٌّ يُكتب على التذكرة.
     *
     * **ولا يُشغَّل المستمِعُ هنا باليد.** الفعلُ يُطلق `CommentPosted`، والمستمِعُ مسجَّل،
     * والطابورُ في الاختبارات `sync` — فالطريقُ الحقيقيُّ هو الذي يُقاس، وتشغيلُه مرّةً ثانية
     * كان سينشر خبرَين عن ردٍّ واحد.
     */
    private function reply(
        DesignTicket $ticket,
        User $author,
        string $body = 'تمام، جاري التعديل',
    ): Comment {
        return app(PostComment::class)->handle($ticket, $body, $author);
    }

    /**
     * @return list<int>
     */
    private function recipientsOf(Notification $notification): array
    {
        return $notification->recipients()
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }
}
