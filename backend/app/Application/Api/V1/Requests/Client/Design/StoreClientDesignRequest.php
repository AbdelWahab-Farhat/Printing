<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Design;

use App\Application\Api\V1\Requests\Customer\StoreCustomerDesignRequest;
use App\Domain\Customer\Support\PrintColors;

/**
 * A customer uploading their own artwork.
 *
 * **Extends the staff request rather than restating it**, because the rules that matter here are
 * the file rules — the magic-byte `mimetypes` check, the absent `svg`, the size cap read from
 * config — and those are security decisions that must exist exactly once. A copy would be a
 * second list to keep in step, and the copy that drifts is always the one facing the internet.
 *
 * Two differences. `notes` is dropped: that field is what staff write to each other about a
 * design, and it is neither shown to the customer nor settable by them. The controller also
 * simply never passes it, so this is the outer of two guards rather than the only one.
 *
 * And «ألوان الطباعة» are the customer's **name and swatch** — the swatch required, because
 * choosing the colour is the whole point of letting them — with no code: that is staff's to
 * write. The code rule is dropped here, and `ChooseDesignColors`' rule that strips codes is
 * applied to the upload too, so this is again the outer guard.
 */
class StoreClientDesignRequest extends StoreCustomerDesignRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $rules = parent::rules();

        unset($rules['notes'], $rules['print_colors.*.code']);

        $rules['print_colors.*.hex'] = ['required', 'string', 'regex:'.PrintColors::HEX_PATTERN];

        return $rules;
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return parent::messages() + [
            'print_colors.*.hex.required' => 'اختر لون كل حبر',
        ];
    }
}
