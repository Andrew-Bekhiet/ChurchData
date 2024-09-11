import 'dart:convert';

import 'package:churchdata/models/hive_persistence_provider.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/auth_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:connectivity_plus_platform_interface/method_channel_connectivity.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth_platform_interface/src/pigeon/messages.pigeon.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'fakes/fake_firebase_database.dart';
import 'fakes/fakes.dart';
import 'globals.dart';
import 'main.mocks.dart';

bool _initialized = false;

@GenerateMocks([
  FirebaseMessaging,
  FirebaseFunctions,
  FirebaseRemoteConfig,
  MockUser,
  LocalAuthentication,
  HttpsCallable,
  DeviceInfoPlatform,
  UrlLauncherPlatform
])
Future<void> initTests() async {
  if (_initialized) return;

  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  //FlutterSecureStorage Mocks
  flutterSecureStorage = FakeFlutterSecureStorage();

  await initHive();

  HivePersistenceProvider.instance = MockHivePersistenceProvider();

  //Notifications:
  // await AndroidAlarmManager.initialize();

  // await FlutterLocalNotificationsPlugin().initialize(
  //   InitializationSettings(android: AndroidInitializationSettings('warning')),
  //   onSelectNotification: onNotificationClicked,
  // );

  //Firebase Mocks:
  firestore = FakeFirebaseFirestore();
  firebaseDatabase = MockFirebaseDatabase();
  firebaseFunctions = MockFirebaseFunctions();
  firebaseStorage = MockFirebaseStorage();
  firebaseMessaging = MockFirebaseMessaging();
  firebaseDynamicLinks = MockFirebaseDynamicLinks();
  googleSignIn = MyGoogleSignInMock();
  remoteConfig = MockFirebaseRemoteConfig();

  //FirebaseAuth
  final MyMockUser user =
      MyMockUser(email: 'random@email.com', uid: '8t7we9rhuiU%762');

  when(user.getIdTokenResult()).thenAnswer(
    (_) async => auth.IdTokenResult(PigeonIdTokenResult(claims: userClaims)),
  );
  when(user.getIdTokenResult(true)).thenAnswer(
    (_) async => auth.IdTokenResult(PigeonIdTokenResult(claims: userClaims)),
  );

  firebaseAuth = FakeFirebaseAuth(mockUser: user);
  when(firebaseMessaging.getToken()).thenAnswer((_) async => '{FCMToken}');
  when(firebaseMessaging.requestPermission()).thenAnswer(
    (_) async => const NotificationSettings(
      criticalAlert: AppleNotificationSetting.enabled,
      timeSensitive: AppleNotificationSetting.enabled,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.enabled,
      authorizationStatus: AuthorizationStatus.authorized,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.enabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.whenAuthenticated,
      sound: AppleNotificationSetting.enabled,
    ),
  );

  //local_auth Mocks
  localAuthentication = MockLocalAuthentication();

  setUpAll(() async {
    //dot env

    //Plugins mocks
    UrlLauncherPlatform.instance = MockUrlLauncherPlatform();

    (ConnectivityPlatform.instance as MethodChannelConnectivity)
        .methodChannel
        .setMockMethodCallHandler((call) async {
      if (call.method == 'check') return 'wifi';
    });

    PackageInfo.setMockInitialValues(
      buildSignature: '',
      appName: 'ChurchData',
      packageName: 'com.AndroidQuartz.churchdata',
      version: '8.0.0',
      buildNumber: '0',
    );

    //RemoteConfig mocks
    when(remoteConfig.setDefaults({
      'LatestVersion': (await PackageInfo.fromPlatform()).version,
      'LoadApp': 'false',
      'DownloadLink':
          'https://github.com/Andrew-Bekhiet/ChurchData/releases/latest/'
              'download/ChurchData.apk',
    })).thenAnswer(
      (_) async {},
    );
    when(
      remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: const Duration(minutes: 2),
        ),
      ),
    ).thenAnswer(
      (_) async {},
    );
    when(remoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
    when(remoteConfig.getString('LoadApp')).thenReturn('true');
    when(remoteConfig.getString('LatestVersion')).thenReturn('8.0.0');
    when(remoteConfig.getString('DownloadLink')).thenReturn(
        'https://github.com/Andrew-Bekhiet/ChurchData/releases/latest/'
        'download/ChurchData.apk');

    await Hive.box('Settings').put('FCM_Token_Registered', true);
    configureMessaging = false;

    reportUID = false;

    when(localAuthentication.canCheckBiometrics).thenAnswer((_) async => true);
    when(localAuthentication.isDeviceSupported()).thenAnswer((_) async => true);
    when(localAuthentication.authenticate(
      localizedReason: 'برجاء التحقق للمتابعة',
      options: const AuthenticationOptions(
        biometricOnly: true,
        useErrorDialogs: false,
      ),
    )).thenAnswer((_) async => true);

    when(firebaseMessaging.getInitialMessage()).thenAnswer((_) async => null);

    // DeviceInfoPlugin.disableDeviceInfoPlatformOverride = true;
    DeviceInfoPlatform.instance = MockDeviceInfo();
    when(DeviceInfoPlatform.instance.deviceInfo()).thenAnswer(
      (_) async => AndroidDeviceInfo.fromMap({
        'supported32BitAbis': [],
        'supported64BitAbis': [],
        'supportedAbis': [],
        'systemFeatures': [],
        'board': 'board',
        'bootloader': 'bootloader',
        'brand': 'brand',
        'device': 'device',
        'display': 'display',
        'fingerprint': 'fingerprint',
        'hardware': 'hardware',
        'host': 'host',
        'id': 'id',
        'manufacturer': 'manufacturer',
        'model': 'model',
        'product': 'product',
        'tags': 'tags',
        'type': 'type',
        'isPhysicalDevice': true,
        'displayMetrics': {
          'widthPixels': 1080,
          'heightPixels': 1920,
          'xdpi': 480.0,
          'ydpi': 480.0,
        },
        'version': MockAndroidBuildVersion(sdkInt: 22).toMap(),
      }),
    );

    const MethodChannel('dexterous.com/flutter/local_notifications')
        .setMockMethodCallHandler((call) => null);
  });

  _initialized = true;
}

