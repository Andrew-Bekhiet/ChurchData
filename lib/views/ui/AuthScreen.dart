import 'dart:async';

import 'package:churchdata/EncryptionKeys.dart';
import 'package:churchdata/Models/User.dart';
import 'package:churchdata/utils/Helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
export 'package:tuple/tuple.dart';

var authKey = GlobalKey<ScaffoldState>();
final LocalAuthentication _localAuthentication = LocalAuthentication();

class AuthScreen extends StatefulWidget {
  final Widget nextWidget;
  final String nextRoute;
  const AuthScreen({Key key, this.nextWidget, this.nextRoute})
      : super(key: key);
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController passwordText = TextEditingController();
  final FocusNode passwordFocus = FocusNode();

  Completer<bool> _authCompleter = Completer<bool>();

  bool ignoreBiometrics = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _localAuthentication.canCheckBiometrics,
      builder: (context, future) {
        bool canCheckBio = false;
        if (future.hasData) canCheckBio = future.data;
/* 
        return Selector<User, Tuple2<String, String>>(
          selector: (_, user) => Tuple2(user.name, user.password),
          builder: (context, user, child) {
            try {
              if (canCheckBio && !ignoreBiometrics) {
                return FutureBuilder<bool>(
                  future: _authCompleter.future,
                  builder: (context, snapshot) {
                    if (!_authCompleter.isCompleted ||
                        (snapshot.hasData && snapshot.data))
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
            } */
        return Scaffold(
          key: authKey,
          resizeToAvoidBottomInset: !kIsWeb,
          appBar: AppBar(
            leading: Container(),
            title: Text('برجاء التحقق للمتابعة'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(8.0),
            children: <Widget>[
              Image.asset('assets/Logo2.png', fit: BoxFit.scaleDown),
              Divider(),
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
                autofocus: future.hasData && !future.data,
                controller: passwordText,
                focusNode: passwordFocus,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                },
                onFieldSubmitted: (v) => _submit(v),
              ),
              ElevatedButton(
                onPressed: () => _submit(passwordText.text),
                child: Text('تسجيل الدخول'),
              ),
              if (canCheckBio)
                OutlinedButton.icon(
                  icon: Icon(Icons.fingerprint),
                  label: Text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
                  onPressed: () {
                    _authenticate();
                    /* setState(() {
                          ignoreBiometrics = false;
                        }); */
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  void _authenticate() async {
    try {
      if (!await _localAuthentication.canCheckBiometrics) return;
      _authCompleter = Completer<bool>();
      bool value = await _localAuthentication.authenticateWithBiometrics(
          localizedReason: 'برجاء التحقق للمتابعة',
          stickyAuth: true,
          useErrorDialogs: false);
      if (!_authCompleter.isCompleted) _authCompleter.complete(value);
      if (value) {
        if (widget.nextRoute != null) {
          // ignore: unawaited_futures
          Navigator.of(context).pushReplacementNamed(widget.nextRoute);
        } else if (widget.nextWidget == null) {
          Navigator.of(context).pop(true);
        } else {
          // ignore: unawaited_futures
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (con) {
              return widget.nextWidget;
            }),
          );
        }
      }
    } on Exception catch (e) {
      _authCompleter.completeError(e);
      print(e);
    }
  }

  Future _submit(String password) async {
    String encryptedPassword = Encryption.encryptPassword(password);
    if (password.isEmpty) {
      encryptedPassword = null;
      await showErrorDialog(context, 'كلمة سر فارغة!');
      setState(() {});
    } else if (User.instance.password == encryptedPassword) {
      encryptedPassword = null;
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
      await showErrorDialog(context, 'كلمة سر خاطئة!');
      passwordText.clear();
      setState(() {});
    }
    encryptedPassword = null;
  }
}
