import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase/src/interop/messaging_interop.dart';
import 'package:firebase/src/interop/remote_config_interop.dart';

export 'package:cloud_firestore/cloud_firestore.dart';
export 'package:cloud_functions/cloud_functions.dart';
// export 'package:firebase_auth_web/firebase_auth_web.dart';
export 'package:firebase_core/firebase_core.dart';
export 'package:firebase_storage/firebase_storage.dart' hide ListOptions;

class ServerValue {
  static Object get timestamp => firebase.ServerValue.TIMESTAMP;
}

class FirebaseAuth {
  static FirebaseAuthWeb get instance => FirebaseAuthWeb.instance;
}

class Database {
  firebase.DatabaseReference child(String path) {
    return firebase.database().ref(path);
  }

  Database reference() {
    return this;
  }
}

class FirebaseCrashlytics {
  static FirebaseCrashlytics get instance => FirebaseCrashlytics();

  void recordError(error, stackTrace) {}
  void recordFlutterError(error) {}
  void setCustomKey(key, value) {}
}

class FirebaseDatabase {
  static Database get instance => Database();
}

class FirebaseMessaging implements firebase.Messaging {
  static firebase.Messaging get instance => firebase.messaging();
  FirebaseMessaging();

  @override
  MessagingJsImpl get jsObject => instance.jsObject;

  @override
  Stream<firebase.Payload> get onBackgroundMessage =>
      instance.onBackgroundMessage;

  @override
  Stream<firebase.Payload> get onMessage => instance.onMessage;

  @override
  Stream<Null> get onTokenRefresh => instance.onTokenRefresh;

  void configure({
    Future<dynamic> Function(Map<String, dynamic> message) onMessage,
    Future<dynamic> Function(Map<String, dynamic> message) onBackgroundMessage,
    Future<dynamic> Function(Map<String, dynamic> message) onLaunch,
    Future<dynamic> Function(Map<String, dynamic> message) onResume,
  }) {
    instance.onMessage.listen((e) => onMessage(e.data));
    instance.onBackgroundMessage.listen((e) => onBackgroundMessage(e.data));
  }

  @override
  void deleteToken(String token) {
    instance.deleteToken(token);
  }

  @override
  Future<String> getToken() async {
    return await instance.getToken();
  }

  Future requestNotificationPermissions() async {
    return instance.requestPermission();
  }

  @override
  Future requestPermission() async {
    return instance.requestPermission();
  }

  @override
  void usePublicVapidKey(String key) {
    instance.usePublicVapidKey(key);
  }

  @override
  void useServiceWorker(registration) {
    instance.useServiceWorker(registration);
  }
}

class RemoteConfig implements firebase.RemoteConfig {
  static firebase.RemoteConfig get instance => firebase.remoteConfig();

  @override
  Map<String, dynamic> defaultConfig;

  @override
  DateTime get fetchTime => instance.fetchTime;

  @override
  RemoteConfigJsImpl get jsObject => instance.jsObject;

  @override
  firebase.RemoteConfigFetchStatus get lastFetchStatus =>
      instance.lastFetchStatus;

  @override
  firebase.RemoteConfigSettings get settings => instance.settings;

  @override
  Future<bool> activate() async {
    return await instance.activate();
  }

  Future<bool> activateFetched() async {
    return await instance.fetchAndActivate();
  }

  @override
  Future<void> ensureInitialized() async {
    return await instance.ensureInitialized();
  }

  @override
  Future<void> fetch({Duration expiration}) async {
    return await instance.fetch();
  }

  @override
  Future<bool> fetchAndActivate() async {
    return await instance.fetchAndActivate();
  }

  @override
  Map<String, firebase.RemoteConfigValue> getAll() {
    return instance.getAll();
  }

  @override
  bool getBoolean(String key) {
    return instance.getBoolean(key);
  }

  @override
  num getNumber(String key) {
    return instance.getNumber(key);
  }

  @override
  String getString(String key) {
    return instance.getString(key);
  }

  @override
  firebase.RemoteConfigValue getValue(String key) {
    return instance.getValue(key);
  }

  Future<void> setDefaults(Map<String, dynamic> defaults) async {
    instance.defaultConfig = defaults;
  }

  @override
  void setLogLevel(firebase.RemoteConfigLogLevel value) {
    instance.setLogLevel(value);
  }
}
