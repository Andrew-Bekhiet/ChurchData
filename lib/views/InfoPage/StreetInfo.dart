import 'dart:async';

import 'package:churchdata/Models.dart';
import 'package:churchdata/Models/Area.dart';
import 'package:churchdata/Models/SearchString.dart';
import 'package:churchdata/Models/User.dart';
import 'package:churchdata/utils/Helpers.dart';
import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:churchdata/views/utils/DataObjectWidget.dart';
import 'package:churchdata/views/utils/HistoryProperty.dart';
import 'package:churchdata/views/utils/List.dart';
import 'package:churchdata/views/utils/SearchFilters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.io) 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class StreetInfo extends StatefulWidget {
  final Street street;

  StreetInfo({Key key, this.street}) : super(key: key);

  @override
  _StreetInfoState createState() => _StreetInfoState();
}

class _StreetInfoState extends State<StreetInfo> {
  Street street;
  bool showWarning = true;

  StreamSubscription<DocumentSnapshot> _listener;

  void addTap([bool type]) {
    Navigator.of(context).pushNamed(
      'Data/EditFamily',
      arguments: {'IsStore': type, 'StreetId': street.ref},
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!street.locationConfirmed &&
          street.locationPoints != null &&
          showWarning) {
        showWarning = false;
        showDialog(
          context: context,
          builder: (context) => DataDialog(
            content: Text('لم يتم تأكيد موقع الشارع الموجود على الخريطة'),
            title: Text('تحذير'),
          ),
        );
      }
    });

    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, permission, _) => Scaffold(
        appBar: AppBar(
          backgroundColor:
              street.color != Colors.transparent ? street.color : null,
          title: Text(street.name),
          actions: <Widget>[
            if (permission)
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () async {
                  dynamic result = await Navigator.of(context)
                      .pushNamed('Data/EditStreet', arguments: street);
                  if (result is DocumentReference) {
                    street = await Street.fromId(result.id);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم الحفظ بنجاح'),
                      ),
                    );
                  } else if (result == 'deleted') Navigator.of(context).pop();
                },
                tooltip: 'تعديل',
              ),
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () async {
                await Share.share(
                  await shareStreet(street),
                );
              },
              tooltip: 'مشاركة برابط',
            ),
            PopupMenuButton(
              onSelected: (_) => sendNotification(context, street),
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: '',
                    child: Text('ارسال إشعار للمستخدمين عن الشارع'),
                  ),
                ];
              },
            ),
          ],
        ),
        body: ListenableProvider<SearchString>(
          create: (_) => SearchString(''),
          builder: (context, child) => NestedScrollView(
            headerSliverBuilder: (context, x) {
              return <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      ListTile(
                        title: Hero(
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                street.name,
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ),
                            tag: street.id + '-name'),
                      ),
                      if (street.locationPoints != null)
                        ElevatedButton.icon(
                          icon: Icon(Icons.map),
                          onPressed: () => showMap(),
                          label: Text('إظهار على الخريطة'),
                        ),
                      Divider(thickness: 1),
                      HistoryProperty('تاريخ أخر زيارة:', street.lastVisit,
                          street.ref.collection('VisitHistory')),
                      HistoryProperty(
                          'تاريخ أخر زيارة (لللأب الكاهن):',
                          street.fatherLastVisit,
                          street.ref.collection('FatherVisitHistory')),
                      EditHistoryProperty(
                          'أخر تحديث للبيانات:',
                          street.lastEdit,
                          street.ref.collection('EditHistory')),
                      Divider(thickness: 1),
                      ListTile(
                        title: Text('داخل منطقة:'),
                        subtitle: street.areaId != null &&
                                street.areaId.parent.id != 'null'
                            ? FutureBuilder<Area>(
                                future: Area.fromId(street.areaId.id),
                                builder: (context, area) => area.hasData
                                    ? DataObjectWidget<Area>(area.data,
                                        isDense: true)
                                    : LinearProgressIndicator(),
                              )
                            : Text('غير موجودة'),
                      ),
                      Divider(
                        thickness: 1,
                      ),
                      Text('العائلات بالشارع:',
                          style: Theme.of(context).textTheme.bodyText1),
                      SearchFilters(2),
                    ],
                  ),
                ),
              ];
            },
            body: SafeArea(
              child: Consumer<OrderOptions>(
                builder: (context, options, _) => DataObjectList<Family>(
                  options: ListOptions<Family>(
                      doubleActionButton: true,
                      floatingActionButton: permission
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 32),
                                  child: FloatingActionButton(
                                    child: Icon(Icons.update),
                                    tooltip: 'تسجيل أخر زيارة اليوم',
                                    heroTag: 'lastVisit',
                                    onPressed: recordLastVisit,
                                  ),
                                ),
                                PopupMenuButton<bool>(
                                  child: FloatingActionButton(
                                      child: Icon(Icons.add), onPressed: null),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: Icon(Icons.add_business),
                                        title: Text('اضافة محل'),
                                      ),
                                      value: true,
                                    ),
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: Icon(Icons.group_add),
                                        title: Text('اضافة عائلة'),
                                      ),
                                      value: false,
                                    )
                                  ],
                                  onSelected: addTap,
                                ),
                              ],
                            )
                          : null,
                      generate: Family.fromDocumentSnapshot,
                      tap: familyTap,
                      documentsData: () => street.getMembersLive(
                          orderBy: options.familyOrderBy,
                          descending: !options.familyASC)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    street = widget.street;
  }

  @override
  void dispose() {
    _listener?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _listener = widget.street.ref.snapshots().listen((event) {
      street = Street.fromDocumentSnapshot(event);
      if (mounted) setState(() {});
    });
  }

  void recordLastVisit() async {
    await street.ref.update({
      'LastVisit': Timestamp.now(),
      'LastEdit': FirebaseAuth.instance.currentUser.uid
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم بنجاح'),
    ));
  }

  void showMap() {
    bool approve = context.read<User>().approveLocations;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                PopupMenuButton(
                  itemBuilder: (context) => approve
                      ? [
                          PopupMenuItem(
                            value: true,
                            child: Text(street.locationConfirmed
                                ? 'عدم تأكيد الموقع'
                                : 'تأكيد الموقع'),
                          ),
                        ]
                      : [],
                  onSelected: (item) async {
                    if (item && approve) {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: LinearProgressIndicator(),
                        ));
                        await street.ref.update(
                            {'LocationConfirmed': !street.locationConfirmed});
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم الحفظ بنجاح'),
                          ),
                        );
                      } catch (err, stkTrace) {
                        await FirebaseCrashlytics.instance
                            .setCustomKey('LastErrorIn', 'StreetInfo.showMap');
                        await FirebaseCrashlytics.instance
                            .recordError(err, stkTrace);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              err.toString(),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
              title: Text('مكان ${street.name} على الخريطة'),
            ),
            body: street.getMapView(),
          );
        },
      ),
    );
  }
}
