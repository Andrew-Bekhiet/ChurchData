import 'dart:async';

import 'package:churchdata/views/utils/List.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.io) 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
export 'package:tuple/tuple.dart';

import '../../EncryptionKeys.dart';
import '../../utils/Helpers.dart';
import '../../views/utils/LoadingWidget.dart';
import '../../Models/User.dart';
import '../../utils/globals.dart';

var authKey = GlobalKey<ScaffoldState>();

class AuthScreen extends StatefulWidget {
  final Widget nextWidget;
  final String nextRoute;
  AuthScreen({Key key, this.nextWidget, this.nextRoute}) : super(key: key);
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController passwordText = TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  final TextEditingController userName = TextEditingController();

  Completer<bool> _authCompleter = Completer<bool>();

  bool ignoreBiometrics = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  void _authenticate() {
    if (!canCheckBio) return;
    _authCompleter = Completer<bool>();
    LocalAuthentication()
        .authenticateWithBiometrics(
            localizedReason: 'برجاء التحقق للمتابعة',
            stickyAuth: true,
            useErrorDialogs: false)
        .then((value) {
      _authCompleter.complete(value);
      if (value) {
        if (widget.nextRoute != null) {
          Navigator.of(context).pushReplacementNamed(widget.nextRoute);
        } else if (widget.nextWidget == null) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (con) {
              return widget.nextWidget;
            }),
          );
        }
      }
    }).catchError(_authCompleter.completeError);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<User, Tuple2<String, String>>(
      selector: (_, user) => Tuple2(user.name, user.password),
      builder: (context, user, child) {
        if (user.item2 != null) {
          try {
            if (canCheckBio && !ignoreBiometrics) {
              return FutureBuilder<bool>(
                future: _authCompleter.future,
                builder: (context, snapshot) {
                  if (!_authCompleter.isCompleted || snapshot.data)
                    return Scaffold(
                      key: authKey,
                      resizeToAvoidBottomInset: !kIsWeb,
                      appBar: AppBar(
                        leading: Container(),
                        title: Text('جار التحقق...'),
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            OutlinedButton.icon(
                              icon: Icon(Icons.refresh),
                              label: Text('إعادة المحاولة'),
                              onPressed: () {
                                _authenticate();
                                setState(() {});
                              },
                            ),
                            OutlinedButton.icon(
                              icon: Icon(Icons.security),
                              label: Text('إدخال كلمة السر'),
                              onPressed: () {
                                setState(() {
                                  ignoreBiometrics = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  else {
                    return Scaffold(
                      key: authKey,
                      resizeToAvoidBottomInset: !kIsWeb,
                      appBar: AppBar(
                        title: Text('فشل التحقق!'),
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            OutlinedButton.icon(
                              icon: Icon(Icons.refresh),
                              label: Text('إعادة المحاولة'),
                              onPressed: () {
                                _authenticate();
                                setState(() {});
                              },
                            ),
                            OutlinedButton.icon(
                              icon: Icon(Icons.security),
                              label: Text('إدخال كلمة السر'),
                              onPressed: () {
                                setState(() {
                                  ignoreBiometrics = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              );
            }
          } on PlatformException catch (err, stkTrace) {
            FirebaseCrashlytics.instance
                .setCustomKey('LastErrorIn', 'AuthScreen.build');
            FirebaseCrashlytics.instance.recordError(err, stkTrace);
          }
        }
        if (canCheckBio) LocalAuthentication().stopAuthentication();
        return Scaffold(
          key: authKey,
          resizeToAvoidBottomInset: !kIsWeb,
          appBar: AppBar(
            leading: Container(),
            title: Text(user.item2 == null
                ? 'اقتربت من الانتهاء'
                : 'إدخال كلمة المرور للدخول للبرنامج'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (user.item2 == null)
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      controller: userName..text = user.item1,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'هذا الحقل مطلوب';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => passwordFocus.requestFocus(),
                    ),
                  if (user.item2 == null)
                    Text(
                        'يرجى إدخال كلمة السر لاستخدامها فيما بعد للدخول للبرنامج:'),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'كلمة السر',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    obscureText: true,
                    autocorrect: false,
                    autofocus: true,
                    controller: passwordText,
                    focusNode: passwordFocus,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                    onFieldSubmitted: (v) =>
                        _submit(v, userName.text, user.item2 == null),
                  ),
                  ElevatedButton(
                    onPressed: () => _submit(
                        passwordText.text, userName.text, user.item2 == null),
                    child: Text('تسجيل الدخول'),
                  ),
                  if (user.item2 != null && canCheckBio)
                    OutlinedButton.icon(
                      icon: Icon(Icons.fingerprint),
                      label: Text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
                      onPressed: () {
                        _authenticate();
                        setState(() {
                          ignoreBiometrics = false;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future _submit(String password, String userName,
      [bool nameRequired = false]) async {
    if (nameRequired && (userName == null || userName.isEmpty)) {
      passwordText.clear();
      await showErrorDialog(context, 'اسم المستخدم لا يمكن ان يكون فارغا');
      return;
    }
    // ignore: unawaited_futures
    showDialog(
      context: context,
      builder: (context) => Loading(),
    );
    String pwd = context.read<User>().password;
    String encryptedPassword = Encryption.encryptPassword(password);
    if (pwd == null && password.isNotEmpty) {
      try {
        await FirebaseFunctions.instance
            .httpsCallable('changePassword')
            .call({'oldPassword': null, 'newPassword': encryptedPassword});
        encryptedPassword = null;
        pwd = null;
        await FirebaseFunctions.instance
            .httpsCallable('changeUserName')
            .call({'newName': userName});
        Navigator.of(context).pop();
        if (widget.nextWidget != null) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (c) => widget.nextWidget),
          );
        } else if (widget.nextRoute != null) {
          await Navigator.of(context).pushReplacementNamed(widget.nextRoute);
        } else {
          Navigator.of(context).pop();
        }
      } catch (err, stkTrace) {
        await FirebaseCrashlytics.instance
            .setCustomKey('LastErrorIn', 'AuthScreen._submit');
        await FirebaseCrashlytics.instance.recordError(err, stkTrace);
        await showErrorDialog(context, 'حدث خطأ أثناء تحديث كلمة السر!');
        setState(() {});
      }
    } else if (password.isNotEmpty && pwd == encryptedPassword) {
      encryptedPassword = null;
      pwd = null;
      Navigator.of(context).pop();
      if (widget.nextWidget != null) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (c) => widget.nextWidget),
        );
      } else if (widget.nextRoute != null) {
        await Navigator.of(context).pushReplacementNamed(widget.nextRoute);
      } else {
        Navigator.of(context).pop();
      }
    } else {
      encryptedPassword = null;
      pwd = null;
      Navigator.of(context).pop();
      await showErrorDialog(context, 'كلمة سر خاطئة أو فارغة!');
      setState(() {});
    }
    encryptedPassword = null;
    pwd = null;
  }
}
