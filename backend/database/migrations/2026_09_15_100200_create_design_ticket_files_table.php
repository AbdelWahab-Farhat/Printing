<?php

declare(strict_types=1);

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Every file on a design ticket — the employee's brief and the designer's versions.
 *
 * **One table with a `kind`, not two tables**, and the reason is how it is read rather than how
 * it is written. The ticket screen draws an attachment strip and a version timeline from the same
 * fetch; splitting them would buy a distinction that the shape constraint below buys with one
 * column, at the cost of a second model, a second resource and a second set of routes.
 *
 * **The bytes live here rather than in `customer_designs`, and that is the feature.** The obvious
 * alternative was to send every designer upload straight into the customer's library and point at
 * it, exactly as `order_designs` does. It fails the brief's own acceptance criterion: "التصميم
 * النهائي **فقط** هو الذي يضاف إلى حساب الزبون". Rejected drafts are a work conversation, not the
 * customer's property, and keeping them out of that library by construction is better than a
 * filter on an endpoint that works today and that somebody will later forget. On approval,
 * `PromoteApprovedDesign` writes the winner across. See DESIGN-TICKETS-DESIGN.md §3.
 *
 * The media columns are the same ones `customer_designs` carries, written by the same
 * `StoreUploadedFile` — the disk and the path per row, never a URL, so moving to S3 stays a
 * config change with no migration.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('design_ticket_files', function (Blueprint $table) {
            $table->id();

            $table->foreignId('design_ticket_id')->constrained('design_tickets')->cascadeOnDelete();

            // DesignTicketFileKind — `brief` (what the employee sent: the logo, a similar design)
            // or `submission` (what the designer drew).
            $table->string('kind', 20);

            // ── the file itself, as written by App\Support\Media\StoreUploadedFile ──
            $table->string('disk', 30);
            $table->string('path', 1024);
            $table->string('original_filename')->nullable();

            // Sniffed from the bytes on upload, never taken from the client's claim.
            $table->string('mime_type', 100);

            // DesignKind — `image` or `pdf`. Reuses the Customer context's enum rather than
            // declaring a second one: it answers the same question for the same reason, which is
            // whether the app can draw this thing or must hand it to the system viewer.
            $table->string('file_kind', 10);

            $table->unsignedBigInteger('size_bytes');

            // sha256 of the contents. Not a uniqueness key here — a designer may legitimately
            // re-upload an unchanged file alongside a new note — but it is what makes promoting
            // the winner into the customer's library idempotent, because *that* table's checksum
            // index answers with the existing row.
            $table->char('checksum', 64);

            $table->unsignedInteger('width_px')->nullable();
            $table->unsignedInteger('height_px')->nullable();

            // ── the version story, for submissions only ──

            /*
             * 1, 2, 3 … within the ticket. **Allocated, not counted** (`max(version) + 1` over
             * trashed rows included), so removing version 2 does not make the next upload a
             * second version 3 — «التصميم الثالث» keeps meaning the file it meant in the
             * conversation. The same rule `AddOrderDesign` follows, for the same reason.
             */
            $table->unsignedSmallInteger('version')->nullable();

            // DesignSubmissionStatus — proposed | approved | changes_requested.
            $table->string('status', 20)->nullable();

            /*
             * **What has to change** — «كبّر الشعار وغيّر الرقم».
             *
             * Required by the action when the verdict is «تعديل مطلوب», on the argument
             * `DesignRejectionRequiresReason` already makes: the whole value of keeping versions
             * is knowing *why* one was replaced, and a rejection with no words turns the history
             * into a count. Enforced in the action rather than here, because the database cannot
             * express "required for one value" without a constraint that must then also know
             * about every future status.
             */
            $table->text('review_note')->nullable();

            $table->timestamp('reviewed_at')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();

            // Who put this file here — the employee on a brief, the designer on a submission.
            $table->foreignId('uploaded_by_user_id')->nullable()
                ->constrained('users')->nullOnDelete();

            // The designer's own note sent with the version. Distinct from `review_note`, which
            // is the employee's reply about it.
            $table->text('note')->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            // Both lists on the ticket screen read this way: the attachments and the versions,
            // each in its own order, from one index.
            $table->index(['design_ticket_id', 'kind', 'version']);
        });

        /*
         * **The shape constraint** — the column that earns this table the right to be one table.
         *
         * A submission is numbered and has a verdict; a brief has neither, and may not acquire a
         * review either. Written in the same form as `shortages_source_shape`, and for the same
         * reason: a rule only the careful path respects is one the second path, written a year
         * from now by somebody who did not read this file, walks straight past.
         */
        $submission = DesignTicketFileKind::Submission->value;

        DB::statement(<<<SQL
            ALTER TABLE design_ticket_files
                ADD CONSTRAINT design_ticket_files_kind_shape CHECK (
                    (kind = '{$submission}' AND version IS NOT NULL AND status IS NOT NULL)
                    OR
                    (kind <> '{$submission}' AND version IS NULL AND status IS NULL
                     AND review_note IS NULL AND reviewed_at IS NULL AND reviewed_by IS NULL)
                )
        SQL);

        // Two rows claiming to be version 3 of the same ticket is a bug, not a decision. Partial
        // on both counts: a brief has no version and must not compete for the single NULL slot,
        // and a removed submission must not hold a number it no longer uses.
        DB::statement(<<<SQL
            CREATE UNIQUE INDEX design_ticket_files_unique_version_per_ticket
                ON design_ticket_files (design_ticket_id, version)
                WHERE kind = '{$submission}' AND deleted_at IS NULL
        SQL);

        /*
         * **At most one approved version per ticket.**
         *
         * The same index `order_designs` carries, for the same reason: "which one did we agree
         * on?" has to have an answer, and two approved versions make it unanswerable. It is also
         * what the promotion into the customer's library reads, so a second approved row would be
         * a second design on the customer's account for one request.
         */
        $approved = DesignSubmissionStatus::Approved->value;

        DB::statement(<<<SQL
            CREATE UNIQUE INDEX design_ticket_files_one_approved_per_ticket
                ON design_ticket_files (design_ticket_id)
                WHERE status = '{$approved}' AND deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('design_ticket_files');
    }
};
