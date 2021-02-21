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
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class AreaInfo extends StatelessWidget {
  final Area area;
  final Map showWarning = <String, bool>{'p1': true};

  AreaInfo({Key key, this.area}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!area.locationConfirmed &&
          area.locationPoints != null &&
          showWarning['p1']) {
        showWarning['p1'] = false;
        await showDialog(
          context: context,
          builder: (context) => DataDialog(
            content: Text('لم يتم تأكيد موقع المنطقة الموجود على الخريطة'),
            title: Text('تحذير'),
          ),
        );
      }
      FeatureDiscovery.discoverFeatures(context, [
        if (context.read<User>().write) 'Edit',
        'Share',
        'MoreOptions',
        'EditHistory',
        if (context.read<User>().write) 'LastVisit',
        if (context.read<User>().write) 'Add'
      ]);
    });

    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, permission, _) {
        return StreamBuilder<Area>(
          initialData: area,
          stream: area.ref.snapshots().map(Area.fromDoc),
          builder: (context, snapshot) {
            final Area area = snapshot.data;
            return Scaffold(
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
                                    onPressed: () =>
                                        FeatureDiscovery.completeCurrentStep(
                                            context),
                                  ),
                                  OutlinedButton(
                                    child: Text(
                                      'تخطي',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .color,
                                      ),
                                    ),
                                    onPressed: () =>
                                        FeatureDiscovery.dismissAll(context),
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
                                    Icons.edit,
                                    color: IconTheme.of(context).color,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () async {
                              dynamic result = await Navigator.of(context)
                                  .pushNamed('Data/EditArea', arguments: area);
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
                                  child: Text(
                                    'تخطي',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyText2
                                          .color,
                                    ),
                                  ),
                                  onPressed: () =>
                                      FeatureDiscovery.dismissAll(context),
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
                                child: Text(
                                  'تخطي',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        .color,
                                  ),
                                ),
                                onPressed: () =>
                                    FeatureDiscovery.dismissAll(context),
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
                            onSelected: (_) => sendNotification(context, area),
                            itemBuilder: (context) {
                              return [
                                PopupMenuItem(
                                  value: '',
                                  child:
                                      Text('ارسال إشعار للمستخدمين عن المنطقة'),
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
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: Text(
                                    area.name,
                                    style:
                                        Theme.of(context).textTheme.headline6,
                                  ),
                                ),
                                tag: area.id + '-name'),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(right: 32),
                                        child: FloatingActionButton(
                                          child: DescribedFeatureOverlay(
                                            backgroundDismissible: false,
                                            barrierDismissible: false,
                                            contentLocation:
                                                ContentLocation.above,
                                            featureId: 'LastVisit',
                                            tapTarget: Icon(Icons.update),
                                            title:
                                                Text('تسجيل تاريخ أخر زيارة'),
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
                                                      FeatureDiscovery
                                                          .completeCurrentStep(
                                                              context),
                                                ),
                                                OutlinedButton(
                                                  child: Text(
                                                    'تخطي',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyText2
                                                          .color,
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      FeatureDiscovery
                                                          .dismissAll(context),
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                Theme.of(context).accentColor,
                                            targetColor:
                                                Theme.of(context).primaryColor,
                                            textColor: Theme.of(context)
                                                .primaryTextTheme
                                                .bodyText1
                                                .color,
                                            child: Icon(Icons.update),
                                          ),
                                          tooltip: 'تسجيل أخر زيارة اليوم',
                                          heroTag: 'lastVisit',
                                          onPressed: () =>
                                              recordLastVisit(context),
                                        ),
                                      ),
                                      FloatingActionButton(
                                        heroTag: null,
                                        onPressed: () => Navigator.of(context)
                                            .pushNamed('Data/EditStreet',
                                                arguments: area.ref),
                                        child: DescribedFeatureOverlay(
                                          onBackgroundTap: () async {
                                            await FeatureDiscovery
                                                .completeCurrentStep(context);
                                            return true;
                                          },
                                          onDismiss: () async {
                                            await FeatureDiscovery
                                                .completeCurrentStep(context);
                                            return true;
                                          },
                                          backgroundDismissible: true,
                                          contentLocation:
                                              ContentLocation.above,
                                          featureId: 'Add',
                                          tapTarget: Icon(Icons.add_road),
                                          title: Text('اضافة شارع'),
                                          description: Column(
                                            children: [
                                              Text(
                                                  'يمكنك اضافة شارع داخل المنطقة بسرعة وسهولة من هنا'),
                                              OutlinedButton(
                                                child: Text(
                                                  'تخطي',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2
                                                        .color,
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    FeatureDiscovery
                                                        .completeCurrentStep(
                                                            context),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              Theme.of(context).accentColor,
                                          targetColor:
                                              Theme.of(context).primaryColor,
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
                            generate: Street.fromDoc,
                            tap: streetTap,
                            documentsData: area.getMembersLive(
                                orderBy: options.streetOrderBy,
                                descending: !options.streetASC)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void recordLastVisit(BuildContext context) async {
    await area.ref.update({
      'LastVisit': Timestamp.now(),
      'LastEdit': FirebaseAuth.instance.currentUser.uid
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم بنجاح'),
    ));
  }

  void showMap(BuildContext context, Area area) {
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
