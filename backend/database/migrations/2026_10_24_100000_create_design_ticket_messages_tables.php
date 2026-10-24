<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * محادثة تذكرة التصميم على شكل التذاكر الداخلية: نصٌّ وصورٌ وصوت — Docs/design-tickets/DESIGN-TICKET-CHAT.md.
 *
 * كانت المحادثة ملاحظاتٍ عامة (`comments`)، نصّاً فقط، لأنها بُنيت قبل أن يوجد غيرُ ذلك. فهذا
 * الترحيل يضع جدولَي التذاكر الداخلية نفسيهما للتذكرة، ومؤشّرَي القراءة لـ✓✓، **وينسخ الملاحظات
 * الحيّة رسائلَ نصية** — بكاتبها ووقتها و«معدّلة» إن كانت — كي لا يفقد المصمّمُ ما قيل له قبل
 * التحديث (السؤال ٢).
 *
 * **الأصولُ لا تُلمس.** تبقى في `comments` كما هي، وسجلُّ تدقيقها في سجلّ التذكرة، والنسخةُ
 * القديمة من التطبيق تقرؤها (السؤال ٣). ولهذا لا يحذف التراجعُ إلا ما أضافه هذا الترحيل.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('design_ticket_messages', function (Blueprint $table) {
            $table->id();

            $table->foreignId('design_ticket_id')->constrained('design_tickets')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users');

            // فارغٌ لرسالةٍ هي صورةٌ أو صوتٌ وحده.
            $table->text('body')->nullable();

            // الاقتباس: الرسالة التي يردّ عليها هذا الكلام، من التذكرة نفسها — يحرسه الفعل.
            $table->foreignId('reply_to_message_id')->nullable()->constrained('design_ticket_messages')->nullOnDelete();

            $table->string('client_token', 64)->nullable();

            // «معدّلة»: متى غيّر صاحبُها نصّها آخر مرة. لا `updated_at`، الذي يتحرّك مع أيّ كتابة.
            $table->timestamp('edited_at')->nullable();
            // النصُّ كما أُرسل أول مرة، يُحفظ عند أول تعديلٍ حقيقيّ ولا يُعرض لأحد — للتدقيق عند الخلاف.
            $table->text('original_body')->nullable();
            // «تم حذف هذه الرسالة»: سحبها صاحبها، وتبقى مكانها.
            $table->timestamp('retracted_at')->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['design_ticket_id', 'id']);
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX design_ticket_messages_client_token_unique
            ON design_ticket_messages (design_ticket_id, client_token)
            WHERE client_token IS NOT NULL AND deleted_at IS NULL
        SQL);

        // ليس `design_ticket_attachments`: «المرفقات» اسمُ ملفات التذكرة نفسها (`design_ticket_files`).
        Schema::create('design_ticket_message_attachments', function (Blueprint $table) {
            $table->id();

            $table->foreignId('message_id')->constrained('design_ticket_messages')->cascadeOnDelete();

            // قيمةٌ من `ChatAttachmentKind`: صورة أو صوت.
            $table->string('kind', 10);
            $table->string('disk', 40);
            $table->string('path');
            // ما سمّاه صاحبه، للعرض وحده. المسار على القرص يولّده الخادم.
            $table->string('filename');
            // مقروءٌ من البايتات بـfinfo، لا من ادّعاء الهاتف.
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('size_bytes');

            // للصور: يحجز التطبيق مكانها بنسبتها قبل أن تصل.
            $table->unsignedInteger('width_px')->nullable();
            $table->unsignedInteger('height_px')->nullable();

            // للصوت: المدّة كما قاسها الهاتف، والموجة ٤٨ رقماً من ٠ إلى ١٠٠.
            $table->unsignedSmallInteger('duration_seconds')->nullable();
            $table->jsonb('waveform')->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index('message_id');
        });

        Schema::table('design_tickets', function (Blueprint $table) {
            // ✓✓: آخرُ رسالةٍ رآها كلُّ طرف. «المصمّم» مَن قبلها، أو مَن أُسندت إليه قبل القبول،
            // ومؤشّرُه يُصفَّر حين يتغيّر — انظر `DesignTicket::booted()`.
            $table->unsignedBigInteger('requester_read_message_id')->nullable();
            $table->unsignedBigInteger('designer_read_message_id')->nullable();
        });

        $this->copyTheNotesIntoTheConversation();
    }

    public function down(): void
    {
        Schema::table('design_tickets', function (Blueprint $table) {
            $table->dropColumn(['requester_read_message_id', 'designer_read_message_id']);
        });

        Schema::dropIfExists('design_ticket_message_attachments');
        Schema::dropIfExists('design_ticket_messages');
    }

    /**
     * كلُّ ملاحظةٍ حيّة على تذكرة تصميم، رسالةً نصية بترتيبها.
     *
     * **بـSQL لا بالنماذج**: الترحيلُ يصف الجداول كما هي ساعته، والنموذجُ يتغيّر بعده. ولهذا لا
     * يُكتب لها سجلُّ تدقيق — السجلُّ القائم على الملاحظات هو قصّتها، وهو باقٍ.
     */
    private function copyTheNotesIntoTheConversation(): void
    {
        DB::statement(<<<'SQL'
            INSERT INTO design_ticket_messages (design_ticket_id, user_id, body, edited_at, created_at, updated_at)
            SELECT commentable_id, user_id, body, edited_at, created_at, updated_at
            FROM comments
            WHERE commentable_type = 'design_ticket'
              AND deleted_at IS NULL
              AND commentable_id IN (SELECT id FROM design_tickets)
            ORDER BY id
        SQL);
    }
};
