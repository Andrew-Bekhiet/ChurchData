import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:churchdata/models/invitation.dart';

import '../../models/mini_models.dart';
import '../../models/user.dart';

class EditInvitation extends StatefulWidget {
  final Invitation invitation;
  EditInvitation({Key key, @required this.invitation}) : super(key: key);
  @override
  _EditInvitationState createState() => _EditInvitationState();
}

class _EditInvitationState extends State<EditInvitation> {
  List<FocusNode> foci = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode()
  ];
  Map<String, dynamic> old;

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
            padding: EdgeInsets.all(5),
            child: ListView(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                        labelText: 'عنوان الدعوة',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        )),
                    focusNode: foci[0],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => foci[1].requestFocus(),
                    initialValue: widget.invitation.name,
                    onChanged: nameChanged,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Focus(
                    focusNode: foci[6],
                    child: GestureDetector(
                      onTap: () async => widget.invitation.expiryDate =
                          await _selectDateTime(
                              'تاريخ الانتهاء',
                              widget.invitation.expiryDate?.toDate() ??
                                  DateTime.now()),
                      child: InputDecorator(
                        decoration: InputDecoration(
                            labelText: 'تاريخ انتهاء الدعوة',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor),
                            )),
                        child: widget.invitation.expiryDate != null
                            ? Text(DateFormat('h:m a yyyy/M/d', 'ar-EG')
                                .format(widget.invitation.expiryDate.toDate()))
                            : Text('(فارغ)'),
                      ),
                    ),
                  ),
                ),
                FutureBuilder<QuerySnapshot>(
                  future: StudyYear.getAllForUser(),
                  builder: (conext, data) {
                    if (data.hasData) {
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: DropdownButtonFormField(
                          validator: (v) {
                            return null;
                          },
                          value: widget.invitation
                                      .permissions['servingStudyYear'] !=
                                  null
                              ? 'StudyYears/' +
                                  widget.invitation
                                      .permissions['servingStudyYear']
                              : null,
                          items: data.data.docs
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.reference.path,
                                  child: Text(item.data()['Name']),
                                ),
                              )
                              .toList()
                                ..insert(
                                  0,
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(''),
                                  ),
                                ),
                          onChanged: (value) {
                            setState(() {});
                            widget.invitation.permissions['servingStudyYear'] =
                                value != null
                                    ? value.split('/')[1].toString()
                                    : null;
                            foci[2].requestFocus();
                          },
                          decoration: InputDecoration(
                              labelText: 'صف الخدمة',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor),
                              )),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: DropdownButtonFormField(
                    validator: (v) {
                      return null;
                    },
                    value: widget.invitation.permissions['servingStudyGender'],
                    items: [true, false]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item ? 'بنين' : 'بنات'),
                          ),
                        )
                        .toList()
                          ..insert(
                              0,
                              DropdownMenuItem(
                                value: null,
                                child: Text(''),
                              )),
                    onChanged: (value) {
                      setState(() {});
                      widget.invitation.permissions['servingStudyGender'] =
                          value;
                      foci[2].requestFocus();
                    },
                    decoration: InputDecoration(
                        labelText: 'نوع الخدمة',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        )),
                  ),
                ),
                if (User.instance.manageUsers)
                  ListTile(
                    trailing: Checkbox(
                      value:
                          widget.invitation.permissions['manageUsers'] ?? false,
                      onChanged: (v) => setState(() =>
                          widget.invitation.permissions['manageUsers'] = v),
                    ),
                    leading: Icon(
                        const IconData(0xef3d, fontFamily: 'MaterialIconsR')),
                    title: Text('إدارة المستخدمين'),
                    onTap: () => setState(() =>
                        widget.invitation.permissions['manageUsers'] =
                            !(widget.invitation.permissions['manageUsers'] ??
                                false)),
                  ),
                ListTile(
                  trailing: Checkbox(
                    value:
                        widget.invitation.permissions['manageAllowedUsers'] ??
                            false,
                    onChanged: (v) => setState(() => widget
                        .invitation.permissions['manageAllowedUsers'] = v),
                  ),
                  leading: Icon(
                      const IconData(0xef3d, fontFamily: 'MaterialIconsR')),
                  title: Text('إدارة مستخدمين محددين'),
                  onTap: () => setState(() => widget
                          .invitation.permissions['manageAllowedUsers'] =
                      !(widget.invitation.permissions['manageAllowedUsers'] ??
                          false)),
                ),
                ListTile(
                  trailing: Checkbox(
                    value:
                        widget.invitation.permissions['superAccess'] ?? false,
                    onChanged: (v) => setState(
                        () => widget.invitation.permissions['superAccess'] = v),
                  ),
                  leading: Icon(
                      const IconData(0xef56, fontFamily: 'MaterialIconsR')),
                  title: Text('رؤية جميع البيانات'),
                  onTap: () => setState(() => widget
                          .invitation.permissions['superAccess'] =
                      !(widget.invitation.permissions['superAccess'] ?? false)),
                ),
                ListTile(
                  trailing: Checkbox(
                    value: widget.invitation.permissions['secretary'] ?? false,
                    onChanged: (v) => setState(
                        () => widget.invitation.permissions['secretary'] = v),
                  ),
                  leading: Icon(Icons.shield),
                  title: Text('تسجيل حضور الخدام'),
                  onTap: () => setState(() => widget
                          .invitation.permissions['secretary'] =
                      !(widget.invitation.permissions['secretary'] ?? false)),
                ),
                ListTile(
                  trailing: Checkbox(
                    value: widget.invitation.permissions['write'] ?? false,
                    onChanged: (v) => setState(
                        () => widget.invitation.permissions['write'] = v),
                  ),
                  leading: Icon(Icons.edit),
                  title: Text('تعديل البيانات'),
                  onTap: () => setState(() =>
                      widget.invitation.permissions['write'] =
                          !(widget.invitation.permissions['write'] ?? false)),
                ),
                ListTile(
                  trailing: Checkbox(
                    value:
                        widget.invitation.permissions['exportClasses'] ?? false,
                    onChanged: (v) => setState(() =>
                        widget.invitation.permissions['exportClasses'] = v),
                  ),
                  leading: Icon(Icons.cloud_download),
                  title: Text('تصدير فصل لملف إكسل'),
                  onTap: () => setState(() =>
                      widget.invitation.permissions['exportClasses'] =
                          !(widget.invitation.permissions['exportClasses'] ??
                              false)),
                ),
                ListTile(
                  trailing: Checkbox(
                    value: widget.invitation.permissions['birthdayNotify'] ??
                        false,
                    onChanged: (v) => setState(() =>
                        widget.invitation.permissions['birthdayNotify'] = v),
                  ),
                  leading: Icon(
                      const IconData(0xe7e9, fontFamily: 'MaterialIconsR')),
                  title: Text('إشعار أعياد الميلاد'),
                  onTap: () => setState(() =>
                      widget.invitation.permissions['birthdayNotify'] =
                          !(widget.invitation.permissions['birthdayNotify'] ??
                              false)),
                ),
                ListTile(
                  trailing: Checkbox(
                    value: widget.invitation.permissions['confessionsNotify'] ??
                        false,
                    onChanged: (v) => setState(() =>
                        widget.invitation.permissions['confessionsNotify'] = v),
                  ),
                  leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR')),
                  title: Text('إشعار  الاعتراف'),
                  onTap: () => setState(() => widget
                          .invitation.permissions['confessionsNotify'] =
                      !(widget.invitation.permissions['confessionsNotify'] ??
                          false)),
                ),
                ListTile(
                  trailing: Checkbox(
                    value:
                        widget.invitation.permissions['tanawolNotify'] ?? false,
                    onChanged: (v) => setState(() =>
                        widget.invitation.permissions['tanawolNotify'] = v),
                  ),
                  leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR')),
                  title: Text('إشعار التناول'),
                  onTap: () => setState(() =>
                      widget.invitation.permissions['tanawolNotify'] =
                          !(widget.invitation.permissions['tanawolNotify'] ??
                              false)),
                ),
                ListTile(
                  trailing: Checkbox(
                    value:
                        widget.invitation.permissions['kodasNotify'] ?? false,
                    onChanged: (v) => setState(
                        () => widget.invitation.permissions['kodasNotify'] = v),
                  ),
                  leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR')),
                  title: Text('إشعار القداس'),
                  onTap: () => setState(() => widget
                          .invitation.permissions['kodasNotify'] =
                      !(widget.invitation.permissions['kodasNotify'] ?? false)),
                ),
                ListTile(
                  trailing: Checkbox(
                    value:
                        widget.invitation.permissions['meetingNotify'] ?? false,
                    onChanged: (v) => setState(() =>
                        widget.invitation.permissions['meetingNotify'] = v),
                  ),
                  leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR')),
                  title: Text('إشعار حضور الاجتماع'),
                  onTap: () => setState(() =>
                      widget.invitation.permissions['meetingNotify'] =
                          !(widget.invitation.permissions['meetingNotify'] ??
                              false)),
                ),
              ],
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
            style: Theme.of(innerContext).textButtonTheme.style.copyWith(
                foregroundColor:
                    MaterialStateProperty.resolveWith((state) => Colors.red)),
            onPressed: () async {
              try {
                ScaffoldMessenger.of(innerContext).showSnackBar(
                  SnackBar(
                    content: LinearProgressIndicator(),
                    duration: Duration(seconds: 15),
                  ),
                );
                Navigator.of(innerContext).pop();
                await widget.invitation.ref.delete();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.of(context).pop('deleted');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم بنجاح'),
                    duration: Duration(seconds: 15),
                  ),
                );
              } catch (err, stkTrace) {
                await FirebaseCrashlytics.instance
                    .setCustomKey('LastErrorIn', 'UserPState.delete');
                await FirebaseCrashlytics.instance.recordError(err, stkTrace);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
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
              Navigator.of(context).pop();
            },
            child: Text('تراجع'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    old = widget.invitation?.getMap();
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
      if (form.currentState.validate() &&
          widget.invitation.expiryDate != null &&
          widget.invitation.expiryDate.toDate().difference(DateTime.now()) >=
              Duration(hours: 24)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('جار الحفظ...'),
          duration: Duration(seconds: 15),
        ));
        if (widget.invitation.id == '') {
          widget.invitation.id =
              FirebaseFirestore.instance.collection('Invitations').doc().id;
          widget.invitation.generatedBy = User.instance.uid;
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.of(context).pop(widget.invitation.ref);
        ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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