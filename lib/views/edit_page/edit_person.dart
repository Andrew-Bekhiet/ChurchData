import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/mini_models.dart';
import 'package:churchdata/models/order_options.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/mini_lists/colors_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../mini_model_list.dart';

class EditPerson extends StatefulWidget {
  final Person? person;
  final bool userData;

  EditPerson({Key? key, this.person, this.userData = false}) : super(key: key);
  @override
  _EditPersonState createState() => _EditPersonState();
}

class _EditPersonState extends State<EditPerson> {
  Map<String, AsyncCache> cache = {
    'StudyYears': AsyncCache<JsonQuery>(Duration(minutes: 2)),
    'Colleges': AsyncCache<JsonQuery>(Duration(minutes: 2)),
    'Jobs': AsyncCache<JsonQuery>(Duration(minutes: 2)),
    'Fathers': AsyncCache<JsonQuery>(Duration(minutes: 2)),
    'Churches': AsyncCache<JsonQuery>(Duration(minutes: 2)),
    'ServingTypes': AsyncCache<JsonQuery>(Duration(minutes: 2)),
    'ServingAreaName': AsyncCache<String?>(Duration(minutes: 2)),
    'FamilyName': AsyncCache<String?>(Duration(minutes: 2)),
    'PersonStringType': AsyncCache<String?>(Duration(minutes: 2)),
    'StudyYear': AsyncCache<JsonDoc?>(Duration(minutes: 2)),
    'College': AsyncCache<JsonDoc?>(Duration(minutes: 2)),
  };

  String? changedImage;
  bool deletePhoto = false;

  GlobalKey<FormState> form = GlobalKey<FormState>();

