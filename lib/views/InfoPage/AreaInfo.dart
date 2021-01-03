import 'dart:async';

import 'package:churchdata/Models.dart';
import 'package:churchdata/Models/Area.dart';
import 'package:churchdata/Models/SearchString.dart';
import 'package:churchdata/Models/User.dart';
import 'package:churchdata/utils/Helpers.dart';
import 'package:churchdata/views/utils/CopiableProperty.dart';
import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:churchdata/views/utils/HistoryProperty.dart';
import 'package:churchdata/views/utils/List.dart';
import 'package:churchdata/views/utils/SearchFilters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.io) 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class AreaInfo extends StatefulWidget {
  final Area area;
  AreaInfo({Key key, this.area}) : super(key: key);

  @override
  _AreaInfoState createState() => _AreaInfoState();
}

class _AreaInfoState extends State<AreaInfo> {
  Area area;
  bool showWarning = true;
  StreamSubscription<DocumentSnapshot> _listener;

  void addTap() {
    Navigator.of(context).pushNamed('Data/EditStreet', arguments: area.ref);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!area.locationConfirmed &&
          area.locationPoints != null &&
          showWarning) {
        showWarning = false;
        showDialog(
          context: context,
          builder: (context) => DataDialog(
            content: Text('لم يتم تأكيد موقع المنطقة الموجود على الخريطة'),
            title: Text('تحذير'),
          ),
        );
      }
    });

    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, permission, _) => Scaffold(
        body: ListenableProvider<SearchString>(
          create: (_) => SearchString(''),
          builder: (context, child) => NestedScrollView(
            headerSliverBuilder: (context, _) => <Widget>[
              SliverAppBar(
                backgroundColor:
                    area.color != Colors.transparent ? area.color : null,
                actions: <Widget>[
                  if (permission)
                    IconButton(
                      icon: IconShadowWidget(
                        Icon(
                          Icons.edit,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                      onPressed: () async {
                        dynamic result = await Navigator.of(context)
                            .pushNamed('Data/EditArea', arguments: area);
                        if (result is DocumentReference) {
                          area = await Area.fromId(result.id);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم الحفظ بنجاح'),
                            ),
                          );
                        } else if (result == 'deleted')
                          Navigator.of(context).pop();
                      },
                      tooltip: 'تعديل',
                    ),
                  IconButton(
                    icon: IconShadowWidget(
                      Icon(
                        Icons.share,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                    onPressed: () async {
                      await Share.share(
                        await shareArea(area),
                      );
                    },
                    tooltip: 'مشاركة برابط',
                  ),
                  PopupMenuButton(
                    onSelected: (_) => sendNotification(context, area),
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: '',
                          child: Text('ارسال إشعار للمستخدمين عن المنطقة'),
                        ),
                      ];
                    },
                  ),
                ],
                expandedHeight: 250.0,
                stretch: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                    title: Text(area.name), background: area.photo),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  <Widget>[
                    ListTile(
                      title: Hero(
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              area.name,
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ),
                          tag: area.id + '-name'),
                    ),
                    if ((area.address ?? '') != '')
                      CopiableProperty('العنوان:', area.address),
                    if (area.locationPoints != null)
                      ElevatedButton.icon(
                        icon: Icon(Icons.map),
                        onPressed: () => showMap(),
                        label: Text('إظهار على الخريطة'),
                      ),
                    Divider(thickness: 1),
                    HistoryProperty('تاريخ أخر زيارة:', area.lastVisit,
                        area.ref.collection('VisitHistory')),
                    HistoryProperty(
                        'تاريخ أخر زيارة (لللأب الكاهن):',
                        area.fatherLastVisit,
                        area.ref.collection('FatherVisitHistory')),
                    EditHistoryProperty('أخر تعديل بواسطة:', area.lastEdit,
                        area.ref.collection('EditHistory')),
                    Divider(thickness: 1),
                    Text('الشوارع بالمنطقة:',
                        style: Theme.of(context).textTheme.bodyText1),
                    SearchFilters(1),
                  ],
                ),
              ),
            ],
            body: SafeArea(
              child: Consumer<OrderOptions>(
                builder: (context, options, _) => DataObjectList<Street>(
                  options: ListOptions<Street>(
                      doubleActionButton: true,
                      floatingActionButton: permission
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 32),
                                  child: FloatingActionButton(
                                    child: Icon(Icons.update),
                                    tooltip: 'تسجيل أخر زيارة اليوم',
                                    heroTag: 'lastVisit',
                                    onPressed: recordLastVisit,
                                  ),
                                ),
                                FloatingActionButton(
                                  heroTag: null,
                                  onPressed: addTap,
                                  child: Icon(Icons.add_road),
                                ),
                              ],
                            )
                          : null,
                      generate: Street.fromDocumentSnapshot,
                      tap: streetTap,
                      documentsData: () => area.getMembersLive(
                          orderBy: options.streetOrderBy,
                          descending: !options.streetASC)),
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
    area = widget.area;
  }

  @override
  void dispose() {
    _listener?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _listener = widget.area.ref.snapshots().listen((event) {
      area = Area.fromDocumentSnapshot(event);
      if (mounted) setState(() {});
    });
  }

  void recordLastVisit() async {
    await area.ref.update({
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
                            child: Text(area.locationConfirmed
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
                        await area.ref.update(
                            {'LocationConfirmed': !area.locationConfirmed});
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم الحفظ بنجاح'),
                          ),
                        );
                      } catch (err, stkTrace) {
                        await FirebaseCrashlytics.instance
                            .setCustomKey('LastErrorIn', 'AreaInfo.showMap');
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
              title: Text('مكان ${area.name} على الخريطة'),
            ),
            body: area.getMapView(),
          );
        },
      ),
    );
  }
}
