<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Controller;
use App\Domain\Investor\Queries\FundCashLedger;
use App\Domain\Investor\Queries\FundGoodsOnOrder;
use App\Domain\Investor\Queries\FundGoodsOut;
use App\Domain\Investor\Queries\FundProfitOwed;
use App\Domain\Investor\Queries\FundShelfStock;
use App\Domain\Investor\Queries\FundValuation;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * ما وراء كلِّ بندٍ في لوحة الصندوق
 *
 * اللوحةُ تقول «نقد ٩٬٣٦٢ — بضاعة على الرفّ ١٢٬٢١٦ — خرجت ولم تُسلَّم ٣٤٠ — أرباح مستحقّة
 * ١٬١٠٦». وطلبُ المالك 2026-09-24 أن يُفتح كلُّ رقمٍ على ما صنعه: النقدُ على سجلّه داخلاً
 * وخارجاً، والبضاعةُ على موادّها، والخارجةُ والمسلَّمةُ غيرُ المحصَّلة على طلبياتها، والأرباحُ
 * على الطلبيات التي أعطتها.
 *
 * **وكلُّ قائمةٍ تجمع إلى رقم اللوحة الذي فُتحت منه** — تقرأ الصفوفَ نفسَها التي يجمعها
 * {@see FundValuation}. قراءةٌ كلُّها، بصلاحية اللوحة نفسِها.
 */
class FundBreakdownController extends Controller
{
    use ResponseTrait;

    public function __construct(
        private readonly FundCashLedger $cashLedger,
        private readonly FundGoodsOnOrder $onOrder,
        private readonly FundShelfStock $shelf,
        private readonly FundGoodsOut $goodsOut,
        private readonly FundProfitOwed $profitOwed,
    ) {}

    /**
     * List the fund's cash movements
     *
     * الأحدثُ أوّلاً، بما بقي في الخزينة بعد كلّ حركة، وبما جاء منه المالُ أو ذهب إليه.
     * و`meta.balance` نقدُ اللوحة بعينه.
     */
    public function cash(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'page' => ['nullable', 'integer', 'min:1'],
        ]);

        $ledger = $this->cashLedger->page((int) ($validated['page'] ?? 1));

        return $this->successWithMeta($ledger['rows'], [
            'current_page' => $ledger['current_page'],
            'per_page' => $ledger['per_page'],
            'last_page' => $ledger['last_page'],
            'total' => $ledger['total'],
            'balance' => $ledger['balance'],
        ]);
    }

    /**
     * List the purchases the fund paid for that have not arrived yet
     *
     * أوامرُ الشراء التي خرج ثمنُها من الخزينة ولم تصل بضاعتُها الرفَّ بعد — كاملةً أو ما نقص منها.
     */
    public function onOrder(): JsonResponse
    {
        return $this->success(($this->onOrder)());
    }

    /**
     * List the goods on the fund's shelf
     */
    public function shelf(): JsonResponse
    {
        return $this->success(($this->shelf)());
    }

    /**
     * List the orders holding the fund's goods on their way
     */
    public function inFlight(): JsonResponse
    {
        return $this->success($this->goodsOut->inFlight());
    }

    /**
     * List the delivered orders the fund has not been paid for
     */
    public function receivables(): JsonResponse
    {
        return $this->success($this->goodsOut->uncollected());
    }

    /**
     * Break the profit owed to investors down by order
     */
    public function profitOwed(): JsonResponse
    {
        return $this->success(($this->profitOwed)());
    }
}
