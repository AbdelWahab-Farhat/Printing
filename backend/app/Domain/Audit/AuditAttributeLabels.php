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

        // The warehouse and money vocabulary, which reads the same on a purchase order, an
        // arrival, a batch and a movement — the whole point of this list. Naming them per
        // subject would be the same word written nine times, and nine chances to differ.
        'quantity' => 'الكمية',
        'unit' => 'الوحدة',
        'unit_cost' => 'تكلفة الوحدة',
        'total_cost' => 'إجمالي التكلفة',
        'amount' => 'المبلغ',
        'cost_type' => 'نوع التكلفة',
        'warehouse_id' => 'المخزن',
        'vendor_id' => 'المورد',
        'stock_item_id' => 'المادة',
        // On a product it is «what this is made of», on a stock item «which material this is a
        // size of» — near enough the same sentence that one word serves both.
        'stock_item_group_id' => 'التصنيف',
        'product_variant_id' => 'المقاس',
        'order_id' => 'الطلبية',
        'recorded_by' => 'سجّلها',

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
            'salary' => 'الراتب',
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
            'business_field_id' => 'مجال العمل',
        ],
        'customer_design' => [
            'customer_id' => 'العميل',
            'kind' => 'نوع التصميم',
            'label' => 'اسم التصميم',
        ],
        'comment' => [
            'commentable_type' => 'نوع السجل',
            'commentable_id' => 'السجل',
            'user_id' => 'المستخدم',
            'body' => 'نص الملاحظة',
            'edited_at' => 'تاريخ التعديل',
        ],
        'business_field' => [
            'name' => 'اسم مجال العمل',
        ],

        'product' => [
            'name' => 'اسم المنتج',
            'slug' => 'المعرّف',
            'description' => 'الوصف',
            'features' => 'المزايا',
            'pricing_mode' => 'طريقة التسعير',
            'min_order_quantity' => 'أقل كمية للطلب',
            // «تصنيف المنتج» while a `category` column stood beside it; the word is free now.
            'product_category_id' => 'التصنيف',
        ],
        'product_category' => [
            'name' => 'اسم التصنيف',
            'description' => 'الوصف',
            'parent_id' => 'التصنيف الرئيسي',
            // Worth a history entry more than most: turning it on changes the road every order
            // taken under this heading walks from that moment — see `ResolveOrderFlow`.
            'skips_production' => 'يتخطّى التصميم والطباعة',
            // Four columns for one picture, and all four are read the same way by somebody
            // scanning a history: «تغيّرت الصورة». Naming them separately is what stops the
            // screen printing `image_path` at them.
            'image_disk' => 'قرص صورة التصنيف',
            'image_path' => 'مسار صورة التصنيف',
            'image_width_px' => 'عرض الصورة (بكسل)',
            'image_height_px' => 'ارتفاع الصورة (بكسل)',
        ],
        'product_variant' => [
            'product_id' => 'المنتج',
            'label' => 'المقاس',
            'width_cm' => 'العرض (سم)',
            'height_cm' => 'الارتفاع (سم)',
        ],
        // The material a family of shelves is made of. Renaming it renames every size of it, so
        // «اسم التصنيف» is the entry somebody scanning a history will see most often.
        'stock_item_group' => [
            'name' => 'اسم التصنيف',
            'default_unit' => 'وحدة التخزين الافتراضية',
            'description' => 'الوصف',
        ],
        // The shelf itself. `name` and the two dimensions are its own words rather than the
        // shared ones above, because «الاسم» on a stock item means the material — «كيس شحن» —
        // and the size beside it is what makes the row a shelf rather than a category.
        //
        // **`unit` is deliberately absent**, even though it is the most important column here.
        // The shared list above already names it «الوحدة», and a per-subject override would make
        // the word differ by one row — which is precisely what stops `AuditAttributeLabelsTest`
        // treating it as shared, and it would then be read as a claim that every *other* subject
        // has a `unit` column too. Same word everywhere, or it is not shared vocabulary.
        'stock_item' => [
            'name' => 'اسم المادة',
            'width_cm' => 'العرض (سم)',
            'height_cm' => 'الارتفاع (سم)',
            'description' => 'الوصف',
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
            'ready_to_print_at' => 'تاريخ الجاهزية للطباعة',
            'design_started_at' => 'بدء التصميم',
            'printing_started_at' => 'بدء الطباعة',
            'ready_at' => 'تاريخ الجاهزية',
            'dispatched_at' => 'تاريخ الإرسال',
            'delivered_at' => 'تاريخ التسليم',
            'returned_at' => 'تاريخ الإرجاع',
            'cancelled_at' => 'تاريخ الإلغاء',
            'cancellation_reason' => 'سبب الإلغاء',
            'created_by' => 'أنشأها',
            'paid_amount' => 'المدفوع',
            'written_off_amount' => 'المشطوب',
            'collected_amount' => 'المبلغ المحصّل',
            'settled_at' => 'تاريخ التسوية',
            // «شركة التوصيل» beside the older free-text `shipping_company`، وهما لا يجتمعان في
            // صفٍّ واحد: أحدهما اسمٌ مكتوب باليد والآخر الشركة المسجّلة عندنا.
            'shipping_company_id' => 'شركة التوصيل',
            'courier_phone' => 'هاتف المندوب',
            'stock_deducted_at' => 'تاريخ خصم المخزون',
            'fulfillment_warehouse_id' => 'مخزن التنفيذ',
            'total_cogs' => 'إجمالي تكلفة البضاعة',
            // Its *values* need no dictionary: `OrderFlow` names itself, and AuditValueLabels
            // translates any enum-cast column whose enum can — so a history row reads «بلا تصميم
            // وطباعة» rather than `no_production`.
            'production_flow' => 'مسار التنفيذ',
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
            'shortage_quantity' => 'الكمية الناقصة',
            'warehouse_quantity' => 'الكمية من المخزن',
            'material_cost' => 'تكلفة الخامات',
            'labor_cost' => 'تكلفة العمالة',
            'overhead_cost' => 'التكاليف غير المباشرة',
            'cogs' => 'تكلفة البضاعة',
            'fulfillment_stock_movement_id' => 'حركة الصرف المخزني',
        ],
        'order_payment' => [
            'type' => 'نوع الدفعة',
            'method' => 'طريقة الدفع',
            'reference' => 'المرجع',
            'paid_at' => 'تاريخ الدفع',
            // The reversal, not the reversed: a payment is never edited, it is undone by a
            // second row pointing back at the first. See PAYMENTS-DESIGN.md.
            'reverses_payment_id' => 'تعكس الدفعة',
            'receipt_disk' => 'مكان تخزين الإيصال',
            'receipt_path' => 'مسار الإيصال',
            'receipt_original_filename' => 'اسم ملف الإيصال',
            'receipt_size_bytes' => 'حجم الإيصال',
            'receipt_checksum' => 'بصمة الإيصال',
        ],
        'manufacturing_cost_rate' => [
            'product_id' => 'المنتج',
            'rate_per_unit' => 'التكلفة للوحدة',
        ],
        'production_cost_entry' => [
            'order_item_id' => 'بند الطلبية',
            'rate' => 'المعدّل',
            'incurred_at' => 'تاريخ التكلفة',
            'reverses_entry_id' => 'يعكس القيد',
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

        'warehouse' => [
            'name' => 'اسم المخزن',
            'type' => 'نوع المخزن',
            'location' => 'الموقع',
        ],
        'warehouse_stock' => [
            'low_stock_threshold' => 'حدّ التنبيه',
        ],
        'stock_movement' => [
            'from_warehouse_id' => 'من مخزن',
            'to_warehouse_id' => 'إلى مخزن',
            'movement_type' => 'نوع الحركة',
            'reference_id' => 'المرجع',
            'employee_id' => 'الموظف',
        ],
        'stock_batch' => [
            'source_type' => 'مصدر الدفعة',
            'stock_arrival_item_id' => 'بند التوريد',
            'quantity_received' => 'الكمية المستلمة',
            'quantity_remaining' => 'الكمية المتبقية',
            'received_at' => 'تاريخ الاستلام',
        ],
        'stock_batch_consumption' => [
            'stock_batch_id' => 'دفعة التكلفة',
            'stock_movement_id' => 'الحركة المخزنية',
        ],

        'vendor' => [
            'name' => 'اسم المورد',
            'contact_person' => 'مسؤول التواصل',
            'email' => 'البريد الإلكتروني',
            'address' => 'العنوان',
        ],
        'stock_arrival' => [
            'received_by' => 'استلمها',
            'invoice_number' => 'رقم الفاتورة',
            'purchase_order_id' => 'أمر الشراء',
        ],
        'stock_arrival_item' => [
            'stock_arrival_id' => 'التوريد',
            'stock_movement_id' => 'الحركة المخزنية',
        ],

        'purchase_order' => [
            'order_date' => 'تاريخ الأمر',
            'expected_date' => 'التاريخ المتوقع',
            'total_amount' => 'الإجمالي',
            // Part of `total_amount`, not on top of it: every line's final cost already carries
            // its share. The wording says «منها» for that reason, as the detail screen does.
            'total_additional_cost' => 'منها تكاليف إضافية',
        ],
        'purchase_order_item' => [
            'purchase_order_id' => 'أمر الشراء',
            'quantity_ordered' => 'الكمية المطلوبة',
            'quantity_received' => 'الكمية المستلمة',
            // «الأساسية» is what the vendor invoiced; «النهائية» is what the goods landed at
            // once delivery and customs were spread over the lines. A history screen that
            // called both «التكلفة» would show a cost changing for no visible reason.
            'base_total_cost' => 'التكلفة الأساسية',
            'base_unit_cost' => 'تكلفة الوحدة الأساسية',
            'allocated_additional_cost' => 'حصة التكاليف الإضافية',
            'final_unit_cost' => 'تكلفة الوحدة النهائية',
            'final_total_cost' => 'التكلفة النهائية',
        ],
        'purchase_order_additional_cost' => [
            'purchase_order_id' => 'أمر الشراء',
            // Not the shared «الاسم»: this names what the charge was for — التوصيل، الجمارك —
            // which is what the form asks for and what the invoice calls it.
            'name' => 'البيان',
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
