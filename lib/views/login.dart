import 'dart:async';

import 'package:churchdata/utils/firebase_repo.dart';
import 'package:firebase_auth/firebase_auth.dart' hide FirebaseAuth, User;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user.dart';
import '../utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _LoginTitle(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          children: <Widget>[
            SizedBox(
              height: 200,
              width: 200,
              child: Image.asset('assets/Logo2.png'),
            ),
            const SizedBox(
              height: 10,
            ),
            Center(
              child: Text(
                'قم بتسجيل الدخول أو انشاء حساب',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _loading ? null : _loginWithGoogle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0),
                    child: Image.asset(
                      'assets/google_logo.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : const Text(
                            'تسجيل الدخول بجوجل',
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                  ),
                ],
              ),
            ),
            Container(height: MediaQuery.of(context).size.height / 38),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    text: 'بتسجيل دخولك فإنك توافق على ',
                  ),
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue,
                        ),
                    text: 'شروط الاستخدام',
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const url =
                            'https://church-data.flycricket.io/terms.html';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                  ),
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    text: ' و',
                  ),
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue,
                        ),
                    text: 'سياسة الخصوصية',
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const url =
                            'https://church-data.flycricket.io/privacy.html';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    try {
      Future<UserCredential>? signInFuture;
      if (kIsWeb) {
        final credential =
            (await firebaseAuth.signInWithPopup(GoogleAuthProvider()))
                .credential;
        if (credential != null) {
          signInFuture = firebaseAuth.signInWithCredential(credential);
        }
      } else {
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          if (googleAuth.accessToken != null) {
            final AuthCredential credential = GoogleAuthProvider.credential(
              idToken: googleAuth.idToken,
              accessToken: googleAuth.accessToken,
            );
            signInFuture = firebaseAuth.signInWithCredential(credential);
          }
        }
      }
      if (signInFuture != null) {
        await signInFuture;
        await User.instance.initialized;
        await setupSettings();
      }
    } catch (err, stack) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'Login.build');
      await FirebaseCrashlytics.instance.recordError(err, stack);
      await showErrorDialog(context, err.toString());
    }
  }

  Future<bool> setupSettings() async {
    try {
      final settings = Hive.box('Settings');

      settings.get('AreaSecondLine') ??
          await settings.put('AreaSecondLine', 'Address');

      settings.get('StreetSecondLine') ??
          await settings.put('StreetSecondLine', 'LastVisit');

      settings.get('FamilySecondLine') ??
          await settings.put('FamilySecondLine', 'Address');

      settings.get('PersonSecondLine') ??
          await settings.put('PersonSecondLine', 'Type');

      return true;
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'LoginScreenState.setupSettings');
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      return false;
    }
  }
}

class _LoginTitle extends StatelessWidget implements PreferredSizeWidget {
  const _LoginTitle();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        child: Center(
          child: Text(
            'خدمة الافتقاد',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.color
                      ?.withOpacity(1),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 30);
}
