import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:churchdata/models/data_map.dart';
import 'package:churchdata/models/mini_models.dart';
import 'package:churchdata/services/notifications_service.dart';
import 'package:churchdata/services/theming_service.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/views/analytics/activity_analysis.dart';
import 'package:churchdata/views/analytics/spiritual_analysis.dart';
import 'package:churchdata/views/edit_page/edit_family.dart';
import 'package:churchdata/views/edit_page/edit_person.dart';
import 'package:churchdata/views/edit_page/edit_street.dart';
import 'package:churchdata/views/edit_page/update_user_data_error_p.dart';
import 'package:churchdata/views/exports.dart';
import 'package:churchdata/views/info_page/area_info.dart';
import 'package:churchdata/views/info_page/family_info.dart';
import 'package:churchdata/views/info_page/person_info.dart';
import 'package:churchdata/views/info_page/street_info.dart';
import 'package:churchdata/views/info_page/user_info.dart';
import 'package:churchdata/views/mini_model_list.dart';
import 'package:churchdata/views/trash.dart';
import 'package:churchdata/views/user_registeration.dart';
import 'package:churchdata_core/churchdata_core.dart'
    show
        NotificationsService,
        ThemingService,
        initCore,
        registerFirebaseDependencies;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';

import 'EncryptionKeys.dart';
import 'models/area.dart';
import 'models/family.dart';
import 'models/hive_persistence_provider.dart';
import 'models/invitation.dart';
import 'models/loading_widget.dart';
import 'models/person.dart';
import 'models/street.dart';
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

Completer<void> _initialization = Completer();
bool _initializing = false;

void main() async {
  FlutterError.onError =
      (details) => FirebaseCrashlytics.instance.recordFlutterError(details);
  ErrorWidget.builder = (error) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterError(error);
    }
    return Material(
      child: ColoredBox(
        color: Colors.white,
        child: Text(
          'حدث خطأ:' '\n' + error.summary.toString(),
        ),
      ),
    );
  };

  WidgetsFlutterBinding.ensureInitialized();

  await initConfigs();

  runApp(const App());
}

const bool kUseFirebaseEmulators = false;

