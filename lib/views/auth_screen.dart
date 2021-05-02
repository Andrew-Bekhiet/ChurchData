import 'dart:async';

import 'package:churchdata/EncryptionKeys.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/helpers.dart';
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
  final TextEditingController _passwordText = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  Completer<bool> _authCompleter = Completer<bool>();

  bool obscurePassword = true;
  bool ignoreBiometrics = false;

  String _getAssetImage() {
    final riseDay = getRiseDay();
    if (DateTime.now()
            .isAfter(riseDay.subtract(Duration(days: 7, seconds: 20))) &&
        DateTime.now().isBefore(riseDay.subtract(Duration(days: 1)))) {
      return 'assets/holyweek.jpeg';
    } else if (DateTime.now()
            .isBefore(riseDay.add(Duration(days: 50, seconds: 20))) &&
        DateTime.now().isAfter(riseDay.subtract(Duration(days: 1)))) {
      return 'assets/risen.jpg';
    }
    return 'assets/Logo2.png';
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _localAuthentication.canCheckBiometrics,
      builder: (context, future) {
        bool canCheckBio = false;
        if (future.hasData) canCheckBio = future.data;
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
              Image.asset(_getAssetImage(), fit: BoxFit.scaleDown),
              Divider(),
              TextFormField(
                decoration: InputDecoration(
                  suffix: IconButton(
                    icon: Icon(obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    tooltip:
                        obscurePassword ? 'اظهار كلمة السر' : 'اخفاء كلمة السر',
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                  labelText: 'كلمة السر',
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                textInputAction: TextInputAction.done,
                obscureText: obscurePassword,
                autocorrect: false,
                autofocus: future.hasData && !future.data,
                controller: _passwordText,
                focusNode: _passwordFocus,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                },
                onFieldSubmitted: (v) => _submit(v),
              ),
              ElevatedButton(
                onPressed: () => _submit(_passwordText.text),
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
      bool value = await _localAuthentication.authenticate(
          localizedReason: 'برجاء التحقق للمتابعة',
          biometricOnly: true,
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
      _passwordText.clear();
      setState(() {});
    }
    encryptedPassword = null;
  }
}
