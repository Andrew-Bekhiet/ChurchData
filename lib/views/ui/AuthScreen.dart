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
  bool isNew = false;
  bool forcePassMode = false;
  bool showLoading = false;
  bool requestUserName = false;
  TextEditingController pAs = TextEditingController();
  FocusNode pasFocus = FocusNode();
  TextEditingController userName = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Selector<User, Tuple2<String, String>>(
      selector: (_, user) => Tuple2(user.name, user.password),
      builder: (context, user, child) {
        try {
          if (showLoading) {
            return Scaffold(
              key: authKey,
              resizeToAvoidBottomInset: !kIsWeb,
              appBar: AppBar(
                leading: Container(),
                title: Text('جار التحقق...'),
              ),
              body: Loading(),
            );
          }
          if (canCheckBio &&
              user.item1 != null &&
              user.item2 != null &&
              !forcePassMode) {
            // if (!mounted) {
            //   return widget.nextWidget;
            // }
            return FutureBuilder<bool>(
              future: LocalAuthentication()
                  .authenticateWithBiometrics(
                      localizedReason: 'برجاء التحقق للمتابعة',
                      stickyAuth: true,
                      useErrorDialogs: false)
                  .catchError(
                (err) {
                  return false;
                },
              ),
              builder: (context, data) {
                if (data.hasData && data.data == true) {
                  if (widget.nextRoute != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context)
                          .pushReplacementNamed(widget.nextRoute);
                    });
                  } else if (widget.nextWidget == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pop();
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (con) {
                          return widget.nextWidget;
                        }),
                      );
                    });
                  }
                  return Scaffold(
                    key: authKey,
                    resizeToAvoidBottomInset: !kIsWeb,
                  );
                } else if (data.hasData && data.data == false) {
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
                              setState(() {});
                            },
                          ),
                          OutlinedButton.icon(
                            icon: Icon(Icons.security),
                            label: Text('إدخال كلمة السر'),
                            onPressed: () {
                              setState(() {
                                forcePassMode = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
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
                            setState(() {});
                          },
                        ),
                        OutlinedButton.icon(
                          icon: Icon(Icons.security),
                          label: Text('إدخال كلمة السر'),
                          onPressed: () {
                            setState(() {
                              forcePassMode = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        } on PlatformException catch (err, stkTrace) {
          FirebaseCrashlytics.instance
              .setCustomKey('LastErrorIn', 'AuthScreen.build');
          FirebaseCrashlytics.instance.recordError(err, stkTrace);
        }
        return Scaffold(
          key: authKey,
          resizeToAvoidBottomInset: !kIsWeb,
          appBar: AppBar(
            leading: Container(),
            title: Text(isNew
                ? 'اقتربت من الانتهاء'
                : 'إدخال كلمة المرور للدخول للبرنامج'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (isNew)
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
                      controller: userName,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'هذا الحقل مطلوب';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) => pasFocus.requestFocus(),
                    ),
                  if (isNew)
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
                    controller: pAs,
                    focusNode: pasFocus,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                    onFieldSubmitted: (v) =>
                        _submit(pAs.text, userName.text, isNew),
                  ),
                  ElevatedButton(
                    onPressed: () => _submit(pAs.text, userName.text, isNew),
                    child: Text('تسجيل الدخول'),
                  ),
                  if (!isNew && canCheckBio)
                    OutlinedButton.icon(
                      icon: Icon(Icons.fingerprint),
                      label: Text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
                      onPressed: () {
                        setState(() {
                          forcePassMode = false;
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
    if (nameRequired && (userName == null || userName == '')) {
      setState(() => showLoading = false);
      await showErrorDialog(context, 'اسم المستخدم لا يمكن ان يكون فارغا');
    }
    setState(() => showLoading = true);
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
        setState(() {
          showLoading = false;
        });
      }
    } else if (password.isNotEmpty && pwd == encryptedPassword) {
      encryptedPassword = null;
      pwd = null;
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
      setState(() => showLoading = false);
      await showErrorDialog(context, 'كلمة سر خاطئة أو فارغة!');
    }
    encryptedPassword = null;
    pwd = null;
  }
}