Future<void> initConfigs([bool retryOnHiveError = true]) async {
  if (_initializing) return _initialization.future;
  _initializing = true;

  //Firebase initialization
  if (kUseFirebaseEmulators && kDebugMode) {
    //dot env
    await dotenv.load();
    final String kEmulatorsHost = dotenv.env['kEmulatorsHost']!;

    await Firebase.initializeApp();

    await auth.FirebaseAuth.instance.useAuthEmulator(kEmulatorsHost, 9099);
    await FirebaseStorage.instance.useStorageEmulator(kEmulatorsHost, 9199);
    firestore.FirebaseFirestore.instance
        .useFirestoreEmulator(kEmulatorsHost, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(kEmulatorsHost, 5001);
    FirebaseDatabase.instance.databaseURL = kEmulatorsHost + ':9000';
    FirebaseDatabase.instance.useDatabaseEmulator(kEmulatorsHost, 9000);
  } else {
    await Firebase.initializeApp();
  }

  registerFirebaseDependencies();

  await initCore(
    sentryDSN: sentryDSN,
    overrides: {
      ThemingService: () {
        final instance = CDThemingService();

        GetIt.I.registerSingleton<CDThemingService>(
          instance,
          dispose: (t) => t.dispose(),
        );

        return instance;
      },
      NotificationsService: () {
        final instance = CDNotificationsService();

        GetIt.I.registerSingleton<CDNotificationsService>(
          instance,
          signalsReady: true,
          dispose: (n) => n.dispose(),
        );

        return instance;
      },
    },
  );

  //Hive initialization:
  try {
    await Hive.initFlutter();

    final containsEncryptionKey =
        await flutterSecureStorage.containsKey(key: 'key');
    if (!containsEncryptionKey)
      await flutterSecureStorage.write(
        key: 'key',
        value: base64Url.encode(Hive.generateSecureKey()),
      );

    final encryptionKey =
        base64Url.decode((await flutterSecureStorage.read(key: 'key'))!);

    await Hive.openBox(
      'User',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox('Settings');
    await Hive.openBox<bool>('FeatureDiscovery');
    await Hive.openBox<String?>('PhotosURLsCache');
  } catch (e) {
    await Hive.close();
    await Hive.deleteBoxFromDisk('User');
    await Hive.deleteBoxFromDisk('Settings');
    await Hive.deleteBoxFromDisk('FeatureDiscovery');
    await Hive.deleteBoxFromDisk('NotificationsSettings');
    await Hive.deleteBoxFromDisk('PhotosURLsCache');

    if (retryOnHiveError) {
      _initializing = false;

      await initConfigs(false);

      return _initialization.future;
    }
    rethrow;
  }

  if (firebaseAuth.currentUser?.uid != null) await User.instance.initialized;

  return _initialization.complete();
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  final AsyncMemoizer<void> _loader = AsyncMemoizer();
  StreamSubscription? userTokenListener;

  bool showFormOnce = false;
  bool updateUserDataDialogShown = false;

  @override
  void dispose() {
    userTokenListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User>.value(
          initialData: User.instance,
          value: User.instance.stream,
        ),
      ],
      builder: (context, _) => FeatureDiscovery.withProvider(
        persistenceProvider: HivePersistenceProvider(),
        child: StreamBuilder<ThemeData>(
          initialData: GetIt.I<ThemingService>().theme,
          stream: GetIt.I<ThemingService>().stream,
          builder: (context, theme) {
            return MaterialApp(
              navigatorKey: navigator,
              scaffoldMessengerKey: scaffoldMessenger,
              debugShowCheckedModeBanner: false,
              title: 'بيانات الكنيسة',
              initialRoute: '/',
              routes: {
                '/': buildLoadAppWidget,
                'Login': (context) => const LoginScreen(),
                'Data/EditArea': (context) => EditArea(
                      area:
                          ModalRoute.of(context)?.settings.arguments as Area? ??
                              Area.empty(),
                    ),
                'Data/EditStreet': (context) {
                  if (ModalRoute.of(context)!.settings.arguments is Street)
                    return EditStreet(
                      street:
                          ModalRoute.of(context)!.settings.arguments! as Street,
                    );
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
                      family:
                          ModalRoute.of(context)!.settings.arguments! as Family,
                    );
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
                      person:
                          ModalRoute.of(context)!.settings.arguments! as Person,
                    );
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
                          Invitation.empty(),
                    ),
                'MyAccount': (context) => const MyAccount(),
                'ActivityAnalysis': (context) => ActivityAnalysis(
                      areas: ModalRoute.of(context)!.settings.arguments
                          as List<Area>?,
                    ),
                'SpiritualAnalysis': (context) => SpiritualAnalysis(
                      areas: ModalRoute.of(context)!.settings.arguments
                          as List<Area>?,
                    ),
                'Notifications': (context) => const NotificationsPage(),
                'Update': (context) => const Update(),
                'Search': (context) => const SearchQuery(),
                'Trash': (context) => const Trash(),
                'ExportOps': (context) => const Exports(),
                'DataMap': (context) => const DataMap(),
                'AreaInfo': (context) => AreaInfo(
                      area:
                          ModalRoute.of(context)!.settings.arguments as Area? ??
                              Area.empty(),
                    ),
                'StreetInfo': (context) => StreetInfo(
                      street: ModalRoute.of(context)!.settings.arguments
                              as Street? ??
                          Street.empty(),
                    ),
                'FamilyInfo': (context) => FamilyInfo(
                      family: ModalRoute.of(context)!.settings.arguments
                              as Family? ??
                          Family.empty(),
                    ),
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
                      user: ModalRoute.of(context)!.settings.arguments! as User,
                    ),
                'InvitationInfo': (context) => InvitationInfo(
                      invitation: ModalRoute.of(context)!.settings.arguments!
                          as Invitation,
                    ),
                'Settings': (context) => const settingsui.Settings(),
                'Settings/Churches': (context) => const ChurchesPage(),
                'Settings/Fathers': (context) => const FathersPage(),
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
                'Invitations': (context) => const InvitationsPage(),
                'EditUserData': (context) => FutureBuilder<Person?>(
                      future: User.getCurrentPerson(),
                      builder: (context, data) {
                        if (data.hasError)
                          return Center(child: ErrorWidget(data.error!));
                        if (data.connectionState == ConnectionState.waiting)
                          return const Scaffold(
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
                              ),
                          userData: true,
                        );
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
              locale: const Locale('ar', 'EG'),
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
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasError)
          return const Loading(
            showVersionInfo: true,
          );

        if (snapshot.hasError) {
          if (snapshot.error.toString() ==
                  'Exception: Error Update User Data' &&
              User.instance.password != null &&
              !updateUserDataDialogShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
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
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (user.personRef == null && !showFormOnce) {
                  showFormOnce = true;
                  if (kIsWeb ||
                      await navigator.currentState!.pushNamed('EditUserData')
                          is JsonRef) {
                    scaffoldMessenger.currentState!.showSnackBar(
                      const SnackBar(
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

  @override
  void initState() {
    super.initState();

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
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: const Duration(minutes: 2),
      ),
    );

    try {
      await remoteConfig.fetchAndActivate();
    } catch (e) {}

    if (remoteConfig.getString('LoadApp') == 'false') {
      throw Exception('يجب التحديث لأخر إصدار لتشغيل البرنامج');
    } else {
      if (User.instance.uid != null) {
        firestore.FirebaseFirestore.instance.settings =
            const firestore.Settings(
          persistenceEnabled: true,
          sslEnabled: true,
          cacheSizeBytes: 104857600,
        );

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
