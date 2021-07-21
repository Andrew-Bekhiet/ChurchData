import 'dart:async';

import 'package:churchdata/EncryptionKeys.dart';
import 'package:churchdata/main.dart';
import 'package:churchdata/models/loading_widget.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/auth_screen.dart';
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:intl/intl.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([FirebaseFunctions, RemoteConfig, MockUser, LocalAuthentication])
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

  final Map<String, dynamic> userClaims = {
    'password': 'password',
    'manageUsers': false,
    'superAccess': false,
    'manageDeleted': false,
    'write': true,
    'exportAreas': false,
    'birthdayNotify': false,
    'confessionsNotify': false,
    'tanawolNotify': false,
    'approveLocations': false,
    'approved': true,
    'personRef': 'Persons/user'
  };

  when(user.getIdTokenResult(false)).thenAnswer(
    (_) async => auth.IdTokenResult({'claims': userClaims}),
  );
  when(user.getIdTokenResult(true)).thenAnswer(
    (_) async => auth.IdTokenResult({'claims': userClaims}),
  );

  firebaseAuth = FakeFirebaseAuth(signedIn: false, mockUser: user);
  // firebaseAuth.userChanges().listen((e) => print(e));

  //FlutterSecureStorage Mocks
  flutterSecureStorage = FakeFlutterSecureStorage();

