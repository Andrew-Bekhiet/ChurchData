import 'dart:async';

import 'package:churchdata/models/invitation.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';

class EditInvitation extends StatefulWidget {
  final Invitation invitation;

  EditInvitation({Key? key, required this.invitation}) : super(key: key);

  @override
  _EditInvitationState createState() => _EditInvitationState();
}

class _EditInvitationState extends State<EditInvitation> {
  Json old = {};

  GlobalKey<FormState> form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.delete_forever),
                  tooltip: 'حذف الدعوة',
                  onPressed: deleteInvitation,
                ),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) => FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: constraints.biggest.height > kToolbarHeight * 1.7
                        ? 0
                        : 1,
                    child: Text(widget.invitation.name,
                        style: TextStyle(
                          fontSize: 16.0,
                        )),
                  ),
                  background: Icon(Icons.link),
                ),
              ),
            ),
          ];
        },
        body: Form(
          key: form,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'عنوان الدعوة',
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      initialValue: widget.invitation.name,
                      onChanged: nameChanged,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'هذا الحقل مطلوب';
                        }
                        return null;
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Focus(
                      child: GestureDetector(
                        onTap: () async => widget.invitation.expiryDate =
                            await _selectDateTime(
                          'تاريخ الانتهاء',
                          widget.invitation.expiryDate.toDate(),
                        ),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'تاريخ انتهاء الدعوة',
                          ),
                          child: Text(DateFormat('h:m a yyyy/M/d', 'ar-EG')
                              .format(widget.invitation.expiryDate.toDate())),
                        ),
                      ),
                    ),
                  ),
                  if (User.instance.manageUsers)
                    ListTile(
                      trailing: Checkbox(
                        value: widget.invitation.permissions?['manageUsers'] ??
                            false,
                        onChanged: (v) => setState(() =>
                            widget.invitation.permissions?['manageUsers'] = v),
                      ),
                      leading: Icon(
                          const IconData(0xef3d, fontFamily: 'MaterialIconsR')),
                      title: Text('إدارة المستخدمين'),
                      onTap: () => setState(() =>
                          widget.invitation.permissions?['manageUsers'] =
                              !(widget.invitation.permissions?['manageUsers'] ??
                                  false)),
                    ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget
                              .invitation.permissions?['manageAllowedUsers'] ??
                          false,
                      onChanged: (v) => setState(() => widget
                          .invitation.permissions?['manageAllowedUsers'] = v),
                    ),
                    leading: Icon(
                        const IconData(0xef3d, fontFamily: 'MaterialIconsR')),
                    title: Text('إدارة مستخدمين محددين'),
                    onTap: () => setState(() => widget.invitation
                        .permissions?['manageAllowedUsers'] = !(widget
                            .invitation.permissions?['manageAllowedUsers'] ??
                        false)),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.invitation.permissions?['superAccess'] ??
                          false,
                      onChanged: (v) => setState(() =>
                          widget.invitation.permissions?['superAccess'] = v),
                    ),
                    leading: Icon(
                      const IconData(0xef56, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('رؤية جميع البيانات'),
                    onTap: () => setState(() =>
                        widget.invitation.permissions?['superAccess'] =
                            !(widget.invitation.permissions?['superAccess'] ??
                                false)),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.invitation.permissions?['manageDeleted'] ??
                          false,
                      onChanged: (v) => setState(() =>
                          widget.invitation.permissions?['manageDeleted'] = v),
                    ),
                    leading: Icon(Icons.delete_outline),
                    title: Text('استرجاع المحذوفات'),
                    onTap: () => setState(() =>
                        widget.invitation.permissions?['manageDeleted'] =
                            !(widget.invitation.permissions?['manageDeleted'] ??
                                false)),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.invitation.permissions?['write'] ?? false,
                      onChanged: (v) => setState(
                          () => widget.invitation.permissions?['write'] = v),
                    ),
                    leading: Icon(Icons.edit),
                    title: Text('تعديل البيانات'),
                    onTap: () => setState(() => widget
                            .invitation.permissions?['write'] =
                        !(widget.invitation.permissions?['write'] ?? false)),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.invitation.permissions?['exportAreas'] ??
                          false,
                      onChanged: (v) => setState(() =>
                          widget.invitation.permissions?['exportAreas'] = v),
                    ),
                    leading: Icon(Icons.cloud_download),
                    title: Text('تصدير منطقة لملف إكسل'),
                    onTap: () => setState(() =>
                        widget.invitation.permissions?['exportAreas'] =
                            !(widget.invitation.permissions?['exportAreas'] ??
                                false)),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.invitation.permissions?['birthdayNotify'] ??
                          false,
                      onChanged: (v) => setState(() =>
                          widget.invitation.permissions?['birthdayNotify'] = v),
                    ),
                    leading: Icon(
                      const IconData(0xe7e9, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار أعياد الميلاد'),
                    onTap: () => setState(() => widget
                            .invitation.permissions?['birthdayNotify'] =
                        !(widget.invitation.permissions?['birthdayNotify'] ??
                            false)),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value:
                          widget.invitation.permissions?['confessionsNotify'] ??
                              false,
                      onChanged: (v) => setState(() => widget
                          .invitation.permissions?['confessionsNotify'] = v),
                    ),
                    leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار الاعتراف'),
                    onTap: () => setState(
                      () => widget.invitation
                          .permissions?['confessionsNotify'] = !(widget
                              .invitation.permissions?['confessionsNotify'] ??
                          false),
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.invitation.permissions?['tanawolNotify'] ??
                          false,
                      onChanged: (v) => setState(() =>
                          widget.invitation.permissions?['tanawolNotify'] = v),
                    ),
                    leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار التناول'),
                    onTap: () => setState(
                      () => widget.invitation.permissions?['tanawolNotify'] =
                          !(widget.invitation.permissions?['tanawolNotify'] ??
                              false),
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value:
                          widget.invitation.permissions?['approveLocations'] ??
                              false,
                      onChanged: (v) => setState(() => widget
                          .invitation.permissions?['approveLocations'] = v),
                    ),
                    title: Text('التأكيد على المواقع'),
                    onTap: () => setState(() => widget
                            .invitation.permissions?['approveLocations'] =
                        !(widget.invitation.permissions?['approveLocations'] ??
                            false)),
                    leading: Icon(
                      const IconData(0xe8e8, fontFamily: 'MaterialIconsR'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'حفظ',
        heroTag: 'Save',
        onPressed: save,
        child: Icon(Icons.save),
      ),
    );
  }

  void deleteInvitation() {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        content: Text('هل تريد حذف هذه الدعوة؟'),
        actions: <Widget>[
          TextButton(
            style: Theme.of(innerContext).textButtonTheme.style?.copyWith(
                foregroundColor:
                    MaterialStateProperty.resolveWith((state) => Colors.red)),
            onPressed: () async {
              try {
                scaffoldMessenger.currentState!.showSnackBar(
                  SnackBar(
                    content: LinearProgressIndicator(),
                    duration: Duration(seconds: 15),
                  ),
                );
                Navigator.of(innerContext).pop();
                await widget.invitation.ref.delete();
                scaffoldMessenger.currentState!.hideCurrentSnackBar();
                navigator.currentState!.pop('deleted');
                scaffoldMessenger.currentState!.showSnackBar(
                  SnackBar(
                    content: Text('تم بنجاح'),
                    duration: Duration(seconds: 15),
                  ),
                );
              } catch (err, stkTrace) {
                await FirebaseCrashlytics.instance
                    .setCustomKey('LastErrorIn', 'UserPState.delete');
                await FirebaseCrashlytics.instance.recordError(err, stkTrace);
                scaffoldMessenger.currentState!.hideCurrentSnackBar();
                scaffoldMessenger.currentState!.showSnackBar(
                  SnackBar(
                    content: Text(
                      err.toString(),
                    ),
                    duration: Duration(seconds: 7),
                  ),
                );
              }
            },
            child: Text('حذف'),
          ),
          TextButton(
            onPressed: () {
              navigator.currentState!.pop();
            },
            child: Text('تراجع'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    old = widget.invitation.getMap();
    super.initState();
  }

  void nameChanged(String value) {
    widget.invitation.name = value;
  }

  Future save() async {
    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      await showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(content: Text('لا يوجد اتصال انترنت')));
      return;
    }
    try {
      if (form.currentState!.validate() &&
          widget.invitation.expiryDate.toDate().difference(DateTime.now()) >=
              Duration(hours: 24)) {
        scaffoldMessenger.currentState!.showSnackBar(SnackBar(
          content: Text('جار الحفظ...'),
          duration: Duration(seconds: 15),
        ));
        if (widget.invitation.id == '') {
          widget.invitation.ref =
              FirebaseFirestore.instance.collection('Invitations').doc();
          widget.invitation.generatedBy = User.instance.uid!;
          await widget.invitation.ref.set({
            ...widget.invitation.getMap(),
            'GeneratedOn': FieldValue.serverTimestamp()
          });
        } else {
          var update = widget.invitation.getMap()
            ..removeWhere((key, value) => old[key] == value);
          if (update.isNotEmpty) {
            await widget.invitation.update(old: update);
          }
        }
        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        navigator.currentState!.pop(widget.invitation.ref);
        scaffoldMessenger.currentState!.showSnackBar(
          SnackBar(
            content: Text('تم الحفظ بنجاح'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(
                'يرجى ملء تاريخ انتهاء الدعوة على أن يكون على الأقل بعد 24 ساعة'),
          ),
        );
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'UserPState.save');
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(SnackBar(
        content: Text(err.toString()),
        duration: Duration(seconds: 7),
      ));
    }
  }

  Future<Timestamp> _selectDateTime(
      String helpText, DateTime initialDate) async {
    var picked = await showDatePicker(
        helpText: helpText,
        locale: Locale('ar', 'EG'),
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 14)));
    if (picked != null && picked != initialDate) {
      var time = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(initialDate));
      if (time != null)
        picked = picked.add(Duration(hours: time.hour, minutes: time.minute));
      setState(() {});
      return Timestamp.fromDate(picked);
    }
    return Timestamp.fromDate(initialDate);
  }
}
