import 'package:flutter/foundation.dart';

/// Public OAuth client identifiers from the Firebase config files
/// (android/app/google-services.json, ios/Runner/GoogleService-Info.plist).
/// These are not secrets; access is enforced by Firebase.
abstract final class GoogleOAuth {
  /// "Web client" (type 3): required by Android Credential Manager to mint
  /// an ID token that Firebase Auth accepts.
  static const webClientId =
      '595724452129-bpso55g5l7rcpl0t96o60brlri927vj1.apps.googleusercontent.com';

  /// iOS client (type 2).
  static const iosClientId =
      '595724452129-l3ds198uauk1ese6i4r8pb2h108a3uab.apps.googleusercontent.com';

  static String? get platformClientId =>
      defaultTargetPlatform == TargetPlatform.iOS ? iosClientId : null;
}
