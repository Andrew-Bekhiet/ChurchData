import 'package:churchdata/EncryptionKeys.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:churchdata/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:churchdata/main.dart';
import 'package:provider/provider.dart';

class UserRegisteration extends StatefulWidget {
  const UserRegisteration({Key key}) : super(key: key);
  @override
  State createState() => _UserRegisterationState();
}

class _UserRegisterationState extends State<UserRegisteration> {
  final TextEditingController _linkController = TextEditingController();

  final TextEditingController _userName = TextEditingController();
  final TextEditingController _passwordText = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  final TextEditingController _passwordText2 = TextEditingController();
  final FocusNode _passwordFocus2 = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey();

  bool obscurePassword1 = true;
  bool obscurePassword2 = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<User>(
      builder: (context, user, _) {
        if (user.approved) {
          return Scaffold(
            resizeToAvoidBottomInset: !kIsWeb,
            appBar: AppBar(
              leading: Container(),
              title: Text('تسجيل حساب جديد'),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: <Widget>[
                  Image.asset('assets/Logo.png', fit: BoxFit.scaleDown),
                  Divider(),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      helperText:
                          'يرجى ادخال اسمك الذي سيظهر للمستخدمين في البرنامج',
                      labelText: 'اسم المستخدم',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    controller: _userName..text = user.name,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'لا يمكن أن يكون اسمك فارغًا';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintMaxLines: 3,
                      suffix: IconButton(
                        icon: Icon(obscurePassword1
                            ? Icons.visibility
                            : Icons.visibility_off),
                        tooltip: obscurePassword1
                            ? 'اظهار كلمة السر'
                            : 'اخفاء كلمة السر',
                        onPressed: () => setState(
                            () => obscurePassword1 = !obscurePassword1),
                      ),
                      helperText:
                          'يرجى إدخال كلمة سر لحسابك الجديد في البرنامج',
                      labelText: 'كلمة السر',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    obscureText: obscurePassword1,
                    autocorrect: false,
                    autofocus: true,
                    controller: _passwordText,
                    focusNode: _passwordFocus,
                    validator: (value) {
                      if (value.isEmpty || value.characters.length < 9) {
                        return 'يرجى كتابة كلمة سر قوية تتكون من أكثر من 10 أحرف وتحتوي على رموز وأرقام';
                      }
                      return null;
                    },
                    onFieldSubmitted: (v) => _passwordFocus2.requestFocus(),
                  ),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintMaxLines: 3,
                      suffix: IconButton(
                        icon: Icon(obscurePassword2
                            ? Icons.visibility
                            : Icons.visibility_off),
                        tooltip: obscurePassword2
                            ? 'اظهار كلمة السر'
                            : 'اخفاء كلمة السر',
                        onPressed: () => setState(
                            () => obscurePassword2 = !obscurePassword2),
                      ),
                      labelText: 'تأكيد كلمة السر',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    obscureText: obscurePassword2,
                    autocorrect: false,
                    autofocus: true,
                    controller: _passwordText2,
                    focusNode: _passwordFocus2,
                    validator: (value) {
                      if (value.isEmpty || value != _passwordText2.text) {
                        return 'كلمتا السر غير متطابقتين';
                      }
                      return null;
                    },
                    onFieldSubmitted: (v) => _submit(v, _userName.text),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        _submit(_passwordText.text, _userName.text),
                    child: Text('انشاء حساب جديد'),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          resizeToAvoidBottomInset: !kIsWeb,
          appBar: AppBar(
            title: Text('في انتظار الموافقة'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.exit_to_app),
                tooltip: 'تسجيل الخروج',
                onPressed: () async {
                  var user = User.instance;
                  await Hive.box('Settings').put('FCM_Token_Registered', false);
                  // ignore: unawaited_futures
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        return App();
                      },
                    ),
                  );
                  await user.signOut();
                },
              )
            ],
          ),
          body: Column(
            children: [
              Center(
                child: Text(
                  'يجب ان يتم الموافقة على دخولك للبيانات '
                  'من قبل أحد '
                  'المشرفين أو المسؤلين في البرنامج',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text('أو'),
              Text(
                'يمكنك ادخال لينك الدعوة هنا',
                style: Theme.of(context).textTheme.bodyText1,
              ),
              Container(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  hintMaxLines: 3,
                  hintText:
                      'مثال: https://churchdata.page.link/ZaBc1KnFgh6K3YO92',
                  helperText: 'يمكنك أن تسأل أحد المشرفين ليعطيك لينك دعوة',
                  labelText: 'لينك الدعوة',
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.done,
                controller: _linkController,
                onFieldSubmitted: _registerUser,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'برجاء ادخال لينك الدخول لتفعيل حسابك';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () => _registerUser(_linkController.text),
                child: Text('تفعيل الحساب باللينك'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (kIsWeb ||
                      await Navigator.of(context).pushNamed('EditUserData')
                          is DocumentReference) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم الحفظ بنجاح'),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.edit),
                label: Text('تعديل بياناتي'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit(String password, String _userName) async {
    if (!_formKey.currentState.validate()) return;
    // ignore: unawaited_futures
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('جار انشاء حساب جديد'),
            LinearProgressIndicator(),
          ],
        ),
      ),
    );
    try {
      await FirebaseFunctions.instance.httpsCallable('registerAccount').call({
        'name': _userName,
        'password': Encryption.encryptPassword(password),
        'fcmToken': await FirebaseMessaging.instance.getToken(),
      });
      await Hive.box('Settings').put('FCM_Token_Registered', true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'UserRgisteration._submit');
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      await showErrorDialog(context, 'حدث خطأ أثناء تسجيل الحساب!');
      setState(() {});
    }
  }

  void _registerUser(String registerationLink) async {
    // ignore: unawaited_futures
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: FutureBuilder<HttpsCallableResult>(
          future: FirebaseFunctions.instance
              .httpsCallable('registerWithLink')
              .call({'link': registerationLink}),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                  (snapshot.error as FirebaseFunctionsException).message);
            } else if (snapshot.connectionState == ConnectionState.done) {
              Navigator.pop(context);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircularProgressIndicator(),
                Text('جار تفعيل الحساب...'),
              ],
            );
          },
        ),
      ),
    );
  }
}
