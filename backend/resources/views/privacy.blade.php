{{-- The customer app's privacy policy, served at /privacy for the App Store and Google Play.
     Generated from Docs/customer-app/PRIVACY-POLICY.md; change the Markdown and the page together.
     Fonts and the logo are served from this host so that reading the policy sends nothing to a third party. --}}
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>سياسة الخصوصية | تطبيق دعاية</title>
<meta name="description" content="ما يجمعه تطبيق دعاية من بياناتك، ولماذا، ومع من نشاركه، وكيف تطلب حذف حسابك.">
<meta name="color-scheme" content="light dark">
<link rel="icon" type="image/png" href="/images/daaya-mark.png">
@verbatim
<style>
@font-face { font-family: "Cairo"; src: url("/fonts/cairo/Cairo-Regular.ttf") format("truetype"); font-weight: 400; font-display: swap; }
@font-face { font-family: "Cairo"; src: url("/fonts/cairo/Cairo-Bold.ttf") format("truetype"); font-weight: 700; font-display: swap; }
@font-face { font-family: "Cairo"; src: url("/fonts/cairo/Cairo-Black.ttf") format("truetype"); font-weight: 900; font-display: swap; }

:root {
  --page: #f6f5fb;
  --card: #ffffff;
  --ink: #15122b;
  --muted: #5b5878;
  --line: #dddaec;
  --brand: #4c29d0;
  --link: #4c29d0;
  --band: #1b1449;
  --on-band: #ffffff;
  --on-band-muted: #b8b0e8;
  --yellow: #d5d74d;
  --summary: #f8f8de;
  --summary-line: #e3e48f;
  --head: #f1effa;
  --todo: #fff3a3;
}
@media (prefers-color-scheme: dark) {
  :root {
    --page: #0b0919;
    --card: #15122b;
    --ink: #ece9fb;
    --muted: #aaa5c9;
    --line: #2c2852;
    --link: #b8b0e8;
    --band: #0b0919;
    --summary: #23223a;
    --summary-line: #4a4a2a;
    --head: #1d1a3a;
    --todo: #5c5200;
  }
}

* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  margin: 0;
  background: var(--page);
  color: var(--ink);
  font-family: "Cairo", "Geeza Pro", "Segoe UI", Tahoma, sans-serif;
  font-size: 17px;
  line-height: 1.9;
  -webkit-text-size-adjust: 100%;
}

