import 'dart:async';

import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/order_options.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/views/mini_lists/colors_list.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class EditStreet extends StatefulWidget {
  final Street street;

  EditStreet({Key key, this.street}) : super(key: key);
  @override
  _EditStreetState createState() => _EditStreetState();
}

class _EditStreetState extends State<EditStreet> {
  Map<String, dynamic> old;
  GlobalKey<FormState> form = GlobalKey<FormState>();
  Street street;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            street.color != Colors.transparent ? street.color : null,
        title: Text(street.name),
      ),
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
                    labelText: 'اسم الشارع',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  initialValue: street.name,
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
                child: InkWell(
                  onTap: selectArea,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'داخل منطقة',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    child: FutureBuilder(
                        future:
                            street.areaId == null ? null : street.getAreaName(),
                        builder: (con, data) {
                          if (data.connectionState == ConnectionState.done) {
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
              ElevatedButton.icon(
                  icon: Icon(
                    const IconData(0xe568, fontFamily: 'MaterialIconsR'),
                  ),
                  label: Text('تعديل مكان الشارع على الخريطة'),
                  onPressed: () async {
                    var oldPoints = street.locationPoints?.sublist(0);
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
                                onPressed: () => Navigator.pop(context, false),
                                tooltip: 'حذف التحديد',
                              )
                            ],
                            title:
                                Text('تعديل مكان ${street.name} على الخريطة'),
                          ),
                          body: street.getMapView(
                              editMode: true, useGPSIfNull: true),
                        ),
                      ),
                    );
                    if (rslt == null) {
                      street.locationPoints = oldPoints;
                    } else if (rslt == false) {
                      street.locationPoints = null;
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
                      street.lastVisit.toDate(),
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
                    child: street.fatherLastVisit != null
                        ? Text(DateFormat('yyyy/M/d').format(
                            street.fatherLastVisit.toDate(),
                          ))
                        : Text(DateFormat('yyyy/M/d').format(
                            DateTime(DateTime.now().year, DateTime.now().month,
                                DateTime.now().day),
                          )),
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(primary: street.color),
                onPressed: selectColor,
                icon: Icon(Icons.color_lens),
                label: Text('اللون'),
              ),
            ].map((w) => Focus(child: w)).toList(),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (widget.street.id != 'null')
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
    street.lastVisit = Timestamp.fromDate(value);
  }

  void delete() async {
    if (await showDialog(
          context: context,
          builder: (context) => DataDialog(
            title: Text(street.name),
            content: Text(
                'هل أنت متأكد من حذف ${street.name} وكل ما بداخله من عائلات وأشخاص؟'),
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
          content: Text('جار حذف الشارع وما بداخله من بيانات...'),
          duration: Duration(minutes: 20),
        ),
      );
      if (await Connectivity().checkConnectivity() != ConnectivityResult.none)
        await street.ref.delete();
      else {
        // ignore: unawaited_futures
        street.ref.delete();
      }
      Navigator.pop(context, 'deleted');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    street ??= widget.street ?? Street.empty();
    old ??= street.getMap();
  }

  void nameChanged(String value) {
    street.name = value;
  }

  Future save() async {
    try {
      if (form.currentState.validate() && street.areaId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(minutes: 20),
          ),
        );
        if (street.getMap()['Location'] != null &&
            hashList(street.getMap()['Location']) !=
                hashList(old['Location'])) {
          if (User.instance.approveLocations) {
            street.locationConfirmed = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => DataDialog(
                title: Text('هل أنت متأكد من موقع الشارع على الخريطة؟'),
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
            old['LocationConfirmed'] = true;
            street.locationConfirmed = false;
          }
        }

        street.lastEdit = auth.FirebaseAuth.instance.currentUser.uid;

        bool update = widget.street.id != 'null';
        if (!update)
          widget.street.ref =
              FirebaseFirestore.instance.collection('Street').doc();

        if (update &&
            await Connectivity().checkConnectivity() !=
                ConnectivityResult.none) {
          await street.ref.update(
            street.getMap()..removeWhere((key, value) => old[key] == value),
          );
        } else if (update) {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          street.ref.update(
            street.getMap()..removeWhere((key, value) => old[key] == value),
          );
        } else if (await Connectivity().checkConnectivity() !=
            ConnectivityResult.none) {
          await street.ref.set(
            street.getMap(),
          );
        } else {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          street.ref.set(
            street.getMap(),
          );
        }

        Navigator.of(context).pop(street.ref);
      } else {
        await showDialog(
            context: context,
            builder: (context) => DataDialog(
                  title: Text('بيانات غير كاملة'),
                  content:
                      Text('يرجى التأكد من ملئ هذه الحقول:\nالاسم\nالمنطقة'),
                ));
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'StreetP.save');
      await FirebaseCrashlytics.instance.setCustomKey('Street', street.id);
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

  void selectArea() {
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
              street.areaId =
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
                street.areaId = (await Navigator.of(context)
                        .pushNamed('Data/EditArea')) as DocumentReference ??
                    street.areaId;
                FocusScope.of(context).nextFocus();
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

  void selectColor() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                street.color = Colors.transparent;
              });
            },
            child: Text('بلا لون'),
          ),
        ],
        content: ColorsList(
          selectedColor: street.color,
          onSelect: (color) {
            Navigator.of(context).pop();
            setState(() {
              street.color = color;
            });
            FocusScope.of(context).nextFocus();
          },
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: street.lastVisit.toDate(),
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && Timestamp.fromDate(picked) != street.lastVisit)
      setState(() {
        street.lastVisit = Timestamp.fromDate(picked);
        FocusScope.of(context).nextFocus();
      });
  }

  Future<void> _selectDate2(BuildContext context) async {
    DateTime picked = await showDatePicker(
      context: context,
      initialDate: street.fatherLastVisit?.toDate() ?? DateTime.now(),
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && Timestamp.fromDate(picked) != street.fatherLastVisit)
      setState(() {
        street.fatherLastVisit = Timestamp.fromDate(picked);
        FocusScope.of(context).nextFocus();
      });
  }
}
