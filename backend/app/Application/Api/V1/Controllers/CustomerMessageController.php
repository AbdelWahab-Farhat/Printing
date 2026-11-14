<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Controller;
use App\Domain\Order\Enums\CustomerMessage;
use App\Domain\Order\Support\CustomerMessageTexts;
use App\Domain\Settings\SettingsService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Customer messages
 *
 * The five texts staff copy and send — the two ready messages and the two return messages to
 * customers, and the vendor message on an outsourced order — as the admin wants them worded.
 * Each has a built-in default; saving an empty text puts the default back. `{رقم_الفاتورة}` in a
 * text is replaced with the order's number; `{الأصناف}`, in the vendor text only, with the
 * order's lines and colours. See Docs/orders/ORDER-RETURN-MESSAGE.md §٥ and
 * Docs/outsourced-products/OUTSOURCED-PRODUCTS.md §10.
 */
class CustomerMessageController extends Controller
{
    use ResponseTrait;

    /** Long enough for a few paragraphs, short enough that a paste of the wrong thing is caught. */
    private const MAX_LENGTH = 2000;

    public function __construct(
        private readonly SettingsService $settings,
        private readonly CustomerMessageTexts $texts,
    ) {}

    /**
     * Read the customer messages
     */
    public function show(): JsonResponse
    {
        return $this->success($this->payload());
    }

    /**
     * Update the customer messages
     *
     * Send only the messages being changed, keyed by `key`. Null or an empty string restores
     * the built-in wording.
     */
    public function update(Request $request): JsonResponse
    {
        $rules = ['messages' => ['required', 'array']];

        foreach (CustomerMessage::cases() as $message) {
            $rules["messages.{$message->value}"] = ['sometimes', 'nullable', 'string', 'max:'.self::MAX_LENGTH];
        }

        $validated = $request->validate($rules, [
            'messages.required' => 'لم تصل أيّ رسالة للحفظ',
            'messages.*.max' => 'الرسالة لا تتجاوز '.self::MAX_LENGTH.' حرف',
        ]);

        $columns = [];

        foreach (CustomerMessage::cases() as $message) {
            if (array_key_exists($message->value, $validated['messages'])) {
                $columns[$message->settingColumn()] = $validated['messages'][$message->value];
            }
        }

        $this->settings->updateCustomerMessages($columns, $request->user()?->id);
        $this->texts->forget();

        return $this->success($this->payload(), 'تم حفظ نصوص الرسائل');
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(): array
    {
        return [
            'placeholder' => CustomerMessage::INVOICE_PLACEHOLDER,
            'messages' => array_map(
                fn (CustomerMessage $message): array => [
                    'key' => $message->value,
                    'label' => $message->label(),
                    'body' => $this->texts->template($message),
                    'default_body' => $message->defaultBody(),
                    'is_customised' => $this->texts->isCustomised($message),
                    // What this text may contain besides plain words: the order's number on all
                    // of them, and the line list on the vendor text.
                    'placeholders' => $message->placeholders(),
                ],
                CustomerMessage::cases(),
            ),
        ];
    }
}
