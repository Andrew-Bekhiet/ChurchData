import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/double_circular_notched_bhape.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/globals.dart';
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
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

class FamilyInfo extends StatefulWidget {
  final Family family;

  FamilyInfo({Key key, this.family}) : super(key: key);

  @override
  _FamilyInfoState createState() => _FamilyInfoState();
}

class _FamilyInfoState extends State<FamilyInfo> {
  final BehaviorSubject<String> _searchStream =
      BehaviorSubject<String>.seeded('');

  final BehaviorSubject<OrderOptions> _orderOptions =
      BehaviorSubject<OrderOptions>.seeded(OrderOptions());

  bool showWarning = true;

  @override
  void initState() {
    super.initState();
    if (!widget.family.locationConfirmed &&
        widget.family.locationPoint != null &&
        showWarning) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          showWarning = false;
          showDialog(
            context: context,
            builder: (context) => DataDialog(
              content: Text('لم يتم تأكيد موقع ال' +
                  (widget.family.isStore ? 'محل' : 'عائلة') +
                  ' الموجود على الخريطة'),
              title: Text('تحذير'),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, permission, _) => StreamBuilder<Family>(
        initialData: widget.family,
        stream: widget.family.ref.snapshots().map(Family.fromDoc),
        builder: (context, snapshot) {
          final Family family = snapshot.data;
          if (family == null)
            return Scaffold(
              body: Center(
                child: Text('تم حذف العائلة'),
              ),
            );

          final _listOptions = DataObjectListOptions(
            searchQuery: _searchStream,
            tap: (person) => personTap(person, context),
            itemsStream: _orderOptions.switchMap(
              (o) => family
                  .getMembersLive(orderBy: o.orderBy, descending: !o.asc)
                  .map((s) => s
                      .map((s) => s.docs
                          .map((e) => e.reference.parent.id == 'Persons'
                              ? Person.fromDoc(e)
                              : Family.fromDoc(e))
                          .toList())
                      .expand((e) => e)
                      .toList()
                      .cast<DataObject>()),
            ),
          );

          return Scaffold(
            appBar: AppBar(
              backgroundColor:
                  family.color != Colors.transparent ? family.color : null,
              title: Text(family.name),
              actions: family.ref.path.startsWith('Deleted')
                  ? <Widget>[
                      if (permission)
                        IconButton(
                          icon: Icon(Icons.restore),
                          tooltip: 'استعادة',
                          onPressed: () {
                            recoverDoc(context, family.ref.path);
                          },
                        )
                    ]
                  : <Widget>[
                      if (permission)
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            dynamic result = await Navigator.of(context)
                                .pushNamed('Data/EditFamily',
                                    arguments: family);
                            if (result == null) return;

                            ScaffoldMessenger.of(mainScfld.currentContext)
                                .hideCurrentSnackBar();
                            if (result is DocumentReference) {
                              ScaffoldMessenger.of(mainScfld.currentContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text('تم الحفظ بنجاح'),
                                ),
                              );
                            } else if (result == 'deleted') {
                              Navigator.of(mainScfld.currentContext).pop();
                              ScaffoldMessenger.of(mainScfld.currentContext)
                                  .showSnackBar(
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
                            await shareFamily(family),
                          );
                        },
                        tooltip: 'مشاركة برابط',
                      ),
                      PopupMenuButton(
                        onSelected: (_) => sendNotification(context, family),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              value: '',
                              child: Text('ارسال إشعار للمستخدمين عن ال' +
                                  (family.isStore ? 'محل' : 'عائلة') +
                                  ''),
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
                            tag: family.id + '-name',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                family.name,
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ),
                          ),
                        ),
                        if ((family.address ?? '') != '')
                          ListTile(
                            title: Text('العنوان'),
                            subtitle: Text(family.address),
                            trailing: IconButton(
                              icon: Icon(Icons.copy),
                              tooltip: 'نسخ',
                              onPressed: () => Clipboard.setData(
                                  ClipboardData(text: family.address ?? '')),
                            ),
                          ),
                        if ((family.notes ?? '') != '')
                          ListTile(
                            title: Text('ملاحظات'),
                            subtitle: Text(family.notes),
                            trailing: IconButton(
                              icon: Icon(Icons.copy),
                              tooltip: 'نسخ',
                              onPressed: () => Clipboard.setData(
                                  ClipboardData(text: family.notes ?? '')),
                            ),
                          ),
                        if (family.locationPoint != null)
                          ElevatedButton.icon(
                            icon: Icon(Icons.map),
                            onPressed: () => showMap(context, family),
                            label: Text('إظهار على الخريطة'),
                          ),
                        Divider(thickness: 1),
                        HistoryProperty('تاريخ أخر زيارة:', family.lastVisit,
                            family.ref.collection('VisitHistory')),
                        HistoryProperty(
                            'تاريخ أخر زيارة (لللأب الكاهن):',
                            family.fatherLastVisit,
                            family.ref.collection('FatherVisitHistory')),
                        EditHistoryProperty(
                            'أخر تحديث للبيانات:',
                            family.lastEdit,
                            family.ref.collection('EditHistory')),
                        Divider(thickness: 1),
                        ListTile(
                          title: Text('داخل منطقة'),
                          subtitle: family.areaId != null &&
                                  family.areaId.parent.id != 'null'
                              ? AsyncDataObjectWidget<Area>(
                                  family.areaId, Area.fromDoc)
                              : Text('غير موجودة'),
                        ),
                        ListTile(
                          title: Text('داخل شارع'),
                          subtitle: family.streetId != null &&
                                  family.streetId.parent.id != 'null'
                              ? AsyncDataObjectWidget<Street>(
                                  family.streetId, Street.fromDoc)
                              : Text('غير موجود'),
                        ),
                        if (family.insideFamily != null &&
                            family.insideFamily.parent.id != 'null')
                          ListTile(
                            title: Text(family.isStore
                                ? 'ادارة المحل'
                                : 'داخل ' +
                                    (family.isStore ? 'محل' : 'عائلة') +
                                    ''),
                            subtitle: AsyncDataObjectWidget<Family>(
                                family.insideFamily, Family.fromDoc),
                          ),
                        if (family.insideFamily2 != null &&
                            family.insideFamily2.parent.id != 'null')
                          ListTile(
                            title: Text('داخل عائلة 2'),
                            subtitle: AsyncDataObjectWidget<Family>(
                                family.insideFamily2, Family.fromDoc),
                          ),
                        Divider(thickness: 1),
                        Text(
                            'الأشخاص بال' +
                                (family.isStore ? 'محل' : 'عائلة') +
                                '',
                            style: Theme.of(context).textTheme.bodyText1),
                        SearchFilters(3,
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
                child: family.ref.path.startsWith('Deleted')
                    ? Text('يجب استعادة العائلة لرؤية الأشخاص بداخلها')
                    : DataObjectList(
                        options: _listOptions,
                      ),
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              color: Theme.of(context).primaryColor,
              shape: const DoubleCircularNotchedButton(),
              child: StreamBuilder<List<DataObject>>(
                stream: _listOptions.objectsData,
                builder: (context, snapshot) {
                  StringBuffer text = StringBuffer(
                      (snapshot.data?.whereType<Person>()?.length ?? 0)
                              .toString() +
                          ' شخص');
                  final int familiesCount = snapshot.data
                          ?.whereType<Family>()
                          ?.where((f) => !f.isStore)
                          ?.length ??
                      0;
                  if (familiesCount > 0) {
                    text.write(' و');
                    text.write(familiesCount.toString());
                    text.write(' عائلة');
                  }
                  final int storesCount = snapshot.data
                          ?.whereType<Family>()
                          ?.where((f) => f.isStore)
                          ?.length ??
                      0;
                  if (storesCount > 0) {
                    text.write(' و');
                    text.write(storesCount.toString());
                    text.write(' محل');
                  }
                  return Text(
                    text.toString(),
                    textAlign: TextAlign.center,
                    strutStyle:
                        StrutStyle(height: IconTheme.of(context).size / 7.5),
                    style: Theme.of(context).primaryTextTheme.bodyText1,
                  );
                },
              ),
            ),
            floatingActionButton: permission &&
                    !family.ref.path.startsWith('Deleted')
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 32),
                        child: FloatingActionButton(
                          tooltip: 'تسجيل أخر زيارة اليوم',
                          heroTag: 'lastVisit',
                          onPressed: () => recordLastVisit(context, family),
                          child: Icon(Icons.update),
                        ),
                      ),
                      PopupMenuButton<dynamic>(
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
                          ),
                          PopupMenuItem(
                            value: 'null',
                            child: ListTile(
                              leading: Icon(Icons.person_add),
                              title: Text('اضافة شخص'),
                            ),
                          )
                        ],
                        onSelected: (type) => type == 'null'
                            ? Navigator.of(context).pushNamed('Data/EditPerson',
                                arguments: family.ref)
                            : Navigator.of(context).pushNamed(
                                'Data/EditFamily',
                                arguments: {
                                  'Family': family.ref,
                                  'IsStore': type as bool
                                },
                              ),
                        child: FloatingActionButton(
                          onPressed: null,
                          child: Icon(Icons.add),
                        ),
                      ),
                    ],
                  )
                : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,
          );
        },
      ),
    );
  }

  void recordLastVisit(BuildContext context, Family family) async {
    if (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('هل تريد تسجيل أخر زيارة ل' + family.name + '?'),
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
    await family.ref.update({
      'LastVisit': Timestamp.now(),
      'LastEdit': FirebaseAuth.instance.currentUser.uid
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم بنجاح'),
    ));
  }

  void showMap(BuildContext context, Family family) {
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
                            child: Text(family.locationConfirmed
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
                        await family.ref.update({
                          'LocationConfirmed': !family.locationConfirmed,
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
                            .setCustomKey('LastErrorIn', 'FamilyInfo.showMap');
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
              title: Text('مكان ${family.name} على الخريطة'),
            ),
            body: family.getMapView(),
          );
        },
      ),
    );
  }
}
