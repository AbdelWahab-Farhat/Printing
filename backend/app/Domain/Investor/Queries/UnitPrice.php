<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Support\FundDeal;

/**
 * بكم تُشترى وحدةٌ اليوم — الرقمُ الذي يجعل الداخلَ الجديد لا يأخذ ولا يُعطي.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٣، البند ١٤.
 *
 * ```
 * سعرُ الوحدة = قيمةُ الصندوق ÷ الوحدات القائمة
 * ```
 *
 * ## مثالُ المالك، بالأرقام
 *
 * ألفٌ من الأول وألفٌ ومئتان من الثاني اشترت بضاعةً صارت تساوي ١٬٦٠٠ بعد بيعٍ وشراء. الوحداتُ
 * ٢٬٢٠٠ والقيمةُ ١٬٦٠٠، فالوحدةُ بـ٠٫٧٢٧. ومن يدخل بـ١٬١٠٠ يشتري ١٬٥١٢ وحدة — أربعين بالمئة من
 * الصندوق، لا ثلثاً كما توحي نسبةُ المال المدفوع، **ولا شيئاً من ربحٍ صُنع قبله**: هو دفع سعرَ
 * البضاعة كما هي اليوم، لا سعرَها يوم اشتُريت.
 *
 * وهذا هو الفرقُ كلُّه بين هذا النظام والسابق، بعبارة المالك: «يعتبر مالكها لاكن مش هاذي القطعة
 * بالذات بل يملك قيمتها».
 *
 * ## والحالتان الحدّيّتان
 *
 * **لا وحداتِ بعد** — أول دينارٍ في عمر الصندوق: السعرُ واحدٌ صحيح، فيصير الدينارُ وحدة. ولا
 * يمكن أن تكون هناك قيمةٌ تُقسَم وقتها، لأن قيمة الصندوق كلَّها جاءت ممّا اشترته وحداتٌ.
 *
 * **وحداتٌ وقيمةٌ صفرٌ أو أقلّ** — صندوقٌ خسر كلَّ ما فيه. السعرُ يبقى موجباً بأصغر ما تمثّله
 * الخانةُ السادسة: صفرٌ كان سيقسم على صفر، وسالبٌ كان سيعطي الداخلَ الجديد وحداتٍ سالبة. وهي
 * حالٌ لا تقع إلا بعد شطبٍ كامل، ويُستحسن أن تُرى على الشاشة لا أن تنفجر.
 */
final class UnitPrice
{
    /** أصغرُ سعرٍ تمثّله الخانةُ السادسة — أرضيةٌ تمنع القسمةَ على صفر. */
    public const FLOOR = '0.000001';

    public function __construct(
        private readonly FundValuation $valuation,
        private readonly FundUnits $units,
        private readonly FundDeal $fund,
    ) {}

    public function __invoke(): string
    {
        $outstanding = $this->units->outstanding();

        if (bccomp($outstanding, '0', FundUnits::SCALE) <= 0) {
            return bcadd('1', '0', FundUnits::SCALE);
        }

        $dealId = $this->fund->idOrNull();
        $value = ($this->valuation)($dealId)['total'];

        if (bccomp($value, '0', 2) <= 0) {
            return self::FLOOR;
        }

        $price = bcdiv($value, $outstanding, FundUnits::SCALE);

        return bccomp($price, self::FLOOR, FundUnits::SCALE) <= 0 ? self::FLOOR : $price;
    }
}
