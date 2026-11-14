<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Notification;

use App\Domain\Notification\Enums\NotificationType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * One push switch for an employee — Docs/notifications/PUSH-PREFERENCES.md.
 *
 * Behind `users.manage` on the route. Whether the type and scope name a real switch is the
 * domain's question (`SetPushPreference`), not this request's.
 */
class SetPushPreferenceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'type' => ['required', 'string', Rule::enum(NotificationType::class)],
            // Omitted or empty for a type that is one switch; an order status for `order.status`.
            'scope' => ['nullable', 'string', 'max:40'],
            'push' => ['required', 'boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'type' => 'نوع الإشعار',
            'scope' => 'الحالة',
            'push' => 'إشعار على الهاتف',
        ];
    }

    public function notificationType(): NotificationType
    {
        return NotificationType::from((string) $this->validated('type'));
    }

    public function scope(): string
    {
        return (string) ($this->validated('scope') ?? '');
    }
}
