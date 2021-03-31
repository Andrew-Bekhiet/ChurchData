import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/double_circular_notched_bhape.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata/models/copiable_property.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/history_property.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

class AreaInfo extends StatefulWidget {
  final Area area;

  AreaInfo({Key key, this.area}) : super(key: key);

  @override
  _AreaInfoState createState() => _AreaInfoState();
}

class _AreaInfoState extends State<AreaInfo> {
  final BehaviorSubject<String> _searchStream =
      BehaviorSubject<String>.seeded('');

  final BehaviorSubject<OrderOptions> _orderOptions =
      BehaviorSubject<OrderOptions>.seeded(OrderOptions());

  bool showWarning = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        if (!widget.area.locationConfirmed &&
            widget.area.locationPoints != null &&
            showWarning) {
          showWarning = false;
          await showDialog(
            context: context,
            builder: (context) => DataDialog(
              content: Text('لم يتم تأكيد موقع المنطقة الموجود على الخريطة'),
              title: Text('تحذير'),
            ),
          );
        }
        FeatureDiscovery.discoverFeatures(context, [
          if (User.instance.write) 'Edit',
          'Share',
          'MoreOptions',
          'EditHistory',
          if (User.instance.write) 'LastVisit',
          if (User.instance.write) 'Add'
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, permission, _) {
        return StreamBuilder<Area>(
          initialData: widget.area,
          stream: widget.area.ref.snapshots().map(Area.fromDoc),
          builder: (context, snapshot) {
            final Area area = snapshot.data;
            if (area == null)
              return Scaffold(
                body: Center(
                  child: Text('تم حذف المنطقة'),
                ),
              );
            final _listOptions = DataObjectListOptions<Street>(
              searchQuery: _searchStream,
              tap: (street) => streetTap(street, context),
              itemsStream: _orderOptions.switchMap(
                (o) => area
                    .getMembersLive(orderBy: o.orderBy, descending: !o.asc)
                    .map((s) => s.docs.map(Street.fromDoc).toList()),
              ),
            );
            return Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, _) => <Widget>[
                  SliverAppBar(
                    backgroundColor:
                        area.color != Colors.transparent ? area.color : null,
                    actions: area.ref.path.startsWith('Deleted')
                        ? <Widget>[
                            if (permission)
                              IconButton(
                                icon: Icon(Icons.restore),
                                tooltip: 'استعادة',
                                onPressed: () {
                                  recoverDoc(context, area.ref.path);
                                },
                              )
                          ]
                        : <Widget>[
                            if (permission)
                              IconButton(
                                icon: DescribedFeatureOverlay(
                                  backgroundDismissible: false,
                                  barrierDismissible: false,
                                  contentLocation: ContentLocation.below,
                                  featureId: 'Edit',
                                  tapTarget: Icon(
                                    Icons.edit,
                                    color: IconTheme.of(context).color,
                                  ),
                                  title: Text('تعديل'),
                                  description: Column(
                                    children: <Widget>[
                                      Text('يمكنك تعديل البيانات من هنا'),
                                      OutlinedButton.icon(
                                        icon: Icon(Icons.forward),
                                        label: Text(
                                          'التالي',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .color,
                                          ),
                                        ),
                                        onPressed: () => FeatureDiscovery
                                            .completeCurrentStep(context),
                                      ),
                                      OutlinedButton(
                                        onPressed: () =>
                                            FeatureDiscovery.dismissAll(
                                                context),
                                        child: Text(
                                          'تخطي',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                      Theme.of(context).accentColor,
                                  targetColor: Colors.transparent,
                                  textColor: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText1
                                      .color,
                                  child: Builder(
                                    builder: (context) => IconShadowWidget(
                                      Icon(
                                        Icons.edit,
                                        color: IconTheme.of(context).color,
                                      ),
                                    ),
                                  ),
                                ),
                                onPressed: () async {
                                  dynamic result = await Navigator.of(context)
                                      .pushNamed('Data/EditArea',
                                          arguments: area);
                                  if (result == null) return;

                                  ScaffoldMessenger.of(mainScfld.currentContext)
                                      .hideCurrentSnackBar();
                                  if (result is DocumentReference) {
                                    ScaffoldMessenger.of(
                                            mainScfld.currentContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text('تم الحفظ بنجاح'),
                                      ),
                                    );
                                  } else if (result == 'deleted') {
                                    Navigator.of(mainScfld.currentContext)
                                        .pop();
                                    ScaffoldMessenger.of(
                                            mainScfld.currentContext)
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
                              icon: DescribedFeatureOverlay(
                                backgroundDismissible: false,
                                barrierDismissible: false,
                                contentLocation: ContentLocation.below,
                                featureId: 'Share',
                                tapTarget: Icon(
                                  Icons.share,
                                ),
                                title: Text('مشاركة البيانات'),
                                description: Column(
                                  children: <Widget>[
                                    Text(
                                        'يمكنك مشاركة البيانات بلينك يفتح البيانات مباشرة داخل البرنامج'),
                                    OutlinedButton.icon(
                                      icon: Icon(Icons.forward),
                                      label: Text(
                                        'التالي',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyText2
                                              .color,
                                        ),
                                      ),
                                      onPressed: () =>
                                          FeatureDiscovery.completeCurrentStep(
                                              context),
                                    ),
                                    OutlinedButton(
                                      onPressed: () =>
                                          FeatureDiscovery.dismissAll(context),
                                      child: Text(
                                        'تخطي',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyText2
                                              .color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Theme.of(context).accentColor,
                                targetColor: Colors.transparent,
                                textColor: Theme.of(context)
                                    .primaryTextTheme
                                    .bodyText1
                                    .color,
                                child: Builder(
                                  builder: (context) => IconShadowWidget(
                                    Icon(
                                      Icons.share,
                                      color: IconTheme.of(context).color,
                                    ),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                await Share.share(
                                  await shareArea(area),
                                );
                              },
                              tooltip: 'مشاركة برابط',
                            ),
                            DescribedFeatureOverlay(
                              backgroundDismissible: false,
                              barrierDismissible: false,
                              contentLocation: ContentLocation.below,
                              featureId: 'MoreOptions',
                              tapTarget: Icon(
                                Icons.more_vert,
                              ),
                              title: Text('المزيد من الخيارات'),
                              description: Column(
                                children: <Widget>[
                                  Text(
                                      'يمكنك ايجاد المزيد من الخيارات من هنا مثل: اشعار المستخدمين عن المنطقة'),
                                  OutlinedButton.icon(
                                    icon: Icon(Icons.forward),
                                    label: Text(
                                      'التالي',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .color,
                                      ),
                                    ),
                                    onPressed: () =>
                                        FeatureDiscovery.completeCurrentStep(
                                            context),
                                  ),
                                  OutlinedButton(
                                    onPressed: () =>
                                        FeatureDiscovery.dismissAll(context),
                                    child: Text(
                                      'تخطي',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Theme.of(context).accentColor,
                              targetColor: Colors.transparent,
                              textColor: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyText1
                                  .color,
                              child: PopupMenuButton(
                                onSelected: (_) =>
                                    sendNotification(context, area),
                                itemBuilder: (context) {
                                  return [
                                    PopupMenuItem(
                                      value: '',
                                      child: Text(
                                          'ارسال إشعار للمستخدمين عن المنطقة'),
                                    ),
                                  ];
                                },
                              ),
                            ),
                          ],
                    expandedHeight: 250.0,
                    stretch: true,
                    pinned: true,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) => FlexibleSpaceBar(
                          title: AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            opacity: constraints.biggest.height >
                                    kToolbarHeight * 1.7
                                ? 0
                                : 1,
                            child: Text(area.name),
                          ),
                          background: area.photo),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        ListTile(
                          title: Hero(
                            tag: area.id + '-name',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                area.name,
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ),
                          ),
                        ),
                        if ((area.address ?? '') != '')
                          CopiableProperty('العنوان:', area.address),
                        if (area.locationPoints != null)
                          ElevatedButton.icon(
                            icon: Icon(Icons.map),
                            onPressed: () => showMap(context, area),
                            label: Text('إظهار على الخريطة'),
                          ),
                        Divider(thickness: 1),
                        HistoryProperty('تاريخ أخر زيارة:', area.lastVisit,
                            area.ref.collection('VisitHistory')),
                        HistoryProperty(
                            'تاريخ أخر زيارة (لللأب الكاهن):',
                            area.fatherLastVisit,
                            area.ref.collection('FatherVisitHistory')),
                        EditHistoryProperty(
                          'أخر تحديث للبيانات:',
                          area.lastEdit,
                          area.ref.collection('EditHistory'),
                          discoverFeature: true,
                        ),
                        Divider(thickness: 1),
                        Text('الشوارع بالمنطقة:',
                            style: Theme.of(context).textTheme.bodyText1),
                        SearchFilters(1,
                            orderOptions: _orderOptions,
                            options: _listOptions,
                            searchStream: _searchStream,
                            textStyle: Theme.of(context).textTheme.bodyText2),
                      ],
                    ),
                  ),
                ],
                body: SafeArea(
                  child: area.ref.path.startsWith('Deleted')
                      ? Text('يجب استعادة المنطقة لرؤية الشوراع بداخلها')
                      : DataObjectList<Street>(
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
              floatingActionButton: permission &&
                      !area.ref.path.startsWith('Deleted')
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 32),
                          child: FloatingActionButton(
                            tooltip: 'تسجيل أخر زيارة اليوم',
                            heroTag: 'lastVisit',
                            onPressed: () => recordLastVisit(context, area),
                            child: DescribedFeatureOverlay(
                              backgroundDismissible: false,
                              barrierDismissible: false,
                              contentLocation: ContentLocation.above,
                              featureId: 'LastVisit',
                              tapTarget: Icon(Icons.update),
                              title: Text('تسجيل تاريخ أخر زيارة'),
                              description: Column(
                                children: <Widget>[
                                  Text(
                                      'يمكنك تسجيل تاريخ أخر زيارة من هنا بشكل مباشر'),
                                  OutlinedButton.icon(
                                    icon: Icon(Icons.forward),
                                    label: Text(
                                      'التالي',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .color,
                                      ),
                                    ),
                                    onPressed: () =>
                                        FeatureDiscovery.completeCurrentStep(
                                            context),
                                  ),
                                  OutlinedButton(
                                    onPressed: () =>
                                        FeatureDiscovery.dismissAll(context),
                                    child: Text(
                                      'تخطي',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Theme.of(context).accentColor,
                              targetColor: Theme.of(context).primaryColor,
                              textColor: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyText1
                                  .color,
                              child: Icon(Icons.update),
                            ),
                          ),
                        ),
                        FloatingActionButton(
                          heroTag: null,
                          onPressed: () => Navigator.of(context).pushNamed(
                              'Data/EditStreet',
                              arguments: area.ref),
                          child: DescribedFeatureOverlay(
                            onBackgroundTap: () async {
                              await FeatureDiscovery.completeCurrentStep(
                                  context);
                              return true;
                            },
                            onDismiss: () async {
                              await FeatureDiscovery.completeCurrentStep(
                                  context);
                              return true;
                            },
                            backgroundDismissible: true,
                            contentLocation: ContentLocation.above,
                            featureId: 'Add',
                            tapTarget: Icon(Icons.add_road),
                            title: Text('اضافة شارع'),
                            description: Column(
                              children: [
                                Text(
                                    'يمكنك اضافة شارع داخل المنطقة بسرعة وسهولة من هنا'),
                                OutlinedButton(
                                  onPressed: () =>
                                      FeatureDiscovery.completeCurrentStep(
                                          context),
                                  child: Text(
                                    'تخطي',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyText2
                                          .color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Theme.of(context).accentColor,
                            targetColor: Theme.of(context).primaryColor,
                            textColor: Theme.of(context)
                                .primaryTextTheme
                                .bodyText1
                                .color,
                            child: Icon(Icons.add_road),
                          ),
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  void recordLastVisit(BuildContext context, Area area) async {
    if (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('هل تريد تسجيل أخر زيارة ل' + area.name + '?'),
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
    await area.ref.update({
      'LastVisit': Timestamp.now(),
      'LastEdit': FirebaseAuth.instance.currentUser.uid
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم بنجاح'),
    ));
  }

  void showMap(BuildContext context, Area area) {
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
                        await area.ref.update({
                          'LocationConfirmed': !area.locationConfirmed,
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
