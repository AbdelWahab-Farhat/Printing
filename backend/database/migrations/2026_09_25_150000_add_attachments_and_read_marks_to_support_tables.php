<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * المحادثة تصير محادثة: ملفٌّ في الرسالة، وعلامةُ قراءةٍ لا تكذب.
 *
 * **ملفٌّ واحد في كل رسالة، أعمدةً في `ticket_messages` لا جدولاً مستقلاً.** هكذا تُرسل تطبيقات
 * المحادثة الملفات: كل صورةٍ رسالة، والتعليق عليها نصُّ الرسالة نفسها. جدولٌ مستقل كان سيفتح
 * «كم ملفاً في الرسالة؟» — سؤالاً لا يسأله أحد — ويضيف نموذجاً بسجلّه وحذفه اللطيف ليقول ما
 * تقوله ثمانية أعمدة. والأسماء على نسق `customer_designs` نفسه، بسابقة `attachment_`.
 *
 * **والنصّ صار اختيارياً، والرسالة لا.** صورةٌ بلا تعليق رسالةٌ كاملة؛ رسالةٌ بلا نصٍّ ولا
 * ملف جملةٌ فارغة لا يُسأل عنها أحد — و`CHECK` أدناه يقولها على الجدول نفسه، كما يقول قيدُ
 * الكاتب الواحد إن للرسالة كاتباً.
 *
 * **`client_token` يجعل الإعادة آمنة.** التطبيق يولّد الرمز قبل الإرسال؛ اتصالٌ انقطع بعد الحفظ
 * يترك صاحبه لا يعرف هل وصلت رسالته، فيعيد — والرمز نفسه يُرجع الرسالة نفسها بدل نسخةٍ ثانية.
 * فريدٌ داخل التذكرة وحدها، وجزئيٌّ كما تقتضي قاعدة الحذف اللطيف.
 *
 * **مؤشّر القراءة رقمُ رسالة لا ساعة.** `*_read_at` بدقّة الثانية، فرسالةٌ كُتبت في الثانية التي
 * فُتح فيها الخيط كانت تُعدّ مقروءة ولم تُعرض على أحد: ✓✓ كاذبة، وشارةٌ لا تظهر لردٍّ جديد.
 * الرقم لا يتساوى فيه اثنان. والساعتان باقيتان لما تقولانه فعلاً — متى قُرئ — لا لما قُرئ.
 * بلا مفتاحٍ أجنبي عمداً: المؤشّر حدٌّ عدديّ لا إشارةٌ إلى صفّ، والرسائل لا تُحذف حذفاً حقيقياً.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ticket_messages', function (Blueprint $table) {
            $table->text('body')->nullable()->change();

            $table->string('attachment_disk', 40)->nullable();
            $table->string('attachment_path')->nullable();
            // ما سمّاه صاحبه، للعرض وحده. المسار على القرص يولّده الخادم ولا يأخذ منه شيئاً.
            $table->string('attachment_filename')->nullable();
            // مقروءٌ من البايتات بـfinfo، لا من ادّعاء العميل.
            $table->string('attachment_mime_type', 100)->nullable();
            // قيمةٌ من `AttachmentKind`.
            $table->string('attachment_kind', 20)->nullable();
            $table->unsignedBigInteger('attachment_size_bytes')->nullable();
            // للصور وحدها، كي يحجز التطبيق مكانها قبل أن تصل فلا تقفز المحادثة تحت الإصبع.
            $table->unsignedInteger('attachment_width_px')->nullable();
            $table->unsignedInteger('attachment_height_px')->nullable();

            $table->string('client_token', 64)->nullable();
        });

        DB::statement(<<<'SQL'
            ALTER TABLE ticket_messages
            ADD CONSTRAINT ticket_messages_says_something
            CHECK (body IS NOT NULL OR attachment_path IS NOT NULL)
        SQL);

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX ticket_messages_client_token_unique
            ON ticket_messages (support_ticket_id, client_token)
            WHERE client_token IS NOT NULL AND deleted_at IS NULL
        SQL);

        Schema::table('support_tickets', function (Blueprint $table) {
            $table->unsignedBigInteger('customer_read_message_id')->nullable();
            $table->unsignedBigInteger('staff_read_message_id')->nullable();
        });

        // **كل طرفٍ يخرج بالمقروء نفسه الذي دخل به**: آخرُ رسالةٍ كُتبت حتى ساعة قراءته، لا
        // آخرُ رسالةٍ في الخيط — وإلا صار ردٌّ لم يُقرأ مقروءاً وانطفأت شارته بلا سبب.
        foreach (['customer', 'staff'] as $side) {
            DB::statement(<<<SQL
                UPDATE support_tickets
                SET {$side}_read_message_id = (
                    SELECT MAX(ticket_messages.id)
                    FROM ticket_messages
                    WHERE ticket_messages.support_ticket_id = support_tickets.id
                      AND ticket_messages.created_at <= support_tickets.{$side}_read_at
                )
                WHERE {$side}_read_at IS NOT NULL
            SQL);
        }
    }

    public function down(): void
    {
        Schema::table('support_tickets', function (Blueprint $table) {
            $table->dropColumn(['customer_read_message_id', 'staff_read_message_id']);
        });

        DB::statement('DROP INDEX IF EXISTS ticket_messages_client_token_unique');
        DB::statement('ALTER TABLE ticket_messages DROP CONSTRAINT IF EXISTS ticket_messages_says_something');

        // رسالةٌ كانت ملفاً وحده تحتاج نصاً قبل أن يعود العمود إلزامياً: اسمُ ملفها.
        DB::statement("UPDATE ticket_messages SET body = COALESCE(attachment_filename, '') WHERE body IS NULL");

        Schema::table('ticket_messages', function (Blueprint $table) {
            $table->dropColumn([
                'attachment_disk', 'attachment_path', 'attachment_filename', 'attachment_mime_type',
                'attachment_kind', 'attachment_size_bytes', 'attachment_width_px', 'attachment_height_px',
                'client_token',
            ]);
            $table->text('body')->nullable(false)->change();
        });
    }
};
