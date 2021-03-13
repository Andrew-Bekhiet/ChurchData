import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/search_string.dart';
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
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class FamilyInfo extends StatelessWidget {
  final Family family;
  final Map showWarning = <String, bool>{'p1': true};

  FamilyInfo({Key key, this.family}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!family.locationConfirmed &&
          family.locationPoint != null &&
          showWarning['p1']) {
        showWarning['p1'] = false;
        showDialog(
          context: context,
          builder: (context) => DataDialog(
            content: Text('لم يتم تأكيد موقع ال' +
                (family.isStore ? 'محل' : 'عائلة') +
                ' الموجود على الخريطة'),
            title: Text('تحذير'),
          ),
        );
      }
    });

    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, permission, _) => StreamBuilder<Family>(
        initialData: family,
        stream: family.ref.snapshots().map(Family.fromDoc),
        builder: (context, snapshot) {
          final Family family = snapshot.data;
          if (family == null)
            return Scaffold(
              body: Center(
                child: Text('تم حذف العائلة'),
              ),
            );
          return Scaffold(
            appBar: AppBar(
              backgroundColor:
                  family.color != Colors.transparent ? family.color : null,
              title: Text(family.name),
              actions: <Widget>[
                if (permission)
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      dynamic result = await Navigator.of(context)
                          .pushNamed('Data/EditFamily', arguments: family);
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
                              onPressed: () => showMap(context),
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
                                ? FutureBuilder<Area>(
                                    future: Area.fromId(family.areaId.id),
                                    builder: (context, area) => area.hasData
                                        ? DataObjectWidget<Area>(area.data,
                                            isDense: true)
                                        : LinearProgressIndicator(),
                                  )
                                : Text('غير موجودة'),
                          ),
                          ListTile(
                            title: Text('داخل شارع'),
                            subtitle: family.streetId != null &&
                                    family.streetId.parent.id != 'null'
                                ? FutureBuilder<Street>(
                                    future: Street.fromId(family.streetId.id),
                                    builder: (context, street) => street.hasData
                                        ? DataObjectWidget<Street>(street.data,
                                            isDense: true)
                                        : LinearProgressIndicator(),
                                  )
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
                              subtitle: FutureBuilder<Family>(
                                future: Family.fromId(family.insideFamily.id),
                                builder: (context, family) => family.hasData
                                    ? DataObjectWidget<Family>(family.data)
                                    : (!family.hasError
                                        ? LinearProgressIndicator()
                                        : (family.error
                                                .toString()
                                                .toLowerCase()
                                                .contains('denied')
                                            ? Text('لا يمكن اظهار ال' +
                                                (this.family.isStore
                                                    ? 'محل'
                                                    : 'عائلة') +
                                                '')
                                            : Text('حدث خطأ'))),
                              ),
                            ),
                          if (family.insideFamily2 != null &&
                              family.insideFamily2.parent.id != 'null')
                            ListTile(
                              title: Text('داخل عائلة 2'),
                              subtitle: FutureBuilder<Family>(
                                future: Family.fromId(family.insideFamily2.id),
                                builder: (context, family) => family.hasData
                                    ? DataObjectWidget<Family>(family.data)
                                    : (!family.hasError
                                        ? LinearProgressIndicator()
                                        : (family.error
                                                .toString()
                                                .toLowerCase()
                                                .contains('denied')
                                            ? Text('لا يمكن اظهار العائلة')
                                            : Text('حدث خطأ'))),
                              ),
                            ),
                          Divider(thickness: 1),
                          Text(
                              'الأشخاص بال' +
                                  (family.isStore ? 'محل' : 'عائلة') +
                                  '',
                              style: Theme.of(context).textTheme.bodyText1),
                          SearchFilters(3),
                        ],
                      ),
                    ),
                  ];
                },
                body: SafeArea(
                  child: Consumer<OrderOptions>(
                    builder: (context, options, _) => DataObjectList<Person>(
                      options: ListOptions<Person>(
                          doubleActionButton: true,
                          floatingActionButton: permission
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 32),
                                      child: FloatingActionButton(
                                        tooltip: 'تسجيل أخر زيارة اليوم',
                                        heroTag: 'lastVisit',
                                        onPressed: () =>
                                            recordLastVisit(context, family),
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
                                          ? Navigator.of(context).pushNamed(
                                              'Data/EditPerson',
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
                          generate: (doc) {
                            if (doc.reference.parent.id == 'Persons')
                              return Person.fromDoc(doc);
                            if (doc.reference.parent.id == 'Families')
                              return Family.fromDoc(doc);
                            throw UnimplementedError();
                          },
                          familiesData: family.getMembersLive(
                              orderBy: options.personOrderBy,
                              descending: !options.personASC)),
                    ),
                  ),
                ),
              ),
            ),
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
                        await family.ref.update(
                            {'LocationConfirmed': !family.locationConfirmed});
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
