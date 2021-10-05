import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:churchdata/main.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:firebase_auth/firebase_auth.dart' hide FirebaseAuth, User;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user.dart';
import '../utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تسجيل الدخول'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text('بيانات الكنيسة',
                style: Theme.of(context).textTheme.headline4),
            Container(height: MediaQuery.of(context).size.height / 19),
            SizedBox(
              height: MediaQuery.of(context).size.height / 7.6,
              width: MediaQuery.of(context).size.width / 3.42,
              child: Image.asset(
                'assets/Logo2.png',
                fit: BoxFit.scaleDown,
              ),
            ),
            Container(height: MediaQuery.of(context).size.height / 38),
            Text('قم بتسجيل الدخول أو انشاء حساب'),
            Container(height: 30),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    primary: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      Future<UserCredential>? signInFuture;
                      if (kIsWeb) {
                        final credential = (await firebaseAuth
                                .signInWithPopup(GoogleAuthProvider()))
                            .credential;
                        if (credential != null) {
                          signInFuture =
                              firebaseAuth.signInWithCredential(credential);
                        }
                      } else {
                        final GoogleSignInAccount? googleUser =
                            await googleSignIn.signIn();
                        if (googleUser != null) {
                          final GoogleSignInAuthentication googleAuth =
                              await googleUser.authentication;
                          if (googleAuth.accessToken != null) {
                            final AuthCredential credential =
                                GoogleAuthProvider.credential(
                                    idToken: googleAuth.idToken,
                                    accessToken: googleAuth.accessToken);
                            signInFuture =
                                firebaseAuth.signInWithCredential(credential);
                          }
                        }
                      }
                      if (signInFuture != null) {
                        await signInFuture.catchError((er) {
                          if (er.toString().contains(
                              'An account already exists with the same email address'))
                            showDialog(
                              context: context,
                              builder: (context) => const AlertDialog(
                                content: Text(
                                    'هذا الحساب مسجل من قبل بنفس البريد الاكتروني'
                                    '\n'
                                    'جرب تسجيل الدخول بفيسبوك'),
                              ),
                            );
                        });
                        await User.instance.initialized;
                        await setupSettings();
                      }
                    } catch (err, stack) {
                      await FirebaseCrashlytics.instance
                          .setCustomKey('LastErrorIn', 'Login.build');
                      await FirebaseCrashlytics.instance
                          .recordError(err, stack);
                      await showErrorDialog(context, err.toString());
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0),
                        child: Image.asset(
                          'assets/google_logo.png',
                          width: 30,
                          height: 30,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Google',
                          style: TextStyle(color: Colors.black),
                        ),
                      )
                    ],
                  ),
                ),
                if (kDebugMode && kUseFirebaseEmulators)
                  ElevatedButton(
                    onPressed: () async {
                      await firebaseAuth.signInWithEmailAndPassword(
                          email: 'admin@churchdata.org',
                          password: 'admin@churchdata.org');
                    },
                    child: Text('{debug only} Email and password'),
                  ),
                Container(height: MediaQuery.of(context).size.height / 38),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyText2,
                        text: 'بتسجيل دخولك فإنك توافق على ',
                      ),
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyText2?.copyWith(
                              color: Colors.blue,
                            ),
                        text: 'شروط الاستخدام',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const url =
                                'https://church-data.flycricket.io/terms.html';
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          },
                      ),
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyText2,
                        text: ' و',
                      ),
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyText2?.copyWith(
                              color: Colors.blue,
                            ),
                        text: 'سياسة الخصوصية',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const url =
                                'https://church-data.flycricket.io/privacy.html';
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // @override
  // void dispose() {
  //   killMe.cancel();
  //   super.dispose();
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   killMe = firebaseAuth.authStateChanges().listen((user) async {
  //     setState(() {});
  //   });
  // }

  Future<bool> setupSettings() async {
    try {
      final user = User.instance;
      final settings = Hive.box('Settings');
      settings.get('cacheSize') ?? await settings.put('cacheSize', 314572800);

      settings.get('AreaSecondLine') ??
          await settings.put('AreaSecondLine', 'Address');

      settings.get('StreetSecondLine') ??
          await settings.put('StreetSecondLine', 'LastVisit');

      settings.get('FamilySecondLine') ??
          await settings.put('FamilySecondLine', 'Address');

      settings.get('PersonSecondLine') ??
          await settings.put('PersonSecondLine', 'Type');

      if (!kIsWeb)
        WidgetsBinding.instance!.addPostFrameCallback(
          (_) async {
            if (user
                .getNotificationsPermissions()
                .values
                .toList()
                .any((e) => e)) {
              final notificationsSettings =
                  Hive.box<Map>('NotificationsSettings');
              if (user.confessionsNotify) {
                if (notificationsSettings.get('ConfessionTime') == null) {
                  await notificationsSettings.put('ConfessionTime',
                      <String, int>{'Period': 7, 'Hours': 11, 'Minutes': 0});
                }
                await AndroidAlarmManager.periodic(Duration(days: 7),
                    'Confessions'.hashCode, showConfessionNotification,
                    exact: true,
                    startAt: DateTime(DateTime.now().year, DateTime.now().month,
                        DateTime.now().day, 11),
                    rescheduleOnReboot: true);
              }

              if (user.tanawolNotify) {
                if (notificationsSettings.get('TanawolTime') == null) {
                  await notificationsSettings.put('TanawolTime',
                      <String, int>{'Period': 7, 'Hours': 11, 'Minutes': 0});
                }
                await AndroidAlarmManager.periodic(Duration(days: 7),
                    'Tanawol'.hashCode, showTanawolNotification,
                    exact: true,
                    startAt: DateTime(DateTime.now().year, DateTime.now().month,
                        DateTime.now().day, 11),
                    rescheduleOnReboot: true);
              }

              if (user.birthdayNotify) {
                if (notificationsSettings.get('BirthDayTime') == null) {
                  await notificationsSettings.put(
                      'BirthDayTime', <String, int>{'Hours': 11, 'Minutes': 0});
                }
                await AndroidAlarmManager.periodic(Duration(days: 1),
                    'BirthDay'.hashCode, showBirthDayNotification,
                    exact: true,
                    startAt: DateTime(DateTime.now().year, DateTime.now().month,
                        DateTime.now().day, 11),
                    wakeup: true,
                    rescheduleOnReboot: true);
              }
            }
          },
        );
      return true;
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'LoginScreenState.setupSettings');
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      return false;
    }
  }
}
