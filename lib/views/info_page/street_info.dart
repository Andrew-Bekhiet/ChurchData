import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/double_circular_notched_bhape.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/history_property.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

class StreetInfo extends StatelessWidget {
  final Street street;
  final Map showWarning = <String, bool>{'p1': true};

  final BehaviorSubject<String> _searchStream =
      BehaviorSubject<String>.seeded('');
  final BehaviorSubject<OrderOptions> _orderOptions =
      BehaviorSubject<OrderOptions>.seeded(OrderOptions());

  StreetInfo({Key key, this.street}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!street.locationConfirmed &&
          street.locationPoints != null &&
          showWarning['p1']) {
        showWarning['p1'] = false;
        showDialog(
          context: context,
          builder: (context) => DataDialog(
            content: Text('لم يتم تأكيد موقع الشارع الموجود على الخريطة'),
            title: Text('تحذير'),
          ),
        );
      }
    });

    var _listOptions = DataObjectListOptions<Family>(
      searchQuery: _searchStream,
      tap: (family) => familyTap(family, context),
      itemsStream: _orderOptions.flatMap(
        (o) => street
            .getMembersLive(orderBy: o.orderBy, descending: !o.asc)
            .map((s) => s.docs.map(Family.fromDoc).toList()),
      ),
    );

    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, permission, _) => StreamBuilder<Street>(
        initialData: street,
        stream: street.ref.snapshots().map(Street.fromDoc),
        builder: (context, snapshot) {
          final Street street = snapshot.data;
          if (street == null)
            return Scaffold(
              body: Center(
                child: Text('تم حذف الشارع'),
              ),
            );
          return Scaffold(
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
            body: NestedScrollView(
              headerSliverBuilder: (context, x) {
                return <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        ListTile(
                          title: Hero(
                            tag: street.id + '-name',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                street.name,
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ),
                          ),
                        ),
                        if (street.locationPoints != null)
                          ElevatedButton.icon(
                            icon: Icon(Icons.map),
                            onPressed: () => showMap(context),
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
                              ? AsyncDataObjectWidget<Area>(
                                  street.areaId, Area.fromDoc)
                              : Text('غير موجودة'),
                        ),
                        Divider(
                          thickness: 1,
                        ),
                        Text('العائلات بالشارع:',
                            style: Theme.of(context).textTheme.bodyText1),
                        SearchFilters(2,
                            orderOptions: _orderOptions,
                            options: _listOptions,
                            searchStream: _searchStream,
                            textStyle: Theme.of(context).textTheme.bodyText2),
                      ],
                    ),
                  ),
                ];
              },
              body: SafeArea(
                child: DataObjectList<Family>(
                  options: _listOptions,
                ),
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              color: Theme.of(context).primaryColor,
              shape: const DoubleCircularNotchedButton(),
              child: StreamBuilder(
                stream: _listOptions.objectsData,
                builder: (context, snapshot) {
                  return Text(
                    (snapshot.data?.length ?? 0).toString() + ' شخص',
                    textAlign: TextAlign.center,
                    strutStyle:
                        StrutStyle(height: IconTheme.of(context).size / 7.5),
                    style: Theme.of(context).primaryTextTheme.bodyText1,
                  );
                },
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,
            floatingActionButton: permission
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 32),
                        child: FloatingActionButton(
                          tooltip: 'تسجيل أخر زيارة اليوم',
                          heroTag: 'lastVisit',
                          onPressed: () => recordLastVisit(context, street),
                          child: Icon(Icons.update),
                        ),
                      ),
                      PopupMenuButton<bool>(
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: true,
                            child: ListTile(
                              leading: Icon(Icons.add_business),
                              title: Text('اضافة محل'),
                            ),
                          ),
                          PopupMenuItem(
                            value: false,
                            child: ListTile(
                              leading: Icon(Icons.group_add),
                              title: Text('اضافة عائلة'),
                            ),
                          )
                        ],
                        onSelected: (type) => Navigator.of(context).pushNamed(
                          'Data/EditFamily',
                          arguments: {'IsStore': type, 'StreetId': street.ref},
                        ),
                        child: FloatingActionButton(
                          onPressed: null,
                          child: Icon(Icons.add),
                        ),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  void recordLastVisit(BuildContext context, Street street) async {
    if (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('هل تريد تسجيل أخر زيارة ل' + street.name + '?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('تسجيل أخر زيارة'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('رجوع'),
              ),
            ],
          ),
        ) !=
        true) return;
    await street.ref.update({
      'LastVisit': Timestamp.now(),
      'LastEdit': FirebaseAuth.instance.currentUser.uid
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم بنجاح'),
    ));
  }

  void showMap(BuildContext context) {
    bool approve = User.instance.approveLocations;
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
                        await street.ref.update({
                          'LocationConfirmed': !street.locationConfirmed,
                          'LastEdit': User.instance.uid
                        });
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
