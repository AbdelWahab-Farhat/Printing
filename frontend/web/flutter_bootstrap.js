{{flutter_js}}
{{flutter_build_config}}

// الإقلاعُ الافتراضي بلا `serviceWorkerSettings`: عاملُ Flutter الخدمي مهمَلٌ في Flutter نفسه، والذي
// يُولَّد اليوم لا يخزّن شيئاً — يسجّل نفسه ثم يلغي تسجيله في كل زيارة. طلبٌ لا يفعل شيئاً.
_flutter.loader.load();
