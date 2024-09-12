import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/double_circular_notched_bhape.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/history_property.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

class FamilyInfo extends StatefulWidget {
  final Family family;

  const FamilyInfo({required this.family, super.key});

  @override
  _FamilyInfoState createState() => _FamilyInfoState();
}

class _FamilyInfoState extends State<FamilyInfo> {
  final BehaviorSubject<OrderOptions> _orderOptions =
      BehaviorSubject<OrderOptions>.seeded(const OrderOptions());

  late final DataObjectListController _listOptions;

  bool showWarning = true;

  @override
  Future<void> dispose() async {
    super.dispose();
    await _listOptions.dispose();
    await _orderOptions.close();
  }

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
              content: Text(
                'لم يتم تأكيد موقع ال' +
                    (widget.family.isStore ? 'محل' : 'عائلة') +
                    ' الموجود على الخريطة',
              ),
              title: const Text('تحذير'),
            ),
          );
        },
      );
    }
    _listOptions = DataObjectListController(
      tap: dataObjectTap,
      itemsStream: _orderOptions.switchMap(
        (o) => widget.family
            .getMembersLive(orderBy: o.orderBy, descending: !o.asc)
            .map(
              (s) => s
                  .map(
                    (s) => s.docs
                        .map(
                          (e) => e.reference.parent.id == 'Persons'
                              ? Person.fromDoc(e)
                              : Family.fromDoc(e),
                        )
                        .toList(),
                  )
                  .expand((e) => e)
                  .toList()
                  .cast<DataObject>(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, permission, _) => StreamBuilder<Family?>(
        initialData: widget.family,
        stream: widget.family.ref.snapshots().map(Family.fromDoc),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Scaffold(
              body: Center(
                child: Text('تم حذف العائلة'),
              ),
            );

          final Family family = snapshot.data!;

          return Scaffold(
            appBar: AppBar(
              backgroundColor:
                  family.color != Colors.transparent ? family.color : null,
              title: Text(family.name),
              actions: family.ref.path.startsWith('Deleted')
                  ? <Widget>[
                      if (permission)
                        IconButton(
                          icon: const Icon(Icons.restore),
                          tooltip: 'استعادة',
                          onPressed: () {
                            recoverDoc(context, family.ref.path);
                          },
                        ),
                    ]
                  : <Widget>[
                      if (permission)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final dynamic result =
                                await navigator.currentState!.pushNamed(
                              'Data/EditFamily',
                              arguments: family,
                            );
                            if (result == null) return;

                            scaffoldMessenger.currentState!
                                .hideCurrentSnackBar();
                            if (result is JsonRef) {
                              scaffoldMessenger.currentState!.showSnackBar(
                                const SnackBar(
                                  content: Text('تم الحفظ بنجاح'),
                                ),
                              );
                            } else if (result == 'deleted') {
                              navigator.currentState!.pop();
                              scaffoldMessenger.currentState!.showSnackBar(
                                const SnackBar(
                                  content: Text('تم الحذف بنجاح'),
                                ),
                              );
                            }
                          },
                          tooltip: 'تعديل',
                        ),
                      IconButton(
                        icon: const Icon(Icons.share),
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
                              child: Text(
                                'ارسال إشعار للمستخدمين عن ال' +
                                    (family.isStore ? 'محل' : 'عائلة') +
                                    '',
                              ),
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
                              tag: family.id + '-name',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(
                                  family.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            title: const Text('العنوان'),
                            subtitle: Text(family.address ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: 'نسخ',
                              onPressed: () => Clipboard.setData(
                                ClipboardData(text: family.address ?? ''),
                              ),
                            ),
                          ),
                          if (family.notes?.isNotEmpty ?? false)
                            ListTile(
                              title: const Text('ملاحظات'),
                              subtitle: Text(family.notes!),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'نسخ',
                                onPressed: () => Clipboard.setData(
                                  ClipboardData(text: family.notes ?? ''),
                                ),
                              ),
                            ),
                          if (family.locationPoint != null)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.map),
                              onPressed: () => showMap(context, family),
                              label: const Text('إظهار على الخريطة'),
                            ),
                          const Divider(thickness: 1),
                          HistoryProperty(
                            'تاريخ أخر زيارة:',
                            family.lastVisit,
                            family.ref.collection('VisitHistory'),
                          ),
                          HistoryProperty(
                            'تاريخ أخر زيارة (لللأب الكاهن):',
                            family.fatherLastVisit,
                            family.ref.collection('FatherVisitHistory'),
                          ),
                          EditHistoryProperty(
                            'أخر تحديث للبيانات:',
                            family.lastEdit,
                            family.ref.collection('EditHistory'),
                          ),
                          const Divider(thickness: 1),
                          ListTile(
                            title: const Text('داخل منطقة'),
                            subtitle: family.areaId != null &&
                                    family.areaId!.parent.id != 'null'
                                ? AsyncDataObjectWidget<Area>(
                                    family.areaId!,
                                    Area.fromDoc,
                                  )
                                : const Text('غير موجودة'),
                          ),
                          ListTile(
                            title: const Text('داخل شارع'),
                            subtitle: family.streetId != null &&
                                    family.streetId!.parent.id != 'null'
                                ? AsyncDataObjectWidget<Street>(
                                    family.streetId!,
                                    Street.fromDoc,
                                  )
                                : const Text('غير موجود'),
                          ),
                          if (family.insideFamily != null &&
                              family.insideFamily!.parent.id != 'null')
                            ListTile(
                              title: Text(
                                family.isStore
                                    ? 'ادارة المحل'
                                    : 'داخل ' +
                                        (family.isStore ? 'محل' : 'عائلة') +
                                        '',
                              ),
                              subtitle: AsyncDataObjectWidget<Family>(
                                family.insideFamily!,
                                Family.fromDoc,
                              ),
                            ),
                          if (family.insideFamily2 != null &&
                              family.insideFamily2!.parent.id != 'null')
                            ListTile(
                              title: const Text('داخل عائلة 2'),
                              subtitle: AsyncDataObjectWidget<Family>(
                                family.insideFamily2!,
                                Family.fromDoc,
                              ),
                            ),
                          const Divider(thickness: 1),
                          Text(
                            'الأشخاص بال' +
                                (family.isStore ? 'محل' : 'عائلة') +
                                '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SearchFilters(
                            3,
                            orderOptions: _orderOptions,
                            options: _listOptions,
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: SafeArea(
                child: family.ref.path.startsWith('Deleted')
                    ? const Text('يجب استعادة العائلة لرؤية الأشخاص بداخلها')
                    : DataObjectList(
                        options: _listOptions,
                        autoDisposeController: false,
                      ),
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              shape: const DoubleCircularNotchedButton(),
              child: StreamBuilder<List<DataObject>>(
                stream: _listOptions.objectsData,
                builder: (context, snapshot) {
                  final StringBuffer text = StringBuffer(
                    (snapshot.data?.whereType<Person>().length ?? 0)
                            .toString() +
                        ' شخص',
                  );
                  final int familiesCount = snapshot.data
                          ?.whereType<Family>()
                          .where((f) => !f.isStore)
                          .length ??
                      0;
                  if (familiesCount > 0) {
                    text
                      ..write(' و')
                      ..write(familiesCount.toString())
                      ..write(' عائلة');
                  }
                  final int storesCount = snapshot.data
                          ?.whereType<Family>()
                          .where((f) => f.isStore)
                          .length ??
                      0;
                  if (storesCount > 0) {
                    text
                      ..write(' و')
                      ..write(storesCount.toString())
                      ..write(' محل');
                  }
                  return Text(
                    text.toString(),
                    textAlign: TextAlign.center,
                    strutStyle:
                        StrutStyle(height: IconTheme.of(context).size! / 7.5),
                    style: Theme.of(context).primaryTextTheme.bodyLarge,
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
                        padding: const EdgeInsets.only(right: 32),
                        child: FloatingActionButton(
                          tooltip: 'تسجيل أخر زيارة اليوم',
                          heroTag: 'lastVisit',
                          onPressed: () => recordLastVisit(context, family),
                          child: const Icon(Icons.update),
                        ),
                      ),
                      PopupMenuButton<dynamic>(
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: true,
                            child: ListTile(
                              leading: Icon(Icons.add_business),
                              title: Text('اضافة محل'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: false,
                            child: ListTile(
                              leading: Icon(Icons.group_add),
                              title: Text('اضافة عائلة'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'null',
                            child: ListTile(
                              leading: Icon(Icons.person_add),
                              title: Text('اضافة شخص'),
                            ),
                          ),
                        ],
                        onSelected: (type) async {
                          final dynamic result = type == 'null'
                              ? await navigator.currentState!.pushNamed(
                                  'Data/EditPerson',
                                  arguments: family.ref,
                                )
                              : await navigator.currentState!.pushNamed(
                                  'Data/EditFamily',
                                  arguments: {
                                    'Family': family.ref,
                                    'IsStore': type as bool,
                                  },
                                );

                          if (result == null) return;

                          scaffoldMessenger.currentState!.hideCurrentSnackBar();
                          if (result is JsonRef) {
                            scaffoldMessenger.currentState!.showSnackBar(
                              const SnackBar(
                                content: Text('تم الحفظ بنجاح'),
                              ),
                            );
                          }
                        },
                        child: const FloatingActionButton(
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

  Future<void> recordLastVisit(BuildContext context, Family family) async {
    if (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('هل تريد تسجيل أخر زيارة ل' + family.name + '؟'),
            actions: [
              TextButton(
                onPressed: () => navigator.currentState!.pop(true),
                child: const Text('تسجيل أخر زيارة'),
              ),
              TextButton(
                onPressed: () => navigator.currentState!.pop(false),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ) !=
        true) return;
    await family.ref.update({
      'LastVisit': Timestamp.now(),
      'LastEdit': firebaseAuth.currentUser!.uid,
    });
    scaffoldMessenger.currentState!.showSnackBar(
      const SnackBar(
        content: Text('تم بنجاح'),
      ),
    );
  }

  void showMap(BuildContext context, Family family) {
    final bool approve = User.instance.approveLocations;
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
                        child: Text(
                          family.locationConfirmed
                              ? 'عدم تأكيد الموقع'
                              : 'تأكيد الموقع',
                        ),
                      ),
                    ],
                    onSelected: (item) async {
                      if (item && approve) {
                        try {
                          scaffoldMessenger.currentState!.showSnackBar(
                            const SnackBar(
                              content: LinearProgressIndicator(),
                            ),
                          );
                          await family.ref.update({
                            'LocationConfirmed': !family.locationConfirmed,
                            'LastEdit': User.instance.uid,
                          });
                          scaffoldMessenger.currentState!.hideCurrentSnackBar();
                          scaffoldMessenger.currentState!.showSnackBar(
                            const SnackBar(
                              content: Text('تم الحفظ بنجاح'),
                            ),
                          );
                        } catch (err, stkTrace) {
                          await FirebaseCrashlytics.instance.setCustomKey(
                            'LastErrorIn',
                            'FamilyInfo.showMap',
                          );
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
              title: Text('مكان ${family.name} على الخريطة'),
            ),
            body: family.getMapView(),
          );
        },
      ),
    );
  }
}
