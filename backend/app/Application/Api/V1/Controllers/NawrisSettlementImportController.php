<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Carrier\ImportNawrisSettlementRequest;
use App\Application\Api\V1\Requests\Carrier\PreviewNawrisSettlementRequest;
use App\Application\Api\V1\Resources\NawrisSettlementImportResource;
use App\Application\Api\V1\Resources\NawrisSettlementPreviewResource;
use App\Application\Controller;
use App\Domain\Carrier\CarrierService;
use App\Domain\Carrier\DTOs\NawrisSettlementSubmission;
use App\Domain\Carrier\Models\NawrisSettlementImport;
use App\Domain\Identity\Models\User;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Nawris settlement file
 *
 * تسوية الطلبيات دفعةً واحدة من تقرير النورس. خطوتان: **معاينة** لا تكتب شيئاً، ثم **تنفيذ** يسوّي
 * ما يصلح ويتخطّى ما عداه. Docs/nawris/NAWRIS-SETTLEMENT-IMPORT.md.
 */
class NawrisSettlementImportController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly CarrierService $carrier) {}

    /**
     * Download the template
     *
     * ثلاثة أعمدة للإدخال اليدوي. الموظف لا يحتاجه غالباً: تقرير النورس يُرفع كما هو.
     */
    public function template(): StreamedResponse
    {
        $book = $this->carrier->settlementTemplate();

        return response()->streamDownload(
            fn () => (new Xlsx($book))->save('php://output'),
            'قالب-تسوية-النورس.xlsx',
            ['Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
        );
    }

    /**
     * Preview a file
     *
     * قرار كل طلبية **بلا كتابة حرف واحد**: `settled` تُسوّى، `already_settled` مسوّاة سلفاً،
     * `rejected` لن تتحرك وسببها في `reason`. و`total_held` ما عند النورس للتي ستُسوّى وحدها.
     */
    public function preview(PreviewNawrisSettlementRequest $request): JsonResponse
    {
        $preview = $this->carrier->previewSettlement(
            (string) $request->file('file')?->getRealPath(),
            $this->actor($request),
        );

        return $this->success(new NawrisSettlementPreviewResource($preview), 'معاينة التسوية — لم يتغيّر شيء');
    }

    /**
     * Settle a file
     *
     * يسوّي ما يصلح ويتخطّى الباقي. يُرفض بـ409 إن تغيّرت الطلبيات أو ما عند النورس منذ المعاينة،
     * ولا يُنفَّذ شيء. وبالرمز نفسه يعيد الدفعة نفسها، فالضغطة الثانية لا تسوّي مرتين.
     */
    public function store(ImportNawrisSettlementRequest $request): JsonResponse
    {
        $file = $request->file('file');

        $import = $this->carrier->importSettlement(
            (string) $file?->getRealPath(),
            NawrisSettlementSubmission::fromArray((string) $file?->getClientOriginalName(), $request->validated()),
            $request->user(),
        );

        return $this->created(
            new NawrisSettlementImportResource($this->carrier->loadSettlementImport($import)),
            "سُوّيت {$import->settled_count} طلبية من {$import->orders_count}",
        );
    }

    /**
     * List past batches
     *
     * الأحدث أولاً، بلا أسطرها.
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min(max((int) $request->integer('per_page', 15), 1), 100);

        return $this->successWithPagination(
            NawrisSettlementImportResource::collection($this->carrier->settlementImports($perPage)),
        );
    }

    /**
     * Show a batch
     *
     * بكل أسطرها وأسبابها.
     */
    public function show(NawrisSettlementImport $import): JsonResponse
    {
        return $this->success(new NawrisSettlementImportResource($this->carrier->loadSettlementImport($import)));
    }

    private function actor(Request $request): ?User
    {
        $user = $request->user();

        return $user instanceof User ? $user : null;
    }
}
