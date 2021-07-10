import 'package:churchdata/main.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/views/login.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([FirebaseFunctions, RemoteConfig])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  //dot env
  await dotenv.load(fileName: '.env');

  //Hive initialization:
  await Hive.initFlutter();

  await Hive.openBox('Settings');
  await Hive.openBox<bool>('FeatureDiscovery');
  await Hive.openBox<Map>('NotificationsSettings');
  await Hive.openBox<String>('PhotosURLsCache');

  //Notifications:
  // await AndroidAlarmManager.initialize();

  // await FlutterLocalNotificationsPlugin().initialize(
  //   InitializationSettings(android: AndroidInitializationSettings('warning')),
  //   onSelectNotification: onNotificationClicked,
  // );

  //Firebase Mocks:
  firestore = FakeFirebaseFirestore();
  firebaseAuth = MyMockFirebaseAuth();
  firebaseDatabase = MockFirebaseDatabase();
  firebaseFunctions = MockFirebaseFunctions();
  firebaseStorage = MockFirebaseStorage();
  googleSignIn = MockGoogleSignIn();
  remoteConfig = MockRemoteConfig();

  PackageInfo.setMockInitialValues(
      appName: 'ChurchData',
      packageName: 'com.AndroidQuartz.churchdata',
      version: '8.0.0',
      buildNumber: '0');

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

  group('Initialization tests', () {
    group('Login', () {
      testWidgets(
        'Displays Login screen when not logged in',
        (tester) async {
          await tester.pumpWidget(App());

          expect(firebaseAuth.currentUser, null);

          await tester.pumpAndSettle();

          expect(find.byType(LoginScreen), findsOneWidget);
        },
        tags: ['logic'],
      );

      testWidgets(
        'Login Screen Structure',
        (tester) async {
          await tester.pumpWidget(App());
          await tester.pumpAndSettle();

          expect(find.text('بيانات الكنيسة'), findsOneWidget);
          expect(find.textContaining('تسجيل الدخول'), findsWidgets);
          expect(find.text('Google'), findsOneWidget);
        },
        tags: ['widgetStructure'],
      );

      testWidgets(
        'Login logic',
        (tester) async {
          await tester.pumpWidget(App());
          await tester.pumpAndSettle();

          expect(firebaseAuth.currentUser, null);

          await tester.tap(find.text('Google'));
          await tester.pumpAndSettle();

          expect(firebaseAuth.currentUser != null, true);
        },
        tags: ['logic'],
      );
    });

    testWidgets(
      'Blocks running when LoadApp is false',
      (tester) async {
        when(remoteConfig.getString('LoadApp')).thenReturn('false');
        when(remoteConfig.getString('LatestVersion')).thenReturn('9.0.0');

        await tester.pumpWidget(App());

        await tester.pumpAndSettle();

        expect(find.text('تحديث'), findsOneWidget);
      },
      tags: ['logic'],
    );
  });
}

class MyMockFirebaseAuth extends MockFirebaseAuth {
  BehaviorSubject<auth.User?> changeIdToken =
      BehaviorSubject<auth.User?>.seeded(null);

  @override
  Stream<auth.User?> idTokenChanges() => changeIdToken.shareValue();

  @override
  Stream<auth.User?> userChanges() =>
      Rx.merge([stateChangedStreamController.stream, changeIdToken]);

  MyMockFirebaseAuth({signedIn = false, MockUser? mockUser})
      : super(signedIn: signedIn, mockUser: mockUser);

  Future<void> dipose() async {
    await changeIdToken.close();
  }
}
