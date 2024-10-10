import 'dart:io';

import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata/views/form_widgets/color_field.dart';
import 'package:churchdata/views/mini_lists/users_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:derived_colors/derived_colors.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class EditArea extends StatefulWidget {
  final Area? area;

  const EditArea({super.key, this.area});

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
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor:
                  area.color != Colors.transparent ? area.color : null,
              foregroundColor: (area.color == Colors.transparent
                      ? Theme.of(context).colorScheme.primary
                      : area.color)
                  .findInvert(),
              actions: <Widget>[
                IconButton(
                  icon: Builder(
                    builder: (context) {
                      return Stack(
                        children: <Widget>[
                          const Positioned(
                            left: 1.0,
                            top: 2.0,
                            child:
                                Icon(Icons.photo_camera, color: Colors.black54),
                          ),
                          Icon(
                            Icons.photo_camera,
                            color: IconTheme.of(context).color,
                          ),
                        ],
                      );
                    },
                  ),
                  onPressed: () async {
                    final source = await showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        children: <Widget>[
                          TextButton.icon(
                            onPressed: () => navigator.currentState!.pop(true),
                            icon: const Icon(Icons.camera),
                            label: const Text('التقاط صورة من الكاميرا'),
                          ),
                          TextButton.icon(
                            onPressed: () => navigator.currentState!.pop(false),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('اختيار من المعرض'),
                          ),
                          if (changedImage != null || area.hasPhoto)
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
                      changedImage = null;
                      deletePhoto = true;
                      area.hasPhoto = false;
                      setState(() {});
                      return;
                    }
                    if (source as bool &&
                        !(await Permission.camera.request()).isGranted) return;
                    final selectedImage = await ImagePicker().pickImage(
                      source: source ? ImageSource.camera : ImageSource.gallery,
                    );
                    if (selectedImage == null) return;
                    changedImage = (await ImageCropper().cropImage(
                      sourcePath: selectedImage.path,
                      uiSettings: [
                        AndroidUiSettings(
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
                    ))
                        ?.path;
                    deletePhoto = false;
                    setState(() {});
                  },
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
                    child: Text(
                      area.name,
                      style: const TextStyle(
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
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
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
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      maxLines: null,
                      decoration: const InputDecoration(
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
                    icon: const Icon(
                      IconData(0xe568, fontFamily: 'MaterialIconsR'),
                    ),
                    label: const Text('تعديل مكان المنطقة على الخريطة'),
                    onPressed: () async {
                      final List<GeoPoint> oldPoints =
                          area.locationPoints.sublist(0);
                      final rslt = await navigator.currentState!.push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              actions: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.done),
                                  onPressed: () =>
                                      navigator.currentState!.pop(true),
                                  tooltip: 'حفظ',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      navigator.currentState!.pop(false),
                                  tooltip: 'حذف التحديد',
                                ),
                              ],
                              title:
                                  Text('تعديل مكان ${area.name} على الخريطة'),
                            ),
                            body: area.getMapView(
                              editMode: true,
                              useGPSIfNull: true,
                            ),
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
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        isEmpty: area.lastVisit == null,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ أخر زيارة',
                        ),
                        child: area.lastVisit != null
                            ? Text(
                                DateFormat('yyyy/M/d').format(
                                  area.lastVisit!.toDate(),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () => _selectDate2(context),
                      child: InputDecorator(
                        isEmpty: area.fatherLastVisit == null,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ أخر زيارة (للأب الكاهن)',
                        ),
                        child: area.fatherLastVisit != null
                            ? Text(
                                DateFormat('yyyy/M/d').format(
                                  area.fatherLastVisit!.toDate(),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  ColorField(
                    initialValue: area.color,
                    onChanged: (value) => setState(
                      () => area.color = value ?? Colors.transparent,
                    ),
                  ),
                  Selector<User, bool>(
                    selector: (_, user) => user.manageUsers,
                    builder: (context, permission, _) {
                      if (permission) {
                        return ElevatedButton.icon(
                          style: area.color != Colors.transparent
                              ? ElevatedButton.styleFrom(
                                  backgroundColor: area.color,
                                )
                              : null,
                          icon: const Icon(Icons.visibility),
                          onPressed: showUsers,
                          label: const Text(
                            'المستخدمين المسموح لهم برؤية المنطقة وما بداخلها',
                            softWrap: false,
                            textScaler: TextScaler.linear(0.95),
                            overflow: TextOverflow.fade,
                          ),
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
        children: <Widget>[
          if (area.id != 'null')
            FloatingActionButton(
              mini: true,
              tooltip: 'حذف',
              heroTag: null,
              onPressed: delete,
              child: const Icon(Icons.delete),
            ),
          FloatingActionButton(
            tooltip: 'حفظ',
            heroTag: null,
            onPressed: save,
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }

  Future<void> delete() async {
    if (await showDialog(
          context: context,
          builder: (context) => DataDialog(
            title: Text(area.name),
            content: Text(
              'هل أنت متأكد من حذف ${area.name} وكل ما بها من شوارع وعائلات وأشخاص؟',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  navigator.currentState!.pop(true);
                },
                child: const Text('نعم'),
              ),
              TextButton(
                onPressed: () {
                  navigator.currentState!.pop();
                },
                child: const Text('تراجع'),
              ),
            ],
          ),
        ) ==
        true) {
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('جار حذف المنطقة وما بداخلها من بيانات...'),
          duration: Duration(minutes: 20),
        ),
      );
      if ((await Connectivity().checkConnectivity()).isConnected) {
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
          const SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(minutes: 20),
          ),
        );
        if (area.locationPoints.isNotEmpty &&
            Object.hashAll(area.locationPoints) !=
                Object.hashAll(widget.area?.locationPoints ?? [])) {
          if (User.instance.approveLocations) {
            area.locationConfirmed = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => DataDialog(
                title: const Text('هل أنت متأكد من موقع المنطقة على الخريطة؟'),
                content: const Text(
                  'إن لم تكن متأكدًا سيتم إعلام المستخدمين الأخرين ليأكدوا عليه',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => navigator.currentState!.pop(true),
                    child: const Text('نعم'),
                  ),
                  TextButton(
                    onPressed: () => navigator.currentState!.pop(false),
                    child: const Text('لا'),
                  ),
                ],
              ),
            );
          } else {
            // oldArea['LocationConfirmed'] = true;
            area.locationConfirmed = false;
          }
        }
        final bool update = area.id != 'null';
        if (!update) area.ref = firestore.collection('Areas').doc();

        area.lastEdit = User.instance.uid;

        if (update && (await Connectivity().checkConnectivity()).isConnected) {
          await area.update(old: widget.area?.getMap() ?? {});
        } else if (update) {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          area.update(old: widget.area?.getMap() ?? {});
        } else if ((await Connectivity().checkConnectivity()).isConnected) {
          await area.set();
        } else {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          area.set();
        }

        if (changedImage != null) {
          await firebaseStorage.ref().child('AreasPhotos/${area.id}').putFile(
                File(changedImage!),
              );
          area.hasPhoto = true;
        } else if (deletePhoto) {
          await firebaseStorage.ref().child('AreasPhotos/${area.id}').delete();
        }

        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        if (mounted) navigator.currentState!.pop(area.ref);
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'AreaP.save');
      await FirebaseCrashlytics.instance.setCustomKey('Area', area.id);
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(
        SnackBar(
          content: Text(
            err.toString(),
          ),
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }

  Future<void> showUsers() async {
    area.allowedUsers = await navigator.currentState!.push(
          MaterialPageRoute(
            builder: (context) => FutureBuilder<List<User>>(
              future: User.getAllForUser().first.then(
                    (value) => value
                        .where((u) => area.allowedUsers.contains(u.uid))
                        .toList(),
                  ),
              builder: (c, users) {
                if (!users.hasData)
                  return const Center(child: CircularProgressIndicator());

                return Provider<DataObjectListController<User>>(
                  create: (_) => DataObjectListController<User>(
                    itemBuilder: (
                      current, [
                      void Function(User)? onLongPress,
                      void Function(User)? onTap,
                      trailing,
                      subtitle,
                    ]) =>
                        DataObjectWidget(
                      current,
                      onTap: () => onTap!(current),
                      trailing: trailing,
                      showSubtitle: false,
                    ),
                    selectionMode: true,
                    selected: {for (final item in users.data!) item.id: item},
                    itemsStream: User.getAllForUser(),
                  ),
                  dispose: (context, c) => c.dispose(),
                  builder: (context, _) => Scaffold(
                    appBar: AppBar(
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: navigator.currentState!.pop,
                      ),
                      title: SearchField(
                        showSuffix: false,
                        searchStream: context
                            .read<DataObjectListController<User>>()
                            .searchQuery,
                        textStyle:
                            Theme.of(context).primaryTextTheme.titleLarge,
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            navigator.currentState!.pop(
                              context
                                  .read<DataObjectListController<User>>()
                                  .selectedLatest
                                  ?.keys
                                  .toList(),
                            );
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
    final DateTime? picked = await showDatePicker(
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
    final DateTime? picked = await showDatePicker(
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
