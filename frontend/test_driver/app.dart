import 'package:flutter_driver/driver_extension.dart';
import 'package:printing/main.dart' as app;

/// The app, with the Flutter Driver extension switched on.
///
/// A second entry point rather than a flag inside `main`, so the extension — which opens a
/// service port that will drive taps into the UI — cannot possibly end up in a release build.
/// Outside `lib/` for the same reason: nothing here is compiled into the app people install.
///
/// ```bash
/// flutter run test_driver/app.dart --dart-define=FLAVOR=dev   # then drive it from tooling
/// ```
///
/// It exists so a screen can be *checked* rather than described: open the drawer, tap through a
/// form, and take a screenshot of what the user would actually see. `flutter test` does not
/// need it and does not use it.
void main() {
  enableFlutterDriverExtension();
  app.main();
}
