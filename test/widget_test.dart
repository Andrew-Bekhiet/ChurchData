import 'package:churchdata/main.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/edit_page/update_user_data_error_p.dart';
import 'package:churchdata/views/login.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:connectivity_plus_platform_interface/method_channel_connectivity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth_mocks/src/mock_confirmation_result.dart';
import 'package:firebase_auth_mocks/src/mock_user_credential.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:intl/intl.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([FirebaseFunctions, RemoteConfig, MockUser])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
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
  firebaseDatabase = MockFirebaseDatabase();
  firebaseFunctions = MockFirebaseFunctions();
  firebaseStorage = MockFirebaseStorage();
  googleSignIn = MyGoogleSignInMock();
  remoteConfig = MockRemoteConfig();

  //FirebaseAuth
  MyMockUser user =
      MyMockUser(email: 'random@email.com', uid: '8t7we9rhuiU%762');
  when(user.getIdTokenResult(false)).thenAnswer(
    (_) async => auth.IdTokenResult({
      'claims': {
        'password': 'aaa',
        'personRef': 'Persons/user',
      }
    }),
  );
  when(user.getIdTokenResult(true)).thenAnswer(
    (_) async => auth.IdTokenResult({
      'claims': {
        'password': 'aaa',
        'personRef': 'Persons/user',
      }
    }),
  );

  firebaseAuth = FakeFirebaseAuth(signedIn: false, mockUser: user);
  // firebaseAuth.userChanges().listen((e) => print(e));

  //FlutterSecureStorage Mocks
  flutterSecureStorage = FakeFlutterSecureStorage();

  setUp(() async {
    //dot env

//Plugins mocks
    (ConnectivityPlatform.instance as MethodChannelConnectivity)
        .methodChannel
        .setMockMethodCallHandler((call) async {
      if (call.method == 'check') return 'wifi';
    });

    PackageInfo.setMockInitialValues(
        appName: 'ChurchData',
        packageName: 'com.AndroidQuartz.churchdata',
        version: '8.0.0',
        buildNumber: '0');

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
  });
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

          expect(firebaseAuth.currentUser?.uid, '8t7we9rhuiU%762');
        },
        tags: ['logic'],
      );
      tearDownAll(User.instance.signOut);
    });

    group('Updating lastConfession and lastTanawol', () {
      DateTime lastConfession = DateTime.now().subtract(Duration(days: 2 * 30));
      DateTime lastTanawol =
          DateTime.now().subtract(Duration(days: (2 * 30) + 1));

      setUp(() async {
        await firebaseAuth.signInWithCustomToken('token');
        await User.instance.initialized;

        await firestore.doc('Persons/user').set(
          {
            'LastTanawol': lastTanawol,
            'LastConfession': lastConfession,
          },
        );
      });
      testWidgets(
        'Displays UpdateUserDataError when needed',
        (tester) async {
          await tester.pumpWidget(App());
          await tester.pumpAndSettle();

          expect(find.text('تحديث بيانات التناول والاعتراف'), findsOneWidget);
        },
        tags: ['logic'],
      );
      testWidgets(
        'User can update its lastConfession and lastTanawol',
        (tester) async {
          await tester.pumpWidget(App());
          await tester.pumpAndSettle();

          await tester.tap(find.text('تحديث بيانات التناول والاعتراف'));

          await tester.pumpAndSettle();

          expect(find.byType(UpdateUserDataErrorPage), findsOneWidget);
        },
        tags: ['logic'],
      );

      testWidgets(
        'UpdateUserDataErrorPage structure',
        (tester) async {
          await tester.pumpWidget(App());
          await tester.pumpAndSettle();

          await tester.tap(find.text('تحديث بيانات التناول والاعتراف'));

          await tester.pumpAndSettle();

          Finder lastTanawolMatcher =
              find.text(DateFormat('yyyy/M/d').format(lastTanawol));
          Finder lastConfessionMatcher =
              find.text(DateFormat('yyyy/M/d').format(lastConfession));
          expect(lastConfessionMatcher, findsOneWidget);
          expect(lastTanawolMatcher, findsOneWidget);

          expect(
              find.descendant(
                of: find.ancestor(
                  of: lastConfessionMatcher,
                  matching: find.byType(Container),
                ),
                matching: find.byIcon(Icons.close),
              ),
              findsOneWidget);
          expect(
              find.descendant(
                of: find.ancestor(
                  of: lastTanawolMatcher,
                  matching: find.byType(Container),
                ),
                matching: find.byIcon(Icons.close),
              ),
              findsOneWidget);

          await tester.tap(lastConfessionMatcher);
          await tester.pumpAndSettle();

          expect(find.byType(DatePickerDialog), findsOneWidget);
          if (lastConfession.day != 27)
            await tester.tap(find.text('٢٧'));
          else
            await tester.tap(find.text('٢٨'));

          await tester.tap(find.text('حسنًا'));
          await tester.pumpAndSettle();

          lastConfessionMatcher = find.text(DateFormat('yyyy/M/d').format(
              DateTime(lastConfession.year, lastConfession.month,
                  lastConfession.day != 27 ? 27 : 28)));
          expect(lastConfessionMatcher, findsOneWidget);
//

          await tester.tap(lastTanawolMatcher);
          await tester.pumpAndSettle();

          expect(find.byType(DatePickerDialog), findsOneWidget);
          if (lastTanawol.day != 27)
            await tester.tap(find.text('٢٧'));
          else
            await tester.tap(find.text('٢٨'));

          await tester.tap(find.text('حسنًا'));
          await tester.pumpAndSettle();

          lastTanawolMatcher = find.text(DateFormat('yyyy/M/d').format(DateTime(
              lastTanawol.year,
              lastTanawol.month,
              lastTanawol.day != 27 ? 27 : 28)));
          expect(lastTanawolMatcher, findsNWidgets(2));
        },
        tags: ['widgetStructure'],
      );

      testWidgets(
        'UpdateUserDataErrorPage saves data correctly',
        (tester) async {
          await tester.pumpWidget(App());
          await tester.pumpAndSettle();

          await tester.tap(find.text('تحديث بيانات التناول والاعتراف'));

          await tester.pumpAndSettle();

          Finder lastTanawolMatcher =
              find.text(DateFormat('yyyy/M/d').format(lastTanawol));
          Finder lastConfessionMatcher =
              find.text(DateFormat('yyyy/M/d').format(lastConfession));

          await tester.tap(lastConfessionMatcher);
          await tester.pumpAndSettle();

          if (lastConfession.day != 27)
            await tester.tap(find.text('٢٧'));
          else
            await tester.tap(find.text('٢٨'));

          await tester.tap(find.text('حسنًا'));
          await tester.pumpAndSettle();

          lastConfessionMatcher = find.text(DateFormat('yyyy/M/d').format(
              DateTime(lastConfession.year, lastConfession.month,
                  lastConfession.day != 27 ? 27 : 28)));
//

          await tester.tap(lastTanawolMatcher);
          await tester.pumpAndSettle();

          if (lastTanawol.day != 27)
            await tester.tap(find.text('٢٧'));
          else
            await tester.tap(find.text('٢٨'));

          await tester.tap(find.text('حسنًا'));
          await tester.pumpAndSettle();

          lastTanawolMatcher = find.text(DateFormat('yyyy/M/d').format(DateTime(
              lastTanawol.year,
              lastTanawol.month,
              lastTanawol.day != 27 ? 27 : 28)));

          await tester.tap(find.byIcon(Icons.save));

          expect(
            (await firestore.doc('Persons/user').get())
                .data()?['LastTanawol']
                ?.millisecondsSinceEpoch,
            DateTime(lastTanawol.year, lastTanawol.month,
                    lastTanawol.day != 27 ? 27 : 28)
                .millisecondsSinceEpoch,
          );
          expect(
            (await firestore.doc('Persons/user').get())
                .data()?['LastConfession']
                ?.millisecondsSinceEpoch,
            DateTime(lastConfession.year, lastConfession.month,
                    lastConfession.day != 27 ? 27 : 28)
                .millisecondsSinceEpoch,
          );
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

class FakeFirebaseAuth implements auth.FirebaseAuth {
  final stateChanged = BehaviorSubject<auth.User?>.seeded(null);
  final MockUser? _mockUser;
  auth.User? _currentUser;

  FakeFirebaseAuth({signedIn = false, MockUser? mockUser})
      : _mockUser = mockUser {
    if (signedIn) {
      signInWithCredential(null);
    }
  }

  @override
  auth.User? get currentUser {
    return _currentUser;
  }

  @override
  Future<auth.UserCredential> signInWithCredential(
      auth.AuthCredential? credential) {
    return _fakeSignIn();
  }

  @override
  Future<auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _fakeSignIn();
  }

  @override
  Future<auth.UserCredential> signInWithCustomToken(String token) async {
    return _fakeSignIn();
  }

  @override
  Future<auth.ConfirmationResult> signInWithPhoneNumber(String phoneNumber,
      [auth.RecaptchaVerifier? verifier]) async {
    return MockConfirmationResult(onConfirm: _fakeSignIn);
  }

  @override
  Future<auth.UserCredential> signInAnonymously() {
    return _fakeSignIn(isAnonymous: true);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    stateChanged.add(null);
  }

  Future<auth.UserCredential> _fakeSignIn({bool isAnonymous = false}) async {
    final userCredential = MockUserCredential(isAnonymous, mockUser: _mockUser);
    _currentUser = userCredential.user;
    stateChanged.add(_currentUser);
    return userCredential;
  }

  @override
  Stream<auth.User?> authStateChanges() => stateChanged.shareValue();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  BehaviorSubject<auth.User?> changeIdToken =
      BehaviorSubject<auth.User?>.seeded(null);

  @override
  Stream<auth.User?> idTokenChanges() => changeIdToken.shareValue();

  @override
  Stream<auth.User?> userChanges() =>
      Rx.merge([authStateChanges(), idTokenChanges()]);

  Future<void> dipose() async {
    await changeIdToken.close();
    await stateChanged.close();
  }
}

class _FakeIdTokenResult extends Fake implements auth.IdTokenResult {}

class MyMockUser extends MockUser with Mock {
  MyMockUser({
    bool isAnonymous = false,
    bool isEmailVerified = true,
    String uid = 'some_random_id',
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    String? refreshToken,
    auth.UserMetadata? metadata,
  }) : super(
            isAnonymous: isAnonymous,
            isEmailVerified: isEmailVerified,
            uid: uid,
            email: email,
            displayName: displayName,
            phoneNumber: phoneNumber,
            photoURL: photoURL,
            refreshToken: refreshToken,
            metadata: metadata);

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    return (await getIdTokenResult(forceRefresh)).token!;
  }

  @override
  Future<auth.IdTokenResult> getIdTokenResult([bool forceRefresh = false]) {
    return super.noSuchMethod(
            Invocation.method(#getIdTokenResult, [forceRefresh]),
            returnValue: Future<auth.IdTokenResult>.value(_FakeIdTokenResult()))
        as Future<auth.IdTokenResult>;
  }
}

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  @visibleForTesting
  static Map<String, String> data = {};

  @override
  Future<Map<String, String>> readAll({aOptions, iOptions, lOptions}) async =>
      data;

  @override
  Future<void> write(
      {required String key,
      required String? value,
      iOptions,
      aOptions,
      lOptions}) async {
    if (value == null)
      data.remove(key);
    else
      data[key] = value;
  }
}

typedef FormType = FormField<Timestamp?>;

class MyGoogleSignInMock extends Mock implements GoogleSignIn {
  MockGoogleSignInAccount? _currentUser;

  bool _isCancelled = false;

  /// Used to simulate google login cancellation behaviour.
  void setIsCancelled(bool val) {
    _isCancelled = val;
  }

  @override
  GoogleSignInAccount? get currentUser => _currentUser;

  @override
  Future<GoogleSignInAccount?> signIn() {
    _currentUser = MockGoogleSignInAccount();
    return Future.value(_isCancelled ? null : _currentUser);
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    _currentUser = null;
    return Future.value(_isCancelled ? null : _currentUser);
  }
}
