import 'dart:io';

import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/mini_lists/colors_list.dart';
import 'package:churchdata/views/mini_lists/users_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

class EditArea extends StatefulWidget {
  final Area? area;

  EditArea({Key? key, this.area}) : super(key: key);

  @override
  _EditAreaState createState() => _EditAreaState();
}

class _EditAreaState extends State<EditArea> {
  late Area area;

  String? changedImage;
  bool deletePhoto = false;

  final GlobalKey<FormState> _formKey = GlobalKey();

  void addressChange(String value) {
    area.address = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              actions: <Widget>[
                IconButton(
                  icon: Builder(
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
                  ),
                  onPressed: () async {
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
                      area.hasPhoto = false;
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
                            androidUiSettings: AndroidUiSettings(
                              toolbarTitle: 'قص الصورة',
                              toolbarColor: Theme.of(context).primaryColor,
                              toolbarWidgetColor: Theme.of(context)
                                  .primaryTextTheme
                                  .headline6
                                  ?.color,
                              initAspectRatio: CropAspectRatioPreset.original,
                              lockAspectRatio: false,
                            )))
                        ?.path;
                    deletePhoto = false;
                    setState(() {});
                  },
                )
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
                      ? area.photo(cropToCircle: false)
                      : PhotoView(
                          imageProvider: FileImage(
                            File(changedImage!),
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'اسم المنطقة',
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      initialValue: area.name,
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
                    child: TextFormField(
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: 'العنوان',
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
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
                      List<GeoPoint> oldPoints = area.locationPoints.sublist(0);
                      var rslt = await navigator.currentState!.push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              actions: <Widget>[
                                IconButton(
                                  icon: Icon(Icons.done),
                                  onPressed: () =>
                                      navigator.currentState!.pop(true),
                                  tooltip: 'حفظ',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () =>
                                      navigator.currentState!.pop(false),
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
                        area.locationPoints = [];
                      }
                    },
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تاريخ أخر زيارة',
                        ),
                        child: area.lastVisit != null
                            ? Text(DateFormat('yyyy/M/d').format(
                                area.lastVisit!.toDate(),
                              ))
                            : null,
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
                        ),
                        child: area.fatherLastVisit != null
                            ? Text(DateFormat('yyyy/M/d').format(
                                area.fatherLastVisit!.toDate(),
                              ))
                            : null,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: area.color != Colors.transparent
                        ? ElevatedButton.styleFrom(primary: area.color)
                        : null,
                    onPressed: selectColor,
                    icon: Icon(Icons.color_lens),
                    label: Text('اللون'),
                  ),
                  Selector<User, bool>(
                    selector: (_, user) => user.manageUsers,
                    builder: (context, permission, _) {
                      if (permission) {
                        return ElevatedButton.icon(
                          style: area.color != Colors.transparent
                              ? ElevatedButton.styleFrom(primary: area.color)
                              : null,
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
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (area.id != 'null')
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
      scaffoldMessenger.currentState!.showSnackBar(
        SnackBar(
          content: Text('جار حذف المنطقة وما بداخلها من بيانات...'),
          duration: Duration(minutes: 20),
        ),
      );
      if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
        await area.ref.delete();
      } else {
        // ignore: unawaited_futures
        area.ref.delete();
      }
      navigator.currentState!.pop('deleted');
    }
  }

  @override
  void initState() {
    super.initState();
    area = (widget.area ?? Area.empty()).copyWith();
  }

  void nameChanged(String value) {
    area.name = value;
  }

  Future<void> save() async {
    try {
      if (_formKey.currentState!.validate()) {
        scaffoldMessenger.currentState!.showSnackBar(
          SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(minutes: 20),
          ),
        );
        if (area.locationPoints.isNotEmpty &&
            hashList(area.locationPoints) !=
                hashList(widget.area?.locationPoints)) {
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
                    onPressed: () => navigator.currentState!.pop(true),
                    child: Text('نعم'),
                  ),
                  TextButton(
                    onPressed: () => navigator.currentState!.pop(false),
                    child: Text('لا'),
                  )
                ],
              ),
            );
          } else {
            // oldArea['LocationConfirmed'] = true;
            area.locationConfirmed = false;
          }
        }
        bool update = area.id != 'null';
        if (!update)
          area.ref = FirebaseFirestore.instance.collection('Areas').doc();
        if (changedImage != null) {
          await FirebaseStorage.instance
              .ref()
              .child('AreasPhotos/${area.id}')
              .putFile(
                File(changedImage!),
              );
          area.hasPhoto = true;
        } else if (deletePhoto) {
          await FirebaseStorage.instance
              .ref()
              .child('AreasPhotos/${area.id}')
              .delete();
        }

        area.lastEdit = User.instance.uid;

        if (update &&
            await Connectivity().checkConnectivity() !=
                ConnectivityResult.none) {
          await area.update(old: widget.area?.getMap() ?? {});
        } else if (update) {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          area.update(old: widget.area?.getMap() ?? {});
        } else if (await Connectivity().checkConnectivity() !=
            ConnectivityResult.none) {
          await area.set();
        } else {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          area.set();
        }

        navigator.currentState!.pop(area.ref);
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'AreaP.save');
      await FirebaseCrashlytics.instance.setCustomKey('Area', area.id);
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

  void selectColor() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            onPressed: () {
              navigator.currentState!.pop();
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
            navigator.currentState!.pop();
            setState(() {
              area.color = color;
            });
          },
        ),
      ),
    );
  }

  void showUsers() async {
    area.allowedUsers = await navigator.currentState!.push(
          MaterialPageRoute(
            builder: (context) => FutureBuilder<List<User>>(
              future: User.getAllForUser().first.then((value) => value
                  .where((u) => area.allowedUsers.contains(u.uid))
                  .toList()),
              builder: (c, users) {
                if (!users.hasData)
                  return const Center(child: CircularProgressIndicator());

                return Provider<DataObjectListController<User>>(
                  create: (_) => DataObjectListController<User>(
                    itemBuilder: (current,
                            [void Function(User)? onLongPress,
                            void Function(User)? onTap,
                            Widget? trailing,
                            Widget? subtitle]) =>
                        DataObjectWidget(
                      current,
                      onTap: () => onTap!(current),
                      trailing: trailing,
                      showSubtitle: false,
                    ),
                    selectionMode: true,
                    selected: {for (var item in users.data!) item.id: item},
                    itemsStream: User.getAllForUser(),
                  ),
                  dispose: (context, c) => c.dispose(),
                  builder: (context, _) => Scaffold(
                    appBar: AppBar(
                      leading: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: navigator.currentState!.pop),
                      title: SearchField(
                        showSuffix: false,
                        searchStream: context
                            .read<DataObjectListController<User>>()
                            .searchQuery,
                        textStyle: Theme.of(context).primaryTextTheme.headline6,
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            navigator.currentState!.pop(context
                                .read<DataObjectListController<User>>()
                                .selectedLatest
                                ?.keys
                                .toList());
                          },
                          icon: const Icon(Icons.done),
                          tooltip: 'تم',
                        ),
                      ],
                    ),
                    body: const UsersList(
                      autoDisposeController: false,
                    ),
                  ),
                );
              },
            ),
          ),
        ) ??
        area.allowedUsers;
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: area.lastVisit?.toDate() ?? DateTime.now(),
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
    DateTime? picked = await showDatePicker(
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