.band { background: var(--band); color: var(--on-band); border-bottom: 4px solid var(--yellow); }
.band .wrap { padding-top: 40px; padding-bottom: 44px; }
.brand { display: flex; align-items: center; gap: 12px; margin-bottom: 26px; text-decoration: none; color: inherit; }
.brand img { width: 46px; height: 46px; padding: 5px; background: #fff; border-radius: 12px; }
.brand span { font-size: 26px; font-weight: 900; }
h1 { margin: 0; font-size: 40px; font-weight: 900; line-height: 1.3; }
.updated { margin: 8px 0 0; color: var(--on-band-muted); font-size: 16px; }

.wrap { max-width: 820px; margin: 0 auto; padding-left: 20px; padding-right: 20px; }
main.wrap { padding-top: 32px; padding-bottom: 48px; }

h2 { font-size: 24px; font-weight: 900; line-height: 1.5; margin: 0 0 12px; }
h2 .anchor { color: inherit; text-decoration: none; }
h2 .anchor:hover { color: var(--link); }
section { margin-top: 40px; scroll-margin-top: 16px; }
p, ul, ol { margin: 0 0 14px; }
ul, ol { padding-inline-start: 24px; }
li { margin-bottom: 6px; }
strong { font-weight: 700; }
a { color: var(--link); text-underline-offset: 3px; }
mark.todo { background: var(--todo); color: inherit; padding: 0 4px; border-radius: 4px; }

.summary { background: var(--summary); border: 1px solid var(--summary-line); border-radius: 16px; padding: 22px 24px 10px; margin-top: 28px; }
.summary h2 { margin-bottom: 8px; }

.toc { background: var(--card); border: 1px solid var(--line); border-radius: 16px; padding: 20px 24px 12px; margin-top: 24px; }
.toc h2 { font-size: 19px; margin-bottom: 6px; }
.toc ol { columns: 2; column-gap: 32px; margin: 0; }
.toc li { break-inside: avoid; }

.table { margin: 6px 0 18px; border: 1px solid var(--line); border-radius: 14px; overflow: hidden; background: var(--card); }
table { width: 100%; border-collapse: collapse; font-size: 15.5px; line-height: 1.75; }
th, td { text-align: start; vertical-align: top; padding: 12px 14px; border-bottom: 1px solid var(--line); }
th { background: var(--head); font-weight: 700; }
tbody tr:last-child td { border-bottom: 0; }
td + td, th + th { border-inline-start: 1px solid var(--line); }

footer { border-top: 1px solid var(--line); color: var(--muted); font-size: 15px; }
footer .wrap { padding-top: 22px; padding-bottom: 32px; }

@media (max-width: 640px) {
  body { font-size: 16px; }
  h1 { font-size: 32px; }
  h2 { font-size: 21px; }
  .band .wrap { padding-top: 28px; padding-bottom: 32px; }
  .wrap { padding-left: 16px; padding-right: 16px; }
  .toc ol { columns: 1; }
  .summary, .toc { padding-left: 18px; padding-right: 18px; }
  /* Each row becomes a card, with its column names written beside the values. */
  .table { border: 0; background: none; border-radius: 0; overflow: visible; }
  table, tbody, tr, td { display: block; width: 100%; }
  thead { display: none; }
  tr { background: var(--card); border: 1px solid var(--line); border-radius: 12px; margin-bottom: 10px; padding: 6px 0; }
  td { border: 0 !important; padding: 4px 14px; }
  td::before { content: attr(data-label); display: block; font-size: 13px; font-weight: 700; color: var(--muted); }
}
</style>
@endverbatim
</head>
<body>
<header class="band">
<div class="wrap">
<a class="brand" href="https://daaya.ly"><img src="/images/daaya-mark.png" alt="" width="46" height="46"><span>دعاية</span></a>
<h1>سياسة الخصوصية لتطبيق «دعاية»</h1>
<p class="updated">آخر تحديث: 23 نوفمبر 2026</p>
</div>
</header>

<main class="wrap">
<p>تشرح هذه السياسة ما يجمعه تطبيق «دعاية» على iOS وAndroid من بياناتك، ولماذا نجمعه، ومع من نشاركه، وكيف تطلب حذفه. يدير التطبيقَ <strong>«دعاية لخدمات الطباعة»</strong>، وهي مطبعة في ليبيا تطبع الأكياس ومواد التغليف. نسمّيها في هذه السياسة «دعاية» أو «نحن».</p>
<p>باستخدامك التطبيق فأنت توافق على ما في هذه السياسة. وإن لم توافق عليها فلا تستخدمه.</p>

<section class="summary" id="summary" aria-labelledby="summary-title">
<h2 id="summary-title">باختصار</h2>
<ul>
<li><strong>نجمع ما تحتاجه طلبيتك فقط:</strong> اسمك، ورقم هاتفك، ومكان التوصيل، وتصاميمك، ورسائلك مع فريق الدعم، ومعاملات محفظتك.</li>
<li><strong>لا نبيع بياناتك</strong>، ولا نعرض في التطبيق إعلانات من أي جهة أخرى، ولا نتتبّعك في التطبيقات والمواقع الأخرى.</li>
<li><strong>لا نطلب موقعك الجغرافي</strong>، ولا نقرأ جهات الاتصال في هاتفك.</li>
<li><strong>لا توجد في التطبيق أدوات تحليلات ولا أدوات لتقارير الأعطال.</strong></li>
<li><strong>تستطيع أن تطلب حذف حسابك في أي وقت</strong> (<a href="#delete-account">القسم 9</a>).</li>
</ul>
</section>

<nav class="toc" aria-label="محتويات السياسة">
<h2>المحتويات</h2>
<ol>
<li><a href="#s1">البيانات التي تعطينا إياها</a></li>
<li><a href="#s2">البيانات التي تنتج عن استخدامك التطبيق</a></li>
<li><a href="#s3">الدفع والمحفظة</a></li>
<li><a href="#s4">أذونات الهاتف</a></li>
<li><a href="#s5">كيف نستعمل بياناتك</a></li>
<li><a href="#s6">مع من نشارك بياناتك</a></li>
<li><a href="#s7">كيف نحمي بياناتك</a></li>
<li><a href="#s8">مدة الاحتفاظ بالبيانات</a></li>
<li><a href="#delete-account">حذف حسابك</a></li>
<li><a href="#s10">حقوقك</a></li>
<li><a href="#s11">الأطفال</a></li>
<li><a href="#s12">الروابط الخارجية</a></li>
<li><a href="#s13">التغييرات على هذه السياسة</a></li>
<li><a href="#s14">تواصل معنا</a></li>
</ol>
</nav>

<section id="s1">
<h2><a class="anchor" href="#s1">1. البيانات التي تعطينا إياها</a></h2>
<div class="table"><table>
<thead><tr><th>البيانات</th><th>متى تعطينا إياها</th><th>لماذا نحتاجها</th></tr></thead>
<tbody>
<tr><td data-label="البيانات"><strong>الاسم</strong>، سواء كان اسمك أو اسم متجرك</td><td data-label="متى تعطينا إياها">عند التسجيل</td><td data-label="لماذا نحتاجها">ليُعرَف حسابك وتُعرَف طلبياتك</td></tr>
<tr><td data-label="البيانات"><strong>رقم الهاتف</strong></td><td data-label="متى تعطينا إياها">عند التسجيل</td><td data-label="لماذا نحتاجها">لتسجيل الدخول، ولنتواصل معك بشأن طلبياتك</td></tr>
<tr><td data-label="البيانات"><strong>كلمة المرور</strong></td><td data-label="متى تعطينا إياها">عند التسجيل</td><td data-label="لماذا نحتاجها">لتسجيل الدخول. لا نحفظ كلمة المرور نفسها، بل نحفظ بصمة مشفّرة منها لا يمكن أن يُستخرج منها النص الأصلي، فلا يعرف كلمة مرورك أحد، حتى موظفونا</td></tr>
<tr><td data-label="البيانات"><strong>بيانات متاجرك</strong>: الاسم، والمدينة، والمنطقة، ومجال العمل، ورابط صفحة المتجر</td><td data-label="متى تعطينا إياها">حين تضيف متجراً في «متاجري»</td><td data-label="لماذا نحتاجها">لتختار منها وجهة التوصيل، وليعرف فريقنا طبيعة نشاطك</td></tr>
<tr><td data-label="البيانات"><strong>روابط صفحاتك على مواقع التواصل</strong></td><td data-label="متى تعطينا إياها">حين تحفظها في «روابط التواصل»</td><td data-label="لماذا نحتاجها">ليطّلع فريقنا على هوية متجرك</td></tr>
<tr><td data-label="البيانات"><strong>بيانات الطلبية</strong>: المنتجات، والمقاسات، والكميات، والمدينة والمنطقة، وهاتف الاستلام، وملاحظاتك</td><td data-label="متى تعطينا إياها">حين ترسل طلبية</td><td data-label="لماذا نحتاجها">لتسعير الطلبية وتجهيزها وتوصيلها</td></tr>
<tr><td data-label="البيانات"><strong>التصاميم والشعارات</strong> (صور أو ملفات PDF)، وأسماؤها، وألوان الطباعة التي تختارها</td><td data-label="متى تعطينا إياها">حين ترفعها إلى «تصاميمي» أو ترفقها بطلبية</td><td data-label="لماذا نحتاجها">لطباعتها على منتجاتك</td></tr>
<tr><td data-label="البيانات"><strong>رسائل الدعم ومرفقاتها</strong></td><td data-label="متى تعطينا إياها">حين تراسل فريق الدعم</td><td data-label="لماذا نحتاجها">للرد عليك ومتابعة طلبك</td></tr>
<tr><td data-label="البيانات"><strong>بيانات الدفع</strong></td><td data-label="متى تعطينا إياها">حين تشحن محفظتك</td><td data-label="لماذا نحتاجها">تجد تفصيلها في <a href="#s3">القسم 3</a></td></tr>
</tbody></table></div>
</section>

<section id="s2">
<h2><a class="anchor" href="#s2">2. البيانات التي تنتج عن استخدامك التطبيق</a></h2>
<ul>
<li><strong>رقم الحساب ورمز العميل:</strong> يُنشآن عند التسجيل.</li>
<li><strong>سجلّ الطلبيات:</strong> مراحل كل طلبية، والمبالغ المدفوعة، وملاحظات فريقنا عليها.</li>
<li><strong>سجلّ المحفظة:</strong> عمليات الشحن والدفع والاسترداد.</li>
<li><strong>رمز الإشعارات:</strong> رمز تصدره خدمة Firebase من Google لهاتفك، ونحفظه حتى تصلك الإشعارات. يُحذف حين تسجّل الخروج.</li>
<li><strong>نوع نظام التشغيل</strong> (iOS أو Android): نحفظه مع كل جلسة دخول لنفرّق بين جلساتك.</li>
<li><strong>عنوان IP وبيانات الاتصال التقنية:</strong> يستقبلها خادمنا مع كل اتصال. نستعملها لحماية الحسابات من محاولات الدخول المتكرّرة وللحفاظ على أمان الخدمة.</li>
<li><strong>سجلّ التعديلات:</strong> نحتفظ بسجلّ للتغييرات التي تطرأ على حسابك وطلبياتك ومحفظتك (ما الذي تغيّر ومتى). نحتاجه للمحاسبة ولحلّ أي خلاف.</li>
</ul>
</section>

<section id="s3">
<h2><a class="anchor" href="#s3">3. الدفع والمحفظة</a></h2>
<p>لكل حساب محفظة واحدة، تشحنها ثم تدفع منها ثمن طلبياتك. أما شحنها إلكترونياً فيمرّ عبر بوابة الدفع <strong>EzonePay</strong>:</p>
<ul>
<li><strong>الدفع بالبطاقة المصرفية:</strong> تُدخل بيانات بطاقتك في صفحة تابعة لـEzonePay تُفتح داخل التطبيق، وتذهب هذه البيانات إلى EzonePay والمصرف مباشرةً. <strong>رقم بطاقتك لا يصل إلينا ولا نحفظه.</strong></li>
<li><strong>طرق الدفع الأخرى</strong> (مثل موبي كاش، وسداد، وادفعلي، وليبيانا): يطلب منك التطبيق رمز الشراء أو رقم الهاتف المسجّل لدى الخدمة، وقد يطلب سنة الميلاد في بعض الطرق، ثم رمز التحقق الذي تصلك به رسالة. نرسل هذه البيانات إلى EzonePay لإتمام هذه العملية وحدها، ولا نستعملها لأي غرض آخر.</li>
<li><strong>ما نرسله إلى EzonePay مع كل عملية:</strong> اسمك، ورقم هاتفك، والمبلغ، ورقماً مرجعياً للعملية.</li>
<li><strong>ما نحتفظ به:</strong> المبلغ، والعمولة، وطريقة الدفع، وحالة العملية، ورقمها لدى EzonePay. هذه سجلات مالية، ومدة الاحتفاظ بها في <a href="#s8">القسم 8</a>.</li>
</ul>
<p>ولا يحتوي التطبيق على أي مشتريات رقمية أو اشتراكات.</p>
</section>

<section id="s4">
<h2><a class="anchor" href="#s4">4. أذونات الهاتف</a></h2>
<p>لا يطلب التطبيق إذناً إلا حين تستعمل الميزة التي تحتاجه، وتستطيع سحب أي إذن منه في إعدادات هاتفك.</p>
<div class="table"><table>
<thead><tr><th>الإذن</th><th>متى يُطلب</th><th>ما الذي نفعله به</th></tr></thead>
<tbody>
<tr><td data-label="الإذن"><strong>الكاميرا</strong></td><td data-label="متى يُطلب">حين تضغط زر التصوير لترفق شعاراً أو تصميماً</td><td data-label="ما الذي نفعله به">نأخذ الصورة التي تلتقطها، ولا شيء غيرها</td></tr>
<tr><td data-label="الإذن"><strong>الصور</strong></td><td data-label="متى يُطلب">حين تختار صورة لترفعها</td><td data-label="ما الذي نفعله به">نأخذ الصورة التي تختارها وحدها</td></tr>
<tr><td data-label="الإذن"><strong>الإضافة إلى الصور</strong></td><td data-label="متى يُطلب">حين تحفظ تصميماً أو رمز QR أو معاينة الكيس</td><td data-label="ما الذي نفعله به">نضيف الصورة إلى ألبومك، ولا نقرأ ما فيه</td></tr>
<tr><td data-label="الإذن"><strong>الملفات</strong></td><td data-label="متى يُطلب">حين تختار ملفاً (PDF مثلاً)</td><td data-label="ما الذي نفعله به">يُفتح منتقي الملفات الخاص بنظام الهاتف، ولا نرى إلا الملف الذي تختاره</td></tr>
<tr><td data-label="الإذن"><strong>الإشعارات</strong></td><td data-label="متى يُطلب">بعد تسجيل الدخول</td><td data-label="ما الذي نفعله به">ننبّهك حين تنتقل طلبيتك إلى مرحلة جديدة، وحين يرد عليك فريق الدعم</td></tr>
</tbody></table></div>
<p>قد يذكر نظام iOS إذنَي <strong>الموقع</strong> و<strong>الميكروفون</strong> في وصف التطبيق، لأن أداة اختيار الصور وأداة التصوير اللتين يوفّرهما النظام تستطيعان الوصول إليهما. لكن التطبيق لا يطلب موقعك ولا يسجّل صوتاً. وقد تحمل الصورة بيانات يضيفها الهاتف إليها، كمكان التقاطها، ونحن لا نستعمل هذه البيانات.</p>
<p><strong>أداة رمز QR وأداة «معاينة على الكيس»</strong> تعملان على هاتفك وحده، ولا يُرسَل منهما شيء إلا إذا أضفت النتيجة بنفسك إلى «تصاميمي».</p>
</section>

<section id="s5">
<h2><a class="anchor" href="#s5">5. كيف نستعمل بياناتك</a></h2>
<ul>
<li>لاستلام طلبياتك وتسعيرها وتصميمها وطباعتها وتوصيلها.</li>
<li>لإدارة محفظتك وتسجيل مدفوعاتك.</li>
<li>للرد عليك حين تراسل الدعم.</li>
<li>لنرسل إليك إشعارات عن طلبياتك وعن ردود الدعم.</li>
<li>لحماية حسابك والخدمة من الدخول غير المشروع ومن الاحتيال.</li>
<li>للمحاسبة، وللوفاء بما يفرضه القانون علينا.</li>
</ul>
<p><strong>لا نستعمل بياناتك للإعلانات، ولا نبني منها ملفاً تسويقياً عنك.</strong></p>
</section>

<section id="s6">
<h2><a class="anchor" href="#s6">6. مع من نشارك بياناتك</a></h2>
<p>لا نبيع بياناتك ولا نؤجّرها. ولا يطّلع عليها إلا هؤلاء، كلٌّ في حدود ما يحتاجه:</p>
<div class="table"><table>
<thead><tr><th>الجهة</th><th>ما يصل إليها</th><th>لماذا</th></tr></thead>
<tbody>
<tr><td data-label="الجهة"><strong>موظفو دعاية</strong></td><td data-label="ما يصل إليها">ما يحتاجه كلٌّ منهم لعمله</td><td data-label="لماذا">لمراجعة طلبيتك وتصميمها وإنتاجها والرد عليك</td></tr>
<tr><td data-label="الجهة"><strong>شركة التوصيل</strong> (حالياً شركة «النورس»)</td><td data-label="ما يصل إليها">رمز الطلبية، وهاتف الاستلام، والمدينة والمنطقة، والمبلغ الذي سيُحصَّل عند التسليم. <strong>لا نرسل إليها اسمك</strong></td><td data-label="لماذا">لتوصيل الطلبية إليك</td></tr>
<tr><td data-label="الجهة"><strong>EzonePay</strong> (بوابة الدفع)</td><td data-label="ما يصل إليها">ما ورد في <a href="#s3">القسم 3</a></td><td data-label="لماذا">لإتمام شحن المحفظة</td></tr>
<tr><td data-label="الجهة"><strong>Google Firebase Cloud Messaging</strong></td><td data-label="ما يصل إليها">رمز الإشعارات ونص الإشعار، مثل «انتقلت طلبيتك إلى مرحلة جديدة»</td><td data-label="لماذا">لإيصال الإشعارات إلى هاتفك</td></tr>
<tr><td data-label="الجهة"><strong>الجهات الرسمية</strong></td><td data-label="ما يصل إليها">ما يطلبه أمر قانوني صحيح</td><td data-label="لماذا">حين يُلزمنا القانون بذلك</td></tr>
</tbody></table></div>
<p>تخضع EzonePay وGoogle وشركة التوصيل لسياسات الخصوصية الخاصة بكلٍّ منها.</p>
</section>

<section id="s7">
<h2><a class="anchor" href="#s7">7. كيف نحمي بياناتك</a></h2>
<ul>
<li>كل الاتصال بين التطبيق وخادمنا مشفّر (HTTPS وWSS).</li>
<li>لا نحفظ كلمة مرورك نفسها، بل نحفظ بصمة مشفّرة منها لا يمكن أن يُستخرج منها النص الأصلي.</li>
<li>يُحفظ رمز جلستك في المخزن الآمن للهاتف (Keychain في iOS وKeystore في Android).</li>
<li>تُفتح ملفاتك وتصاميمك بروابط مؤقتة تنتهي صلاحيتها بعد وقت قصير.</li>
<li>لا يرى أي حساب إلا بياناته، ولا يتواصل العملاء بعضهم مع بعض داخل التطبيق.</li>
<li>نحدّ من عدد محاولات الدخول المسموح بها في وقت قصير، لنحمي الحسابات من التخمين.</li>
</ul>
<p>ولا توجد طريقة لحفظ البيانات أو نقلها آمنة تماماً، لكننا نعمل على حماية بياناتك بكل ما هو معقول.</p>
</section>

<section id="s8">
<h2><a class="anchor" href="#s8">8. مدة الاحتفاظ بالبيانات</a></h2>
<ul>
<li><strong>بيانات حسابك:</strong> نحتفظ بها ما دام حسابك قائماً.</li>
<li><strong>التصميم الذي تحذفه:</strong> يختفي من «تصاميمي» في الحال، ونحتفظ بملفه حتى تبقى طلبياتك السابقة قابلة للمراجعة. ويُحذف الملف إذا حذفت حسابك.</li>
<li><strong>الطلبيات والمدفوعات والمحفظة:</strong> هذه سجلات مالية، نحتفظ بها المدة التي تفرضها علينا الالتزامات المحاسبية والقانونية، حتى بعد حذف الحساب. لكنها حينئذٍ لا تحمل اسمك ولا رقم هاتفك (<a href="#delete-account">القسم 9</a>).</li>
<li><strong>رمز الإشعارات:</strong> يُحذف حين تسجّل الخروج.</li>
</ul>
</section>

<section id="delete-account">
<h2><a class="anchor" href="#delete-account">9. حذف حسابك</a></h2>
<p><strong>كيف تطلب الحذف:</strong> راسل فريق الدعم من داخل التطبيق (أيقونة الدعم في الشريط العلوي)، أو أرسل طلبك عبر واتساب إلى الرقم <strong><a dir="ltr" href="https://wa.me/218927206561">+218 92 720 6561</a></strong> من رقم الهاتف المسجّل في حسابك. ننفّذ الطلب خلال <strong>30 يوماً</strong> على الأكثر.</p>
<p><strong>ما الذي يُحذف:</strong></p>
<ul>
<li>الاسم، ورقم الهاتف، وكلمة المرور.</li>
<li>متاجرك، وروابط صفحاتك على مواقع التواصل.</li>
<li>تصاميمك وملفاتها.</li>
<li>رسائل الدعم ومرفقاتها.</li>
<li>رموز الإشعارات وجلسات الدخول.</li>
</ul>
<p><strong>ما الذي يبقى:</strong> سجلات الطلبيات والمدفوعات والمحفظة، لأن القانون والمحاسبة يُلزماننا بحفظها، لكنها تبقى دون اسمك ودون رقم هاتفك، فلا يمكن أن تُنسب إليك.</p>
<p><strong>قبل الحذف:</strong> إذا كان في محفظتك رصيد، أو كانت لك طلبية لم تُسلَّم بعد، نتواصل معك أولاً لتسويتها.</p>
</section>

<section id="s10">
<h2><a class="anchor" href="#s10">10. حقوقك</a></h2>
<ul>
<li><strong>أن تطّلع على بياناتك:</strong> طلبياتك وتصاميمك ومتاجرك ومحفظتك ورسائلك كلها ظاهرة لك في التطبيق. ولك أن تطلب منا نسخة من بياناتك.</li>
<li><strong>أن تصحّحها:</strong> تستطيع تعديل متاجرك وروابطك وتصاميمك بنفسك. ولتغيير اسمك أو رقم هاتفك راسل الدعم.</li>
<li><strong>أن تحذفها:</strong> كما في <a href="#delete-account">القسم 9</a>.</li>
<li><strong>أن توقف الإشعارات:</strong> من إعدادات هاتفك، في أي وقت.</li>
</ul>
<p>نرد على كل طلب من هذه الطلبات خلال 30 يوماً على الأكثر.</p>
</section>

<section id="s11">
<h2><a class="anchor" href="#s11">11. الأطفال</a></h2>
<p>التطبيق موجّه إلى أصحاب المتاجر والأعمال، وليس موجّهاً إلى الأطفال دون 13 عاماً، ولا نجمع بياناتهم عن علم. فإن علمنا أن طفلاً أنشأ حساباً حذفناه.</p>
</section>

<section id="s12">
<h2><a class="anchor" href="#s12">12. الروابط الخارجية</a></h2>
<p>قد تفتح بعض الإعلانات في الشاشة الرئيسية، وبعض الروابط التي تحفظها، صفحاتٍ خارج التطبيق. لا تسري هذه السياسة على تلك الصفحات، ولكلٍّ منها سياستها الخاصة.</p>
</section>

<section id="s13">
<h2><a class="anchor" href="#s13">13. التغييرات على هذه السياسة</a></h2>
<p>قد نعدّل هذه السياسة حين يتغيّر التطبيق أو تتغيّر القوانين، وسنغيّر تاريخ «آخر تحديث» أعلاها مع كل تعديل. وإذا كان التغيير جوهرياً فسنخبرك به داخل التطبيق قبل أن يسري.</p>
</section>

<section id="s14">
<h2><a class="anchor" href="#s14">14. تواصل معنا</a></h2>
<p>لأي سؤال عن هذه السياسة أو عن بياناتك:</p>
<ul>
<li><strong>من داخل التطبيق:</strong> أيقونة الدعم في الشريط العلوي</li>
<li><strong>واتساب:</strong> <a dir="ltr" href="https://wa.me/218927206561">+218 92 720 6561</a></li>
<li><strong>الموقع الإلكتروني:</strong> <a dir="ltr" href="https://daaya.ly">daaya.ly</a></li>
</ul>
<p>دعاية لخدمات الطباعة، ليبيا</p>
</section>
</main>

<footer>
<div class="wrap">© 2026 دعاية لخدمات الطباعة · <a href="https://daaya.ly">daaya.ly</a></div>
</footer>
</body>
</html>
