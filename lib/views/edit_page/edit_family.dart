import 'dart:async';

import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/mini_lists/colors_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class EditFamily extends StatefulWidget {
  final Family? family;

  EditFamily({Key? key, this.family}) : super(key: key);
  @override
  _EditFamilyState createState() => _EditFamilyState();
}

class _EditFamilyState extends State<EditFamily> {
  GlobalKey<FormState> form = GlobalKey<FormState>();

  late Family family;

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
          padding: EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('محل'),
                    Switch(
                      value: family.isStore,
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
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    initialValue: family.name,
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
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
                        ? GeoPoint(family.locationPoint!.latitude,
                            family.locationPoint!.longitude)
                        : null;
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
                  },
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: selectStreet,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'داخل شارع',
                      ),
                      child: FutureBuilder<String?>(
                        future: family.streetId == null
                            ? null
                            : family.getStreetName(),
                        builder: (con, data) {
                          if (data.hasData) {
                            return Text(data.data!);
                          } else if (data.connectionState ==
                              ConnectionState.waiting) {
                            return LinearProgressIndicator();
                          } else {
                            return Text('لا يوجد');
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Flexible(
                        flex: 3,
                        child: InkWell(
                          onTap: selectFamily,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText:
                                  family.isStore ? 'ادارة المحل' : 'داخل عائلة',
                            ),
                            child: FutureBuilder<String?>(
                              future: family.insideFamily == null
                                  ? Future(() => null)
                                  : family.getInsideFamilyName(),
                              builder: (con, data) {
                                if (data.hasData) {
                                  return Text(data.data!);
                                } else if (data.connectionState ==
                                    ConnectionState.waiting) {
                                  return LinearProgressIndicator();
                                } else {
                                  return Text('لا يوجد');
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: TextButton.icon(
                          icon: Icon(Icons.close),
                          onPressed: () => setState(() {
                            family.insideFamily = null;
                          }),
                          label: Text('حذف العائلة'),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Flexible(
                        flex: 3,
                        child: InkWell(
                          onTap: selectFamily2,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'داخل عائلة 2',
                            ),
                            child: FutureBuilder<String?>(
                              future: family.insideFamily2 == null
                                  ? Future(() => null)
                                  : family.getInsideFamily2Name(),
                              builder: (con, data) {
                                if (data.hasData) {
                                  return Text(data.data!);
                                } else if (data.connectionState ==
                                    ConnectionState.waiting) {
                                  return LinearProgressIndicator();
                                } else {
                                  return Text('لا يوجد');
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: TextButton.icon(
                          icon: Icon(Icons.close),
                          onPressed: () => setState(() {
                            family.insideFamily2 = null;
                          }),
                          label: Text('حذف العائلة'),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'تاريخ أخر زيارة',
                      ),
                      child: family.lastVisit != null
                          ? Text(
                              DateFormat('yyyy/M/d').format(
                                family.lastVisit!.toDate(),
                              ),
                            )
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
                      child: family.fatherLastVisit != null
                          ? Text(DateFormat('yyyy/M/d').format(
                              family.fatherLastVisit!.toDate(),
                            ))
                          : null,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: family.color != Colors.transparent
                      ? ElevatedButton.styleFrom(primary: family.color)
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (family.id != 'null')
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

  void delete() async {
    if (await showDialog(
          context: context,
          builder: (context) => DataDialog(
            title: Text(family.name),
            content:
                Text('هل أنت متأكد من حذف ${family.name} وكل الأشخاص بداخلها؟'),
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
          content: Text('جار حذف ال' +
              (family.isStore ? 'محل' : 'عائلة') +
              ' وما بداخلها من بيانات...'),
          duration: Duration(minutes: 20),
        ),
      );
      if (await Connectivity().checkConnectivity() != ConnectivityResult.none)
        await family.ref.delete();
      else {
        // ignore: unawaited_futures
        family.ref.delete();
      }
      navigator.currentState!.pop('deleted');
    }
  }

  @override
  void initState() {
    super.initState();
    family = (widget.family ?? Family.empty()).copyWith();
    family.setAreaIdFromStreet();
  }

  void nameChanged(String value) {
    family.name = value;
  }

  void notesChanged(String value) {
    family.notes = value;
  }

  Future save() async {
    try {
      if (form.currentState!.validate() && family.streetId != null) {
        scaffoldMessenger.currentState!.showSnackBar(
          SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(minutes: 20),
          ),
        );
        if (family.locationPoint != null &&
            family.locationPoint != widget.family?.locationPoint) {
          if (User.instance.approveLocations) {
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
            // old['LocationConfirmed'] = true;
            family.locationConfirmed = false;
          }
        }

        family.lastEdit = User.instance.uid!;

        bool update = family.id != 'null';
        if (!update)
          family.ref = FirebaseFirestore.instance.collection('Families').doc();

        if (update &&
            await Connectivity().checkConnectivity() !=
                ConnectivityResult.none) {
          await family.update(old: widget.family?.getMap() ?? {});
        } else if (update) {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          family.update(
            old: widget.family?.getMap() ?? {},
          );
        } else if (await Connectivity().checkConnectivity() !=
            ConnectivityResult.none) {
          await family.set();
        } else {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          family.set();
        }

        navigator.currentState!.pop(family.ref);
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
                family.color = Colors.transparent;
              });
            },
            child: Text('بلا لون'),
          ),
        ],
        content: ColorsList(
          selectedColor: family.color,
          onSelect: (color) {
            navigator.currentState!.pop();
            setState(() {
              family.color = color;
            });
            FocusScope.of(context).nextFocus();
          },
        ),
      ),
    );
  }

  Future<void> selectFamily() async {
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(OrderOptions());

    final listOptions = DataObjectListOptions<Family>(
      tap: (value) {
        navigator.currentState!.pop();
        setState(() {
          family.insideFamily =
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
                family.insideFamily = await navigator.currentState!
                        .pushNamed('Data/EditFamily') as JsonRef? ??
                    family.insideFamily;
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

  void selectFamily2() async {
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(OrderOptions());

    final listOptions = DataObjectListOptions<Family>(
      tap: (value) {
        navigator.currentState!.pop();
        setState(() {
          family.insideFamily2 =
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
                family.insideFamily2 = await navigator.currentState!
                        .pushNamed('Data/EditFamily') as JsonRef? ??
                    family.insideFamily2;
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

  void selectStreet() async {
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(OrderOptions());

    final listOptions = DataObjectListOptions<Street>(
      tap: (value) {
        navigator.currentState!.pop();
        setState(() {
          family.streetId =
              FirebaseFirestore.instance.collection('Streets').doc(value.id);
        });
        FocusScope.of(context).nextFocus();
      },
      itemsStream: _orderOptions
          .switchMap((value) => Street.getAllForUser(
              orderBy: value.orderBy, descending: !value.asc))
          .map((s) => s.docs.map(Street.fromQueryDoc).toList()),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                navigator.currentState!.pop();
                family.streetId = await navigator.currentState!
                        .pushNamed('Data/EditStreet') as JsonRef? ??
                    family.streetId;
                setState(() {});
              },
              tooltip: 'إضافة شارع جديد جديدة',
              child: Icon(Icons.add_road),
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
                    child: DataObjectList<Street>(
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

  Future _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: family.lastVisit?.toDate() ?? DateTime.now(),
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && Timestamp.fromDate(picked) != family.lastVisit)
      setState(() {
        family.lastVisit = Timestamp.fromDate(picked);
        FocusScope.of(context).nextFocus();
      });
  }

  Future _selectDate2(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: family.fatherLastVisit?.toDate() ?? DateTime.now(),
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && Timestamp.fromDate(picked) != family.fatherLastVisit)
      setState(() {
        family.fatherLastVisit = Timestamp.fromDate(picked);
        FocusScope.of(context).nextFocus();
      });
  }
}
