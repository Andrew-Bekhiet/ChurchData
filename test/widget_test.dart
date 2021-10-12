import 'dart:async';

import 'package:churchdata/EncryptionKeys.dart';
import 'package:churchdata/main.dart';
import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/hive_persistence_provider.dart';
import 'package:churchdata/models/loading_widget.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/auth_screen.dart';
import 'package:churchdata/views/edit_page/update_user_data_error_p.dart';
import 'package:churchdata/views/form_widgets/password_field.dart';
import 'package:churchdata/views/form_widgets/tapable_form_field.dart';
import 'package:churchdata/views/login.dart';
import 'package:churchdata/views/root.dart';
import 'package:churchdata/views/updates.dart';
import 'package:churchdata/views/user_registeration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:connectivity_plus_platform_interface/method_channel_connectivity.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth_mocks/src/mock_confirmation_result.dart';
import 'package:firebase_auth_mocks/src/mock_user_credential.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([
  FirebaseMessaging,
  FirebaseFunctions,
  RemoteConfig,
  MockUser,
  LocalAuthentication,
  HttpsCallable,
  UrlLauncherPlatform
])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  //Hive initialization:
  await Hive.initFlutter();

  await Hive.openBox('Settings');
  await Hive.openBox<bool>('FeatureDiscovery');
  await Hive.openBox<Map>('NotificationsSettings');
  await Hive.openBox<String>('PhotosURLsCache');

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
  googleSignIn = MyGoogleSignInMock();
  remoteConfig = MockRemoteConfig();

  //FirebaseAuth
  final MyMockUser user =
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
  when(firebaseMessaging.getToken()).thenAnswer((_) async => '{FCMToken}');
  when(firebaseMessaging.requestPermission()).thenAnswer(
    (_) async => NotificationSettings(
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

  //FlutterSecureStorage Mocks
  flutterSecureStorage = FakeFlutterSecureStorage();

  //local_auth Mocks
  localAuthentication = MockLocalAuthentication();

  final listViewMatcher = find.descendant(
    of: find.byKey(Key('ListView')),
    matching: find.byType(Scrollable).first,
  );

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
            biometricOnly: true,
            useErrorDialogs: false))
        .thenAnswer((_) async => true);

    FirebaseDynamicLinks.channel.setMockMethodCallHandler((call) {
      return null;
    });

    when(firebaseMessaging.getInitialMessage()).thenAnswer((_) async => null);

    DeviceInfoPlugin.disableDeviceInfoPlatformOverride = true;
    DeviceInfoPlatform.instance = MockDeviceInfo();
    when(DeviceInfoPlatform.instance.androidInfo()).thenAnswer(
      (_) async => AndroidDeviceInfo(
        supported32BitAbis: [],
        supported64BitAbis: [],
        supportedAbis: [],
        systemFeatures: [],
        version: MockAndroidBuildVersion(sdkInt: 22),
      ),
    );

    MethodChannel('dexterous.com/flutter/local_notifications')
        .setMockMethodCallHandler((call) => null);
  });

  group('Helping widgets', () {
    group('Tapable Form Field', () {
      testWidgets('Label', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'initialValue',
                labelText: 'some label',
                onTap: (state) {},
                builder: (context, state) {},
              ),
            ),
          ),
        );

        expect(find.text('some label'), findsOneWidget);
      });

      testWidgets('Decoration', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'initialValue',
                decoration: (context, state) =>
                    InputDecoration(labelText: 'Some label'),
                onTap: (state) {},
                builder: (context, state) {},
              ),
            ),
          ),
        );

        expect(find.text('Some label'), findsOneWidget);
      });

      testWidgets('Initial value', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'Initial Value',
                decoration: (context, state) =>
                    InputDecoration(labelText: 'Some label'),
                onTap: (state) {},
                builder: (context, state) => Text(state.value!),
              ),
            ),
          ),
        );

        expect(find.text('Initial Value'), findsOneWidget);
      });

      testWidgets('Tapping', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'Initial Value',
                decoration: (context, state) =>
                    InputDecoration(labelText: 'Some label'),
                onTap: (state) {
                  showDialog(
                    context: state.context,
                    builder: (context) => AlertDialog(
                      content: Text('Test succeeded'),
                    ),
                  );
                },
                builder: (context, state) => Text(state.value!),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Initial Value'));
        await tester.pump();

        expect(find.text('Test succeeded'), findsOneWidget);
      });

      testWidgets('Can change state', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'Initial Value',
                decoration: (context, state) =>
                    InputDecoration(labelText: 'Some label'),
                onTap: (state) {
                  state.didChange('Changed!');
                },
                builder: (context, state) => Text(state.value!),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Initial Value'));
        await tester.pump();

        expect(find.text('Changed!'), findsOneWidget);
        expect(find.text('Initial Value'), findsNothing);
      });
    });

    group('Password Form Field', () {
      testWidgets('Label', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: PasswordFormField(
                labelText: 'Password',
              ),
            ),
          ),
        );

        expect(find.text('Password'), findsOneWidget);
      });

      testWidgets('Text obscuring', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: PasswordFormField(
                key: Key('PasswordField'),
                initialValue: 'initialValue',
                labelText: 'Password',
              ),
            ),
          ),
        );

        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byKey(Key('PasswordField')),
                  matching: find.byType(TextField),
                ),
              )
              .obscureText,
          true,
        );

        expect(find.byIcon(Icons.visibility_off), findsNothing);
        expect(find.byIcon(Icons.visibility), findsOneWidget);

        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();

        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byKey(Key('PasswordField')),
                  matching: find.byType(TextField),
                ),
              )
              .obscureText,
          false,
        );

        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsNothing);

        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();

        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byKey(Key('PasswordField')),
                  matching: find.byType(TextField),
                ),
              )
              .obscureText,
          true,
        );
        expect(find.byIcon(Icons.visibility_off), findsNothing);
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });
    });
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
        tearDown(() {
          when(remoteConfig.getString('LoadApp')).thenReturn('true');
          when(remoteConfig.getString('LatestVersion')).thenReturn('8.0.0');
        });

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
          expect(find.byKey(Key('ClickForMore')), findsOneWidget);

          expect(
              find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
              findsOneWidget);

          await tester.tap(find.byKey(Key('ClickForMore')));
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
          expect(find.byKey(Key('ClickForMore')), findsOneWidget);

          expect(
              find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
              findsOneWidget);

          await tester.tap(find.byKey(Key('ClickForMore')));
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
          expect(find.byKey(Key('ClickForMore')), findsOneWidget);

          expect(
              find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
              findsOneWidget);

          await tester.tap(find.byKey(Key('ClickForMore')));
          await tester.pumpAndSettle();

          expect(find.text('تحديث'), findsOneWidget);
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
        final DateTime lastConfession =
            DateTime.now().subtract(Duration(days: 2 * 30));
        final DateTime lastTanawol =
            DateTime.now().subtract(Duration(days: (2 * 30) + 1));

        await tester.pumpWidget(
          wrapWithMaterialApp(
            UpdateUserDataErrorPage(
              person: Person(
                lastConfession: Timestamp.fromDate(lastConfession),
                lastTanawol: Timestamp.fromDate(lastTanawol),
              ),
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

    group(
      'UserRegisteration',
      () {
        setUp(() async {
          if (User.instance.uid != null) await User.instance.signOut();
          await firebaseAuth.signInWithCustomToken('token');
          await User.instance.initialized;
        });

        tearDown(() async {
          userClaims['approved'] = true;
          await User.instance.signOut();
        });

        testWidgets('When user is not approved', (tester) async {
          userClaims['approved'] = false;
          await User.instance.forceRefresh();

          await tester.pumpWidget(wrapWithMaterialApp(UserRegisteration()));

          expect(find.text('في انتظار الموافقة'), findsOneWidget);
          expect(find.widgetWithIcon(IconButton, Icons.logout), findsOneWidget);
          expect(find.text('لينك الدعوة'), findsOneWidget);
          expect(find.text('تفعيل الحساب باللينك'), findsOneWidget);
        });

        testWidgets(
          'When user is approved',
          (tester) async {
            userClaims['approved'] = true;
            await User.instance.forceRefresh();

            await tester.pumpWidget(wrapWithMaterialApp(UserRegisteration()));

            await tester.scrollUntilVisible(
              find.text('تسجيل حساب جديد'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('تسجيل حساب جديد'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.text('اسم المستخدم'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('اسم المستخدم'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.text('كلمة السر'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('كلمة السر'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.text('تأكيد كلمة السر'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('تأكيد كلمة السر'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.text('انشاء حساب جديد'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('انشاء حساب جديد'), findsOneWidget);
          },
        );
      },
    );

    group(
      'AuthScreen',
      () {
        tearDown(() {
          when(localAuthentication.canCheckBiometrics)
              .thenAnswer((_) async => true);
        });
        testWidgets('With Biometrics', (tester) async {
          tester.binding.window.physicalSizeTestValue =
              Size(1080 * 3, 2400 * 3);

          await tester.pumpWidget(
            wrapWithMaterialApp(
              AuthScreen(),
            ),
          );
          await tester.pump();

          expect(find.byType(BackButton), findsNothing);
          expect(find.text('برجاء التحقق للمتابعة'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.byType(Image),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.byType(Image), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('كلمة السر'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('كلمة السر'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('تسجيل الدخول'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('تسجيل الدخول'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
              findsOneWidget);
        });
        testWidgets('Without Biometrics', (tester) async {
          tester.binding.window.physicalSizeTestValue =
              Size(1080 * 3, 2400 * 3);

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

          await tester.scrollUntilVisible(
            find.byType(Image),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.byType(Image), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('كلمة السر'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('كلمة السر'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('تسجيل الدخول'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('تسجيل الدخول'), findsOneWidget);

          expect(find.text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
              findsNothing);
        });
      },
    );

    group('Updates page', () {
      late String downloadLink;

      setUp(() {
        downloadLink = remoteConfig
            .getString('DownloadLink')
            .replaceFirst('https://', 'https:');
        when(remoteConfig.getString('LatestVersion')).thenReturn('8.5.0');
        when(UrlLauncherPlatform.instance.canLaunch(downloadLink))
            .thenAnswer((_) async => true);
        when((UrlLauncherPlatform.instance as MockUrlLauncherPlatform).launch(
          downloadLink,
          enableDomStorage: anyNamed('enableDomStorage'),
          enableJavaScript: anyNamed('enableJavaScript'),
          headers: anyNamed('headers'),
          universalLinksOnly: anyNamed('universalLinksOnly'),
          useSafariVC: anyNamed('useSafariVC'),
          useWebView: anyNamed('useWebView'),
          webOnlyWindowName: anyNamed('webOnlyWindowName'),
        )).thenAnswer((_) async => true);
      });

      tearDown(() {
        when(remoteConfig.getString('LatestVersion')).thenReturn('8.0.0');
        reset(UrlLauncherPlatform.instance);
      });

      testWidgets(
        'Widget structure',
        (tester) async {
          await tester.pumpWidget(wrapWithMaterialApp(Update()));
          await tester.pumpAndSettle();

          expect(find.text('الإصدار الحالي:'), findsOneWidget);
          expect(find.text('أخر إصدار:'), findsOneWidget);

          expect(
            find.descendant(
              of: find.ancestor(
                of: find.text('الإصدار الحالي:'),
                matching: find.byType(ListTile),
              ),
              matching: find.text('8.0.0'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.ancestor(
                of: find.text('أخر إصدار:'),
                matching: find.byType(ListTile),
              ),
              matching: find.text('8.5.0'),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Update Dialog',
        (tester) async {
          await tester.pumpWidget(wrapWithMaterialApp(Update()));
          await tester.pumpAndSettle();

          expect(find.text('هل تريد التحديث إلى إصدار 8.5.0؟'), findsOneWidget);
          expect(find.text('نعم'), findsOneWidget);

          await tester.tap(find.text('نعم'));

          verify(
              (UrlLauncherPlatform.instance as MockUrlLauncherPlatform).launch(
            downloadLink,
            enableDomStorage: anyNamed('enableDomStorage'),
            enableJavaScript: anyNamed('enableJavaScript'),
            headers: anyNamed('headers'),
            universalLinksOnly: anyNamed('universalLinksOnly'),
            useSafariVC: anyNamed('useSafariVC'),
            useWebView: anyNamed('useWebView'),
            webOnlyWindowName: anyNamed('webOnlyWindowName'),
          ));
        },
      );
    });
  });
  group('Initialization tests', () {
    group('Login', () {
      setUp(User.instance.signOut);

      testWidgets(
        'Displays Login screen when not logged in',
        (tester) async {
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

          await tester.tap(find.text('Google'));
          await tester.pumpAndSettle();

          expect(firebaseAuth.currentUser?.uid, '8t7we9rhuiU%762');
        },
      );
      tearDown(User.instance.signOut);
    });

    group(
      'User registeration',
      () {
        setUp(() async {
          userClaims['approved'] = false;
          userClaims['password'] = null;

          if (User.instance.uid != null) await User.instance.signOut();
          await firebaseAuth.signInWithCustomToken('token');
          await User.instance.initialized;
          await User.instance.forceRefresh();
        });
        tearDown(() async {
          userClaims['approved'] = true;
          userClaims['password'] = 'password';
          await User.instance.signOut();
          reset(firebaseFunctions);
        });

        testWidgets(
          'Shows UserRegisteration widget',
          (tester) async {
            await tester.pumpWidget(App());
            await tester.pumpAndSettle();

            expect(find.byType(UserRegisteration), findsOneWidget);
          },
          timeout: Timeout(Duration(seconds: 5)),
        );

        testWidgets('Using invitation link', (tester) async {
          final MockHttpsCallable mockHttpsCallable = MockHttpsCallable();

          when(firebaseFunctions.httpsCallable('registerWithLink'))
              .thenReturn(mockHttpsCallable);

          when(mockHttpsCallable.call(argThat(predicate((p) {
            if (p == null) return false;
            final Map<String, dynamic> m = p as Map<String, dynamic>;
            return m['link'] == 'https://churchdata.page.link/fakeInvitation';
          }))))
              .thenAnswer((_) async => FakeHttpsCallableResult<String>('dumb'));

          await tester.pumpWidget(App());
          await tester.pumpAndSettle();

          await tester.tap(find.text('تفعيل الحساب باللينك'));
          await tester.pump();

          expect(find.text('برجاء ادخال لينك الدخول لتفعيل حسابك'),
              findsOneWidget);

          await tester.enterText(
              find.widgetWithText(TextFormField, 'لينك الدعوة'),
              'https://churchdata.page.link/fakeInvitation');
          await tester.pump();

          await tester.tap(find.text('تفعيل الحساب باللينك'));
          await tester.pump();

          verify(mockHttpsCallable.call(argThat(predicate((p) {
            if (p == null) return false;
            final Map<String, dynamic> m = p as Map<String, dynamic>;
            return m['link'] == 'https://churchdata.page.link/fakeInvitation';
          }))));
        });

        testWidgets(
          'Submitting account name and password',
          (tester) async {
            final MockHttpsCallable mockHttpsCallable = MockHttpsCallable();

            when(mockHttpsCallable.call(argThat(predicate((p) {
              if (p == null) return false;
              final Map<String, dynamic> m = p as Map<String, dynamic>;
              return m['name'] == 'name' &&
                  m['password'] == Encryption.encryptPassword('Strong*P@ss9') &&
                  m['fcmToken'] == '{FCMToken}';
            })))).thenAnswer(
                (_) async => FakeHttpsCallableResult<String>('dumb'));

            when(firebaseFunctions.httpsCallable('registerAccount'))
                .thenReturn(mockHttpsCallable);

            await firestore.doc('Persons/user').set(
              {
                'LastTanawol': Timestamp.now(),
                'LastConfession': Timestamp.now(),
              },
            );

            userClaims['approved'] = true;
            await User.instance.forceRefresh();

            await tester.pumpWidget(App());
            await tester.pumpAndSettle();

            expect(find.byType(UserRegisteration), findsOneWidget);

            await tester.scrollUntilVisible(
              find.byKey(Key('UsernameField')),
              70,
              scrollable: listViewMatcher,
            );

            await tester.enterText(
              find.byKey(const Key('UsernameField')),
              'name',
            );

            await tester.scrollUntilVisible(
              find.byKey(Key('Password')),
              70,
              scrollable: listViewMatcher,
            );

            await tester.enterText(find.byKey(Key('Password')), 'Strong*P@ss9');

            await tester.scrollUntilVisible(
              find.byKey(Key('PasswordConfirmation')),
              70,
              scrollable: listViewMatcher,
            );

            await tester.enterText(
                find.byKey(Key('PasswordConfirmation')), 'Strong*P@ss9');
            await tester.pump();

            await tester.scrollUntilVisible(
              find.byKey(Key('SubmitButton')),
              70,
              scrollable: listViewMatcher,
            );

            await tester.tap(find.byKey(Key('SubmitButton')));

            await tester.pump();

            verify(mockHttpsCallable.call(argThat(predicate((p) {
              if (p == null) return false;
              final Map<String, dynamic> m = p as Map<String, dynamic>;
              return m['name'] == 'name' &&
                  m['password'] == Encryption.encryptPassword('Strong*P@ss9') &&
                  m['fcmToken'] == '{FCMToken}';
            }))));
          },
          timeout: Timeout(Duration(seconds: 5)),
        );
      },
    );

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
        const _passwordText = '1%Pass word*)';

        setUp(() async {
          userClaims['password'] = Encryption.encryptPassword(_passwordText);

          if (User.instance.uid != null) await User.instance.signOut();
          await firebaseAuth.signInWithCustomToken('token');
          await User.instance.initialized;
        });
        tearDown(() async {
          await User.instance.signOut();
          userClaims['password'] = 'password';
        });

        testWidgets('Entering password', (tester) async {
          tester.binding.window.physicalSizeTestValue =
              Size(1080 * 3, 2400 * 3);

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
            find.byKey(Key('Password')),
            _passwordText,
          );

          await tester.tap(find.byKey(Key('Submit')));

          await tester.pump();
          await tester.pump();

          expect(find.text('Test succeeded'), findsOneWidget);
        });
        group('Errors', () {
          testWidgets('Empty Password', (tester) async {
            tester.binding.window.physicalSizeTestValue =
                Size(1080 * 3, 2400 * 3);

            await tester.pumpWidget(
              wrapWithMaterialApp(
                AuthScreen(),
              ),
            );
            await tester.pump();

            await tester.enterText(
              find.byKey(Key('Password')),
              '',
            );
            await tester.tap(find.byKey(Key('Submit')));
            await tester.pump();

            expect(find.text('كلمة سر فارغة!'), findsOneWidget);
          });
          testWidgets('Wrong Password', (tester) async {
            tester.binding.window.physicalSizeTestValue =
                Size(1080 * 3, 2400 * 3);

            await tester.pumpWidget(
              wrapWithMaterialApp(
                AuthScreen(),
              ),
            );
            await tester.pump();

            await tester.enterText(
              find.byKey(Key('Password')),
              'Wrong',
            );
            await tester.tap(find.text('تسجيل الدخول'));
            await tester.pump();

            expect(find.text('كلمة سر خاطئة!'), findsOneWidget);
          });
        });
      });

      testWidgets('With Biometrics', (tester) async {
        tester.binding.window.physicalSizeTestValue = Size(1080 * 3, 2400 * 3);

        await tester.pumpWidget(
          wrapWithMaterialApp(
            AuthScreen(
              nextRoute: 'Success',
            ),
            routes: {'Success': (_) => Scaffold(body: Text('Test succeeded'))},
          ),
        );
        await tester.pump();

        _authCompleter.complete(false);
        _authCompleter = Completer();

        await tester.tap(find.byKey(Key('Biometrics')));

        _authCompleter.complete(true);

        await tester.pumpAndSettle();

        expect(find.text('Test succeeded'), findsOneWidget);
      });
    });

    group('Updating lastConfession and lastTanawol', () {
      final DateTime lastConfession =
          DateTime.now().subtract(Duration(days: 2 * 30));
      final DateTime lastTanawol =
          DateTime.now().subtract(Duration(days: (2 * 30) + 1));

      setUp(() async {
        if (User.instance.uid != null) await User.instance.signOut();
        await firebaseAuth.signInWithCustomToken('token');
        await User.instance.initialized;

        await firestore.doc('Persons/user').set(
          {
            'LastTanawol': lastTanawol,
            'LastConfession': lastConfession,
          },
        );
      });

      tearDown(() async {
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

        addTearDown(() {
          when(remoteConfig.getString('LoadApp')).thenReturn('true');
          when(remoteConfig.getString('LatestVersion')).thenReturn('8.0.0');
        });

        await tester.pumpWidget(App());

        await tester.pumpAndSettle();

        expect(find.text('تحديث'), findsOneWidget);
      },
    );
  });

  group('Root widget', () {
    setUpAll(() async {
      if (User.instance.uid != null) await User.instance.signOut();
      await firebaseAuth.signInWithCustomToken('token');
      await User.instance.initialized;

      await Person(
        ref: User.instance.personDocRef,
        areaId: firestore.doc('Areas/fakeArea'),
        streetId: firestore.doc('Streets/fakeStreet'),
        familyId: firestore.doc('Families/fakeFamily'),
        name: 'Mock User Data',
        lastTanawol: Timestamp.now(),
        lastConfession: Timestamp.now(),
      ).set();

      //Populate database with fake data:
      await Area(
        null,
        'Fake Area',
        'address',
        false,
        false,
        Timestamp.now(),
        Timestamp.now(),
        [User.instance.uid!],
        User.instance.uid,
        ref: firestore.doc('Areas/fakeArea'),
      ).set();

      await Street(null, firestore.doc('Areas/fakeArea'), 'Fake Street',
              Timestamp.now(), User.instance.uid,
              ref: firestore.doc('Streets/fakeStreet'))
          .set();

      await Family(
        null,
        firestore.doc('Areas/fakeArea'),
        firestore.doc('Streets/fakeStreet'),
        'Fake Family',
        'address',
        Timestamp.now(),
        Timestamp.now(),
        User.instance.uid,
        ref: firestore.doc('Families/fakeFamily'),
      ).set();

      await Person(
        ref: firestore.doc('Persons/fakePerson'),
        areaId: firestore.doc('Areas/fakeArea'),
        streetId: firestore.doc('Streets/fakeStreet'),
        familyId: firestore.doc('Families/fakeFamily'),
        name: 'Fake Person',
      ).set();
    });

    testWidgets('Tabs', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FeatureDiscovery.withProvider(
            persistenceProvider: MockHivePersistenceProvider(),
            child: Root(),
          ),
        ),
      );

      expect(
        find.ancestor(
          of: find.byIcon(Icons.pin_drop),
          matching: find.byType(Tab),
        ),
        findsOneWidget,
      );
      expect(find.byKey(Key('_AreasTab')), findsOneWidget);

      expect(
        find.ancestor(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == 'assets/streets.png',
          ),
          matching: find.byType(Tab),
        ),
        findsOneWidget,
      );
      expect(find.byKey(Key('_StreetsTab')), findsOneWidget);

      expect(
        find.ancestor(
          of: find.byIcon(Icons.group),
          matching: find.byType(Tab),
        ),
        findsOneWidget,
      );
      expect(find.byKey(Key('_FamiliesTab')), findsOneWidget);

      expect(
        find.ancestor(
          of: find.byIcon(Icons.person),
          matching: find.byType(Tab),
        ),
        findsOneWidget,
      );
      expect(find.byKey(Key('_PersonsTab')), findsOneWidget);
    });
    testWidgets('Data', (tester) async {
      tester.binding.window.physicalSizeTestValue = Size(1080 * 3, 2400 * 3);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          FeatureDiscovery.withProvider(
            persistenceProvider: MockHivePersistenceProvider(),
            child: Root(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(_AreaWidget, 'Fake Area'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(Key('_StreetsTab')));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(_StreetWidget, 'Fake Street'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(Key('_FamiliesTab')));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(_FamilyWidget, 'Fake Family'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(Key('_PersonsTab')));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(_PersonWidget, 'Fake Person'),
        findsOneWidget,
      );
    });
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
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
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
  Future<Map<String, String>> readAll({
    aOptions,
    iOptions,
    lOptions,
    mOptions,
    wOptions,
    webOptions,
  }) async =>
      data;

  @override
  Future<void> write({
    required String key,
    required String? value,
    iOptions,
    aOptions,
    lOptions,
    mOptions,
    wOptions,
    webOptions,
  }) async {
    if (value == null)
      data.remove(key);
    else
      data[key] = value;
  }
}

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

class FakeHttpsCallableResult<T> extends Fake
    implements HttpsCallableResult<T> {
  FakeHttpsCallableResult(this.data);

  @override
  T data;
}

typedef _AreaWidget = DataObjectWidget<Area>;
typedef _StreetWidget = DataObjectWidget<Street>;
typedef _FamilyWidget = DataObjectWidget<Family>;
typedef _PersonWidget = DataObjectWidget<Person>;