  late Person person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              actions: <Widget>[
                IconButton(icon: Builder(
                  builder: (context) {
                    return Stack(
                      children: <Widget>[
                        Positioned(
                          left: 1.0,
                          top: 2.0,
                          child:
                              Icon(Icons.photo_camera, color: Colors.black54),
                        ),
                        Icon(Icons.photo_camera,
                            color: IconTheme.of(context).color),
                      ],
                    );
                  },
                ), onPressed: () async {
                  var source = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      actions: <Widget>[
                        TextButton.icon(
                          onPressed: () => navigator.currentState!.pop(true),
                          icon: Icon(Icons.camera),
                          label: Text('التقاط صورة من الكاميرا'),
                        ),
                        TextButton.icon(
                          onPressed: () => navigator.currentState!.pop(false),
                          icon: Icon(Icons.photo_library),
                          label: Text('اختيار من المعرض'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              navigator.currentState!.pop('delete'),
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
                          !(await Permission.storage.request()).isGranted) ||
                      !(await Permission.camera.request()).isGranted) return;
                  var selectedImage = await ImagePicker().getImage(
                      source:
                          source ? ImageSource.camera : ImageSource.gallery);
                  if (selectedImage == null) return;
                  changedImage = (await ImageCropper.cropImage(
                    sourcePath: selectedImage.path,
                    cropStyle: CropStyle.circle,
                    androidUiSettings: AndroidUiSettings(
                      toolbarTitle: 'قص الصورة',
                      toolbarColor: Theme.of(context).primaryColor,
                      toolbarWidgetColor:
                          Theme.of(context).primaryTextTheme.headline6?.color,
                      initAspectRatio: CropAspectRatioPreset.original,
                      lockAspectRatio: false,
                    ),
                  ))
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
                      ? person.photo(cropToCircle: false)
                      : Image.file(
                          File(changedImage!),
                        ),
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
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'الاسم',
                      ),
                      textInputAction: TextInputAction.next,
                      initialValue: person.name,
                      onChanged: _nameChanged,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
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
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      initialValue: person.phone,
                      onChanged: _phoneChanged,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
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
                                          onPressed: () => navigator
                                              .currentState!
                                              .pop(name.text),
                                          child: Text('حفظ'),
                                        ),
                                        TextButton(
                                          onPressed: () => navigator
                                              .currentState!
                                              .pop('delete'),
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
                                        navigator.currentState!.pop(name.text),
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
                                await _selectDate(
                                    'تاريخ الميلاد',
                                    person.birthDate?.toDate() ??
                                        DateTime.now()),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'تاريخ الميلاد',
                              ),
                              child: person.birthDate != null
                                  ? Text(DateFormat('yyyy/M/d').format(
                                      person.birthDate!.toDate(),
                                    ))
                                  : null,
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
                          child: FutureBuilder<JsonQuery>(
                            key: ValueKey('StudyYear'),
                            future: cache['StudyYears']!
                                    .fetch(StudyYear.getAllForUser)
                                as Future<JsonQuery>,
                            builder: (context, data) {
                              if (data.hasData) {
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('StudyYearDropDown'),
                                    isDense: true,
                                    value: person.studyYear?.path,
                                    items: data.data!.docs
                                        .map(
                                          (item) => DropdownMenuItem<String>(
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
                                      cache['StudyYear']!.invalidate();
                                      setState(() {});
                                      person.studyYear = value != null
                                          ? FirebaseFirestore.instance
                                              .doc(value)
                                          : null;
                                      FocusScope.of(context).nextFocus();
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'السنة الدراسية',
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
                            await navigator.currentState!
                                .pushNamed('Settings/StudyYears');
                            cache['StudyYears']!.invalidate();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  if (person.isStudent)
                    FutureBuilder<JsonDoc?>(
                      key: ValueKey('College'),
                      future: cache['College']!.fetch(() async =>
                              await person.studyYear?.get(dataSource))
                          as Future<JsonDoc?>,
                      builder: (context, data) {
                        if (data.hasData &&
                            (data.data?.data()?['IsCollegeYear'] ?? false))
                          return Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<JsonQuery>(
                                  future: cache['Colleges']!.fetch(
                                          () async => College.getAllForUser())
                                      as Future<JsonQuery>,
                                  builder: (context, data) {
                                    if (data.hasData) {
                                      return Container(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 4.0),
                                        child: DropdownButtonFormField<String>(
                                          key: ValueKey('StudyYearDropDown'),
                                          isDense: true,
                                          value: person.college?.path,
                                          items: data.data!.docs
                                              .map(
                                                (item) =>
                                                    DropdownMenuItem<String>(
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
                                  await navigator.currentState!
                                      .pushNamed('Settings/Colleges');
                                  cache['Colleges']!.invalidate();
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
                          child: FutureBuilder<JsonQuery>(
                            key: ValueKey('Job'),
                            future: cache['Jobs']!.fetch(Job.getAllForUser)
                                as Future<JsonQuery>,
                            builder: (context, data) {
                              if (data.hasData) {
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('JobDropDown'),
                                    isDense: true,
                                    value: person.job?.path,
                                    items: data.data!.docs
                                        .map(
                                          (item) => DropdownMenuItem<String>(
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
                                          ? FirebaseFirestore.instance
                                              .doc(value)
                                          : null;
                                      FocusScope.of(context).nextFocus();
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'الوظيفة',
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
                            await navigator.currentState!
                                .pushNamed('Settings/Jobs');
                            cache['Jobs']!.invalidate();
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
                              ),
                              child: FutureBuilder<String?>(
                                future: cache['PersonStringType']!
                                        .fetch(person.getStringType)
                                    as Future<String?>,
                                builder: (cote, ty) {
                                  if (ty.connectionState ==
                                          ConnectionState.done &&
                                      ty.hasData) {
                                    return Text(ty.data!);
                                  } else if (ty.connectionState ==
                                      ConnectionState.done)
                                    return Text('');
                                  else {
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
                          await navigator.currentState!
                              .pushNamed('Settings/PersonTypes');
                          cache['StudyYears']!.invalidate();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<JsonQuery>(
                          future: cache['Churches']!.fetch(Church.getAllForUser)
                              as Future<JsonQuery>,
                          builder: (context, data) {
                            if (data.hasData) {
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: DropdownButtonFormField<String>(
                                  isDense: true,
                                  value: person.church?.path,
                                  items: data.data!.docs
                                      .map(
                                        (item) => DropdownMenuItem<String>(
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
                          await navigator.currentState!
                              .pushNamed('Settings/Churches');
                          cache['Churches']!.invalidate();
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
                      ),
                      textInputAction: TextInputAction.next,
                      initialValue: person.meeting,
                      onChanged: _meetingChanged,
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
                        child: FutureBuilder<JsonQuery>(
                          future: cache['Fathers']!.fetch(Father.getAllForUser)
                              as Future<JsonQuery>,
                          builder: (context, data) {
                            if (data.hasData) {
                              return DropdownButtonFormField<String>(
                                isDense: true,
                                value: person.cFather?.path,
                                items: data.data!.docs
                                    .map(
                                      (item) => DropdownMenuItem<String>(
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
                          await navigator.currentState!
                              .pushNamed('Settings/Fathers');
                          cache['Fathers']!.invalidate();
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
                              ),
                              child: person.lastTanawol != null
                                  ? Text(DateFormat('yyyy/M/d').format(
                                      person.lastTanawol!.toDate(),
                                    ))
                                  : null,
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
                              ),
                              child: person.lastConfession != null
                                  ? Text(DateFormat('yyyy/M/d').format(
                                      person.lastConfession!.toDate(),
                                    ))
                                  : null,
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
                          ),
                          child: FutureBuilder<String?>(
                            future: cache['FamilyName']!
                                .fetch(person.getFamilyName) as Future<String?>,
                            builder: (con, data) {
                              if (data.hasData) {
                                return Text(data.data!);
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
                    StreamBuilder<JsonQuery>(
                      stream: FirebaseFirestore.instance
                          .collection('States')
                          .orderBy('Name')
                          .snapshots(),
                      builder: (context, data) {
                        if (data.hasData) {
                          return DropdownButtonFormField<String>(
                            isDense: true,
                            value: person.state?.path,
                            items: data.data!.docs
                                .map(
                                  (item) => DropdownMenuItem<String>(
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
                                ),
                                child: person.lastCall != null
                                    ? Text(DateFormat('yyyy/M/d').format(
                                        person.lastCall!.toDate(),
                                      ))
                                    : null,
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
                          onChanged: _isServantChanged,
                        ),
                      ],
                    ),
                  if (person.isServant || widget.userData)
                    Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<JsonQuery?>(
                            future: cache['ServingTypes']!
                                    .fetch(ServingType.getAllForUser)
                                as Future<JsonQuery?>,
                            builder: (conext, data) {
                              if (data.hasData) {
                                return DropdownButtonFormField<JsonRef?>(
                                  isDense: true,
                                  value: person.servingType,
                                  items: data.data!.docs
                                      .map(
                                        (item) => DropdownMenuItem<JsonRef?>(
                                          value: item.reference,
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
                                    person.servingType = value;
                                    FocusScope.of(context).nextFocus();
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'نوع الخدمة',
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
                            await navigator.currentState!
                                .pushNamed('Settings/ServingTypes');
                            cache['ServingTypes']!.invalidate();
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
                                ),
                                child: FutureBuilder<String?>(
                                  future: cache['ServingAreaName']!
                                          .fetch(person.getServingAreaName)
                                      as Future<String?>,
                                  builder: (contextt, dataServ) {
                                    if (dataServ.hasData) {
                                      return Text(dataServ.data!);
                                    } else if (dataServ.connectionState ==
                                        ConnectionState.waiting) {
                                      return LinearProgressIndicator();
                                    }
                                    return Text('');
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
                    style: person.color != Colors.transparent
                        ? ElevatedButton.styleFrom(primary: person.color)
                        : null,
                    onPressed: selectColor,
                    icon: Icon(Icons.color_lens),
                    label: Text('اللون'),
                  ),
                  SizedBox(height: 100),
                ].map((w) => Focus(child: w)).toList(),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (person.id != 'null' && !widget.userData)
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
  void initState() {
    super.initState();
    person = (widget.person ?? Person()).copyWith();
    person.setStreetIdFromFamily();
  }

  void selectColor() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            onPressed: () {
              navigator.currentState!.pop();
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
            navigator.currentState!.pop();
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
                  navigator.currentState!.pop(true);
                },
                child: Text('نعم'),
              ),
              TextButton(
                onPressed: () {
                  navigator.currentState!.pop();
                },
                child: Text('تراجع'),
              ),
            ],
          ),
        ) ==
        true) {
      if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
        await person.ref.delete();
      } else {
        // ignore: unawaited_futures
        person.ref.delete();
      }
      navigator.currentState!.pop('deleted');
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
      if (form.currentState!.validate() &&
          (person.familyId != null || widget.userData) &&
          person.type != null &&
          person.type!.isNotEmpty) {
        scaffoldMessenger.currentState!.showSnackBar(
          SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(minutes: 1),
          ),
        );
        if (widget.userData) {
          if (person.lastConfession == null ||
              person.lastTanawol == null ||
              ((person.lastTanawol!.millisecondsSinceEpoch + 2592000000) <=
                      DateTime.now().millisecondsSinceEpoch ||
                  (person.lastConfession!.millisecondsSinceEpoch +
                          5184000000) <=
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
        bool update = person.id != 'null';
        if (!update)
          person.ref = FirebaseFirestore.instance.collection('Persons').doc();

        if (changedImage != null) {
          await FirebaseStorage.instance
              .ref()
              .child('PersonsPhotos/${person.id}')
              .putFile(
                File(changedImage!),
              );
          person.hasPhoto = true;
        } else if (deletePhoto) {
          await FirebaseStorage.instance
              .ref()
              .child('PersonsPhotos/${person.id}')
              .delete();
        }

        person.lastEdit = User.instance.uid!;

        if (update &&
            await Connectivity().checkConnectivity() !=
                ConnectivityResult.none) {
          await person.update(old: widget.person?.getMap() ?? {});
        } else if (update) {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          person.update(old: widget.person?.getMap() ?? {});
        } else if (await Connectivity().checkConnectivity() !=
            ConnectivityResult.none) {
          await person.set();
        } else {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          person.set();
        }
        navigator.currentState!.pop(person.ref);
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
      scaffoldMessenger.currentState!;
      scaffoldMessenger.currentState!.showSnackBar(
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
              File(changedImage!),
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
      scaffoldMessenger.currentState!;
      navigator.currentState!.pop(person.ref);
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'PersonP.saveUserData');
      await FirebaseCrashlytics.instance.setCustomKey('Person', person.id);
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      scaffoldMessenger.currentState!;
      scaffoldMessenger.currentState!.showSnackBar(
        SnackBar(
          content: Text(
            err.toString(),
          ),
          duration: Duration(seconds: 7),
        ),
      );
    }
  }

  void _selectArea() async {
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(OrderOptions());

    final listOptions = DataObjectListController<Area>(
      tap: (value) {
        navigator.currentState!.pop();
        setState(() {
          person.servingAreaId =
              FirebaseFirestore.instance.collection('Areas').doc(value.id);
        });
        FocusScope.of(context).nextFocus();
      },
      itemsStream: _orderOptions
          .switchMap((value) => Area.getAllForUser(
              orderBy: value.orderBy, descending: !value.asc))
          .map((s) => s.docs.map(Area.fromQueryDoc).toList()),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                navigator.currentState!.pop();
                person.servingAreaId = await navigator.currentState!
                        .pushNamed('Data/EditArea') as JsonRef? ??
                    person.servingAreaId;
                cache['ServingAreaName']!.invalidate();
                setState(() {});
              },
              tooltip: 'إضافة منطقة جديدة',
              child: Icon(Icons.add_location),
            ),
            body: SizedBox(
              width: MediaQuery.of(context).size.width - 55,
              height: MediaQuery.of(context).size.height - 110,
              child: Column(
                children: [
                  SearchFilters(
                    1,
                    options: listOptions,
                    orderOptions: BehaviorSubject<OrderOptions>.seeded(
                      OrderOptions(),
                    ),
                    textStyle: Theme.of(context).textTheme.bodyText2,
                  ),
                  Expanded(
                    child: DataObjectList<Area>(
                      options: listOptions,
                      autoDisposeController: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    await _orderOptions.close();
  }

  Future<Timestamp> _selectDate(String helpText, DateTime initialDate) async {
    DateTime? picked = await showDatePicker(
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

  void _selectFamily() async {
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(OrderOptions());

    final listOptions = DataObjectListController<Family>(
      tap: (value) {
        navigator.currentState!.pop();
        setState(() {
          person.familyId =
              FirebaseFirestore.instance.collection('Families').doc(value.id);
        });
        FocusScope.of(context).nextFocus();
      },
      itemsStream: _orderOptions
          .switchMap((value) => Family.getAllForUser(
              orderBy: value.orderBy, descending: !value.asc))
          .map((s) => s.docs.map(Family.fromQueryDoc).toList()),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                navigator.currentState!.pop();
                person.familyId = await navigator.currentState!
                        .pushNamed('Data/EditFamily') as JsonRef? ??
                    person.familyId;
                cache['FamilyName']!.invalidate();
                setState(() {});
              },
              tooltip: 'إضافة عائلة جديدة',
              child: Icon(Icons.group_add),
            ),
            body: SizedBox(
              width: MediaQuery.of(context).size.width - 55,
              height: MediaQuery.of(context).size.height - 110,
              child: Column(
                children: [
                  SearchFilters(
                    1,
                    options: listOptions,
                    orderOptions: BehaviorSubject<OrderOptions>.seeded(
                      OrderOptions(),
                    ),
                    textStyle: Theme.of(context).textTheme.bodyText2,
                  ),
                  Expanded(
                    child: DataObjectList<Family>(
                      options: listOptions,
                      autoDisposeController: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    await _orderOptions.close();
  }

  void _selectType() {
    navigator.currentState!.push(
      MaterialPageRoute(
        builder: (context) {
          return MiniModelList<PersonType>(
            title: 'أنواع الأشخاص',
            collection: FirebaseFirestore.instance.collection('Types'),
            modify: (type) {
              navigator.currentState!.pop();
              cache['PersonStringType']!.invalidate();
              setState(() {
                person.type = type.id;
              });
              FocusScope.of(context).nextFocus();
            },
            transformer: PersonType.fromQueryDoc,
          );
        },
      ),
    );
  }
}
