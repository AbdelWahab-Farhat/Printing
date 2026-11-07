<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\DTOs\NawrisSettlementRow;
use App\Domain\Carrier\Exceptions\NawrisSettlementRefused;
use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

/**
 * تقرير النورس (`MissionsPreviewsReport_*.xlsx`) صفوفاً خام.
 *
 * **الأعمدة تُلتقط بنص الترويسة لا برقمها.** النورس يضيف عموداً بين حين وآخر، والقراءة بالفهرس
 * تصير حينها تقرأ «المدينة» على أنها «المستلم» وتُسوّي الطلبية الخطأ بلا أي خطأ ظاهر. وبهذا يُرفع
 * التقرير كما هو، بكل أعمدته.
 */
final class ReadNawrisSettlementFile
{
    public const SHEET = 'الطرود';

    /** حارس ذاكرة لا قاعدة عمل. */
    public const MAX_ROWS = 5000;

    /** النورس غيّر تسمياتها من قبل. */
    private const HEADERS = [
        'status' => ['الحالة', 'حالة الطرد'],
        'code' => ['الكود', 'كود النورس', 'كود الطرد'],
        'receiver' => ['اسم المستلم', 'المستلم'],
    ];

    /** ما تتسع له أعمدة السطر الخام. */
    private const CELL_LIMIT = 255;

    /**
     * @return list<NawrisSettlementRow>
     */
    public function __invoke(string $path): array
    {
        $book = $this->open($path);

        [$sheet, $columns] = $this->locate($book);

        // بلا تنسيق: رقم الطلبية يبقى رقماً، لا «1,203».
        $cells = $sheet->toArray(null, true, false, false);
        array_shift($cells);

        $rows = [];

        foreach ($cells as $index => $cell) {
            $status = $this->cell($cell, $columns['status']);
            $code = $this->cell($cell, $columns['code']);
            $receiver = $this->cell($cell, $columns['receiver']);

            // حشو في آخر الملف.
            if ($status === '' && $code === '' && $receiver === '') {
                continue;
            }

            $rows[] = new NawrisSettlementRow($index + 1, $status, $code, $receiver);

            if (count($rows) > self::MAX_ROWS) {
                throw NawrisSettlementRefused::tooManyRows(self::MAX_ROWS);
            }
        }

        $book->disconnectWorksheets();

        if ($rows === []) {
            throw NawrisSettlementRefused::noRows();
        }

        return $rows;
    }

    private function open(string $path): Spreadsheet
    {
        // ملفٌ تالف جوابُه الرفض لا عطل — ما يسمّيه RULES §٥ فحصاً فشلُه هو الجواب.
        $book = rescue(function () use ($path): Spreadsheet {
            $reader = IOFactory::createReaderForFile($path, [IOFactory::READER_XLSX, IOFactory::READER_XLS]);
            $reader->setReadDataOnly(true);

            return $reader->load($path);
        }, null, false);

        return $book ?? throw NawrisSettlementRefused::unreadable();
    }

    /**
     * الورقة المتوقعة أولاً، وإلا أول ورقة تحمل الترويسات.
     *
     * @return array{0: Worksheet, 1: array{status: int, code: int, receiver: int}}
     */
    private function locate(Spreadsheet $book): array
    {
        $preferred = $book->getSheetByName(self::SHEET);

        foreach (array_filter([$preferred, ...$book->getAllSheets()]) as $sheet) {
            $columns = $this->columns($sheet);

            if ($columns !== null) {
                return [$sheet, $columns];
            }
        }

        throw NawrisSettlementRefused::missingHeaders();
    }

    /**
     * @return array{status: int, code: int, receiver: int}|null
     */
    private function columns(Worksheet $sheet): ?array
    {
        $header = $sheet->rangeToArray('A1:'.$sheet->getHighestColumn().'1', null, true, false, false)[0] ?? [];
        $header = array_map(fn (mixed $value): string => $this->normalize((string) $value), $header);

        $columns = [];

        foreach (self::HEADERS as $field => $names) {
            $found = array_intersect($header, $names);

            if ($found === []) {
                return null;
            }

            $columns[$field] = (int) array_key_first($found);
        }

        return $columns;
    }

    /** فراغ زائد أو «الـحـالـة» بتطويل لا يُسقطان الملف. */
    private function normalize(string $value): string
    {
        $value = str_replace("\u{0640}", '', $value);

        return trim(preg_replace('/\s+/u', ' ', $value) ?? $value);
    }

    /**
     * @param  array<int, mixed>  $cell
     */
    private function cell(array $cell, int $column): string
    {
        return mb_substr(trim((string) ($cell[$column] ?? '')), 0, self::CELL_LIMIT);
    }
}
