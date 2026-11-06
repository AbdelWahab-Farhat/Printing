<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use PhpOffice\PhpSpreadsheet\Spreadsheet;

/**
 * قالب للإدخال اليدوي: الأعمدة الثلاثة التي يقرؤها {@see ReadNawrisSettlementFile}.
 *
 * يُولَّد لحظياً: الملف المخزَّن يتعفّن، والقارئ يطابق بأسماء الترويسات.
 *
 * ⚠️ **أرقام المثال مستحيلة عمداً، ولا تُؤخذ من بيانات حيّة أبداً.** في بريمولا كانت حقيقية، فرفع
 * موظف القالب للتجربة وسُوّيت ثلاث طلبيات بلا قصد. وهنا تتحرك معها أموال. أسوأ ما يحدث لو نُسي
 * الصفّان أن يظهرا «لا توجد طلبية بالرقم …».
 */
final class BuildNawrisSettlementTemplate
{
    public function __invoke(): Spreadsheet
    {
        $book = new Spreadsheet;
        $sheet = $book->getActiveSheet();

        $sheet->setTitle(ReadNawrisSettlementFile::SHEET);
        $sheet->setRightToLeft(true);

        $sheet->fromArray([
            ['الحالة', 'الكود', 'اسم المستلم'],
            ['امسح هذه الصفوف قبل الرفع — للتوضيح فقط', '', ''],
            ['تم التسوية', '99999001', '99999001'],
            ['تم التسوية', '99999002', '99999002+99999003'],
        ], null, 'A1', true);

        foreach (['A', 'B', 'C'] as $column) {
            $sheet->getColumnDimension($column)->setAutoSize(true);
        }

        return $book;
    }
}
