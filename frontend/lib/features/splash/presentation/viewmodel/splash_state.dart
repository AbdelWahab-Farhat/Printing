part of 'splash_cubit.dart';

/// The four things the app can know on start-up.
///
/// Note what is *not* here: a single "failure" case. Splitting "your session ended" from "the
/// server did not answer" is the whole fix — one of them is the user's problem to solve with a
/// password, and the other is not their problem at all.
@freezed
sealed class SplashState with _$SplashState {
  /// The logo, and a request in flight.
  const factory SplashState.checking() = SplashChecking;

  /// The token is good. → the home screen.
  const factory SplashState.signedIn() = SplashSignedIn;

  /// There is no token, or the server said the token is dead. → the login screen.
  const factory SplashState.signedOut() = SplashSignedOut;

  /// The check could not be completed. The session is not in question, so the screen stays put
  /// and offers to try again — [failure] carries the server's own words for why.
  const factory SplashState.unreachable(Failure failure) = SplashUnreachable;
}
