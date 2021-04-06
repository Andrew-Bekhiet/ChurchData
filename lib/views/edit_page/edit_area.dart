import 'dart:io';

import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/views/mini_lists.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:firebase_storage/firebase_storage.dart' hide ListOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class EditArea extends StatefulWidget {
  final Area area;

  EditArea({Key key, this.area}) : super(key: key);

  @override
  _EditAreaState createState() => _EditAreaState();
}

class _EditAreaState extends State<EditArea> {
  Area area;

  Map<String, dynamic> oldArea;

  String changedImage;
  bool deletePhoto = false;

  final GlobalKey<FormState> _formKey = GlobalKey();

  void addressChange(String value) {
    area.address = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
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
                          onPressed: () => Navigator.of(context).pop('delete'),
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
                    area.hasPhoto = false;
                    setState(() {});
                    return;
                  }
                  if ((source &&
                          !(await Permission.storage.request()).isGranted) ||
                      !(await Permission.camera.request()).isGranted) return;
                  var selectedImage = (await ImagePicker().getImage(
                      source:
                          source ? ImageSource.camera : ImageSource.gallery));
                  if (selectedImage == null) return;
                  changedImage = (await ImageCropper.cropImage(
                          sourcePath: selectedImage.path,
                          androidUiSettings: AndroidUiSettings(
                              toolbarTitle: 'قص الصورة',
                              toolbarColor: Theme.of(context).primaryColor,
                              toolbarWidgetColor: Theme.of(context)
                                  .primaryTextTheme
                                  .headline6
                                  .color,
                              initAspectRatio: CropAspectRatioPreset.original,
                              lockAspectRatio: false)))
                      ?.path;
                  deletePhoto = false;
                  setState(() {});
                })
              ],
              backgroundColor:
                  area.color != Colors.transparent ? area.color : null,
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
                      area.name,
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  background: changedImage == null || deletePhoto
                      ? area.photo(false)
                      : PhotoView(
                          imageProvider: FileImage(
                            File(changedImage),
                          ),
                        ),
                ),
              ),
            ),
          ];
        },
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: ListView(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'اسم المنطقة',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    initialValue: area.name,
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
                  child: TextFormField(
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: 'العنوان',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    initialValue: area.address,
                    onChanged: addressChange,
                    validator: (value) {
                      return null;
                    },
                  ),
                ),
                ElevatedButton.icon(
                    icon: Icon(
                      const IconData(0xe568, fontFamily: 'MaterialIconsR'),
                    ),
                    label: Text('تعديل مكان المنطقة على الخريطة'),
                    onPressed: () async {
                      List<GeoPoint> oldPoints =
                          area.locationPoints?.sublist(0);
                      var rslt = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            resizeToAvoidBottomInset: !kIsWeb,
                            appBar: AppBar(
                              actions: <Widget>[
                                IconButton(
                                  icon: Icon(Icons.done),
                                  onPressed: () => Navigator.pop(context, true),
                                  tooltip: 'حفظ',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  tooltip: 'حذف التحديد',
                                )
                              ],
                              title:
                                  Text('تعديل مكان ${area.name} على الخريطة'),
                            ),
                            body: area.getMapView(
                                editMode: true, useGPSIfNull: true),
                          ),
                        ),
                      );
                      if (rslt == null) {
                        area.locationPoints = oldPoints;
                      } else if (rslt == false) {
                        area.locationPoints = null;
                      }
                    }),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'تاريخ أخر زيارة',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      child: Text(DateFormat('yyyy/M/d').format(
                        area.lastVisit.toDate(),
                      )),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () => _selectDate2(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'تاريخ أخر زيارة (للأب الكاهن)',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      child: area.fatherLastVisit != null
                          ? Text(DateFormat('yyyy/M/d').format(
                              area.fatherLastVisit.toDate(),
                            ))
                          : Text(DateFormat('yyyy/M/d').format(
                              DateTime(DateTime.now().year,
                                  DateTime.now().month, DateTime.now().day),
                            )),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(primary: area.color),
                  onPressed: selectColor,
                  icon: Icon(Icons.color_lens),
                  label: Text('اللون'),
                ),
                Selector<User, bool>(
                  selector: (_, user) => user.manageUsers,
                  builder: (context, permission, _) {
                    if (permission) {
                      return ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(primary: area.color),
                        icon: Icon(Icons.visibility),
                        onPressed: showUsers,
                        label: Text(
                            'المستخدمين المسموح لهم برؤية المنطقة وما بداخلها',
                            softWrap: false,
                            textScaleFactor: 0.95,
                            overflow: TextOverflow.fade),
                      );
                    }
                    return Container();
                  },
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
          if (widget.area.id != 'null')
            FloatingActionButton(
              mini: true,
              tooltip: 'حذف',
              heroTag: null,
              onPressed: delete,
              child: Icon(Icons.delete),
            ),
          FloatingActionButton(
            tooltip: 'حفظ',
            heroTag: null,
            onPressed: save,
            child: Icon(Icons.save),
          ),
        ],
      ),
    );
  }

  void delete() async {
    if (await showDialog(
          context: context,
          builder: (context) => DataDialog(
            title: Text(area.name),
            content: Text(
                'هل أنت متأكد من حذف ${area.name} وكل ما بها من شوارع وعائلات وأشخاص؟'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جار حذف المنطقة وما بداخلها من بيانات...'),
          duration: Duration(minutes: 20),
        ),
      );
      if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
        if (area.hasPhoto) {
          await FirebaseStorage.instance
              .ref()
              .child('AreasPhotos/${area.id}')
              .delete();
        }
        await area.ref.delete();
      } else {
        if (area.hasPhoto) {
          // ignore: unawaited_futures
          FirebaseStorage.instance
              .ref()
              .child('AreasPhotos/${area.id}')
              .delete();
        }
        // ignore: unawaited_futures
        area.ref.delete();
      }
      Navigator.of(context).pop('deleted');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    area ??= widget.area ?? Area.empty();
    oldArea ??= area.getMap();
  }

  void nameChanged(String value) {
    area.name = value;
  }

  Future<void> save() async {
    try {
      if (_formKey.currentState.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(minutes: 20),
          ),
        );
        if (area.getMap()['Location'] != null &&
            hashList(area.getMap()['Location']) !=
                hashList(oldArea['Location'])) {
          if (User.instance.approveLocations) {
            area.locationConfirmed = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => DataDialog(
                title: Text('هل أنت متأكد من موقع المنطقة على الخريطة؟'),
                content: Text(
                    'إن لم تكن متأكدًا سيتم إعلام المستخدمين الأخرين ليأكدوا عليه'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('نعم'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('لا'),
                  )
                ],
              ),
            );
          } else {
            oldArea['LocationConfirmed'] = true;
            area.locationConfirmed = false;
          }
        }
        bool update = widget.area.id != 'null';
        if (!update)
          widget.area.ref =
              FirebaseFirestore.instance.collection('Areas').doc();
        if (changedImage != null) {
          await FirebaseStorage.instance
              .ref()
              .child('AreasPhotos/${area.id}')
              .putFile(
                File(changedImage),
              );
          area.hasPhoto = true;
        } else if (deletePhoto) {
          await FirebaseStorage.instance
              .ref()
              .child('AreasPhotos/${area.id}')
              .delete();
        }

        area.lastEdit = auth.FirebaseAuth.instance.currentUser.uid;

        if (update &&
            await Connectivity().checkConnectivity() !=
                ConnectivityResult.none) {
          await area.ref.update(
            area.getMap()..removeWhere((key, value) => oldArea[key] == value),
          );
        } else if (update) {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          area.ref.update(
            area.getMap()..removeWhere((key, value) => oldArea[key] == value),
          );
        } else if (await Connectivity().checkConnectivity() !=
            ConnectivityResult.none) {
          await area.ref.set(
            area.getMap(),
          );
        } else {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          area.ref.set(
            area.getMap(),
          );
        }

        Navigator.of(context).pop(area.ref);
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'AreaP.save');
      await FirebaseCrashlytics.instance.setCustomKey('Area', area.id);
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

  void selectColor() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                area.color = Colors.transparent;
              });
              FocusScope.of(context).nextFocus();
            },
            child: Text('بلا لون'),
          ),
        ],
        content: ColorsList(
          selectedColor: area.color,
          onSelect: (color) {
            Navigator.of(context).pop();
            setState(() {
              area.color = color;
            });
          },
        ),
      ),
    );
  }

  void showUsers() async {
    BehaviorSubject<String> searchStream = BehaviorSubject<String>.seeded('');
    area.allowedUsers = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return FutureBuilder<List<User>>(
                future: User.getAllUsers(area.allowedUsers),
                builder: (c, users) => users.hasData
                    ? MultiProvider(
                        providers: [
                          Provider(
                            create: (_) => DataObjectListOptions<User>(
                              itemBuilder: (current,
                                      {onLongPress,
                                      onTap,
                                      subtitle,
                                      trailing}) =>
                                  DataObjectWidget<User>(
                                current,
                                onTap: () => onTap(current),
                                trailing: trailing,
                                showSubtitle: false,
                              ),
                              searchQuery: searchStream,
                              selectionMode: true,
                              itemsStream:
                                  Stream.fromFuture(User.getAllUsersLive()).map(
                                      (s) => s.docs.map(User.fromDoc).toList()),
                              selected: {
                                for (var item in users.data) item.uid: item
                              },
                            ),
                          )
                        ],
                        builder: (context, child) => Scaffold(
                          appBar: AppBar(
                            title: Text('اختيار مستخدمين'),
                            actions: [
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(
                                      context,
                                      context
                                          .read<DataObjectListOptions<User>>()
                                          .selectedLatest
                                          .values
                                          ?.map((f) => f.uid)
                                          ?.toList());
                                },
                                icon: Icon(Icons.done),
                                tooltip: 'تم',
                              )
                            ],
                          ),
                          body: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SearchField(
                                  searchStream: searchStream,
                                  textStyle:
                                      Theme.of(context).textTheme.bodyText2),
                              Expanded(
                                child: UsersList(),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ) ??
        area.allowedUsers;
  }

  Future _selectDate(BuildContext context) async {
    DateTime picked = await showDatePicker(
      context: context,
      initialDate: area.lastVisit.toDate(),
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && Timestamp.fromDate(picked) != area.lastVisit)
      setState(() {
        area.lastVisit = Timestamp.fromDate(picked);
        FocusScope.of(context).nextFocus();
      });
  }

  Future _selectDate2(BuildContext context) async {
    DateTime picked = await showDatePicker(
      context: context,
      initialDate: area.fatherLastVisit?.toDate() ?? DateTime.now(),
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && Timestamp.fromDate(picked) != area.fatherLastVisit)
      setState(() {
        area.fatherLastVisit = Timestamp.fromDate(picked);
        FocusScope.of(context).nextFocus();
      });
  }
}
