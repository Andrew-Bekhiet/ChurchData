import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.io) 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../EncryptionKeys.dart';
import '../../Models/User.dart';
import '../../utils/Helpers.dart';

class MyAccount extends StatefulWidget {
  MyAccount({Key key}) : super(key: key);

  @override
  _MyAccountState createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  List<FocusNode> focuses = [FocusNode(), FocusNode(), FocusNode()];
  List<TextEditingController> textFields = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
      body: Consumer<User>(
        builder: (c, user, _) {
          return NestedScrollView(
            headerSliverBuilder: (context, _) => <Widget>[
              SliverAppBar(
                  actions: [
                    IconButton(
                      icon: Icon(Icons.info_outline),
                      onPressed: () async {
                        var person = await user.getPerson();
                        if (person == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('لم يتم إيجاد بيانات للمستخدم'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        personTap(await user.getPerson(), context);
                      },
                      tooltip: 'عرض بياناتي داخل البرنامج',
                    ),
                  ],
                  expandedHeight: 250.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(user.name),
                    background: user.getPhoto(false, false),
                  )),
            ],
            body: ListView(
              children: <Widget>[
                ListTile(
                  title: Text('الاسم:'),
                  subtitle: Text(user.name),
                ),
                ListTile(
                  title: Text('البريد الاكتروني:'),
                  subtitle: Text(user.email ?? ''),
                ),
                ListTile(
                  title: Text('الصلاحيات:',
                      style: Theme.of(context).textTheme.bodyText1),
                ),
                if (user.manageUsers == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xef3d, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إدارة المستخدمين'),
                  ),
                if (user.superAccess == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xef56, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('رؤية جميع البيانات'),
                  ),
                if (user.write == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xef56, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('رؤية جميع البيانات'),
                  ),
                if (user.exportAreas == true)
                  ListTile(
                    leading: Icon(Icons.cloud_download),
                    title: Text('تصدير منطقة لملف إكسل'),
                  ),
                if (user.birthdayNotify == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xe7e9, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار أعياد الميلاد'),
                  ),
                if (user.confessionsNotify == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار الاعتراف'),
                  ),
                if (user.tanawolNotify == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار التناول'),
                  ),
                if (user.approveLocations == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xe8e8, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('التأكيد على المواقع'),
                  ),
                ElevatedButton.icon(
                  onPressed: () => changeName(user.name, user.uid),
                  icon: Icon(Icons.edit),
                  label: Text('تغيير الاسم'),
                ),
                ElevatedButton.icon(
                  onPressed: () => changePass(),
                  icon: Icon(Icons.security),
                  label: Text('تغيير كلمة السر'),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void changeName(String oldName, String uid) async {
    var name = TextEditingController(text: oldName);
    if (await showDialog(
          context: context,
          builder: (context) {
            return DataDialog(
              actions: <Widget>[
                TextButton.icon(
                  icon: Icon(Icons.done),
                  onPressed: () => Navigator.of(context).pop(true),
                  label: Text('تغيير'),
                ),
                TextButton.icon(
                  icon: Icon(Icons.cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                  label: Text('الغاء الأمر'),
                ),
              ],
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      controller: name,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'هذا الحقل مطلوب';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ) ==
        true) {
      await FirebaseFunctions.instance
          .httpsCallable('changeUserName')
          .call({'newName': name.text, 'affectedUser': uid});
      if (mounted) setState(() {});
    }
  }

  void changePass() async {
    if (await showDialog(
          context: context,
          builder: (context) {
            return DataDialog(
              actions: <Widget>[
                TextButton.icon(
                  icon: Icon(Icons.done),
                  onPressed: () => Navigator.of(context).pop(true),
                  label: Text('تغيير'),
                ),
                TextButton.icon(
                  icon: Icon(Icons.cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                  label: Text('الغاء الأمر'),
                ),
              ],
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: textFields[0],
                    obscureText: true,
                    autocorrect: false,
                    onSubmitted: (_) => focuses[1].requestFocus(),
                    textInputAction: TextInputAction.next,
                    focusNode: focuses[0],
                    decoration: InputDecoration(labelText: 'كلمة السر القديمة'),
                  ),
                  TextField(
                    controller: textFields[1],
                    obscureText: true,
                    autocorrect: false,
                    onSubmitted: (_) => focuses[2].requestFocus(),
                    textInputAction: TextInputAction.next,
                    focusNode: focuses[1],
                    decoration: InputDecoration(labelText: 'كلمة السر الجديدة'),
                  ),
                  TextField(
                    controller: textFields[2],
                    obscureText: true,
                    autocorrect: false,
                    focusNode: focuses[2],
                    decoration: InputDecoration(
                        labelText: 'اعادة إدخال كلمة السر الجديدة'),
                  ),
                ],
              ),
            );
          },
        ) ==
        true) {
      await _submitPass();
      setState(() {});
    }
  }

  Future _submitPass() async {
    if (textFields[0].text == '' || textFields[1].text == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('كلمة السر لا يمكن ان تكون فارغة!'),
          duration: Duration(seconds: 26),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جار تحديث كلمة السر...'),
        duration: Duration(seconds: 26),
      ),
    );
    if (textFields[2].text == textFields[1].text &&
        textFields[0].text.isNotEmpty) {
      User user = context.read<User>();
      if (user.password == Encryption.encryptPassword(textFields[0].text)) {
        try {
          await FirebaseFunctions.instance
              .httpsCallable('changePassword')
              .call({
            'oldPassword': textFields[0].text,
            'newPassword': Encryption.encryptPassword(textFields[1].text)
          });
        } catch (err, stkTrace) {
          await FirebaseCrashlytics.instance
              .setCustomKey('LastErrorIn', 'MyAccount._submitPass');
          await FirebaseCrashlytics.instance.recordError(err, stkTrace);
          await showErrorDialog(context, 'حدث خطأ أثناء تحديث كلمة السر!');
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث كلمة السر بنجاح'),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('كلمة السر القديمة خاطئة'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('كلمتا السر غير متطابقتين!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    textFields[0].text = '';
    textFields[1].text = '';
    textFields[2].text = '';
  }
}
