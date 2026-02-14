import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Set up firebase core for tests.
void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFirebase.api = FakeFirebaseCoreHostApi();
}

class FakeFirebaseCoreHostApi extends FirebaseCoreHostApi {
  @override
  Future<List<CoreInitializeResponse>> initializeCore() {
    return Future.value(
      [
        CoreInitializeResponse(
          name: defaultFirebaseAppName,
          options: CoreFirebaseOptions(
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
  Future<CoreInitializeResponse> initializeApp(
    String argAppname,
    CoreFirebaseOptions argInitializeapprequest,
  ) {
    return Future.value(
      CoreInitializeResponse(
        name: argAppname,
        options: argInitializeapprequest,
        pluginConstants: {},
      ),
    );
  }
}
