<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use App\Domain\DesignTicket\Events\DesignTicketAssigned;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

/**
 * مرفقاتُ الطلب مع إنشائه: `files[]` على `POST design-tickets`.
 *
 * كانت التذكرة تُنشأ أولاً ثم تُرفق ملفاتها من شاشتها، فيُبلَّغ المصمّمون بطلبٍ بلا شعاره. الآن
 * تصل التذكرة وملفاتها معاً: كلُّها أو لا شيء، والتبليغ بعدها.
 *
 * Arrange - Act - Assert throughout.
 */
class DesignTicketCreateWithAttachmentsTest extends DesignTicketTestCase
{
    public function test_a_ticket_raised_with_files_carries_them_as_its_brief_in_the_order_they_were_picked(): void
    {
        // Arrange
        [$employeeUser, $headers] = $this->employee();
        $customer = $this->customer();

        // Act
        $response = $this->post('/api/v1/design-tickets', $this->payload($customer, [
            'files' => [
                $this->image('logo.png'),
                UploadedFile::fake()->create('menu.pdf', 40, 'application/pdf'),
            ],
        ]), $headers + ['Accept' => 'application/json']);

        // Assert
        $response->assertCreated()
            ->assertJsonCount(2, 'data.attachments')
            ->assertJsonPath('data.attachments.0.original_filename', 'logo.png')
            ->assertJsonPath('data.attachments.1.original_filename', 'menu.pdf')
            ->assertJsonPath('data.attachments.1.file_kind', 'pdf');

        $files = DesignTicket::query()->sole()->files;
        $this->assertSame(
            [DesignTicketFileKind::Brief, DesignTicketFileKind::Brief],
            $files->pluck('kind')->all(),
        );
        $this->assertSame([$employeeUser->id, $employeeUser->id], $files->pluck('uploaded_by_user_id')->all());
        $files->each(fn (DesignTicketFile $file) => Storage::disk('local')->assertExists($file->path));
    }

    /** الإشعارُ «عندك طلبٌ جديد» يصل والملفات في مكانها، لا قبلها. */
    public function test_the_designers_are_told_once_and_only_after_the_files_are_on_the_ticket(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        $customer = $this->customer();
        $filesWhenTold = [];
        Event::listen(DesignTicketAssigned::class, function (DesignTicketAssigned $event) use (&$filesWhenTold): void {
            $filesWhenTold[] = DesignTicketFile::query()->where('design_ticket_id', $event->ticketId)->count();
        });

        // Act
        $this->post('/api/v1/design-tickets', $this->payload($customer, [
            'files' => [$this->image('a.png'), $this->image('b.png')],
        ]), $headers + ['Accept' => 'application/json'])->assertCreated();

        // Assert
        $this->assertSame([2], $filesWhenTold);
    }

    /** ملفٌّ واحدٌ مرفوض يردّ الطلب كلَّه: لا تذكرةٌ ناقصة ولا ملفاتٌ يتيمة. */
    public function test_one_refused_file_refuses_the_whole_request(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        $customer = $this->customer();

        // Act
        $response = $this->post('/api/v1/design-tickets', $this->payload($customer, [
            'files' => [
                $this->image('logo.png'),
                UploadedFile::fake()->create('prices.xlsx', 16, 'application/vnd.ms-excel'),
            ],
        ]), $headers + ['Accept' => 'application/json']);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['files.1' => 'الملف يجب أن يكون صورة أو PDF']);
        $this->assertSame(0, DesignTicket::query()->count());
        $this->assertSame([], Storage::disk('local')->allFiles());
    }

    public function test_more_files_than_the_limit_are_refused(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        $customer = $this->customer();
        $limit = (int) config('media.design_tickets.max_files_on_create');
        $files = array_map(fn (int $i) => $this->image("ref-{$i}.png"), range(1, $limit + 1));

        // Act
        $response = $this->post(
            '/api/v1/design-tickets',
            $this->payload($customer, ['files' => $files]),
            $headers + ['Accept' => 'application/json'],
        );

        // Assert
        $response->assertStatus(422)->assertJsonPath('errors.files.0', "لا تزيد المرفقات على {$limit}");
        $this->assertSame(0, DesignTicket::query()->count());
    }

    /**
     * عطلٌ بعد أن خُزّن ملفٌّ أو اثنان: تُلغى التذكرة، وتُمحى ملفاتها من القرص، ولا يُبلَّغ أحد.
     *
     * يُفتعل العطل عند حفظ صفّ الملف الثاني — أي بعد أن كُتبت بايتاته على القرص.
     */
    public function test_a_failure_while_attaching_leaves_no_ticket_no_files_and_no_notification(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        $customer = $this->customer();
        $saved = 0;
        DesignTicketFile::creating(function () use (&$saved): void {
            if (++$saved === 2) {
                throw new RuntimeException('القرص امتلأ');
            }
        });
        Event::fake([DesignTicketAssigned::class]);

        // Act
        $response = $this->post('/api/v1/design-tickets', $this->payload($customer, [
            'files' => [$this->image('a.png'), $this->image('b.png')],
        ]), $headers + ['Accept' => 'application/json']);

        // Assert
        $response->assertStatus(500);
        $this->assertSame(0, DesignTicket::query()->count());
        $this->assertSame(0, DesignTicketFile::query()->count());
        $this->assertSame([], Storage::disk('local')->allFiles());
        Event::assertNotDispatched(DesignTicketAssigned::class);
    }
}
