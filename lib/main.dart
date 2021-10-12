import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:async/async.dart';
import 'package:churchdata/models/data_map.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/views/analytics/activity_analysis.dart';
import 'package:churchdata/views/analytics/spiritual_analysis.dart';
import 'package:churchdata/views/edit_page/edit_family.dart';
import 'package:churchdata/views/edit_page/edit_person.dart';
import 'package:churchdata/views/edit_page/edit_street.dart';
import 'package:churchdata/views/edit_page/update_user_data_error_p.dart';
import 'package:churchdata/views/info_page/area_info.dart';
import 'package:churchdata/views/info_page/family_info.dart';
import 'package:churchdata/views/info_page/person_info.dart';
import 'package:churchdata/views/info_page/street_info.dart';
import 'package:churchdata/views/info_page/user_info.dart';
import 'package:churchdata/views/mini_model_list.dart';
import 'package:churchdata/views/trash.dart';
import 'package:churchdata/views/user_registeration.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User
    hide UserInfo;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User
    hide UserInfo;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';

import 'models/area.dart';
import 'models/family.dart';
import 'models/hive_persistence_provider.dart';
import 'models/invitation.dart';
import 'models/loading_widget.dart';
import 'models/mini_models.dart';
import 'models/person.dart';
import 'models/street.dart';
import 'models/theme_notifier.dart';
import 'models/user.dart';
import 'utils/globals.dart';
import 'utils/helpers.dart';
import 'views/additional_settings.dart';
import 'views/auth_screen.dart';
import 'views/edit_page/edit_area.dart';
import 'views/edit_page/edit_invitation.dart';
import 'views/info_page/invitation_info.dart';
import 'views/invitations_page.dart';
import 'views/login.dart';
import 'views/my_account.dart';
import 'views/notifications_page.dart';
import 'views/root.dart';
import 'views/search_query.dart';
import 'views/settings.dart' as settingsui;
import 'views/updates.dart';

void main() async {
  FlutterError.onError = (flutterError) {
    FirebaseCrashlytics.instance.recordFlutterError(flutterError);
  };
  ErrorWidget.builder = (error) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterError(error);
    }
    return Material(
      child: Container(
        color: Colors.white,
        child: Text(
          'حدث خطأ:' '\n' + error.summary.toString(),
        ),
      ),
    );
  };

  WidgetsFlutterBinding.ensureInitialized();

  await initConfigs();

  runApp(App());
}

final String kEmulatorsHost = dotenv.env['kEmulatorsHost']!;
final bool kUseFirebaseEmulators =
    dotenv.env['kUseFirebaseEmulators']?.toString() == 'true';

@visibleForTesting
Future<void> initConfigs() async {
  //dot env
  await dotenv.load(fileName: '.env');

  //Firebase initialization
  if (kDebugMode && kUseFirebaseEmulators) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: dotenv.env['apiKey']!,
          appId: dotenv.env['appId']!,
          messagingSenderId: 'messagingSenderId',
          projectId: dotenv.env['projectId']!,
          databaseURL: kEmulatorsHost + ':9000'),
    );
    await auth.FirebaseAuth.instance.useAuthEmulator(kEmulatorsHost, 9099);
    await FirebaseStorage.instance.useStorageEmulator(kEmulatorsHost, 9199);
    firestore.FirebaseFirestore.instance
        .useFirestoreEmulator(kEmulatorsHost, 8080, sslEnabled: false);
    FirebaseFunctions.instance.useFunctionsEmulator(kEmulatorsHost, 5001);
    firebaseDatabase =
        FirebaseDatabase(databaseURL: 'http://' + kEmulatorsHost + ':9000');
  } else
    await Firebase.initializeApp();

  if (firebaseAuth.currentUser?.uid != null) await User.instance.initialized;

  //Hive initialization:
  await Hive.initFlutter();

  await Hive.openBox('Settings');
  await Hive.openBox<bool>('FeatureDiscovery');
  await Hive.openBox<Map>('NotificationsSettings');
  await Hive.openBox<String>('PhotosURLsCache');

  //Notifications:
  if (!kIsWeb) await AndroidAlarmManager.initialize();

  if (!kIsWeb)
    await FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('warning')),
      onSelectNotification: onNotificationClicked,
    );
}

