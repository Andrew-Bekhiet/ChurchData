import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/mini_models.dart';
import 'package:churchdata/models/order_options.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/mini_lists/colors_list.dart';
import 'package:churchdata/views/lists.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class EditPerson extends StatefulWidget {
  final Person person;
  final bool userData;

  EditPerson({Key key, @required this.person, this.userData = false})
      : super(key: key);
  @override
  _EditPersonState createState() => _EditPersonState();
}

class _EditPersonState extends State<EditPerson> {
  Map<String, AsyncCache> cache = {
    'StudyYears': AsyncCache<QuerySnapshot>(Duration(minutes: 2)),
    'StudyYear': AsyncCache<DocumentSnapshot>(Duration(minutes: 2)),
    'Colleges': AsyncCache<QuerySnapshot>(Duration(minutes: 2)),
    'Jobs': AsyncCache<QuerySnapshot>(Duration(minutes: 2)),
    'Fathers': AsyncCache<QuerySnapshot>(Duration(minutes: 2)),
    'Churches': AsyncCache<QuerySnapshot>(Duration(minutes: 2)),
    'ServingAreaName': AsyncCache<String>(Duration(minutes: 2)),
    'FamilyName': AsyncCache<String>(Duration(minutes: 2)),
    'PersonStringType': AsyncCache<String>(Duration(minutes: 2)),
    'ServingTypes': AsyncCache<QuerySnapshot>(Duration(minutes: 2)),
  };

  Map<String, dynamic> old;
  String changedImage;
  bool deletePhoto = false;

  GlobalKey<FormState> form = GlobalKey<FormState>();

