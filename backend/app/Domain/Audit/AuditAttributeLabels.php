<?php

declare(strict_types=1);

namespace App\Domain\Audit;

use App\Domain\Audit\Enums\AuditSubject;

/**
 * What to call each column in a history screen.
 *
 * A change is stored as the column that moved — `page_url`, `min_order_quantity` — because that
 * is what actually changed, and a log that stored a translated name would be a log that reworded
 * itself the day somebody edited a string. But `page_url` is not a thing anybody in a printing
 * shop in Tripoli has ever heard of, so the screen showing it was a screen of database keys.
 *
 * **The dictionary belongs here, on the side that owns the schema.** The alternative was a map
 * inside the Flutter app, and that one is wrong the first morning somebody adds a column: the
 * server would send it, the phone would have no entry, and there is no build that fails. Sent
 * with the entry, an unlabelled column is unlabelled everywhere at once — and
 * `AuditAttributeLabelsTest` reads the real tables and fails before it can ship.
 *
 * A column with no entry is not an error at read time. The client falls back to the raw name,
 * which is exactly what the screen showed before this file existed.
 */
final class AuditAttributeLabels
{
    /**
     * Columns that mean the same thing wherever they appear.
     *
     * `name` is deliberately **not** here: «اسم العميل» and «اسم المحل» sit in the same list on
     * the customer's screen, and one «الاسم» twice would be the ambiguity this file exists to
     * remove.
     *
     * @var array<string, string>
     */
    private const SHARED = [
        'code' => 'الكود',
        'phone' => 'رقم الهاتف',
        'notes' => 'ملاحظات',
        'is_active' => 'مفعّل',
        'sort_order' => 'الترتيب',
        'status' => 'الحالة',
        'latitude' => 'خط العرض',
        'longitude' => 'خط الطول',
        'darb_branch' => 'فرع درب',
        'fulfilment_type' => 'طريقة الاستلام',
        'pricing_unit' => 'وحدة التسعير',
        'delivery_price' => 'سعر التوصيل',

        // The media layer, which is the same five columns on every model that stores a file.
        'disk' => 'مكان التخزين',
        'path' => 'مسار الملف',
        'original_filename' => 'اسم الملف',
        'mime_type' => 'نوع الملف',
        'size_bytes' => 'حجم الملف',
        'checksum' => 'بصمة الملف',
        'width_px' => 'العرض بالبكسل',
        'height_px' => 'الارتفاع بالبكسل',
    ];

