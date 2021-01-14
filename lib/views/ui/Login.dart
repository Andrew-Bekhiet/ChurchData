import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'
    if (dart.library.io) 'package:firebase_auth/firebase_auth.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' as auth;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.io) 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/Helpers.dart';
import '../../Models/User.dart';
import '../../utils/globals.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String pass = '';

  @override
  Widget build(BuildContext context) {
    var btnPdng = const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0);
    var btnShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
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
              child: Image.asset(
                'assets/Logo2.png',
                fit: BoxFit.scaleDown,
              ),
              height: MediaQuery.of(context).size.height / 7.6,
              width: MediaQuery.of(context).size.width / 3.42,
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
                      shape: btnShape),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: btnPdng,
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
                  onPressed: () async {
                    GoogleSignInAccount googleUser =
                        await GoogleSignIn().signIn();
                    if (googleUser != null) {
                      GoogleSignInAuthentication googleAuth =
                          await googleUser.authentication;
                      if (googleAuth.accessToken != null) {
                        try {
                          AuthCredential credential =
                              GoogleAuthProvider.credential(
                                  idToken: googleAuth.idToken,
                                  accessToken: googleAuth.accessToken);
                          await auth.FirebaseAuth.instance
                              .signInWithCredential(credential)
                              .catchError((er) {
                            if (er.toString().contains(
                                'An account already exists with the same email address'))
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        content: Text(
                                            'هذا الحساب مسجل من قبل بنفس البريد الاكتروني'
                                            '\n'
                                            'جرب تسجيل الدخول بفيسبوك'),
                                      ));
                            return null;
                          }).then((user) {
                            if (user != null) setupSettings();
                          });
                        } catch (err, stkTrace) {
                          await FirebaseCrashlytics.instance
                              .setCustomKey('LastErrorIn', 'Login.build');
                          await FirebaseCrashlytics.instance
                              .recordError(err, stkTrace);
                          await showErrorDialog(context, err);
                        }
                      }
                    }
                  },
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
                        style: Theme.of(context).textTheme.bodyText2.copyWith(
                              color: Colors.blue,
                            ),
                        text: 'شروط الاستخدام',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url =
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
                        style: Theme.of(context).textTheme.bodyText2.copyWith(
                              color: Colors.blue,
                            ),
                        text: 'سياسة الخصوصية',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url =
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
  //   killMe = auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
  //     setState(() {});
  //   });
  // }

  Future<bool> setupSettings() async {
    try {
      var user = await User.getCurrentUser();
      (await settingsInstance).getString('cacheSize') ??
          (await settingsInstance).setString('cacheSize', '314572800');

      (await settingsInstance).getString('AreaSecondLine') ??
          (await settingsInstance).setString('AreaSecondLine', 'Address');

      (await settingsInstance).getString('StreetSecondLine') ??
          (await settingsInstance).setString('StreetSecondLine', 'LastVisit');

      (await settingsInstance).getString('FamilySecondLine') ??
          (await settingsInstance).setString('FamilySecondLine', 'Address');

      (await settingsInstance).getString('PersonSecondLine') ??
          (await settingsInstance).setString('PersonSecondLine', 'Type');

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // if (popOnce) {
        //   Navigator.of(context).pop(true);
        //   popOnce = false;
        // }
        if (user.getNotificationsPermissions().values.toList().any((e) => e)) {
          if ((await settingsInstance).getString('ReminderTimeHours') == null) {
            await (await settingsInstance).setString('ReminderTimeHours', '11');
            await (await settingsInstance)
                .setString('ReminderTimeMinutes', '0');
          }
          if (user.confessionsNotify) {
            await notifChannel.invokeMethod('startConfessions');
          }
          if (user.tanawolNotify) {
            await notifChannel.invokeMethod('startTanawol');
          }
          if (user.birthdayNotify) {
            await notifChannel.invokeMethod('startBirthDay');
          }
        }
      });
      return true;
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'LoginScreenState.setupSettings');
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      return false;
    }
  }
}
