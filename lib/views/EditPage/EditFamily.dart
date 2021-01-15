import 'dart:async';

import 'package:churchdata/Models.dart';
import 'package:churchdata/Models/User.dart';
import 'package:churchdata/views/MiniLists/ColorsList.dart';
import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:churchdata/views/utils/List.dart';
import 'package:churchdata/views/utils/SearchFilters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.io) 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditFamily extends StatefulWidget {
  final Family family;

  EditFamily({Key key, this.family}) : super(key: key);
  @override
  _EditFamilyState createState() => _EditFamilyState();
}

class _EditFamilyState extends State<EditFamily> {
  List<FocusNode> foci = List.generate(8, (_) => FocusNode());

  Map<String, dynamic> old;
  GlobalKey<FormState> form = GlobalKey<FormState>();

  Family family;

  void addressChanged(String value) {
    family.address = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            family.color != Colors.transparent ? family.color : null,
        title: Text(family.name),
      ),
      body: Form(
        key: form,
        child: Padding(
          padding: EdgeInsets.all(5),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('محل'),
                    Switch(
                      value: widget.family.isStore,
                      onChanged: (v) {
                        family.isStore = v;
                        setState(() {});
                      },
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'اسم ال' + (family.isStore ? 'محل' : 'عائلة'),
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    focusNode: foci[0],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => foci[1].requestFocus(),
                    initialValue: family.name,
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
                    focusNode: foci[1],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      foci[2].requestFocus();
                      selectStreet();
                    },
                    initialValue: family.address,
                    onChanged: addressChanged,
                    validator: (value) {
                      return null;
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: TextFormField(
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    focusNode: foci[2],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      foci[3].requestFocus();
                      selectStreet();
                    },
                    initialValue: family.notes,
                    onChanged: notesChanged,
                    validator: (value) {
                      return null;
                    },
                  ),
                ),
                ElevatedButton.icon(
                    icon: Icon(
                      const IconData(0xe568, fontFamily: 'MaterialIconsR'),
                    ),
                    label: Text('تعديل مكان ال' +
                        (family.isStore ? 'محل' : 'عائلة') +
                        ' على الخريطة'),
                    onPressed: () async {
                      var oldPoint = family.locationPoint != null
                          ? GeoPoint(family.locationPoint.latitude,
                              family.locationPoint.longitude)
                          : null;
                      var rslt = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
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
                                  Text('تعديل مكان ${family.name} على الخريطة'),
                            ),
                            body: family.getMapView(
                                editMode: true, useGPSIfNull: true),
                          ),
                        ),
                      );
                      if (rslt == null) {
                        family.locationPoint = oldPoint;
                      } else if (rslt == false) {
                        family.locationPoint = null;
                      }
                    }),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Focus(
                    focusNode: foci[3],
                    child: InkWell(
                      onTap: selectStreet,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'داخل شارع',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        child: FutureBuilder(
                            future: family.streetId == null
                                ? null
                                : family.getStreetName(),
                            builder: (con, data) {
                              if (data.connectionState ==
                                  ConnectionState.done) {
                                return Text(data.data);
                              } else if (data.connectionState ==
                                  ConnectionState.waiting) {
                                return LinearProgressIndicator();
                              } else {
                                return Text('لا يوجد');
                              }
                            }),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Focus(
                    focusNode: foci[4],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Flexible(
                          child: InkWell(
                            onTap: selectFamily,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: family.isStore
                                    ? 'ادارة المحل'
                                    : 'داخل عائلة',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                              child: FutureBuilder(
                                  future: family.insideFamily == null
                                      ? Future(() => null)
                                      : family.getInsideFamilyName(),
                                  builder: (con, data) {
                                    if (data.hasData) {
                                      return Text(data.data);
                                    } else if (data.connectionState ==
                                        ConnectionState.waiting) {
                                      return LinearProgressIndicator();
                                    } else {
                                      return Text('لا يوجد');
                                    }
                                  }),
                            ),
                          ),
                          flex: 3,
                        ),
                        Flexible(
                            child: TextButton.icon(
                              icon: Icon(Icons.close),
                              onPressed: () => setState(() {
                                family.insideFamily = null;
                              }),
                              label: Text('حذف العائلة'),
                            ),
                            flex: 2),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Focus(
                    focusNode: foci[5],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Flexible(
                          child: InkWell(
                            onTap: selectFamily2,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'داخل عائلة 2',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                              child: FutureBuilder(
                                  future: family.insideFamily2 == null
                                      ? Future(() => null)
                                      : family.getInsideFamily2Name(),
                                  builder: (con, data) {
                                    if (data.hasData) {
                                      return Text(data.data);
                                    } else if (data.connectionState ==
                                        ConnectionState.waiting) {
                                      return LinearProgressIndicator();
                                    } else {
                                      return Text('لا يوجد');
                                    }
                                  }),
                            ),
                          ),
                          flex: 3,
                        ),
                        Flexible(
                            child: TextButton.icon(
                              icon: Icon(Icons.close),
                              onPressed: () => setState(() {
                                family.insideFamily2 = null;
                              }),
                              label: Text('حذف العائلة'),
                            ),
                            flex: 2),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Focus(
                    focusNode: foci[6],
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تاريخ أخر زيارة',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        child: Text(DateFormat('yyyy/M/d').format(
                          family.lastVisit.toDate(),
                        )),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Focus(
                    focusNode: foci[7],
                    child: InkWell(
                      onTap: _selectDate2,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تاريخ أخر زيارة (للأب الكاهن)',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        child: family.fatherLastVisit != null
                            ? Text(DateFormat('yyyy/M/d').format(
                                family.fatherLastVisit.toDate(),
                              ))
                            : Text(DateFormat('yyyy/M/d').format(
                                DateTime(DateTime.now().year,
                                    DateTime.now().month, DateTime.now().day),
                              )),
                      ),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(primary: family.color),
                  onPressed: selectColor,
                  icon: Icon(Icons.color_lens),
                  label: Text('اللون'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (family.id != '')
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

  void changeDate(DateTime value) {
    family.lastVisit = Timestamp.fromDate(value);
  }

  void delete() {
    showDialog(
      context: context,
      builder: (context) => DataDialog(
        title: Text(family.name),
        content:
            Text('هل أنت متأكد من حذف ${family.name} وكل الأشخاص بداخلها؟'),
        actions: <Widget>[
          TextButton(
              child: Text('نعم'),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('جار حذف ال' +
                        (family.isStore ? 'محل' : 'عائلة') +
                        ' وما بداخلها من بيانات...'),
                    duration: Duration(minutes: 20),
                  ),
                );
                await FirebaseFirestore.instance
                    .collection('Families')
                    .doc(family.id)
                    .delete();
                Navigator.of(context).pop();
                Navigator.of(context).pop('deleted');
              }),
          TextButton(
              child: Text('تراجع'),
              onPressed: () {
                Navigator.of(context).pop();
              }),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    family = widget.family ?? Family.empty();
    old = family.getMap();
  }

  void nameChanged(String value) {
    family.name = value;
  }

  void notesChanged(String value) {
    family.notes = value;
  }

  Future save() async {
    try {
      if (form.currentState.validate() && family.streetId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(minutes: 20),
          ),
        );
        if (family.getMap()['Location'] != null &&
            family.getMap()['Location'] != old['Location']) {
          if (context.read<User>().approveLocations) {
            family.locationConfirmed = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => DataDialog(
                title: Text('هل أنت متأكد من موقع ال' +
                    (family.isStore ? 'محل' : 'عائلة') +
                    ' على الخريطة؟'),
                content: Text(
                    'إن لم تكن متأكدًا سيتم إعلام المستخدمين الأخرين ليأكدوا عليه'),
                actions: <Widget>[
                  TextButton(
                    child: Text('نعم'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  TextButton(
                    child: Text('لا'),
                    onPressed: () => Navigator.of(context).pop(false),
                  )
                ],
              ),
            );
          } else {
            family.locationConfirmed = false;
          }
        }

        family.lastEdit = auth.FirebaseAuth.instance.currentUser.uid;

        if (family.id == '') {
          family.id =
              (await FirebaseFirestore.instance.collection('Families').add(
                        family.getMap(),
                      ))
                  .id;
        } else {
          await family.ref.update(
            family.getMap()..removeWhere((key, value) => old[key] == value),
          );
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.of(context).pop(family.ref);
      } else {
        await showDialog(
          context: context,
          builder: (context) => DataDialog(
            title: Text('بيانات غير كاملة'),
            content: Text('يرجى التأكد من ملئ هذه الحقول:\nالاسم\nالشارع'),
          ),
        );
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'FamilyP.save');
      await FirebaseCrashlytics.instance.setCustomKey('Family', family.id);
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
      builder: (context) => DataDialog(
        content: ColorsList(
          selectedColor: family.color,
          onSelect: (color) {
            Navigator.of(context).pop();
            setState(() {
              family.color = color;
            });
          },
        ),
      ),
    );
  }

  void selectFamily() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width - 55,
            height: MediaQuery.of(context).size.height - 110,
            child: ListenableProvider<SearchString>(
              create: (_) => SearchString(''),
              builder: (context, child) => Column(
                children: [
                  SearchFilters(1),
                  Expanded(
                    child: Selector<OrderOptions, Tuple2<String, bool>>(
                      selector: (_, o) =>
                          Tuple2<String, bool>(o.familyOrderBy, o.familyASC),
                      builder: (context, options, child) =>
                          DataObjectList<Family>(
                        options: ListOptions<Family>(
                          floatingActionButton: FloatingActionButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                widget.family.insideFamily =
                                    (await Navigator.of(context)
                                                .pushNamed('Data/EditFamily'))
                                            as DocumentReference ??
                                        family.insideFamily;
                                setState(() {});
                              },
                              child: Icon(Icons.group_add),
                              tooltip: 'إضافة عائلة جديدة'),
                          tap: (value, _) {
                            Navigator.of(context).pop();
                            setState(() {
                              widget.family.insideFamily = FirebaseFirestore
                                  .instance
                                  .collection('Families')
                                  .doc(value.id);
                            });
                            foci[13].requestFocus();
                          },
                          generate: Family.fromDocumentSnapshot,
                          documentsData: () => Family.getAllForUser(
                              orderBy: options.item1,
                              descending: !options.item2),
                        ),
                      ),
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

  void selectFamily2() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width - 55,
            height: MediaQuery.of(context).size.height - 110,
            child: ListenableProvider<SearchString>(
              create: (_) => SearchString(''),
              builder: (context, child) => Column(
                children: [
                  SearchFilters(1),
                  Expanded(
                    child: Selector<OrderOptions, Tuple2<String, bool>>(
                      selector: (_, o) =>
                          Tuple2<String, bool>(o.familyOrderBy, o.familyASC),
                      builder: (context, options, child) =>
                          DataObjectList<Family>(
                        options: ListOptions<Family>(
                          floatingActionButton: FloatingActionButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                widget.family.insideFamily2 =
                                    (await Navigator.of(context)
                                                .pushNamed('Data/EditFamily'))
                                            as DocumentReference ??
                                        family.insideFamily2;
                                setState(() {});
                              },
                              child: Icon(Icons.group_add),
                              tooltip: 'إضافة عائلة جديدة'),
                          tap: (value, _) {
                            Navigator.of(context).pop();
                            setState(() {
                              widget.family.insideFamily2 = FirebaseFirestore
                                  .instance
                                  .collection('Families')
                                  .doc(value.id);
                            });
                            foci[13].requestFocus();
                          },
                          generate: Family.fromDocumentSnapshot,
                          documentsData: () => Family.getAllForUser(
                              orderBy: options.item1,
                              descending: !options.item2),
                        ),
                      ),
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

  void selectStreet() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width - 55,
            height: MediaQuery.of(context).size.height - 110,
            child: ListenableProvider<SearchString>(
              create: (_) => SearchString(''),
              builder: (context, child) => Column(
                children: [
                  SearchFilters(1),
                  Expanded(
                    child: Selector<OrderOptions, Tuple2<String, bool>>(
                      selector: (_, o) =>
                          Tuple2<String, bool>(o.streetOrderBy, o.streetASC),
                      builder: (context, options, child) =>
                          DataObjectList<Street>(
                        options: ListOptions<Street>(
                          floatingActionButton: FloatingActionButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                family.streetId = (await Navigator.of(context)
                                            .pushNamed('Data/EditStreet'))
                                        as DocumentReference ??
                                    family.streetId;
                                await family.setAreaIdFromStreet();
                                setState(() {});
                              },
                              child: Icon(Icons.add_road),
                              tooltip: 'إضافة شارع جديد'),
                          tap: (street, _) {
                            Navigator.of(context).pop();
                            setState(() {
                              family.streetId = FirebaseFirestore.instance
                                  .collection('Streets')
                                  .doc(street.id);
                              family.setAreaIdFromStreet();
                            });
                            foci[3].requestFocus();
                            _selectDate();
                          },
                          generate: Street.fromDocumentSnapshot,
                          documentsData: () => Street.getAllForUser(
                              orderBy: options.item1,
                              descending: !options.item2),
                        ),
                      ),
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

  Future _selectDate() async {
    DateTime picked = await showDatePicker(
      context: context,
      initialDate: family.lastVisit.toDate(),
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && Timestamp.fromDate(picked) != family.lastVisit)
      setState(() {
        family.lastVisit = Timestamp.fromDate(picked);
      });
  }

  Future _selectDate2() async {
    DateTime picked = await showDatePicker(
      context: context,
      initialDate: family.fatherLastVisit?.toDate() ?? DateTime.now(),
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && Timestamp.fromDate(picked) != family.fatherLastVisit)
      setState(() {
        family.fatherLastVisit = Timestamp.fromDate(picked);
      });
  }
}
