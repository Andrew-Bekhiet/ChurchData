import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/double_circular_notched_bhape.dart';
import 'package:churchdata/models/history_property.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata_core/churchdata_core.dart'
    show CopiablePropertyWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:derived_colors/derived_colors.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

class AreaInfo extends StatefulWidget {
  final Area area;

  const AreaInfo({required this.area, super.key});

  @override
  _AreaInfoState createState() => _AreaInfoState();
}

class _AreaInfoState extends State<AreaInfo> {
  final BehaviorSubject<OrderOptions> _orderOptions =
      BehaviorSubject<OrderOptions>.seeded(const OrderOptions());

  bool showWarning = true;

  late final DataObjectListController<Street> _listOptions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        if (!widget.area.locationConfirmed &&
            widget.area.locationPoints.isNotEmpty &&
            showWarning) {
          showWarning = false;
          await showDialog(
            context: context,
            builder: (context) => const DataDialog(
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
          if (User.instance.write) 'Add',
        ]);
      },
    );
    _listOptions = DataObjectListController<Street>(
      tap: streetTap,
      itemsStream: _orderOptions.switchMap(
        (o) => widget.area
            .getMembersLive(orderBy: o.orderBy, descending: !o.asc)
            .map((s) => s.docs.map(Street.fromQueryDoc).toList()),
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
    return StreamBuilder<Area?>(
      initialData: widget.area,
      stream: widget.area.ref.snapshots().map(Area.fromDoc),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(
              child: Text('تم حذف المنطقة'),
            ),
          );

        final Area area = snapshot.data!;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, _) {
              final foregroundColor =
                  (area.color == Colors.transparent ? null : area.color)
                      ?.findInvert();

              return <Widget>[
                SliverAppBar(
                  backgroundColor:
                      area.color != Colors.transparent ? area.color : null,
                  foregroundColor: foregroundColor,
                  actions: area.ref.path.startsWith('Deleted')
                      ? <Widget>[
                          if (User.instance.write)
                            IconButton(
                              icon: const Icon(Icons.restore),
                              tooltip: 'استعادة',
                              onPressed: () {
                                recoverDoc(context, area.ref.path);
                              },
                            ),
                        ]
                      : <Widget>[
                          if (User.instance.write)
                            IconButton(
                              icon: DescribedFeatureOverlay(
                                barrierDismissible: false,
                                contentLocation: ContentLocation.below,
                                featureId: 'Edit',
                                tapTarget: Icon(
                                  Icons.edit,
                                  color: IconTheme.of(context).color,
                                ),
                                title: const Text('تعديل'),
                                description: Column(
                                  children: <Widget>[
                                    const Text('يمكنك تعديل البيانات من هنا'),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.forward),
                                      label: Text(
                                        'التالي',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                        ),
                                      ),
                                      onPressed: () =>
                                          FeatureDiscovery.completeCurrentStep(
                                        context,
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () =>
                                          FeatureDiscovery.dismissAll(context),
                                      child: Text(
                                        'تخطي',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                targetColor: Colors.transparent,
                                textColor: Theme.of(context)
                                    .primaryTextTheme
                                    .bodyLarge!
                                    .color!,
                                child: Builder(
                                  builder: (context) {
                                    return Stack(
                                      children: <Widget>[
                                        const Positioned(
                                          left: 1.0,
                                          top: 2.0,
                                          child: Icon(
                                            Icons.edit,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Icon(
                                          Icons.edit,
                                          color: IconTheme.of(context).color,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              onPressed: () async {
                                final dynamic result =
                                    await navigator.currentState!.pushNamed(
                                  'Data/EditArea',
                                  arguments: area,
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
                            icon: DescribedFeatureOverlay(
                              barrierDismissible: false,
                              contentLocation: ContentLocation.below,
                              featureId: 'Share',
                              tapTarget: const Icon(
                                Icons.share,
                              ),
                              title: const Text('مشاركة البيانات'),
                              description: Column(
                                children: <Widget>[
                                  const Text(
                                    'يمكنك مشاركة البيانات بلينك يفتح البيانات مباشرة داخل البرنامج',
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.forward),
                                    label: Text(
                                      'التالي',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                      ),
                                    ),
                                    onPressed: () =>
                                        FeatureDiscovery.completeCurrentStep(
                                      context,
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () =>
                                        FeatureDiscovery.dismissAll(context),
                                    child: Text(
                                      'تخطي',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              targetColor: Colors.transparent,
                              textColor: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyLarge!
                                  .color!,
                              child: Builder(
                                builder: (context) {
                                  return Stack(
                                    children: <Widget>[
                                      const Positioned(
                                        left: 1.0,
                                        top: 2.0,
                                        child: Icon(
                                          Icons.share,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Icon(
                                        Icons.share,
                                        color: IconTheme.of(context).color,
                                      ),
                                    ],
                                  );
                                },
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
                            barrierDismissible: false,
                            contentLocation: ContentLocation.below,
                            featureId: 'MoreOptions',
                            tapTarget: const Icon(
                              Icons.more_vert,
                            ),
                            title: const Text('المزيد من الخيارات'),
                            description: Column(
                              children: <Widget>[
                                const Text(
                                  'يمكنك ايجاد المزيد من الخيارات من هنا مثل: اشعار المستخدمين عن المنطقة',
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.forward),
                                  label: Text(
                                    'التالي',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                    ),
                                  ),
                                  onPressed: () =>
                                      FeatureDiscovery.completeCurrentStep(
                                    context,
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      FeatureDiscovery.dismissAll(context),
                                  child: Text(
                                    'تخطي',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            targetColor: Colors.transparent,
                            textColor: Theme.of(context)
                                .primaryTextTheme
                                .bodyLarge!
                                .color!,
                            child: PopupMenuButton(
                              onSelected: (_) =>
                                  sendNotification(context, area),
                              itemBuilder: (context) {
                                return [
                                  const PopupMenuItem(
                                    value: '',
                                    child: Text(
                                      'ارسال إشعار للمستخدمين عن المنطقة',
                                    ),
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
                        duration: const Duration(milliseconds: 300),
                        opacity: 1 -
                                    ((constraints.biggest.height -
                                            kToolbarHeight) /
                                        (250 - kToolbarHeight)) >
                                0.7
                            ? 1
                            : 0,
                        child: Text(
                          area.name,
                          style: TextStyle(color: foregroundColor),
                        ),
                      ),
                      background: area.photo(cropToCircle: false),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        ListTile(
                          title: Hero(
                            tag: area.id + '-name',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                area.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                        ),
                        if (area.address?.isNotEmpty ?? false)
                          CopiablePropertyWidget('العنوان:', area.address),
                        if (area.locationPoints.isNotEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.map),
                            onPressed: () => showMap(context, area),
                            label: const Text('إظهار على الخريطة'),
                          ),
                        const Divider(thickness: 1),
                        HistoryProperty(
                          'تاريخ أخر زيارة:',
                          area.lastVisit,
                          area.ref.collection('VisitHistory'),
                        ),
                        HistoryProperty(
                          'تاريخ أخر زيارة (لللأب الكاهن):',
                          area.fatherLastVisit,
                          area.ref.collection('FatherVisitHistory'),
                        ),
                        EditHistoryProperty(
                          'أخر تحديث للبيانات:',
                          area.lastEdit,
                          area.ref.collection('EditHistory'),
                          discoverFeature: true,
                        ),
                        if (User.instance.manageUsers ||
                            User.instance.manageAllowedUsers)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.analytics_outlined),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              'ActivityAnalysis',
                              arguments: [area],
                            ),
                            label: const Text('تحليل بيانات الخدمة'),
                          ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.analytics_outlined),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            'SpiritualAnalysis',
                            arguments: [area],
                          ),
                          label: const Text('تحليل الحياة الروحية للمخدومين'),
                        ),
                        const Divider(thickness: 1),
                        Text(
                          'الشوارع بالمنطقة:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SearchFilters(
                          1,
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
              child: area.ref.path.startsWith('Deleted')
                  ? const Text('يجب استعادة المنطقة لرؤية الشوراع بداخلها')
                  : DataObjectList<Street>(
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
                  style: Theme.of(context).primaryTextTheme.bodyLarge,
                );
              },
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
          floatingActionButton: User.instance.write &&
                  !area.ref.path.startsWith('Deleted')
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 32),
                      child: FloatingActionButton(
                        tooltip: 'تسجيل أخر زيارة اليوم',
                        heroTag: 'lastVisit',
                        onPressed: () => recordLastVisit(context, area),
                        child: DescribedFeatureOverlay(
                          barrierDismissible: false,
                          contentLocation: ContentLocation.above,
                          featureId: 'LastVisit',
                          tapTarget: const Icon(Icons.update),
                          title: const Text('تسجيل تاريخ أخر زيارة'),
                          description: Column(
                            children: <Widget>[
                              const Text(
                                'يمكنك تسجيل تاريخ أخر زيارة من هنا بشكل مباشر',
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.forward),
                                label: Text(
                                  'التالي',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                                onPressed: () =>
                                    FeatureDiscovery.completeCurrentStep(
                                  context,
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    FeatureDiscovery.dismissAll(context),
                                child: Text(
                                  'تخطي',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          targetColor: Theme.of(context).primaryColor,
                          textColor: Theme.of(context)
                              .primaryTextTheme
                              .bodyLarge!
                              .color!,
                          child: const Icon(Icons.update),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: null,
                      onPressed: () async {
                        final dynamic result = await navigator.currentState!
                            .pushNamed('Data/EditStreet', arguments: area.ref);
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
                      child: DescribedFeatureOverlay(
                        onBackgroundTap: () async {
                          await FeatureDiscovery.completeCurrentStep(context);
                          return true;
                        },
                        onDismiss: () async {
                          await FeatureDiscovery.completeCurrentStep(context);
                          return true;
                        },
                        backgroundDismissible: true,
                        contentLocation: ContentLocation.above,
                        featureId: 'Add',
                        tapTarget: const Icon(Icons.add_road),
                        title: const Text('اضافة شارع'),
                        description: Column(
                          children: [
                            const Text(
                              'يمكنك اضافة شارع داخل المنطقة بسرعة وسهولة من هنا',
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  FeatureDiscovery.completeCurrentStep(context),
                              child: Text(
                                'تخطي',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        targetColor: Theme.of(context).primaryColor,
                        textColor: Theme.of(context)
                            .primaryTextTheme
                            .bodyLarge!
                            .color!,
                        child: const Icon(Icons.add_road),
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Future<void> recordLastVisit(BuildContext context, Area area) async {
    if (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('هل تريد تسجيل أخر زيارة ل' + area.name + '؟'),
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
    await area.ref.update({
      'LastVisit': Timestamp.now(),
      'LastEdit': firebaseAuth.currentUser!.uid,
    });
    scaffoldMessenger.currentState!.showSnackBar(
      const SnackBar(
        content: Text('تم بنجاح'),
      ),
    );
  }

  void showMap(BuildContext context, Area area) {
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
                          area.locationConfirmed
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
                          await area.ref.update({
                            'LocationConfirmed': !area.locationConfirmed,
                            'LastEdit': User.instance.uid,
                          });
                          scaffoldMessenger.currentState!.hideCurrentSnackBar();
                          scaffoldMessenger.currentState!.showSnackBar(
                            const SnackBar(
                              content: Text('تم الحفظ بنجاح'),
                            ),
                          );
                        } catch (err, stkTrace) {
                          await FirebaseCrashlytics.instance
                              .setCustomKey('LastErrorIn', 'AreaInfo.showMap');
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
              title: Text('مكان ${area.name} على الخريطة'),
            ),
            body: area.getMapView(),
          );
        },
      ),
    );
  }
}
