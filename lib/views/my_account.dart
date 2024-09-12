import 'dart:io';

import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../EncryptionKeys.dart';
import '../models/user.dart';
import '../utils/helpers.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  _MyAccountState createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  List<FocusNode> focuses = [FocusNode(), FocusNode(), FocusNode()];
  List<TextEditingController> textFields = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User>(
        initialData: User.instance,
        stream: User.instance.stream,
        builder: (context, data) {
          final user = data.data!;
          return NestedScrollView(
            headerSliverBuilder: (context, _) => <Widget>[
              SliverAppBar(
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () async {
                      final person = await user.getPerson();
                      if (person == null) {
                        scaffoldMessenger.currentState!.showSnackBar(
                          const SnackBar(
                            content: Text('لم يتم إيجاد بيانات للمستخدم'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      personTap(person);
                    },
                    tooltip: 'عرض بياناتي داخل البرنامج',
                  ),
                  IconButton(
                    onPressed: () async {
                      final source = await showDialog(
                        context: context,
                        builder: (context) => SimpleDialog(
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: () =>
                                  navigator.currentState!.pop(true),
                              icon: const Icon(Icons.camera),
                              label: const Text('التقاط صورة من الكاميرا'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  navigator.currentState!.pop(false),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('اختيار من المعرض'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  navigator.currentState!.pop('delete'),
                              icon: const Icon(Icons.delete),
                              label: const Text('حذف الصورة'),
                            ),
                          ],
                        ),
                      );
                      if (source == null) return;
                      if (source == 'delete') {
                        if (await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                content: const Text('هل تريد حذف الصورة؟'),
                                actions: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete),
                                    label: const Text('حذف'),
                                    onPressed: () =>
                                        navigator.currentState!.pop(true),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        navigator.currentState!.pop(false),
                                    child: const Text('تراجع'),
                                  ),
                                ],
                              ),
                            ) ??
                            false) {
                          scaffoldMessenger.currentState!.showSnackBar(
                            const SnackBar(
                              content: Text('جار التحميل'),
                              duration: Duration(minutes: 2),
                            ),
                          );
                          await firebaseFunctions
                              .httpsCallable('deleteImage')
                              .call();
                          user.reloadImage();
                          setState(() {});
                          scaffoldMessenger.currentState!.hideCurrentSnackBar();
                          scaffoldMessenger.currentState!.showSnackBar(
                            const SnackBar(
                              content: Text('تم بنجاح'),
                            ),
                          );
                        }
                        return;
                      }
                      if (source as bool &&
                          !(await Permission.camera.request()).isGranted)
                        return;
                      final selectedImage = await ImagePicker().pickImage(
                        source:
                            source ? ImageSource.camera : ImageSource.gallery,
                      );
                      if (selectedImage == null) return;
                      final finalImage = await ImageCropper().cropImage(
                        sourcePath: selectedImage.path,
                        uiSettings: [
                          AndroidUiSettings(
                            cropStyle: CropStyle.circle,
                            toolbarTitle: 'قص الصورة',
                            toolbarColor: Theme.of(context).primaryColor,
                            toolbarWidgetColor: Theme.of(context)
                                .primaryTextTheme
                                .titleLarge
                                ?.color,
                            initAspectRatio: CropAspectRatioPreset.original,
                            lockAspectRatio: false,
                          ),
                        ],
                      );
                      if (finalImage == null) return;
                      if (await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: const Text('هل تريد تغير الصورة؟'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      navigator.currentState!.pop(true),
                                  child: const Text('تغيير'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      navigator.currentState!.pop(false),
                                  child: const Text('تراجع'),
                                ),
                              ],
                            ),
                          ) ??
                          false) {
                        scaffoldMessenger.currentState!.showSnackBar(
                          const SnackBar(
                            content: Text('جار التحميل'),
                            duration: Duration(minutes: 2),
                          ),
                        );
                        await user.photoRef.putFile(File(finalImage.path));
                        user.reloadImage();
                        setState(() {});
                        scaffoldMessenger.currentState!.hideCurrentSnackBar();
                        scaffoldMessenger.currentState!.showSnackBar(
                          const SnackBar(
                            content: Text('تم بنجاح'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_camera),
                  ),
                ],
                expandedHeight: 250.0,
                pinned: true,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) => FlexibleSpaceBar(
                    title: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: constraints.biggest.height > kToolbarHeight * 1.7
                          ? 0
                          : 1,
                      child: Text(user.name),
                    ),
                    background: user.getPhoto(false, false),
                  ),
                ),
              ),
            ],
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: <Widget>[
                ListTile(
                  title: const Text('الاسم:'),
                  subtitle: Text(user.name),
                ),
                ListTile(
                  title: const Text('البريد الاكتروني:'),
                  subtitle: Text(user.email),
                ),
                ListTile(
                  title: Text(
                    'الصلاحيات:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (user.manageUsers)
                  const ListTile(
                    leading: Icon(
                      IconData(0xef3d, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إدارة المستخدمين'),
                  ),
                if (user.manageAllowedUsers)
                  const ListTile(
                    leading:
                        Icon(IconData(0xef3d, fontFamily: 'MaterialIconsR')),
                    title: Text('إدارة مستخدمين محددين'),
                  ),
                if (user.superAccess)
                  const ListTile(
                    leading: Icon(
                      IconData(0xef56, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('رؤية جميع البيانات'),
                  ),
                if (user.manageDeleted)
                  const ListTile(
                    leading: Icon(Icons.delete_outlined),
                    title: Text('استرجاع المحذوفات'),
                  ),
                if (user.write)
                  const ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('تعديل البيانات'),
                  ),
                if (user.exportAreas)
                  const ListTile(
                    leading: Icon(Icons.cloud_download),
                    title: Text('تصدير منطقة لملف إكسل'),
                  ),
                if (user.birthdayNotify)
                  const ListTile(
                    leading: Icon(
                      IconData(0xe7e9, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار أعياد الميلاد'),
                  ),
                if (user.confessionsNotify)
                  const ListTile(
                    leading: Icon(
                      IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار الاعتراف'),
                  ),
                if (user.tanawolNotify)
                  const ListTile(
                    leading: Icon(
                      IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار التناول'),
                  ),
                if (user.approveLocations)
                  const ListTile(
                    leading: Icon(
                      IconData(0xe8e8, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('التأكيد على المواقع'),
                  ),
                ElevatedButton.icon(
                  onPressed: () => changeName(user.name, user.uid!),
                  icon: const Icon(Icons.edit),
                  label: const Text('تغيير الاسم'),
                ),
                ElevatedButton.icon(
                  onPressed: changePass,
                  icon: const Icon(Icons.security),
                  label: const Text('تغيير كلمة السر'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> changeName(String oldName, String uid) async {
    final name = TextEditingController(text: oldName);
    if (await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              actions: <Widget>[
                TextButton.icon(
                  icon: const Icon(Icons.done),
                  onPressed: () => navigator.currentState!.pop(true),
                  label: const Text('تغيير'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.cancel),
                  onPressed: () => navigator.currentState!.pop(false),
                  label: const Text('الغاء الأمر'),
                ),
              ],
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                      ),
                      controller: name,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
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
      await firebaseFunctions
          .httpsCallable('changeUserName')
          .call({'newName': name.text, 'affectedUser': uid});
      if (mounted) setState(() {});
    }
  }

  Future<void> changePass() async {
    if (await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              actions: <Widget>[
                TextButton.icon(
                  icon: const Icon(Icons.done),
                  onPressed: () => navigator.currentState!.pop(true),
                  label: const Text('تغيير'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.cancel),
                  onPressed: () => navigator.currentState!.pop(false),
                  label: const Text('الغاء الأمر'),
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
                    decoration:
                        const InputDecoration(labelText: 'كلمة السر القديمة'),
                  ),
                  TextField(
                    controller: textFields[1],
                    obscureText: true,
                    autocorrect: false,
                    onSubmitted: (_) => focuses[2].requestFocus(),
                    textInputAction: TextInputAction.next,
                    focusNode: focuses[1],
                    decoration:
                        const InputDecoration(labelText: 'كلمة السر الجديدة'),
                  ),
                  TextField(
                    controller: textFields[2],
                    obscureText: true,
                    autocorrect: false,
                    focusNode: focuses[2],
                    decoration: const InputDecoration(
                      labelText: 'اعادة إدخال كلمة السر الجديدة',
                    ),
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
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('كلمة السر لا يمكن ان تكون فارغة!'),
          duration: Duration(seconds: 26),
        ),
      );
      return;
    }
    scaffoldMessenger.currentState!.showSnackBar(
      const SnackBar(
        content: Text('جار تحديث كلمة السر...'),
        duration: Duration(seconds: 26),
      ),
    );
    if (textFields[2].text == textFields[1].text &&
        textFields[0].text.isNotEmpty) {
      final User user = User.instance;
      if (user.password == Encryption.encryptPassword(textFields[0].text)) {
        try {
          await firebaseFunctions.httpsCallable('changePassword').call({
            'oldPassword': textFields[0].text,
            'newPassword': Encryption.encryptPassword(textFields[1].text),
          });
        } catch (err, stkTrace) {
          await FirebaseCrashlytics.instance
              .setCustomKey('LastErrorIn', 'MyAccount._submitPass');
          await FirebaseCrashlytics.instance.recordError(err, stkTrace);
          await showErrorDialog(context, 'حدث خطأ أثناء تحديث كلمة السر!');
          return;
        }
        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        scaffoldMessenger.currentState!.showSnackBar(
          const SnackBar(
            content: Text('تم تحديث كلمة السر بنجاح'),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {});
      } else {
        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        scaffoldMessenger.currentState!.showSnackBar(
          const SnackBar(
            content: Text('كلمة السر القديمة خاطئة'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
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