Future<void> initHive([bool retryOnHiveError = false]) async {
  //Hive initialization:
  try {
    await Hive.initFlutter();

    final containsEncryptionKey =
        await flutterSecureStorage.containsKey(key: 'key');
    if (!containsEncryptionKey)
      await flutterSecureStorage.write(
          key: 'key', value: base64Url.encode(Hive.generateSecureKey()));

    final encryptionKey =
        base64Url.decode((await flutterSecureStorage.read(key: 'key'))!);

    await Hive.openBox(
      'User',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox('Settings');
    await Hive.openBox<bool>('FeatureDiscovery');
    await Hive.openBox<Map>('NotificationsSettings');
    await Hive.openBox<String?>('PhotosURLsCache');
  } catch (e) {
    await Hive.close();
    await Hive.deleteBoxFromDisk('User');
    await Hive.deleteBoxFromDisk('Settings');
    await Hive.deleteBoxFromDisk('FeatureDiscovery');
    await Hive.deleteBoxFromDisk('NotificationsSettings');
    await Hive.deleteBoxFromDisk('PhotosURLsCache');

    if (retryOnHiveError) return initHive();
    rethrow;
  }
}

class MockDeviceInfo extends Mock
    with MockPlatformInterfaceMixin
    implements DeviceInfoPlatform {
  @override
  Future<AndroidDeviceInfo> deviceInfo() async {
    return super.noSuchMethod(
      Invocation.method(#androidInfo, []),
      returnValue: AndroidDeviceInfo.fromMap({
        'supported32BitAbis': [],
        'supported64BitAbis': [],
        'supportedAbis': [],
        'systemFeatures': [],
        'board': 'board',
        'bootloader': 'bootloader',
        'brand': 'brand',
        'device': 'device',
        'display': 'display',
        'fingerprint': 'fingerprint',
        'hardware': 'hardware',
        'host': 'host',
        'id': 'id',
        'manufacturer': 'manufacturer',
        'model': 'model',
        'product': 'product',
        'tags': 'tags',
        'type': 'type',
        'isPhysicalDevice': true,
        'displayMetrics': {
          'widthPixels': 1080,
          'heightPixels': 1920,
          'xdpi': 480.0,
          'ydpi': 480.0,
        },
        'version': MockAndroidBuildVersion(sdkInt: 22).toMap(),
      }),
    );
  }
}

class MockAndroidBuildVersion implements AndroidBuildVersion {
  MockAndroidBuildVersion({
    this.baseOS,
    this.codename = '',
    this.incremental = '',
    this.previewSdkInt = 0,
    this.release = '',
    this.sdkInt = 0,
    this.securityPatch,
  });

  @override
  String? baseOS;

  @override
  String codename;

  @override
  String incremental;

  @override
  int previewSdkInt;

  @override
  String release;

  @override
  int sdkInt;

  @override
  String? securityPatch;

  @override
  Map<String, dynamic> toMap() {
    return {
      'baseOS': baseOS,
      'codename': codename,
      'incremental': incremental,
      'previewSdkInt': previewSdkInt,
      'release': release,
      'sdkInt': sdkInt,
      'securityPatch': securityPatch,
    };
  }
}
