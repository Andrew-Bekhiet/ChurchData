import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/double_circular_notched_bhape.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/history_property.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

class StreetInfo extends StatefulWidget {
  final Street street;

  StreetInfo({Key? key, required this.street}) : super(key: key);

  @override
  _StreetInfoState createState() => _StreetInfoState();
}

class _StreetInfoState extends State<StreetInfo> {
  bool showWarning = true;

  final BehaviorSubject<OrderOptions> _orderOptions =
      BehaviorSubject<OrderOptions>.seeded(OrderOptions());
  late final DataObjectListController<Family> _listOptions;

  @override
  void initState() {
    super.initState();
    if (!widget.street.locationConfirmed &&
        widget.street.locationPoints.isNotEmpty &&
        showWarning) {
      WidgetsBinding.instance!.addPostFrameCallback(
        (_) {
          showWarning = false;
          showDialog(
            context: context,
            builder: (context) => DataDialog(
              content: Text('لم يتم تأكيد موقع الشارع الموجود على الخريطة'),
              title: Text('تحذير'),
            ),
          );
        },
      );
    }
    _listOptions = DataObjectListController<Family>(
      tap: familyTap,
      itemsStream: _orderOptions.switchMap(
        (o) => widget.street
            .getMembersLive(orderBy: o.orderBy, descending: !o.asc)
            .map((s) => s.docs.map(Family.fromQueryDoc).toList()),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _listOptions.dispose();
    await _orderOptions.close();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, permission, _) => StreamBuilder<Street?>(
        initialData: widget.street,
        stream: widget.street.ref.snapshots().map(Street.fromDoc),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Scaffold(
              body: Center(
                child: Text('تم حذف الشارع'),
              ),
            );

          final Street street = snapshot.data!;

          return Scaffold(
            appBar: AppBar(
              backgroundColor:
                  street.color != Colors.transparent ? street.color : null,
              title: Text(street.name),
              actions: street.ref.path.startsWith('Deleted')
                  ? <Widget>[
                      if (permission)
                        IconButton(
                          icon: Icon(Icons.restore),
                          tooltip: 'استعادة',
                          onPressed: () {
                            recoverDoc(context, street.ref.path);
                          },
                        )
                    ]
                  : <Widget>[
                      if (permission)
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            dynamic result = await navigator.currentState!
                                .pushNamed('Data/EditStreet',
                                    arguments: street);
                            if (result == null) return;

                            scaffoldMessenger.currentState!
                                .hideCurrentSnackBar();
                            if (result is JsonRef) {
                              scaffoldMessenger.currentState!.showSnackBar(
                                SnackBar(
                                  content: Text('تم الحفظ بنجاح'),
                                ),
                              );
                            } else if (result == 'deleted') {
                              navigator.currentState!.pop();
                              scaffoldMessenger.currentState!.showSnackBar(
                                SnackBar(
                                  content: Text('تم الحذف بنجاح'),
                                ),
                              );
                            }
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
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverList(
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
                          if (street.locationPoints.isNotEmpty)
                            ElevatedButton.icon(
                              icon: Icon(Icons.map),
                              onPressed: () => showMap(context, street),
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
                                    street.areaId!.parent.id != 'null'
                                ? AsyncDataObjectWidget<Area>(
                                    street.areaId!, Area.fromDoc)
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
                              textStyle: Theme.of(context).textTheme.bodyText2),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: SafeArea(
                child: street.ref.path.startsWith('Deleted')
                    ? Text('يجب استعادة الشارع لرؤية العائلات بداخله')
                    : DataObjectList<Family>(
                        options: _listOptions,
                        autoDisposeController: false,
                      ),
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              shape: const DoubleCircularNotchedButton(),
              child: StreamBuilder<List>(
                stream: _listOptions.objectsData,
                builder: (context, snapshot) {
                  return Text(
                    (snapshot.data?.length ?? 0).toString() + ' شخص',
                    textAlign: TextAlign.center,
                    strutStyle:
                        StrutStyle(height: IconTheme.of(context).size! / 7.5),
                    style: Theme.of(context).primaryTextTheme.bodyText1,
                  );
                },
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,
            floatingActionButton: permission &&
                    !street.ref.path.startsWith('Deleted')
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
                        onSelected: (type) async {
                          dynamic result =
                              await navigator.currentState!.pushNamed(
                            'Data/EditFamily',
                            arguments: {
                              'IsStore': type,
                              'StreetId': street.ref
                            },
                          );

                          if (result == null) return;

                          scaffoldMessenger.currentState!.hideCurrentSnackBar();
                          if (result is JsonRef) {
                            scaffoldMessenger.currentState!.showSnackBar(
                              SnackBar(
                                content: Text('تم الحفظ بنجاح'),
                              ),
                            );
                          }
                        },
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
            title: Text('هل تريد تسجيل أخر زيارة ل' + street.name + '؟'),
            actions: [
              TextButton(
                onPressed: () => navigator.currentState!.pop(true),
                child: Text('تسجيل أخر زيارة'),
              ),
              TextButton(
                onPressed: () => navigator.currentState!.pop(false),
                child: Text('رجوع'),
              ),
            ],
          ),
        ) !=
        true) return;
    await street.ref.update({
      'LastVisit': Timestamp.now(),
      'LastEdit': firebaseAuth.currentUser!.uid
    });
    scaffoldMessenger.currentState!.showSnackBar(SnackBar(
      content: Text('تم بنجاح'),
    ));
  }

  void showMap(BuildContext context, Street street) {
    bool approve = User.instance.approveLocations;
    navigator.currentState!.push(
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                if (approve)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: true,
                        child: Text(street.locationConfirmed
                            ? 'عدم تأكيد الموقع'
                            : 'تأكيد الموقع'),
                      ),
                    ],
                    onSelected: (item) async {
                      if (item == true && approve) {
                        try {
                          scaffoldMessenger.currentState!.showSnackBar(SnackBar(
                            content: LinearProgressIndicator(),
                          ));
                          await street.ref.update({
                            'LocationConfirmed': !street.locationConfirmed,
                            'LastEdit': User.instance.uid
                          });
                          scaffoldMessenger.currentState!.hideCurrentSnackBar();
                          scaffoldMessenger.currentState!.showSnackBar(
                            SnackBar(
                              content: Text('تم الحفظ بنجاح'),
                            ),
                          );
                        } catch (err, stkTrace) {
                          await FirebaseCrashlytics.instance.setCustomKey(
                              'LastErrorIn', 'StreetInfo.showMap');
                          await FirebaseCrashlytics.instance
                              .recordError(err, stkTrace);
                          scaffoldMessenger.currentState!.hideCurrentSnackBar();
                          scaffoldMessenger.currentState!.showSnackBar(
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