@visibleForTesting
ThemeData initTheme() {
  bool? darkTheme = Hive.box('Settings').get('DarkTheme');
  final bool greatFeastTheme =
      Hive.box('Settings').get('GreatFeastTheme', defaultValue: true);
  MaterialColor color = Colors.cyan;
  Color accent = Colors.cyanAccent;

  final riseDay = getRiseDay();
  if (greatFeastTheme &&
      DateTime.now()
          .isAfter(riseDay.subtract(Duration(days: 7, seconds: 20))) &&
      DateTime.now().isBefore(riseDay.subtract(Duration(days: 1)))) {
    color = black;
    accent = blackAccent;
    darkTheme = true;
  } else if (greatFeastTheme &&
      DateTime.now().isBefore(riseDay.add(Duration(days: 50, seconds: 20))) &&
      DateTime.now().isAfter(riseDay.subtract(Duration(days: 1)))) {
    darkTheme = false;
  }

  return ThemeData(
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: color,
      brightness: darkTheme != null
          ? (darkTheme ? Brightness.dark : Brightness.light)
          : WidgetsBinding.instance!.window.platformBrightness,
      accentColor: accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: color),
      ),
    ),
    floatingActionButtonTheme:
        FloatingActionButtonThemeData(backgroundColor: color),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: darkTheme != null
        ? (darkTheme ? Brightness.dark : Brightness.light)
        : WidgetsBinding.instance!.window.platformBrightness,
    primaryColor: color,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        primary: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        primary: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        primary: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ),
    bottomAppBarTheme: BottomAppBarTheme(
      color: accent,
      shape: const CircularNotchedRectangle(),
    ),
  );
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  final AsyncMemoizer<void> _loader = AsyncMemoizer();
  StreamSubscription<ConnectivityResult>? connection;
  StreamSubscription? userTokenListener;

  bool showFormOnce = false;
  bool updateUserDataDialogShown = false;

  @override
  void dispose() {
    connection?.cancel();
    userTokenListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User>.value(
            initialData: User.instance, value: User.instance.stream),
        Provider<ThemeNotifier>(
          create: (_) => ThemeNotifier(initTheme()),
          dispose: (_, t) => t.dispose(),
        ),
      ],
      builder: (context, _) => FeatureDiscovery.withProvider(
        persistenceProvider: HivePersistenceProvider(),
        child: StreamBuilder<ThemeData>(
          initialData: context.read<ThemeNotifier>().theme,
          stream: context.read<ThemeNotifier>().stream,
          builder: (context, theme) {
            return MaterialApp(
              navigatorKey: navigator,
              scaffoldMessengerKey: scaffoldMessenger,
              debugShowCheckedModeBanner: false,
              title: 'بيانات الكنيسة',
              initialRoute: '/',
              routes: {
                '/': buildLoadAppWidget,
                'Login': (context) => LoginScreen(),
                'Data/EditArea': (context) => EditArea(
                    area: ModalRoute.of(context)?.settings.arguments as Area? ??
                        Area.empty()),
                'Data/EditStreet': (context) {
                  if (ModalRoute.of(context)!.settings.arguments is Street)
                    return EditStreet(
                        street: ModalRoute.of(context)!.settings.arguments!
                            as Street);
                  else {
                    final Street street = Street.empty()
                      ..areaId = ModalRoute.of(context)!.settings.arguments
                          as JsonRef?;
                    return EditStreet(street: street);
                  }
                },
                'Data/EditFamily': (context) {
                  if (ModalRoute.of(context)!.settings.arguments is Family)
                    return EditFamily(
                        family: ModalRoute.of(context)!.settings.arguments!
                            as Family);
                  else if (ModalRoute.of(context)!.settings.arguments is Json) {
                    final Family family = Family.empty()
                      ..streetId = (ModalRoute.of(context)!.settings.arguments
                          as Json?)?['StreetId']
                      ..insideFamily = (ModalRoute.of(context)!
                          .settings
                          .arguments as Json?)?['Family']
                      ..isStore = (ModalRoute.of(context)!.settings.arguments
                          as Json?)?['IsStore'];
                    return EditFamily(family: family);
                  } else {
                    final Family family = Family.empty()
                      ..streetId = ModalRoute.of(context)!.settings.arguments
                          as JsonRef?;
                    return EditFamily(family: family);
                  }
                },
                'Data/EditPerson': (context) {
                  if (ModalRoute.of(context)!.settings.arguments is Person)
                    return EditPerson(
                        person: ModalRoute.of(context)!.settings.arguments!
                            as Person);
                  else {
                    final Person person = Person(
                      ref: null,
                      areaId: null,
                      streetId: null,
                      familyId: ModalRoute.of(context)!.settings.arguments
                          as JsonRef?,
                    );
                    return EditPerson(person: person);
                  }
                },
                'EditInvitation': (context) => EditInvitation(
                    invitation: ModalRoute.of(context)!.settings.arguments
                            as Invitation? ??
                        Invitation.empty()),
                'MyAccount': (context) => MyAccount(),
                'ActivityAnalysis': (context) => ActivityAnalysis(
                      areas: ModalRoute.of(context)!.settings.arguments
                          as List<Area>?,
                    ),
                'SpiritualAnalysis': (context) => SpiritualAnalysis(
                      areas: ModalRoute.of(context)!.settings.arguments
                          as List<Area>?,
                    ),
                'Notifications': (context) => NotificationsPage(),
                'Update': (context) => Update(),
                'Search': (context) => SearchQuery(),
                'Trash': (context) => Trash(),
                'DataMap': (context) => DataMap(),
                'AreaInfo': (context) => AreaInfo(
                    area: ModalRoute.of(context)!.settings.arguments as Area? ??
                        Area.empty()),
                'StreetInfo': (context) => StreetInfo(
                    street:
                        ModalRoute.of(context)!.settings.arguments as Street? ??
                            Street.empty()),
                'FamilyInfo': (context) => FamilyInfo(
                    family:
                        ModalRoute.of(context)!.settings.arguments as Family? ??
                            Family.empty()),
                'PersonInfo': (context) => PersonInfo(
                      person: ModalRoute.of(context)!.settings.arguments
                              as Person? ??
                          Person(
                            ref: null,
                            areaId: null,
                            streetId: null,
                            familyId: null,
                          ),
                    ),
                'UserInfo': (context) => UserInfo(
                    user: ModalRoute.of(context)!.settings.arguments! as User),
                'InvitationInfo': (context) => InvitationInfo(
                    invitation: ModalRoute.of(context)!.settings.arguments!
                        as Invitation),
                'Settings': (context) => settingsui.Settings(),
                'Settings/Churches': (context) => ChurchesPage(),
                'Settings/Fathers': (context) => FathersPage(),
                'Settings/Jobs': (context) => MiniModelList(
                      collection: firestore.FirebaseFirestore.instance
                          .collection('Jobs'),
                      title: 'الوظائف',
                      transformer: Job.fromQueryDoc,
                    ),
                'Settings/StudyYears': (context) => MiniModelList(
                      collection: firestore.FirebaseFirestore.instance
                          .collection('StudyYears'),
                      title: 'السنوات الدراسية',
                      transformer: StudyYear.fromQueryQueryDoc,
                    ),
                'Settings/Colleges': (context) => MiniModelList(
                      collection: firestore.FirebaseFirestore.instance
                          .collection('Colleges'),
                      title: 'الكليات',
                      transformer: College.fromQueryDoc,
                    ),
                'Settings/ServingTypes': (context) => MiniModelList(
                      collection: firestore.FirebaseFirestore.instance
                          .collection('ServingTypes'),
                      title: 'أنواع الخدمات',
                      transformer: ServingType.fromQueryDoc,
                    ),
                'Settings/PersonTypes': (context) => MiniModelList(
                      collection: firestore.FirebaseFirestore.instance
                          .collection('Types'),
                      title: 'أنواع الأشخاص',
                      transformer: PersonType.fromQueryDoc,
                    ),
                'UpdateUserDataError': (context) => UpdateUserDataErrorPage(
                      person: ModalRoute.of(context)!.settings.arguments
                              as Person? ??
                          Person(
                            ref: User.instance.personDocRef,
                            areaId: null,
                            streetId: null,
                            familyId: null,
                            name: User.instance.name,
                          ),
                    ),
                'Invitations': (context) => InvitationsPage(),
                'EditUserData': (context) => FutureBuilder<Person?>(
                      future: User.getCurrentPerson(),
                      builder: (context, data) {
                        if (data.hasError)
                          return Center(child: ErrorWidget(data.error!));
                        if (data.connectionState == ConnectionState.waiting)
                          return Scaffold(
                            resizeToAvoidBottomInset: !kIsWeb,
                            body: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        return EditPerson(
                            person: data.data ??
                                Person(
                                  ref: User.instance.personDocRef,
                                  areaId: null,
                                  streetId: null,
                                  familyId: null,
                                  name: '',
                                ),
                            userData: true);
                      },
                    ),
              },
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ar', 'EG'),
              ],
              themeMode: theme.data!.brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              locale: Locale('ar', 'EG'),
              theme: theme.data,
              darkTheme: theme.data,
            );
          },
        ),
      ),
    );
  }

  Widget buildLoadAppWidget(BuildContext context) {
    return FutureBuilder<void>(
      future: _loader.runOnce(loadApp),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasError)
          return Loading(
            showVersionInfo: true,
          );

        if (snapshot.hasError) {
          if (snapshot.error.toString() ==
                  'Exception: Error Update User Data' &&
              User.instance.password != null &&
              !updateUserDataDialogShown) {
            WidgetsBinding.instance!.addPostFrameCallback((_) {
              showErrorUpdateDataDialog(context: context);
              updateUserDataDialogShown = true;
            });
          } else if (snapshot.error.toString() ==
              'Exception: يجب التحديث لأخر إصدار لتشغيل البرنامج') {
            Updates.showUpdateDialog(context, canCancel: false);
          }
          if (snapshot.error.toString() !=
                  'Exception: Error Update User Data' ||
              User.instance.password != null)
            return Loading(
              error: true,
              message: snapshot.error.toString(),
              showVersionInfo: true,
            );
        }

        return StreamBuilder<User>(
          stream: User.instance.stream,
          initialData: User.instance,
          builder: (context, data) {
            final User user = data.data!;
            if (user.uid == null) {
              return const LoginScreen();
            } else if (user.approved && user.password != null) {
              return const AuthScreen(nextWidget: Root());
            } else {
              WidgetsBinding.instance!.addPostFrameCallback((_) async {
                if (user.personRef == null && !showFormOnce) {
                  showFormOnce = true;
                  if (kIsWeb ||
                      await navigator.currentState!.pushNamed('EditUserData')
                          is JsonRef) {
                    scaffoldMessenger.currentState!.showSnackBar(
                      SnackBar(
                        content: Text('تم الحفظ بنجاح'),
                      ),
                    );
                  }
                }
              });
              return const UserRegisteration();
            }
          },
        );
      },
    );
  }

  Future configureFirebaseMessaging() async {
    if (!Hive.box('Settings')
            .get('FCM_Token_Registered', defaultValue: false) &&
        firebaseAuth.currentUser != null) {
      try {
        if (kIsWeb)
          await firestore.FirebaseFirestore.instance.enablePersistence();
        firestore.FirebaseFirestore.instance.settings = firestore.Settings(
          persistenceEnabled: true,
          sslEnabled: true,
          cacheSizeBytes: Hive.box('Settings')
              .get('cacheSize', defaultValue: 300 * 1024 * 1024),
        );
        // ignore: empty_catches
      } catch (e) {}
      try {
        final bool permission =
            (await firebaseMessaging.requestPermission()).authorizationStatus ==
                AuthorizationStatus.authorized;
        if (permission)
          await FirebaseFunctions.instance
              .httpsCallable('registerFCMToken')
              .call({'token': await firebaseMessaging.getToken()});
        if (permission)
          await Hive.box('Settings').put('FCM_Token_Registered', true);
      } catch (err, stkTrace) {
        await FirebaseCrashlytics.instance
            .setCustomKey('LastErrorIn', 'AppState.initState');
        await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      }
    }
    if (configureMessaging) {
      FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
      FirebaseMessaging.onMessage.listen(onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((m) async {
        await showPendingMessage();
      });
      configureMessaging = false;
    }
  }

  @override
  void initState() {
    super.initState();

    connection = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        dataSource =
            firestore.GetOptions(source: firestore.Source.serverAndCache);
        if (!kIsWeb && (mainScfld.currentState?.mounted ?? false))
          scaffoldMessenger.currentState!.showSnackBar(SnackBar(
            backgroundColor: Colors.greenAccent,
            content: Text('تم استرجاع الاتصال بالانترنت'),
          ));
      } else {
        dataSource = firestore.GetOptions(source: firestore.Source.cache);

        if (!kIsWeb && (mainScfld.currentState?.mounted ?? false))
          scaffoldMessenger.currentState!.showSnackBar(SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('لا يوجد اتصال بالانترنت!'),
          ));
      }
    });

    setLocaleMessages(
      'ar',
      ArMessages(),
    );
  }

  @visibleForTesting
  Future<void> loadApp() async {
    await remoteConfig.setDefaults(<String, dynamic>{
      'LatestVersion': (await PackageInfo.fromPlatform()).version,
      'LoadApp': 'false',
      'DownloadLink':
          'https://github.com/Andrew-Bekhiet/ChurchData/releases/latest/'
              'download/ChurchData.apk',
    });
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: const Duration(minutes: 2)));
    await remoteConfig.fetchAndActivate();

    if (remoteConfig.getString('LoadApp') == 'false') {
      throw Exception('يجب التحديث لأخر إصدار لتشغيل البرنامج');
    } else {
      if (User.instance.uid != null) {
        await configureFirebaseMessaging();
        if (!kIsWeb && reportUID)
          await FirebaseCrashlytics.instance
              .setCustomKey('UID', User.instance.uid!);
        if (User.instance.approved && !await User.instance.userDataUpToDate()) {
          throw Exception('Error Update User Data');
        }
      }
    }
  }
}