  Person person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              actions: <Widget>[
                IconButton(
                    icon: Builder(
                      builder: (context) => IconShadowWidget(
                        Icon(
                          Icons.photo_camera,
                          color: IconTheme.of(context).color,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      var source = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          actions: <Widget>[
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(true),
                              icon: Icon(Icons.camera),
                              label: Text('التقاط صورة من الكاميرا'),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(false),
                              icon: Icon(Icons.photo_library),
                              label: Text('اختيار من المعرض'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pop('delete'),
                              icon: Icon(Icons.delete),
                              label: Text('حذف الصورة'),
                            ),
                          ],
                        ),
                      );
                      if (source == null) return;
                      if (source == 'delete') {
                        changedImage = null;
                        deletePhoto = true;
                        person.hasPhoto = false;
                        setState(() {});
                        return;
                      }
                      if ((source &&
                              !(await Permission.storage.request())
                                  .isGranted) ||
                          !(await Permission.camera.request()).isGranted)
                        return;
                      var selectedImage = (await ImagePicker().getImage(
                          source: source
                              ? ImageSource.camera
                              : ImageSource.gallery));
                      if (selectedImage == null) return;
                      changedImage = (await ImageCropper.cropImage(
                              sourcePath: selectedImage.path,
                              cropStyle: CropStyle.circle,
                              androidUiSettings: AndroidUiSettings(
                                  toolbarTitle: 'قص الصورة',
                                  toolbarColor: Theme.of(context).primaryColor,
                                  toolbarWidgetColor: Theme.of(context)
                                      .primaryTextTheme
                                      .headline6
                                      .color,
                                  initAspectRatio:
                                      CropAspectRatioPreset.original,
                                  lockAspectRatio: false)))
                          ?.path;
                      deletePhoto = false;
                      setState(() {});
                    })
              ],
              backgroundColor:
                  person.color != Colors.transparent ? person.color : null,
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) => FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: constraints.biggest.height > kToolbarHeight * 1.7
                        ? 0
                        : 1,
                    child: Text(
                      person.name,
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  background: changedImage == null
                      ? person.photo
                      : Image.file(
                          File(changedImage),
                        ),
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
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    initialValue: person.name,
                    onChanged: _nameChanged,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    initialValue: person.phone,
                    onChanged: _phoneChanged,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    validator: (value) {
                      return null;
                    },
                  ),
                ),
                if (person.phones.isNotEmpty)
                  ...person.phones.entries.map(
                    (e) => Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: e.key,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.edit),
                            tooltip: 'تعديل اسم الهاتف',
                            onPressed: () async {
                              TextEditingController name =
                                  TextEditingController(text: e.key);
                              var rslt = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, name.text),
                                        child: Text('حفظ'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'delete'),
                                        child: Text('حذف'),
                                      ),
                                    ],
                                    title: Text('اسم الهاتف'),
                                    content: TextField(controller: name)),
                              );
                              if (rslt == 'delete') {
                                person.phones.remove(e.key);
                                setState(() {});
                              } else if (rslt != null) {
                                person.phones.remove(e.key);
                                person.phones[name.text] = e.value;
                                setState(() {});
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        initialValue: e.value,
                        onChanged: (s) => person.phones[e.key] = s,
                        validator: (value) {
                          return null;
                        },
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('اضافة رقم هاتف أخر'),
                  onPressed: () async {
                    TextEditingController name =
                        TextEditingController(text: '');
                    if (await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, name.text),
                                  child: Text('حفظ'),
                                ),
                              ],
                              title: Text('اسم الهاتف'),
                              content: TextField(controller: name)),
                        ) !=
                        null) setState(() => person.phones[name.text] = '');
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Flexible(
                      flex: 3,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: InkWell(
                          onTap: () async => person.birthDate =
                              await _selectDate('تاريخ الميلاد',
                                  person.birthDate?.toDate() ?? DateTime.now()),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'تاريخ الميلاد',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor),
                              ),
                            ),
                            child: person.birthDate != null
                                ? Text(DateFormat('yyyy/M/d').format(
                                    person.birthDate.toDate(),
                                  ))
                                : Text('(فارغ)'),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: TextButton.icon(
                        icon: Icon(Icons.close),
                        onPressed: () => setState(() {
                          person.birthDate = null;
                        }),
                        label: Text('حذف التاريخ'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('طالب؟'),
                    Switch(
                      value: person.isStudent,
                      onChanged: _isStudentChanged,
                    ),
                  ],
                ),
                if (person.isStudent)
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<QuerySnapshot>(
                          future: cache['StudyYears'].fetch(
                              () async => await StudyYear.getAllForUser()),
                          builder: (context, data) {
                            if (data.hasData) {
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: DropdownButtonFormField(
                                  isDense: true,
                                  value: person.studyYear?.path,
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
                                    cache['StudyYear'].invalidate();
                                    setState(() {});
                                    person.studyYear = value != null
                                        ? FirebaseFirestore.instance.doc(value)
                                        : null;
                                    FocusScope.of(context).nextFocus();
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'السنة الدراسية',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ),
                                ),
                              );
                            } else
                              return Container();
                          },
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('اضافة'),
                        onPressed: () async {
                          await Navigator.of(context)
                              .pushNamed('Settings/StudyYears');
                          cache['StudyYears'].invalidate();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                if (person.isStudent)
                  FutureBuilder<DocumentSnapshot>(
                    future: cache['StudyYear'].fetch(
                        () async => await person.studyYear?.get(dataSource)),
                    builder: (context, data) {
                      if (data.hasData && data.data.data()['IsCollegeYear'])
                        return Row(
                          children: [
                            Expanded(
                              child: FutureBuilder<QuerySnapshot>(
                                future: cache['Colleges'].fetch(
                                    () async => await College.getAllForUser()),
                                builder: (context, data) {
                                  if (data.hasData) {
                                    return Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 4.0),
                                      child: DropdownButtonFormField(
                                        isDense: true,
                                        value: widget.person.college?.path,
                                        items: data.data.docs
                                            .map(
                                              (item) => DropdownMenuItem(
                                                value: item.reference.path,
                                                child:
                                                    Text(item.data()['Name']),
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
                                          person.college = value != null
                                              ? FirebaseFirestore.instance
                                                  .doc(value)
                                              : null;
                                          FocusScope.of(context).nextFocus();
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'الكلية',
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .primaryColor),
                                          ),
                                        ),
                                      ),
                                    );
                                  } else
                                    return Container();
                                },
                              ),
                            ),
                            TextButton.icon(
                              icon: Icon(Icons.add),
                              label: Text('اضافة'),
                              onPressed: () async {
                                await Navigator.of(context)
                                    .pushNamed('Settings/Colleges');
                                cache['Colleges'].invalidate();
                                setState(() {});
                              },
                            ),
                          ],
                        );
                      return Container();
                    },
                  ),
                if (!person.isStudent)
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<QuerySnapshot>(
                          future: cache['Jobs']
                              .fetch(() async => await Job.getAllForUser()),
                          builder: (context, data) {
                            if (data.hasData) {
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: DropdownButtonFormField(
                                  isDense: true,
                                  value: person.job?.path,
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
                                    person.job = value != null
                                        ? FirebaseFirestore.instance.doc(value)
                                        : null;
                                    FocusScope.of(context).nextFocus();
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'الوظيفة',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ),
                                ),
                              );
                            } else
                              return Container();
                          },
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('اضافة'),
                        onPressed: () async {
                          await Navigator.of(context)
                              .pushNamed('Settings/Jobs');
                          cache['Jobs'].invalidate();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                if (!person.isStudent)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'تفاصيل الوظيفة',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      initialValue: person.jobDescription,
                      onChanged: _jobDescriptionChanged,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      validator: (value) {
                        return null;
                      },
                    ),
                  ),
                if (!person.isStudent)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'المؤهل',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      initialValue: person.qualification,
                      onChanged: _qualificationChanged,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      validator: (value) {
                        return null;
                      },
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: InkWell(
                          onTap: _selectType,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'نوع الفرد',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor),
                              ),
                            ),
                            child: FutureBuilder<String>(
                              future: cache['PersonStringType'].fetch(
                                  () async => await person.getStringType()),
                              builder: (cote, ty) {
                                if (ty.connectionState ==
                                    ConnectionState.done) {
                                  return Text(ty.data);
                                } else {
                                  return LinearProgressIndicator();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('اضافة'),
                      onPressed: () async {
                        await Navigator.of(context)
                            .pushNamed('Settings/PersonTypes');
                        cache['StudyYears'].invalidate();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<QuerySnapshot>(
                        future: cache['Churches']
                            .fetch(() async => await Church.getAllForUser()),
                        builder: (context, data) {
                          if (data.hasData) {
                            return Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: DropdownButtonFormField(
                                isDense: true,
                                value: person.church?.path,
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
                                  person.church = value != null
                                      ? FirebaseFirestore.instance.doc(value)
                                      : null;
                                  FocusScope.of(context).nextFocus();
                                },
                                decoration: InputDecoration(
                                  labelText: 'الكنيسة',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor),
                                  ),
                                ),
                              ),
                            );
                          } else
                            return Container();
                        },
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('اضافة'),
                      onPressed: () async {
                        await Navigator.of(context)
                            .pushNamed('Settings/Churches');
                        cache['Churches'].invalidate();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'الاجتماع المشارك به',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    initialValue: person.meeting,
                    onChanged: _meetingChanged,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    validator: (value) {
                      return null;
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<QuerySnapshot>(
                        future: cache['Fathers']
                            .fetch(() async => await Father.getAllForUser()),
                        builder: (context, data) {
                          if (data.hasData) {
                            return DropdownButtonFormField(
                              isDense: true,
                              value: person.cFather?.path,
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
                                person.cFather = value != null
                                    ? FirebaseFirestore.instance.doc(value)
                                    : null;
                                FocusScope.of(context).nextFocus();
                              },
                              decoration: InputDecoration(
                                labelText: 'أب الاعتراف',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                            );
                          } else
                            return Container();
                        },
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('اضافة'),
                      onPressed: () async {
                        await Navigator.of(context)
                            .pushNamed('Settings/Fathers');
                        cache['Fathers'].invalidate();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Flexible(
                      flex: 3,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: InkWell(
                          onTap: () async => person.lastTanawol =
                              await _selectDate(
                                  'تاريخ أخر تناول',
                                  person.lastTanawol?.toDate() ??
                                      DateTime.now()),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'تاريخ أخر تناول',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor),
                              ),
                            ),
                            child: person.lastTanawol != null
                                ? Text(DateFormat('yyyy/M/d').format(
                                    person.lastTanawol.toDate(),
                                  ))
                                : Text('(فارغ)'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Flexible(
                      flex: 3,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: InkWell(
                          onTap: () async =>
                              person.lastConfession = await _selectDate(
                            'تاريخ أخر اعتراف',
                            person.lastConfession?.toDate() ?? DateTime.now(),
                          ),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'تاريخ أخر اعتراف',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor),
                              ),
                            ),
                            child: person.lastConfession != null
                                ? Text(DateFormat('yyyy/M/d').format(
                                    person.lastConfession.toDate(),
                                  ))
                                : Text('(فارغ)'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!widget.userData)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: InkWell(
                      onTap: _selectFamily,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'داخل عائلة',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        child: FutureBuilder<String>(
                          future: cache['FamilyName']
                              .fetch(() async => await person.getFamilyName()),
                          builder: (con, data) {
                            if (data.connectionState == ConnectionState.done) {
                              return Text(data.data);
                            } else if (data.connectionState ==
                                ConnectionState.waiting) {
                              return LinearProgressIndicator();
                            } else {
                              return Text('');
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                if (!widget.userData)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('States')
                        .orderBy('Name')
                        .snapshots(),
                    builder: (context, data) {
                      if (data.hasData) {
                        return DropdownButtonFormField(
                          isDense: true,
                          value: person.state?.path,
                          items: data.data.docs
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.reference.path,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(item.data()['Name']),
                                      Container(
                                        height: 50,
                                        width: 50,
                                        color: Color(
                                          int.parse(
                                              "0xff${item.data()['Color']}"),
                                        ),
                                      )
                                    ],
                                  ),
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
                            person.state = value != null
                                ? FirebaseFirestore.instance.doc(value)
                                : null;
                            FocusScope.of(context).nextFocus();
                          },
                          decoration: InputDecoration(
                            labelText: 'الحالة',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),
                        );
                      } else
                        return Container();
                    },
                  ),
                if (!widget.userData)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Flexible(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: InkWell(
                            onTap: () async => person.lastCall =
                                await _selectDate(
                                    'تاريخ أخر مكالمة',
                                    person.lastCall?.toDate() ??
                                        DateTime.now()),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'تاريخ أخر مكالمة',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                              child: person.lastCall != null
                                  ? Text(DateFormat('yyyy/M/d').format(
                                      person.lastCall.toDate(),
                                    ))
                                  : Text('(فارغ)'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (!widget.userData)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'ملاحظات',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      initialValue: person.notes,
                      onChanged: _notesChanged,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      validator: (value) {
                        return null;
                      },
                    ),
                  ),
                if (!widget.userData)
                  Row(
                    children: <Widget>[
                      Text('خادم؟'),
                      Switch(
                        value: person.isServant,
                        onChanged: (value) => _isServantChanged(value),
                      ),
                    ],
                  ),
                if (person.isServant || widget.userData)
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<QuerySnapshot>(
                          future: cache['ServingTypes'].fetch(
                              () async => await ServingType.getAllForUser()),
                          builder: (conext, data) {
                            if (data.hasData) {
                              return DropdownButtonFormField(
                                isDense: true,
                                value: person.servingType?.path,
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
                                  person.servingType = value != null
                                      ? FirebaseFirestore.instance.doc(value)
                                      : null;
                                  FocusScope.of(context).nextFocus();
                                },
                                decoration: InputDecoration(
                                  labelText: 'نوع الخدمة',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor),
                                  ),
                                ),
                              );
                            } else
                              return Container();
                          },
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('اضافة'),
                        onPressed: () async {
                          await Navigator.of(context)
                              .pushNamed('Settings/ServingTypes');
                          cache['ServingTypes'].invalidate();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                if (person.isServant && !widget.userData)
                  Selector<User, bool>(
                    selector: (_, user) => user.superAccess,
                    builder: (context, permission, _) {
                      if (permission) {
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: InkWell(
                            onTap: _selectArea,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'منطقة الخدمة',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                              child: FutureBuilder<String>(
                                future: cache['ServingAreaName'].fetch(
                                    () async =>
                                        await person.getServingAreaName()),
                                builder: (contextt, dataServ) {
                                  if (dataServ.connectionState ==
                                      ConnectionState.done) {
                                    return Text(dataServ.data);
                                  } else {
                                    return LinearProgressIndicator();
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(primary: person.color),
                  onPressed: selectColor,
                  icon: Icon(Icons.color_lens),
                  label: Text('اللون'),
                ),
              ].map((w) => Focus(child: w)).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (person.id != '' && !widget.userData)
            FloatingActionButton(
              mini: true,
              tooltip: 'حذف',
              heroTag: null,
              onPressed: _delete,
              child: Icon(Icons.delete),
            ),
          FloatingActionButton(
            tooltip: 'حفظ',
            heroTag: null,
            onPressed: _save,
            child: Icon(Icons.save),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    person = widget.person ?? Person();
    old = !widget.userData ? person.getMap() : person.getUserRegisterationMap();
  }

  void selectColor() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                person.color = Colors.transparent;
              });
              FocusScope.of(context).nextFocus();
            },
            child: Text('بلا لون'),
          ),
        ],
        content: ColorsList(
          selectedColor: person.color,
          onSelect: (color) {
            Navigator.of(context).pop();
            setState(() {
              person.color = color;
            });
          },
        ),
      ),
    );
  }

  void _delete() async {
    if (await showDialog(
          context: context,
          builder: (context) => DataDialog(
            title: Text(person.name),
            content: Text('هل أنت متأكد من حذف ${person.name}؟'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                },
                child: Text('نعم'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('تراجع'),
              ),
            ],
          ),
        ) ==
        true) {
      if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
        if (person.hasPhoto) {
          await FirebaseStorage.instance
              .ref()
              .child('PersonPhotos/${person.id}')
              .delete();
        }
        await FirebaseFirestore.instance
            .collection('Person')
            .doc(person.id)
            .delete();
      } else {
        if (person.hasPhoto) {
          // ignore: unawaited_futures
          FirebaseStorage.instance
              .ref()
              .child('PersonPhotos/${person.id}')
              .delete();
        }
        // ignore: unawaited_futures
        FirebaseFirestore.instance.collection('Person').doc(person.id).delete();
      }
      Navigator.of(context).pop('deleted');
    }
  }

  void _isServantChanged(bool value) {
    setState(() {
      person.isServant = value;
      FocusScope.of(context).nextFocus();
    });
  }

  void _isStudentChanged(bool value) {
    setState(() {
      person.isStudent = value;
      FocusScope.of(context).nextFocus();
    });
  }

  void _jobDescriptionChanged(String value) {
    person.jobDescription = value;
  }

  void _meetingChanged(String value) {
    person.meeting = value;
  }

  void _nameChanged(String value) {
    person.name = value;
  }

  void _notesChanged(String value) {
    person.notes = value;
  }

  void _phoneChanged(String value) {
    person.phone = value;
  }

  void _qualificationChanged(String value) {
    person.qualification = value;
  }

  Future _save() async {
    try {
      if (form.currentState.validate() &&
          (person.familyId != null || widget.userData) &&
          person.type != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(minutes: 1),
          ),
        );
        if (widget.userData) {
          if (person.lastConfession == null ||
              person.lastTanawol == null ||
              ((person.lastTanawol.millisecondsSinceEpoch + 2592000000) <=
                      DateTime.now().millisecondsSinceEpoch ||
                  (person.lastConfession.millisecondsSinceEpoch + 5184000000) <=
                      DateTime.now().millisecondsSinceEpoch)) {
            await showDialog(
              context: context,
              builder: (context) => DataDialog(
                title: Text('بيانات غير كاملة'),
                content: Text(
                    'يرجى التأكد من ملئ هذه الحقول:\nتاريخ أخر تناول\nتاريخ أخر اعتراف\nوأن يكون أخر اعتراف منذ اقل من شهرين ,اخر تناول منذ أقل من شهر'),
              ),
            );
            return;
          }
          return _saveUserData();
        }
        bool update = person.id != '';
        if (person.id == '') {
          person.ref = FirebaseFirestore.instance.collection('Persons').doc();
        }
        if (changedImage != null) {
          await FirebaseStorage.instance
              .ref()
              .child('PersonsPhotos/${person.id}')
              .putFile(
                File(changedImage),
              );
          person.hasPhoto = true;
        } else if (deletePhoto) {
          await FirebaseStorage.instance
              .ref()
              .child('PersonsPhotos/${person.id}')
              .delete();
        }

        person.lastEdit = auth.FirebaseAuth.instance.currentUser.uid;

        if (update &&
            await Connectivity().checkConnectivity() !=
                ConnectivityResult.none) {
          await person.ref.update(
            person.getMap()..removeWhere((key, value) => old[key] == value),
          );
        } else if (update) {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          person.ref.update(
            person.getMap()..removeWhere((key, value) => old[key] == value),
          );
        } else if (await Connectivity().checkConnectivity() !=
            ConnectivityResult.none) {
          await person.ref.set(
            person.getMap(),
          );
        } else {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          person.ref.set(
            person.getMap(),
          );
        }
        Navigator.of(context).pop(person.ref);
      } else {
        await showDialog(
            context: context,
            builder: (context) => DataDialog(
                  title: Text('بيانات غير كاملة'),
                  content: Text(
                      'يرجى التأكد من ملئ هذه الحقول:\nالاسم\nالعائلة\nنوع الفرد'),
                ));
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'PersonP.save');
      await FirebaseCrashlytics.instance.setCustomKey('Person', person.id);
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
  }

  Future _saveUserData() async {
    try {
      if (person.id == '') {
        person.ref = FirebaseFirestore.instance.collection('Persons').doc();
      }
      if (changedImage != null) {
        await FirebaseStorage.instance
            .ref()
            .child('PersonsPhotos/${person.id}')
            .putFile(
              File(changedImage),
            );
        person.hasPhoto = true;
      } else if (deletePhoto) {
        await FirebaseStorage.instance
            .ref()
            .child('PersonsPhotos/${person.id}')
            .delete();
      }
      await FirebaseFunctions.instance.httpsCallable('registerUserData').call({
        'data': person.getUserRegisterationMap(),
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.of(context).pop(person.ref);
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'PersonP.saveUserData');
      await FirebaseCrashlytics.instance.setCustomKey('Person', person.id);
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
  }

  void _selectArea() {
    final BehaviorSubject<String> _searchStream =
        BehaviorSubject<String>.seeded('');
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(OrderOptions());

    showDialog(
      context: context,
      builder: (context) {
        var listOptions = DataObjectListOptions<Area>(
          searchQuery: _searchStream,
          tap: (value) {
            Navigator.of(context).pop();
            setState(() {
              person.servingAreaId =
                  FirebaseFirestore.instance.collection('Areas').doc(value.id);
            });
            FocusScope.of(context).nextFocus();
          },
          itemsStream: _orderOptions
              .switchMap((value) => Area.getAllForUser(
                  orderBy: value.orderBy, descending: !value.asc))
              .map((s) => s.docs.map(Area.fromDoc).toList()),
        );
        return Dialog(
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                Navigator.of(context).pop();
                person.servingAreaId = (await Navigator.of(context)
                        .pushNamed('Data/EditArea')) as DocumentReference ??
                    person.servingAreaId;
                cache['ServingAreaName'].invalidate();
                setState(() {});
              },
              tooltip: 'إضافة منطقة جديدة',
              child: Icon(Icons.add_location),
            ),
            body: Container(
              width: MediaQuery.of(context).size.width - 55,
              height: MediaQuery.of(context).size.height - 110,
              child: Column(
                children: [
                  SearchFilters(
                    1,
                    searchStream: _searchStream,
                    options: listOptions,
                    orderOptions: BehaviorSubject<OrderOptions>.seeded(
                      OrderOptions(),
                    ),
                    textStyle: Theme.of(context).textTheme.bodyText2,
                  ),
                  Expanded(
                    child: DataObjectList<Area>(
                      options: listOptions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Timestamp> _selectDate(String helpText, DateTime initialDate) async {
    DateTime picked = await showDatePicker(
      helpText: helpText,
      locale: Locale('ar', 'EG'),
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != initialDate) {
      setState(() {});
      FocusScope.of(context).nextFocus();
      return Timestamp.fromDate(picked);
    }
    return Timestamp.fromDate(initialDate);
  }

  void _selectFamily() {
    final BehaviorSubject<String> _searchStream =
        BehaviorSubject<String>.seeded('');
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(OrderOptions());

    showDialog(
      context: context,
      builder: (context) {
        var listOptions = DataObjectListOptions<Family>(
          searchQuery: _searchStream,
          tap: (value) {
            Navigator.of(context).pop();
            setState(() {
              person.familyId = FirebaseFirestore.instance
                  .collection('Families')
                  .doc(value.id);
            });
            FocusScope.of(context).nextFocus();
          },
          itemsStream: _orderOptions
              .switchMap((value) => Family.getAllForUser(
                  orderBy: value.orderBy, descending: !value.asc))
              .map((s) => s.docs.map(Family.fromDoc).toList()),
        );
        return Dialog(
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                Navigator.of(context).pop();
                person.familyId = (await Navigator.of(context)
                        .pushNamed('Data/EditFamily')) as DocumentReference ??
                    person.familyId;
                cache['FamilyName'].invalidate();
                setState(() {});
              },
              tooltip: 'إضافة عائلة جديدة',
              child: Icon(Icons.group_add),
            ),
            body: Container(
              width: MediaQuery.of(context).size.width - 55,
              height: MediaQuery.of(context).size.height - 110,
              child: Column(
                children: [
                  SearchFilters(
                    1,
                    searchStream: _searchStream,
                    options: listOptions,
                    orderOptions: BehaviorSubject<OrderOptions>.seeded(
                      OrderOptions(),
                    ),
                    textStyle: Theme.of(context).textTheme.bodyText2,
                  ),
                  Expanded(
                    child: DataObjectList<Family>(
                      options: listOptions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectType() {
    showDialog(
        context: context,
        builder: (context) {
          return DataDialog(
            content: TypesList(
              list: FirebaseFirestore.instance
                  .collection('Types')
                  .get(dataSource),
              tap: (type, _) {
                Navigator.of(context).pop();
                cache['PersonStringType'].invalidate();
                setState(() {
                  person.type = type?.id;
                });
                FocusScope.of(context).nextFocus();
              },
            ),
          );
        });
  }
}
