<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * التذاكر الداخلية: موظفٌ يكتب إلى زميل — نسخةٌ من تذاكر بريمولا الداخلية، ومعها الرسائل الصوتية.
 * التصميم في Docs/internal-tickets/INTERNAL-TICKETS-DESIGN.md.
 *
 * **جداولُ مستقلّة لا `support_tickets`**، وهو القرار الذي يستحقّ التسجيل. بريمولا تضع التذكرة
 * الداخلية في جدول تذاكر الزبائن وتميّزها بنوعٍ مورفيّ. هنا لا يصلح: `ticket_messages` مبنيٌّ على
 * أن أحد الطرفين عميلٌ دائماً (`ticket_messages_one_author`)، وكلامُ الموظفين بينهم لا يجوز أن يصل
 * عميلاً بخطأ نطاقٍ واحد في استعلام. جدولٌ لا يعرف العملاءَ أصلاً لا يُخطئ هذا الخطأ.
 *
 * **طرفان اثنان، بعمودين لا بجدول أعضاء.** التذكرة بين صاحبها (`opened_by`) وزميلٍ واحد
 * (`assignee_id`)، كما في بريمولا. ولكلٍّ مؤشّرُ قراءةٍ برقم آخر رسالةٍ رآها — النمطُ نفسه الذي
 * انتهت إليه تذاكر الدعم بعد أن خذلتها ساعةُ القراءة بدقّة الثانية.
 *
 * **«حُذفت للجميع» ليست `deleted_at`.** الرسالة التي يسحبها صاحبها تبقى مكانها في المحادثة
 * وتقول «تم حذف هذه الرسالة» (`retracted_at`)؛ و`deleted_at` يبقى لما يعنيه في كل جدولٍ هنا —
 * أرشفةٌ لا يراها أحد. خلطُ الاثنين كان سيجعل كل قراءةٍ للمحادثة `withTrashed()`، ويُرجع ما
 * أُرشف فعلاً مع ما سُحب.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('internal_ticket_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            // نوعٌ أُوقف يبقى على تذاكره القديمة ولا يُعرض في نموذج «تذكرة جديدة».
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes()->index();
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX internal_ticket_categories_name_unique
            ON internal_ticket_categories (name)
            WHERE deleted_at IS NULL
        SQL);

        Schema::create('internal_tickets', function (Blueprint $table) {
            $table->id();

            // `T` ثم الرقم، كـ`D` لتذاكر التصميم. يُحجز من تسلسل الجدول قبل الإدراج — AllocateInternalTicketIdentifier.
            $table->string('code', 20);
            $table->string('title', 255);

            // قيمةٌ من `InternalTicketStatus`. تولد «قيد المعالجة» لا «جديدة»، كبريمولا.
            $table->string('status', 20)->default('in_progress');
            // قيمةٌ من `InternalTicketPriority`.
            $table->string('priority', 10)->default('medium');

            $table->foreignId('category_id')->nullable()->constrained('internal_ticket_categories')->nullOnDelete();

            // صاحبُها — يتغيّر بالتحويل وحده — والزميل الذي وُجّهت إليه.
            $table->foreignId('opened_by')->constrained('users');
            $table->foreignId('assignee_id')->constrained('users');

            $table->foreignId('customer_id')->nullable()->constrained('customers')->nullOnDelete();
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();

            // مؤشّرا القراءة: رقمُ آخر رسالةٍ رآها كلُّ طرف. `null` = لم يفتحها قط.
            $table->unsignedBigInteger('opener_read_message_id')->nullable();
            $table->unsignedBigInteger('assignee_read_message_id')->nullable();

            // لترتيب القائمة بآخر نشاطٍ بلا ربطٍ بكل خيط. يكتبه الفعلُ الذي يكتب الرسالة.
            $table->timestamp('last_message_at')->nullable();

            $table->timestamp('closed_at')->nullable();
            $table->foreignId('closed_by')->nullable()->constrained('users')->nullOnDelete();

            // التذكير كل ساعة بمن تأخّر ردّه: متى ذُكّر آخر مرة، وكم مرةً منذ آخر ردٍّ منه.
            $table->timestamp('last_reminder_at')->nullable();
            $table->unsignedSmallInteger('reminder_count')->default(0);

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['opened_by', 'status']);
            $table->index(['assignee_id', 'status']);
            $table->index('order_id');
            $table->index('customer_id');
            $table->index(['status', 'last_message_at']);
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX internal_tickets_code_unique
            ON internal_tickets (code)
            WHERE deleted_at IS NULL
        SQL);

        // تذكرةٌ يفتحها موظفٌ على نفسه ليست محادثة، وتذكيرُها كل ساعة يوقظ صاحبها بكلامه هو.
        DB::statement(<<<'SQL'
            ALTER TABLE internal_tickets
            ADD CONSTRAINT internal_tickets_two_parties
            CHECK (opened_by <> assignee_id)
        SQL);

        Schema::create('internal_ticket_messages', function (Blueprint $table) {
            $table->id();

            $table->foreignId('internal_ticket_id')->constrained('internal_tickets')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users');

            // فارغٌ لرسالةٍ هي صورةٌ أو صوتٌ وحده.
            $table->text('body')->nullable();

            // الاقتباس: الرسالة التي يردّ عليها هذا الكلام، من التذكرة نفسها — يحرسه الفعل.
            $table->foreignId('reply_to_message_id')->nullable()->constrained('internal_ticket_messages')->nullOnDelete();

            $table->string('client_token', 64)->nullable();

            // «معدّلة»: متى غيّر صاحبُها نصّها آخر مرة. لا `updated_at`، الذي يتحرّك مع أيّ كتابة.
            $table->timestamp('edited_at')->nullable();
            // النصُّ كما أُرسل أول مرة، يُحفظ عند أول تعديلٍ حقيقيّ ولا يُعرض لأحد — للتدقيق عند الخلاف.
            $table->text('original_body')->nullable();
            // «تم حذف هذه الرسالة»: سحبها صاحبها، وتبقى مكانها. انظر تعليق الصنف.
            $table->timestamp('retracted_at')->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['internal_ticket_id', 'id']);
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX internal_ticket_messages_client_token_unique
            ON internal_ticket_messages (internal_ticket_id, client_token)
            WHERE client_token IS NOT NULL AND deleted_at IS NULL
        SQL);

        Schema::create('internal_ticket_attachments', function (Blueprint $table) {
            $table->id();

            $table->foreignId('message_id')->constrained('internal_ticket_messages')->cascadeOnDelete();

            // قيمةٌ من `InternalAttachmentKind`: صورة أو صوت.
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

            // للصوت: المدّة كما قاسها الهاتف — للعرض، والحدُّ الحقيقيّ حجمُ الملف — والموجة
            // ٤٨ رقماً من ٠ إلى ١٠٠ حُسبت أثناء التسجيل. بريمولا لا تحفظ الموجة فيراها المستقبِل
            // مسطّحة؛ هذا الفرقُ الوحيد عنها، بقرار ٢٠٢٦-١٠-٢١.
            $table->unsignedSmallInteger('duration_seconds')->nullable();
            $table->jsonb('waveform')->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index('message_id');
        });

        // الأنواعُ الأولى (السؤال ١ في §١١ من التصميم، بافتراضه). شاشةُ إدارتها لاحقاً.
        $now = now();
        $names = ['طلبية', 'طباعة وإنتاج', 'مخزون', 'حسابات ومدفوعات', 'توصيل', 'أخرى'];

        DB::table('internal_ticket_categories')->insert(array_map(
            fn (string $name, int $order) => [
                'name' => $name,
                'is_active' => true,
                'sort_order' => $order,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            $names,
            array_keys($names),
        ));
    }

    public function down(): void
    {
        Schema::dropIfExists('internal_ticket_attachments');
        Schema::dropIfExists('internal_ticket_messages');
        Schema::dropIfExists('internal_tickets');
        Schema::dropIfExists('internal_ticket_categories');
    }
};
