<?php

declare(strict_types=1);

namespace App\Domain\Comment\Contracts;

use App\Domain\Comment\Concerns\HasComments;
use App\Domain\Comment\Models\Comment;
use Illuminate\Database\Eloquent\Relations\MorphMany;

/**
 * سجلٌّ يجوز للموظفين أن يتركوا عليه ملاحظات، والسؤال الوحيد الذي يختلف بين السجلات: **هل ما تزال
 * المحادثة مفتوحة؟**
 *
 * ملاحظات العميل لا تنتهي أبداً — العميل ما يزال عميلاً، وأوّلُ ما يُعرف عنه بعد سنواتٍ يستحقّ أن
 * يُكتب. وملاحظات تذكرة التصميم تنتهي: التذكرة تنتهي، و«بعد الاعتماد لا يوجد مزيد». وعقدٌ واحد،
 * لأن المتحكّم الذي يخدم الاثنين عليه أن يسأل دون أن يعرف أيَّهما يحمل، ولأن `commentable` على
 * `Comment` مكتوبةٌ `Model` مجرّداً — وهذا ما يجعل سؤالها سؤالاً يسمح به نظام الأنواع.
 *
 * و{@see HasComments} تجيب عن الثلاثة جوابَ المفتوح، فيبقى الانضمام سطرَ `use` واحداً وهذا الاسم
 * في قائمة `implements`؛ والسجلُّ الذي ينتهي يتجاوز الاثنين اللذين يحتاجهما.
 */
interface Commentable
{
    /**
     * @return MorphMany<Comment, $this>
     */
    public function comments(): MorphMany;

    /** هل ما يزال يجوز أن يُكتب هنا شيء، أو يُعاد كتابته، أو يُحذف. */
    public function acceptsComments(): bool;

    /**
     * لماذا أُغلقت، بكلمات السجلّ نفسه — «اعتُمد التصميم وأُغلقت المحادثة».
     *
     * و`null` ما دامت مفتوحة. والسجلُّ هو الذي يقول هذا لا ميزةُ التعليقات، لأن «مغلقة» وحدها
     * تترك المصمّم يتساءل هل وصلت رسالته الأخيرة، ولأن التذكرة وحدها تعرف أيَّ نهايتيها بلغت.
     */
    public function commentsClosedNote(): ?string;
}