    /**
     * Keyed by {@see AuditSubject::value}. Wins over {@see SHARED} where both name a column.
     *
     * @var array<string, array<string, string>>
     */
    private const PER_SUBJECT = [
        'user' => [
            'name' => 'الاسم',
            'email' => 'البريد الإلكتروني',
            'email_verified_at' => 'تاريخ توثيق البريد',
            'employee_code' => 'الرقم الوظيفي',
        ],
        'role' => [
            'name' => 'اسم الدور',
            'guard_name' => 'نطاق الصلاحية',
        ],

        'customer' => [
            'name' => 'اسم العميل',
        ],
        'customer_shop' => [
            'customer_id' => 'العميل',
            'name' => 'اسم المحل',
            'city_id' => 'المدينة',
            'region_id' => 'المنطقة',
            'page_url' => 'رابط الصفحة',
        ],
        'customer_design' => [
            'customer_id' => 'العميل',
            'kind' => 'نوع التصميم',
            'label' => 'اسم التصميم',
        ],

        'product' => [
            'name' => 'اسم المنتج',
            'slug' => 'المعرّف',
            'description' => 'الوصف',
            'features' => 'المزايا',
            'category' => 'التصنيف',
            'pricing_mode' => 'طريقة التسعير',
            'min_order_quantity' => 'أقل كمية للطلب',
        ],
        'product_variant' => [
            'product_id' => 'المنتج',
            'label' => 'المقاس',
            'width_cm' => 'العرض (سم)',
            'height_cm' => 'الارتفاع (سم)',
        ],
        'product_price_tier' => [
            'product_variant_id' => 'المقاس',
            'min_quantity' => 'ابتداءً من كمية',
            'unit_price' => 'سعر القطعة',
        ],
        'product_image' => [
            'product_id' => 'المنتج',
            'alt_text' => 'النص البديل',
            'is_primary' => 'الصورة الرئيسية',
        ],

        'city' => [
            'name' => 'اسم المدينة',
            'is_region_required' => 'المنطقة إلزامية',
        ],
        'region' => [
            'city_id' => 'المدينة',
            'name' => 'اسم المنطقة',
        ],
        'shipping_company' => [
            'name' => 'اسم شركة التوصيل',
        ],

        'order' => [
            'customer_id' => 'العميل',
            'customer_shop_id' => 'المحل',
            'customer_shop_name' => 'اسم المحل',
            'city_id' => 'المدينة',
            'city_name' => 'اسم المدينة',
            'region_id' => 'المنطقة',
            'region_name' => 'اسم المنطقة',
            'design_source' => 'مصدر التصميم',
            'recipient_name' => 'اسم المستلم',
            'recipient_phone' => 'هاتف المستلم',
            'address_details' => 'تفاصيل العنوان',
            'items_total' => 'إجمالي البنود',
            'design_fee' => 'رسوم التصميم',
            'discount' => 'الخصم',
            'grand_total' => 'الإجمالي',
            'shipping_company' => 'شركة الشحن',
            'tracking_number' => 'رقم التتبّع',
            'courier_name' => 'اسم المندوب',
            'placed_at' => 'تاريخ الطلب',
            'design_started_at' => 'بدء التصميم',
            'printing_started_at' => 'بدء الطباعة',
            'ready_at' => 'تاريخ الجاهزية',
            'dispatched_at' => 'تاريخ الإرسال',
            'delivered_at' => 'تاريخ التسليم',
            'returned_at' => 'تاريخ الإرجاع',
            'cancelled_at' => 'تاريخ الإلغاء',
            'cancellation_reason' => 'سبب الإلغاء',
            'created_by' => 'أنشأها',
        ],
        'order_item' => [
            'order_id' => 'الطلبية',
            'product_id' => 'المنتج',
            'product_name' => 'اسم المنتج',
            'product_variant_id' => 'المقاس',
            'variant_label' => 'اسم المقاس',
            'quantity' => 'الكمية',
            'unit_price' => 'سعر الوحدة',
            'line_total' => 'إجمالي البند',
        ],
        'order_design' => [
            'order_id' => 'الطلبية',
            'customer_design_id' => 'التصميم',
            'version' => 'الإصدار',
            'rejection_reason' => 'سبب الرفض',
            'reviewed_at' => 'تاريخ المراجعة',
            'reviewed_by' => 'راجعها',
        ],
        'order_status_transition' => [
            'order_id' => 'الطلبية',
            'from_status' => 'من حالة',
            'to_status' => 'إلى حالة',
            'reason' => 'السبب',
            'user_id' => 'المستخدم',
        ],
    ];

    /**
     * Every label this kind of record has.
     *
     * @return array<string, string>
     */
    public static function for(AuditSubject $subject): array
    {
        return array_merge(self::SHARED, self::PER_SUBJECT[$subject->value] ?? []);
    }

    /**
     * Just the labels for the columns in one entry.
     *
     * Narrowed rather than sent whole: a history page carries fifteen entries, and shipping the
     * order dictionary's forty entries with each of them would be most of the response.
     *
     * @param  list<string>  $attributes
     * @return array<string, string>
     */
    public static function forAttributes(?AuditSubject $subject, array $attributes): array
    {
        if ($subject === null || $attributes === []) {
            return [];
        }

        return array_intersect_key(self::for($subject), array_flip($attributes));
    }
}
