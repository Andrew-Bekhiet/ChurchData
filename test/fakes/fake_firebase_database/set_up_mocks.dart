import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// Set up firebase core for tests.
void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFirebase.api = FakeFirebaseCoreHostApi();
}

class FakeFirebaseCoreHostApi extends FirebaseCoreHostApi {
  @override
  Future<List<PigeonInitializeResponse?>> initializeCore() {
    return Future.value(
      [
        PigeonInitializeResponse(
          name: defaultFirebaseAppName,
          options: PigeonFirebaseOptions(
            apiKey: '123',
            appId: '123',
            messagingSenderId: '123',
            projectId: '123',
          ),
          pluginConstants: {},
        ),
      ],
    );
  }

  @override
  Future<PigeonInitializeResponse> initializeApp(
    String argAppname,
    PigeonFirebaseOptions argInitializeapprequest,
  ) {
    return Future.value(
      PigeonInitializeResponse(
        name: argAppname,
        options: argInitializeapprequest,
        pluginConstants: {},
      ),
    );
  }
}
