import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:trio/firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<bool> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return true;
    } catch (error) {
      debugPrint('Firebase non disponibile: $error');
      return false;
    }
  }
}