//local_auth Mocks
  localAuthentication = MockLocalAuthentication();

  setUpAll(() async {
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

    when(localAuthentication.canCheckBiometrics).thenAnswer((_) async => true);
    when(localAuthentication.isDeviceSupported()).thenAnswer((_) async => true);
    when(localAuthentication.authenticate(
            localizedReason: 'برجاء التحقق للمتابعة',
            biometricOnly: true,
            useErrorDialogs: false))
        .thenAnswer((_) async => true);
  });
  group('Widgets structrures', () {
    group('LoadingWidget', () {
      testWidgets('Normal', (tester) async {
        await tester.pumpWidget(wrapWithMaterialApp(Loading()));
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('جار التحميل...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
            find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
            findsNothing);
      });

      testWidgets('With version', (tester) async {
        await tester.pumpWidget(wrapWithMaterialApp(Loading(
          showVersionInfo: true,
        )));
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('جار التحميل...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
            find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
            findsOneWidget);
      });

      group('Errors', () {
        testWidgets('Other errors', (tester) async {
          await tester.pumpWidget(wrapWithMaterialApp(Loading(
            error: true,
            message: '{Error message}',
          )));
          await tester.pump();

          expect(find.byType(Image), findsOneWidget);

          expect(find.text('جار التحميل...'), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsNothing);

          expect(find.text('لا يمكن تحميل البرنامج في الوقت الحالي'),
              findsOneWidget);
          expect(find.text('اضغط لمزيد من المعلومات'), findsOneWidget);
          expect(
              find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
              findsOneWidget);

          await tester.tap(find.text('اضغط لمزيد من المعلومات'));
          await tester.pumpAndSettle();

          expect(find.text('{Error message}'), findsOneWidget);
        });
        testWidgets('Update User Data Error', (tester) async {
          await tester.pumpWidget(
            wrapWithMaterialApp(
              Loading(
                error: true,
                message: 'Exception: Error Update User Data',
              ),
              routes: {
                'UpdateUserDataError': (context) =>
                    UpdateUserDataErrorPage(person: Person()),
              },
            ),
          );
          await tester.pump();

          expect(find.byType(Image), findsOneWidget);

          expect(find.text('جار التحميل...'), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsNothing);

          expect(find.text('لا يمكن تحميل البرنامج في الوقت الحالي'),
              findsOneWidget);
          expect(find.text('اضغط لمزيد من المعلومات'), findsOneWidget);
          expect(
              find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
              findsOneWidget);

          await tester.tap(find.text('اضغط لمزيد من المعلومات'));
          await tester.pumpAndSettle();

          expect(find.text('تحديث بيانات التناول والاعتراف'), findsOneWidget);

          await tester.tap(find.text('تحديث بيانات التناول والاعتراف'));
          await tester.pumpAndSettle();

          expect(find.byType(UpdateUserDataErrorPage), findsOneWidget);
        });
        testWidgets('Cannot Load App Error', (tester) async {
          when(remoteConfig.getString('LoadApp')).thenReturn('false');
          when(remoteConfig.getString('LatestVersion')).thenReturn('9.0.0');

          await tester.pumpWidget(
            wrapWithMaterialApp(
              Loading(
                error: true,
                message: 'Exception: يجب التحديث لأخر إصدار لتشغيل البرنامج',
              ),
              routes: {
                'UpdateUserDataError': (context) =>
                    UpdateUserDataErrorPage(person: Person()),
              },
            ),
          );
          await tester.pump();

          expect(find.byType(Image), findsOneWidget);

          expect(find.text('جار التحميل...'), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsNothing);

          expect(find.text('لا يمكن تحميل البرنامج في الوقت الحالي'),
              findsOneWidget);
          expect(find.text('اضغط لمزيد من المعلومات'), findsOneWidget);
          expect(
              find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
              findsOneWidget);

          await tester.tap(find.text('اضغط لمزيد من المعلومات'));
          await tester.pumpAndSettle();

          expect(find.text('تحديث'), findsOneWidget);

          when(remoteConfig.getString('LoadApp')).thenReturn('true');
          when(remoteConfig.getString('LatestVersion')).thenReturn('8.0.0');
        });
      });
    });

    testWidgets(
      'Login Screen',
      (tester) async {
        await tester.pumpWidget(wrapWithMaterialApp(LoginScreen()));

        expect(find.text('بيانات الكنيسة'), findsOneWidget);
        expect(find.textContaining('تسجيل الدخول'), findsWidgets);
        expect(find.text('Google'), findsOneWidget);
      },
    );

    testWidgets(
      'UpdateUserDataErrorPage',
      (tester) async {
        DateTime lastConfession =
            DateTime.now().subtract(Duration(days: 2 * 30));
        DateTime lastTanawol =
            DateTime.now().subtract(Duration(days: (2 * 30) + 1));

        await tester.pumpWidget(
          wrapWithMaterialApp(
            UpdateUserDataErrorPage(
              person: Person(
                  lastConfession: Timestamp.fromDate(lastConfession),
                  lastTanawol: Timestamp.fromDate(lastTanawol)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.save), findsOneWidget);

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
    );

    group('AuthScreen', () {
      testWidgets('With Biometrics', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            AuthScreen(),
          ),
        );
        await tester.pump();

        expect(find.byType(BackButton), findsNothing);
        expect(find.text('برجاء التحقق للمتابعة'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);

        expect(find.text('كلمة السر'), findsOneWidget);
        expect(find.text('تسجيل الدخول'), findsOneWidget);
        expect(find.text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
            findsOneWidget);
      });
      testWidgets('Without Biometrics', (tester) async {
        when(localAuthentication.canCheckBiometrics)
            .thenAnswer((_) async => false);
        await tester.pumpWidget(
          wrapWithMaterialApp(
            AuthScreen(),
          ),
        );
        await tester.pump();

        expect(find.byType(BackButton), findsNothing);
        expect(find.text('برجاء التحقق للمتابعة'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);

        expect(find.text('كلمة السر'), findsOneWidget);
        expect(find.text('تسجيل الدخول'), findsOneWidget);
        expect(find.text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
            findsNothing);
      });
    });
  });
  group('Initialization tests', () {
    group('Login', () {
      testWidgets(
        'Displays Login screen when not logged in',
        (tester) async {
          expect(firebaseAuth.currentUser, null);

          await tester.pumpWidget(App());

          await tester.pumpAndSettle();

          expect(find.byType(LoginScreen), findsOneWidget);
        },
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
      );
      tearDownAll(User.instance.signOut);
    });

    group('User registeration', () {});

    group('Entering with AuthScreen', () {
      Completer<bool> _authCompleter = Completer();
      setUp(() {
        when(localAuthentication.canCheckBiometrics)
            .thenAnswer((_) async => true);
        when(localAuthentication.authenticate(
                localizedReason: 'برجاء التحقق للمتابعة',
                biometricOnly: true,
                useErrorDialogs: false))
            .thenAnswer((_) => _authCompleter.future);
      });

      tearDown(() async {
        if (!_authCompleter.isCompleted) _authCompleter.complete(false);
        _authCompleter = Completer();
      });
      group('With password', () {
        final _originalPassword = userClaims['password'];
        const _passwordText = '1%Pass word*)';

        setUp(() async {
          userClaims['password'] = Encryption.encryptPassword(_passwordText);

          await firebaseAuth.signInWithCustomToken('token');
          await User.instance.initialized;
        });
        tearDown(() async {
          await User.instance.signOut();
          userClaims['password'] = _originalPassword;
        });

        testWidgets('Entering password', (tester) async {
          tester.binding.window.physicalSizeTestValue =
              Size(1080 * 3, 2400 * 3);
          addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

          await tester.pumpWidget(
            wrapWithMaterialApp(
              AuthScreen(
                nextRoute: 'Success',
              ),
              routes: {
                'Success': (_) => Scaffold(body: Text('Test succeeded'))
              },
            ),
          );
          await tester.pump();

          _authCompleter.complete(false);

          await tester.enterText(
              find.widgetWithText(TextFormField, 'كلمة السر'), _passwordText);
          await tester.tap(find.text('تسجيل الدخول'));
          await tester.pump();

          await tester.pump();

          expect(find.text('Test succeeded'), findsOneWidget);
        });
        group('Errors', () {
          testWidgets('Empty Password', (tester) async {
            tester.binding.window.physicalSizeTestValue =
                Size(1080 * 3, 2400 * 3);
            addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

            await tester.pumpWidget(
              wrapWithMaterialApp(
                AuthScreen(),
              ),
            );
            await tester.pump();

            await tester.enterText(
                find.widgetWithText(TextFormField, 'كلمة السر'), '');
            await tester.tap(find.text('تسجيل الدخول'));
            await tester.pump();

            expect(find.text('كلمة سر فارغة!'), findsOneWidget);
          });
          testWidgets('Wrong Password', (tester) async {
            tester.binding.window.physicalSizeTestValue =
                Size(1080 * 3, 2400 * 3);
            addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

            await tester.pumpWidget(
              wrapWithMaterialApp(
                AuthScreen(),
              ),
            );
            await tester.pump();

            await tester.enterText(
                find.widgetWithText(TextFormField, 'كلمة السر'), 'Wrong');
            await tester.tap(find.text('تسجيل الدخول'));
            await tester.pump();

            expect(find.text('كلمة سر خاطئة!'), findsOneWidget);
          });
        });

        testWidgets('With Biometrics', (tester) async {
          tester.binding.window.physicalSizeTestValue =
              Size(1080 * 3, 2400 * 3);
          addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

          await tester.pumpWidget(
            wrapWithMaterialApp(
              AuthScreen(
                nextRoute: 'Success',
              ),
              routes: {
                'Success': (_) => Scaffold(body: Text('Test succeeded'))
              },
            ),
          );
          await tester.pump();

          _authCompleter.complete(false);
          _authCompleter = Completer();

          await tester
              .tap(find.text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'));

          _authCompleter.complete(true);

          await tester.pumpAndSettle();

          expect(find.text('Test succeeded'), findsOneWidget);
        });
      });
    });

    group('Updating lastConfession and lastTanawol', () {
      DateTime lastConfession = DateTime.now().subtract(Duration(days: 2 * 30));
      DateTime lastTanawol =
          DateTime.now().subtract(Duration(days: (2 * 30) + 1));

      setUpAll(() async {
        await firebaseAuth.signInWithCustomToken('token');
        await User.instance.initialized;

        await firestore.doc('Persons/user').set(
          {
            'LastTanawol': lastTanawol,
            'LastConfession': lastConfession,
          },
        );
      });

      tearDownAll(() async {
        await User.instance.signOut();
        await firestore.doc('Persons/user').delete();
      });

      testWidgets(
        'Displays UpdateUserDataError when needed',
        (tester) async {
          await tester.pumpWidget(App());
          await tester.pumpAndSettle();

          expect(find.text('تحديث بيانات التناول والاعتراف'), findsOneWidget);
        },
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

        when(remoteConfig.getString('LoadApp')).thenReturn('true');
        when(remoteConfig.getString('LatestVersion')).thenReturn('8.0.0');
      },
    );
  });
}

Widget wrapWithMaterialApp(Widget widget,
    {Map<String, Widget Function(BuildContext)>? routes}) {
  return MaterialApp(
    navigatorKey: navigator,
    scaffoldMessengerKey: scaffoldMessenger,
    debugShowCheckedModeBanner: false,
    title: 'بيانات الكنيسة',
    routes: {
      '/': (_) => widget,
      ...routes ?? {},
    },
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [
      Locale('ar', 'EG'),
    ],
    locale: Locale('ar', 'EG'),
  );
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
