<?php

declare(strict_types=1);

namespace Tests\Feature\Audit;

use App\Domain\Audit\AuditHiddenAttributes;
use Tests\TestCase;

/**
 * The columns a history screen has no reader for.
 *
 * A file's row carries two kinds of column. «رقم النسخة», «الحالة», «رفعها» are what happened —
 * the things somebody opens a history to find out. `disk`, `path`, `checksum`, `width_px` are how
 * the file is kept, and nobody in a printing shop in Tripoli has ever needed to know that a JPEG
 * lives on `local` at `design-tickets/1/34d4c062-….jpg` with a sha256 of `cc1ff8c…`. Nine such
 * lines were drawn on a card that had four worth reading, and the noise buried them.
 *
 * **They are still logged, and deliberately.** The trail records what the row did; this file only
 * says what the screen draws — so the checksum of a file that turns out to be the wrong one is
 * still there to be found in the table, and a row written before today is cleaned up by the same
 * read as a row written after it.
 *
 * The rule is a suffix rather than a list of columns, for the reason `AuditValueLabels` derives a
 * foreign key from the model's own relation: `receipt_checksum` and `image_path` are the same two
 * columns with a prefix, and the next model that stores a file will name them the same way. A
 * list would be right until the morning somebody adds a table and forgets it.
 *
 * Arrange - Act - Assert throughout.
 */
class AuditHiddenAttributesTest extends TestCase
{
    public function test_the_storage_columns_are_taken_out_of_a_change(): void
    {
        // Arrange — the eight columns `StoredFile` writes, beside the three a person reads.
        $attributes = [
            'design_ticket_id' => 1,
            'kind' => 'submission',
            'disk' => 'local',
            'path' => 'design-tickets/1/34d4c062.jpg',
            'mime_type' => 'image/jpeg',
            'size_bytes' => 156393,
            'checksum' => 'cc1ff8c535c196b2259f03d02f46f66d4995f0ab',
            'width_px' => 1340,
            'height_px' => 1785,
            'version' => 1,
            'status' => 'proposed',
        ];

        // Act
        $shown = AuditHiddenAttributes::strip($attributes);

        // Assert — what is left is the sentence: which ticket, which kind, which version, what
        // verdict. The name the uploader gave the file stays too; see the test below.
        $this->assertSame(
            ['design_ticket_id' => 1, 'kind' => 'submission', 'version' => 1, 'status' => 'proposed'],
            $shown,
        );
    }

    public function test_the_same_column_under_a_prefix_is_taken_out_too(): void
    {
        // Arrange — a receipt on a shortage supply and a photo on a stock item group, which
        // carry the media layer under a prefix rather than plain.
        $attributes = [
            'receipt_disk' => 'local',
            'receipt_path' => 'receipts/9/a.pdf',
            'receipt_checksum' => 'ab12',
            'receipt_size_bytes' => 4096,
            'image_path' => 'groups/3/photo.png',
            'image_width_px' => 800,
            'image_height_px' => 600,
            'amount' => '250.00',
        ];

        // Act
        $shown = AuditHiddenAttributes::strip($attributes);

        // Assert — nothing here was registered anywhere. The prefix is the only difference, and
        // a rule that reads the suffix covers the next one for free.
        $this->assertSame(['amount' => '250.00'], $shown);
    }

    public function test_the_name_the_uploader_gave_the_file_is_not_storage(): void
    {
        // Arrange — «شعار-الشركة.pdf» is a name a person chose, and on an attachment it is the
        // only handle the row has: `DesignTicketFile::displayName()` falls back to it for
        // anything that is not a numbered version.
        $attributes = ['original_filename' => 'شعار-الشركة.pdf', 'receipt_original_filename' => 'فاتورة.pdf'];

        // Act
        $shown = AuditHiddenAttributes::strip($attributes);

        // Assert
        $this->assertSame($attributes, $shown);
    }

    public function test_the_size_a_bag_is_printed_at_is_not_a_pixel_count(): void
    {
        // Arrange — `width_cm` and `height_cm` are the product, not the file. The suffix rule
        // reads `_px`, and this is the test that keeps it reading that far.
        $attributes = ['width_cm' => '25.00', 'height_cm' => '35.00'];

        // Act
        $shown = AuditHiddenAttributes::strip($attributes);

        // Assert
        $this->assertSame($attributes, $shown);
    }

    public function test_a_half_that_never_existed_stays_absent(): void
    {
        // Arrange — a creation records no `old`, and a deletion no `attributes`. Null is how the
        // entry says so, and an empty object here would claim a half that was never written.
        // Anything that is not an array comes back untouched for the same reason: a row written
        // by an older build has to stay readable.
        // Act & Assert
        $this->assertNull(AuditHiddenAttributes::strip(null));
        $this->assertSame('نص قديم', AuditHiddenAttributes::strip('نص قديم'));
    }
}
