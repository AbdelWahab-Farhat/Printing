<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Realtime;

use Illuminate\Foundation\Http\FormRequest;

/**
 * ما يرسله عميلُ Pusher حين يطلب دخول قناةٍ خاصة: رقمَ مقبسه واسمَ القناة.
 *
 * **شكلُ رقم المقبس يُفحص هنا، ولسببٍ عملي.** مكتبةُ Pusher في PHP ترمي استثناءً عاماً على رقمٍ
 * مشوّه، فيصير الطلبُ خطأً ٥٠٠ في السجل بدل ٤٢٢ يفهمه من أرسله.
 */
class AuthorizeChannelRequest extends FormRequest
{
    public function authorize(): bool
    {
        // الحارسُ على المسار هو من يقرّر من يطرق، والقناةُ نفسها في routes/channels.php هي من
        // يقرّر من يدخل.
        return true;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            // بصيغة Pusher: رقمان بينهما نقطة، كما يمنحه الخادمُ للمقبس ساعةَ يتصل.
            'socket_id' => ['required', 'string', 'regex:/\A\d+\.\d+\z/'],
            'channel_name' => ['required', 'string', 'max:200'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['socket_id' => 'رقم الاتصال', 'channel_name' => 'القناة'];
    }
}
