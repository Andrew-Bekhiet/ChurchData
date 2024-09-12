import 'dart:async';
import 'dart:io';

import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/services/notifications_service.dart';
import 'package:churchdata/services/theming_service.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/list.dart';
import '../models/list_controllers.dart';
import '../models/user.dart';
import '../utils/globals.dart';
import '../utils/helpers.dart';
import 'auth_screen.dart';
import 'edit_users.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  Timer? _keepAliveTimer;
  bool _timeout = false;
  bool _pushed = false;

  final BehaviorSubject<bool> _showSearch = BehaviorSubject<bool>.seeded(false);
  final FocusNode searchFocus = FocusNode();

  final BehaviorSubject<OrderOptions> _areasOrder =
      BehaviorSubject.seeded(const OrderOptions());
  final BehaviorSubject<OrderOptions> _familiesOrder =
      BehaviorSubject.seeded(const OrderOptions());
  final BehaviorSubject<OrderOptions> _streetsOrder =
      BehaviorSubject.seeded(const OrderOptions());
  final BehaviorSubject<OrderOptions> _personsOrder =
      BehaviorSubject.seeded(const OrderOptions());

  late DataObjectListController<Area> _areasOptions;
  late DataObjectListController<Street> _streetsOptions;
  late DataObjectListController<Family> _familiesOptions;
  late DataObjectListController<Person> _personsOptions;

  final BehaviorSubject<String> _searchQuery =
      BehaviorSubject<String>.seeded('');

  Future<void> addTap([bool type = false]) async {
    dynamic result;
    if (_tabController.index == 0) {
      result = await navigator.currentState!.pushNamed('Data/EditArea');
    } else if (_tabController.index == 1) {
      result = await navigator.currentState!.pushNamed('Data/EditStreet');
    } else if (_tabController.index == 2) {
      result = await navigator.currentState!.pushNamed(
        'Data/EditFamily',
        arguments: {'IsStore': type},
      );
    } else if (_tabController.index == 3) {
      result = await navigator.currentState!.pushNamed('Data/EditPerson');
    }
    if (result == null) return;

    scaffoldMessenger.currentState!.hideCurrentSnackBar();
    if (result is JsonRef) {
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('تم الحفظ بنجاح'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);

        final dialogResult = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text('هل تريد الخروج؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('نعم'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('لا'),
              ),
            ],
          ),
        );

        if (dialogResult ?? false) {
          navigator.pop(result);
        }
      },
      child: Scaffold(
        key: mainScfld,
        appBar: AppBar(
          actions: <Widget>[
            StreamBuilder<bool>(
              initialData: _showSearch.value,
              stream: _showSearch,
              builder: (context, showSearch) {
                return showSearch.data ?? false
                    ? IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => SimpleDialog(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.select_all),
                                  label: const Text('تحديد الكل'),
                                  onPressed: () {
                                    if (_tabController.index == 0) {
                                      _areasOptions.selectAll();
                                    } else if (_tabController.index == 1) {
                                      _streetsOptions.selectAll();
                                    } else if (_tabController.index == 2) {
                                      _familiesOptions.selectAll();
                                    } else if (_tabController.index == 3) {
                                      _personsOptions.selectAll();
                                    }
                                    navigator.currentState!.pop();
                                  },
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.select_all),
                                  label: const Text('تحديد لا شئ'),
                                  onPressed: () {
                                    if (_tabController.index == 0) {
                                      _areasOptions.selectNone();
                                    } else if (_tabController.index == 1) {
                                      _streetsOptions.selectNone();
                                    } else if (_tabController.index == 2) {
                                      _familiesOptions.selectNone();
                                    } else if (_tabController.index == 3) {
                                      _personsOptions.selectNone();
                                    }
                                    navigator.currentState!.pop();
                                  },
                                ),
                                const Text(
                                  'ترتيب حسب:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...getOrderingOptions(
                                  _tabController.index == 0
                                      ? _areasOrder
                                      : _tabController.index == 1
                                          ? _streetsOrder
                                          : _tabController.index == 2
                                              ? _familiesOrder
                                              : _personsOrder,
                                  _tabController.index,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : IconButton(
                        icon: DescribedFeatureOverlay(
                          barrierDismissible: false,
                          contentLocation: ContentLocation.below,
                          featureId: 'Search',
                          onComplete: () async {
                            mainScfld.currentState!.openDrawer();
                            return true;
                          },
                          tapTarget: const Icon(Icons.search),
                          title: const Text('البحث'),
                          description: Column(
                            children: <Widget>[
                              const Text(
                                'يمكنك في أي وقت عمل بحث سريع عن أسماء المناطق، الشوارع، العائلات أو الأشخاص',
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
                                onPressed: () {
                                  FeatureDiscovery.completeCurrentStep(context);
                                  mainScfld.currentState!.openDrawer();
                                },
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
                          child: const Icon(Icons.search),
                        ),
                        onPressed: () {
                          searchFocus.requestFocus();
                          _showSearch.add(true);
                        },
                      );
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'الإشعارات',
              onPressed: () {
                navigator.currentState!.pushNamed('Notifications');
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                key: const Key('_AreasTab'),
                icon: DescribedFeatureOverlay(
                  barrierDismissible: false,
                  contentLocation: ContentLocation.below,
                  featureId: 'Areas',
                  tapTarget: const Icon(Icons.pin_drop),
                  title: const Text('المناطق'),
                  description: Column(
                    children: <Widget>[
                      const Text('هنا تجد قائمة بكل المناطق بالبرنامج'),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.forward),
                        label: Text(
                          'التالي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onPressed: () =>
                            FeatureDiscovery.completeCurrentStep(context),
                      ),
                      OutlinedButton(
                        onPressed: () => FeatureDiscovery.dismissAll(context),
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  targetColor: Colors.transparent,
                  textColor:
                      Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                  child: const Icon(Icons.pin_drop),
                ),
              ),
              Tab(
                key: const Key('_StreetsTab'),
                child: DescribedFeatureOverlay(
                  barrierDismissible: false,
                  contentLocation: ContentLocation.below,
                  featureId: 'Streets',
                  tapTarget: Image.asset(
                    'assets/streets.png',
                    width: IconTheme.of(context).size,
                    height: IconTheme.of(context).size,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: const Text('الشوارع'),
                  description: Column(
                    children: [
                      const Text('هنا تجد قائمة بكل الشوارع بالبرنامج'),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.forward),
                        label: Text(
                          'التالي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onPressed: () =>
                            FeatureDiscovery.completeCurrentStep(context),
                      ),
                      OutlinedButton(
                        onPressed: () => FeatureDiscovery.dismissAll(context),
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  targetColor: Colors.transparent,
                  textColor:
                      Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                  child: Image.asset(
                    'assets/streets.png',
                    width: IconTheme.of(context).size,
                    height: IconTheme.of(context).size,
                    color: Theme.of(context).primaryTextTheme.bodyLarge!.color,
                  ),
                ),
              ),
              Tab(
                key: const Key('_FamiliesTab'),
                icon: DescribedFeatureOverlay(
                  barrierDismissible: false,
                  contentLocation: ContentLocation.below,
                  featureId: 'Families',
                  tapTarget: const Icon(Icons.group),
                  title: const Text('العائلات'),
                  description: Column(
                    children: <Widget>[
                      const Text('وهنا تجد قائمة بكل العائلات بالبرنامج'),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.forward),
                        label: Text(
                          'التالي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onPressed: () =>
                            FeatureDiscovery.completeCurrentStep(context),
                      ),
                      OutlinedButton(
                        onPressed: () => FeatureDiscovery.dismissAll(context),
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  targetColor: Colors.transparent,
                  textColor:
                      Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                  child: const Icon(Icons.group),
                ),
              ),
              Tab(
                key: const Key('_PersonsTab'),
                icon: DescribedFeatureOverlay(
                  barrierDismissible: false,
                  contentLocation: ContentLocation.below,
                  featureId: 'Persons',
                  tapTarget: const Icon(Icons.person),
                  title: const Text('الأشخاص'),
                  description: Column(
                    children: <Widget>[
                      const Text('هنا تجد قائمة بكل الأشخاص بالبرنامج'),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.forward),
                        label: Text(
                          'التالي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onPressed: () {
                          FeatureDiscovery.completeCurrentStep(context);
                        },
                      ),
                      OutlinedButton(
                        onPressed: () => FeatureDiscovery.dismissAll(context),
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  targetColor: Colors.transparent,
                  textColor:
                      Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                  child: const Icon(Icons.person),
                ),
              ),
            ],
          ),
          title: StreamBuilder<bool>(
            initialData: _showSearch.value,
            stream: _showSearch,
            builder: (context, showSearch) {
              return showSearch.data ?? false
                  ? TextField(
                      focusNode: searchFocus,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context)
                                .primaryTextTheme
                                .titleLarge
                                ?.color,
                          ),
                          onPressed: () {
                            _searchQuery.add('');
                            _showSearch.add(false);
                          },
                        ),
                        hintText: 'بحث ...',
                      ),
                      onChanged: _searchQuery.add,
                    )
                  : const Text('البيانات');
            },
          ),
        ),
        extendBody: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: StreamBuilder<User>(
          initialData: User.instance,
          stream: User.instance.stream,
          builder: (context, snapshot) {
            return User.instance.write
                ? FloatingActionButton(
                    heroTag: null,
                    onPressed: addTap,
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) => Icon(
                        _tabController.index == 0
                            ? Icons.add_location
                            : _tabController.index == 1
                                ? Icons.add_road
                                : _tabController.index == 2
                                    ? Icons.group_add
                                    : Icons.person_add,
                      ),
                    ),
                  )
                : const SizedBox(width: 1, height: 1);
          },
        ),
        bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).colorScheme.primary,
          shape: const CircularNotchedRectangle(),
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) => StreamBuilder<List>(
              stream: _tabController.index == 0
                  ? _areasOptions.objectsData
                  : _tabController.index == 1
                      ? _streetsOptions.objectsData
                      : _tabController.index == 2
                          ? _familiesOptions.objectsData
                          : _personsOptions.objectsData,
              builder: (context, snapshot) {
                return Text(
                  (snapshot.data?.length ?? 0).toString() +
                      ' ' +
                      (_tabController.index == 0
                          ? 'منطقة'
                          : _tabController.index == 1
                              ? 'شارع'
                              : _tabController.index == 2
                                  ? 'عائلة'
                                  : 'شخص'),
                  textAlign: TextAlign.center,
                  strutStyle:
                      StrutStyle(height: IconTheme.of(context).size! / 7.5),
                  style: Theme.of(context).primaryTextTheme.bodyLarge,
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            DataObjectList<Area>(
              key: const PageStorageKey('mainAreasList'),
              options: _areasOptions,
              autoDisposeController: false,
            ),
            DataObjectList<Street>(
              key: const PageStorageKey('mainStreetsList'),
              options: _streetsOptions,
              autoDisposeController: false,
            ),
            DataObjectList<Family>(
              key: const PageStorageKey('mainFamiliesList'),
              options: _familiesOptions,
              autoDisposeController: false,
            ),
            DataObjectList<Person>(
              key: const PageStorageKey('mainPersonsList'),
              options: _personsOptions,
              autoDisposeController: false,
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/Logo.png'),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 86, 213, 170),
                      Color.fromARGB(255, 39, 124, 205),
                    ],
                    stops: [0, 1],
                  ),
                ),
                child: SizedBox(),
              ),
              ListTile(
                leading: StreamBuilder<User>(
                  initialData: User.instance,
                  stream: User.instance.stream,
                  builder: (context, user) {
                    return DescribedFeatureOverlay(
                      barrierDismissible: false,
                      contentLocation: ContentLocation.below,
                      featureId: 'MyAccount',
                      tapTarget: user.data!.getPhoto(true, false),
                      title: const Text('حسابي'),
                      description: Column(
                        children: <Widget>[
                          const Text(
                            'يمكنك الاطلاع على حسابك بالبرنامج وجميع الصلاحيات التي تملكها من خلال حسابي',
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
                                FeatureDiscovery.completeCurrentStep(context),
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
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                      child: user.data!.getPhoto(true, false),
                    );
                  },
                ),
                title: const Text('حسابي'),
                onTap: () {
                  navigator.currentState!.pushNamed('MyAccount');
                },
              ),
              Selector<User, bool>(
                selector: (_, user) =>
                    user.manageUsers || user.manageAllowedUsers,
                builder: (context, permission, _) {
                  if (!permission)
                    return const SizedBox(
                      width: 0,
                      height: 0,
                    );
                  return ListTile(
                    leading: DescribedFeatureOverlay(
                      barrierDismissible: false,
                      featureId: 'ManageUsers',
                      tapTarget: const Icon(
                        IconData(0xef3d, fontFamily: 'MaterialIconsR'),
                      ),
                      contentLocation: ContentLocation.below,
                      title: const Text('إدارة المستخدمين'),
                      description: Column(
                        children: <Widget>[
                          const Text(
                            'يمكنك دائمًا الاطلاع على مستخدمي البرنامج وتعديل صلاحياتهم من هنا',
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
                                FeatureDiscovery.completeCurrentStep(context),
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
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                      child: const Icon(
                        IconData(0xef3d, fontFamily: 'MaterialIconsR'),
                      ),
                    ),
                    onTap: () {
                      mainScfld.currentState!.openEndDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthScreen(
                            nextWidget: UsersPage(),
                          ),
                        ),
                      );
                    },
                    title: const Text('إدارة المستخدمين'),
                  );
                },
              ),
              const Divider(),
              StreamBuilder<User>(
                initialData: User.instance,
                stream: User.instance.stream,
                builder: (context, user) {
                  return user.data!.manageUsers || user.data!.manageAllowedUsers
                      ? ListTile(
                          leading: DescribedFeatureOverlay(
                            barrierDismissible: false,
                            featureId: 'ActivityAnalysis',
                            contentLocation: ContentLocation.below,
                            tapTarget: const Icon(Icons.analytics_outlined),
                            title: const Text('تحليل بيانات الخدمة'),
                            description: Column(
                              children: [
                                const Text('يمكنك الأن تحليل بيانات الخدمة'
                                    ' من حيث الافتقاد'
                                    ' وتحديث البيانات وبيانات المكالمات'),
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
                            child: const Icon(Icons.analytics_outlined),
                          ),
                          title: const Text('تحليل بيانات الخدمة'),
                          onTap: () {
                            mainScfld.currentState!.openEndDrawer();
                            navigator.currentState!
                                .pushNamed('ActivityAnalysis');
                          },
                        )
                      : const SizedBox();
                },
              ),
              ListTile(
                leading: DescribedFeatureOverlay(
                  barrierDismissible: false,
                  featureId: 'SpiritualAnalysis',
                  contentLocation: ContentLocation.below,
                  tapTarget: const Icon(Icons.analytics_outlined),
                  title: const Text('تحليل بيانات الحياة الروحية للمخدومين'),
                  description: Column(
                    children: [
                      const Text('يمكنك الأن تحليل بيانات '
                          'الحياة الروحية للمخدومين من حيث اجمالي'
                          ' التناول والاعتراف في اليوم ورسم بياني لذلك'),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.forward),
                        label: Text(
                          'التالي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onPressed: () =>
                            FeatureDiscovery.completeCurrentStep(context),
                      ),
                      OutlinedButton(
                        onPressed: () => FeatureDiscovery.dismissAll(context),
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  targetColor: Colors.transparent,
                  textColor:
                      Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                  child: const Icon(Icons.analytics_outlined),
                ),
                title: const Text('تحليل الحياة الروحية للمخدومين'),
                onTap: () {
                  mainScfld.currentState!.openEndDrawer();
                  navigator.currentState!.pushNamed('SpiritualAnalysis');
                },
              ),
              const Divider(),
              ListTile(
                leading: DescribedFeatureOverlay(
                  barrierDismissible: false,
                  featureId: 'DataMap',
                  contentLocation: ContentLocation.below,
                  tapTarget: const Icon(Icons.map),
                  title: const Text('خريطة الافتقاد'),
                  description: Column(
                    children: [
                      const Text(
                        'يمكنك دائمًا الاطلاع على جميع مواقع العائلات بالبرنامج عن طريق خريطة الافتقاد',
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.forward),
                        label: Text(
                          'التالي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onPressed: () =>
                            FeatureDiscovery.completeCurrentStep(context),
                      ),
                      OutlinedButton(
                        onPressed: () => FeatureDiscovery.dismissAll(context),
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  targetColor: Colors.transparent,
                  textColor:
                      Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                  child: const Icon(Icons.map),
                ),
                title: const Text('عرض خريطة الافتقاد'),
                onTap: () {
                  mainScfld.currentState!.openEndDrawer();
                  navigator.currentState!.pushNamed('DataMap');
                },
              ),
              ListTile(
                leading: DescribedFeatureOverlay(
                  barrierDismissible: false,
                  contentLocation: ContentLocation.below,
                  featureId: 'AdvancedSearch',
                  tapTarget: const Icon(Icons.search),
                  title: const Text('البحث المفصل'),
                  description: Column(
                    children: <Widget>[
                      const Text(
                        'يمكن عمل بحث مفصل عن البيانات بالبرنامج بالخصائص المطلوبة\nمثال: عرض كل الأشخاص الذين يصادف عيد ميلادهم اليوم\nعرض كل الأشخاص داخل منطقة معينة',
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.forward),
                        label: Text(
                          'التالي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onPressed: () =>
                            FeatureDiscovery.completeCurrentStep(context),
                      ),
                      OutlinedButton(
                        onPressed: () => FeatureDiscovery.dismissAll(context),
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  targetColor: Colors.transparent,
                  textColor:
                      Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                  child: const Icon(Icons.search),
                ),
                title: const Text('بحث مفصل'),
                onTap: () {
                  mainScfld.currentState!.openEndDrawer();
                  navigator.currentState!.pushNamed('Search');
                },
              ),
              Selector<User, bool>(
                selector: (_, user) => user.manageDeleted,
                builder: (context, permission, _) {
                  if (!permission)
                    return const SizedBox(
                      width: 0,
                      height: 0,
                    );
                  return ListTile(
                    leading: DescribedFeatureOverlay(
                      barrierDismissible: false,
                      featureId: 'ManageDeleted',
                      tapTarget: const Icon(Icons.delete_outline),
                      contentLocation: ContentLocation.below,
                      title: const Text('سلة المحذوفات'),
                      description: Column(
                        children: <Widget>[
                          const Text(
                            'يمكنك الأن استرجاع المحذوفات خلال مدة شهر من حذفها من هنا',
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
                                FeatureDiscovery.completeCurrentStep(context),
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
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                      child: const Icon(Icons.delete_outline),
                    ),
                    onTap: () {
                      mainScfld.currentState!.openEndDrawer();
                      navigator.currentState!.pushNamed('Trash');
                    },
                    title: const Text('سلة المحذوفات'),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: DescribedFeatureOverlay(
                  onBackgroundTap: () async {
                    await FeatureDiscovery.completeCurrentStep(context);
                    return true;
                  },
                  onDismiss: () async {
                    await FeatureDiscovery.completeCurrentStep(context);
                    return true;
                  },
                  backgroundDismissible: true,
                  contentLocation: ContentLocation.below,
                  featureId: 'Settings',
                  tapTarget: const Icon(Icons.settings),
                  title: const Text('الإعدادات'),
                  description: Column(
                    children: <Widget>[
                      const Text(
                        'يمكنك ضبط بعض الاعدادات بالبرنامج مثل مظهر البرنامج ومظهر البيانات وبعض البيانات الاضافية مثل الوظائف والأباء الكهنة',
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            FeatureDiscovery.completeCurrentStep(context),
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  targetColor: Colors.transparent,
                  textColor:
                      Theme.of(context).primaryTextTheme.bodyLarge!.color!,
                  child: const Icon(Icons.settings),
                ),
                title: const Text('الإعدادات'),
                onTap: () {
                  mainScfld.currentState!.openEndDrawer();
                  navigator.currentState!.pushNamed('Settings');
                },
              ),
              Selector<User, bool>(
                selector: (_, user) => user.write,
                builder: (context2, permission, _) {
                  return permission
                      ? ListTile(
                          leading: const Icon(Icons.cloud_upload),
                          title: const Text('استيراد من ملف اكسل'),
                          onTap: () {
                            mainScfld.currentState!.openEndDrawer();
                            import(context);
                          },
                        )
                      : const SizedBox();
                },
              ),
              Selector<User, bool>(
                selector: (_, user) => user.exportAreas,
                builder: (context2, permission, _) {
                  return permission
                      ? ListTile(
                          leading: const Icon(Icons.cloud_download),
                          title: const Text('تصدير منطقة إلى ملف اكسل'),
                          onTap: () async {
                            mainScfld.currentState!.openEndDrawer();
                            final Area? rslt = await showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Column(
                                  children: [
                                    Text(
                                      'برجاء اختيار المنطقة التي تريد تصديرها:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    Expanded(
                                      child: DataObjectList<Area>(
                                        autoDisposeController: true,
                                        options: DataObjectListController(
                                          itemsStream: Area.getAllForUser().map(
                                            (s) => s.docs
                                                .map(Area.fromQueryDoc)
                                                .toList(),
                                          ),
                                          tap: (area) =>
                                              navigator.currentState!.pop(area),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (rslt != null) {
                              scaffoldMessenger.currentState!.showSnackBar(
                                SnackBar(
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('جار تصدير ' + rslt.name + '...'),
                                      const LinearProgressIndicator(),
                                    ],
                                  ),
                                  duration: const Duration(minutes: 9),
                                ),
                              );
                              try {
                                final String filename = Uri.decodeComponent(
                                  (await firebaseFunctions
                                          .httpsCallable('exportToExcel')
                                          .call({'onlyArea': rslt.id}))
                                      .data,
                                );
                                final documentsDirectory = Platform.isAndroid
                                    ? (await getExternalStorageDirectories(
                                        type: StorageDirectory.documents,
                                      ))!
                                        .first
                                    : await getDownloadsDirectory();

                                final file = await File(
                                  path.join(
                                    documentsDirectory!.path,
                                    filename.replaceAll(':', ''),
                                  ),
                                ).create(recursive: true);

                                await firebaseStorage
                                    .ref(filename)
                                    .writeToFile(file);
                                scaffoldMessenger.currentState!
                                    .hideCurrentSnackBar();
                                scaffoldMessenger.currentState!.showSnackBar(
                                  SnackBar(
                                    content:
                                        const Text('تم تصدير البيانات ينجاح'),
                                    action: SnackBarAction(
                                      label: 'فتح',
                                      onPressed: () {
                                        OpenFile.open(file.path);
                                      },
                                    ),
                                  ),
                                );
                              } on Exception catch (e, st) {
                                scaffoldMessenger.currentState!
                                    .hideCurrentSnackBar();
                                scaffoldMessenger.currentState!.showSnackBar(
                                  const SnackBar(
                                    content: Text('فشل تصدير البيانات'),
                                  ),
                                );
                                await FirebaseCrashlytics.instance.setCustomKey(
                                  'LastErrorIn',
                                  'Root.exportOnlyArea',
                                );
                                await FirebaseCrashlytics.instance
                                    .recordError(e, st);
                              }
                            }
                          },
                        )
                      : const SizedBox();
                },
              ),
              Selector<User, bool>(
                selector: (_, user) => user.exportAreas,
                builder: (context2, permission, _) {
                  return permission
                      ? ListTile(
                          leading: const Icon(Icons.file_download),
                          title: const Text('تصدير جميع البيانات'),
                          onTap: () async {
                            mainScfld.currentState!.openEndDrawer();
                            scaffoldMessenger.currentState!.showSnackBar(
                              const SnackBar(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'جار تصدير جميع البيانات...\nيرجى الانتظار...',
                                    ),
                                    LinearProgressIndicator(),
                                  ],
                                ),
                                duration: Duration(minutes: 9),
                              ),
                            );
                            try {
                              final String filename = Uri.decodeComponent(
                                (await firebaseFunctions
                                        .httpsCallable('exportToExcel')
                                        .call())
                                    .data,
                              );
                              final documentsDirectory = Platform.isAndroid
                                  ? (await getExternalStorageDirectories(
                                      type: StorageDirectory.documents,
                                    ))!
                                      .first
                                  : await getDownloadsDirectory();

                              final file = await File(
                                path.join(
                                  documentsDirectory!.path,
                                  filename.replaceAll(':', ''),
                                ),
                              ).create(recursive: true);

                              await firebaseStorage
                                  .ref(filename)
                                  .writeToFile(file);
                              scaffoldMessenger.currentState!
                                  .hideCurrentSnackBar();
                              scaffoldMessenger.currentState!.showSnackBar(
                                SnackBar(
                                  content:
                                      const Text('تم تصدير البيانات ينجاح'),
                                  action: SnackBarAction(
                                    label: 'فتح',
                                    onPressed: () {
                                      OpenFile.open(file.path);
                                    },
                                  ),
                                ),
                              );
                            } on Exception catch (e, st) {
                              scaffoldMessenger.currentState!
                                  .hideCurrentSnackBar();
                              scaffoldMessenger.currentState!.showSnackBar(
                                const SnackBar(
                                  content: Text('فشل تصدير البيانات'),
                                ),
                              );
                              await FirebaseCrashlytics.instance.setCustomKey(
                                'LastErrorIn',
                                'Root.exportAll',
                              );
                              await FirebaseCrashlytics.instance
                                  .recordError(e, st);
                            }
                          },
                        )
                      : const SizedBox();
                },
              ),
              StreamBuilder<bool>(
                initialData: false,
                stream:
                    User.instance.stream.map((u) => u.exportAreas).distinct(),
                builder: (context, data) => data.data!
                    ? ListTile(
                        leading: const Icon(Icons.list_alt),
                        title: const Text('عمليات التصدير السابقة'),
                        onTap: () =>
                            navigator.currentState!.pushNamed('ExportOps'),
                      )
                    : const SizedBox(),
              ),
              const Divider(),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.system_update_alt),
                  title: const Text('تحديث البرنامج'),
                  onTap: () {
                    mainScfld.currentState!.openEndDrawer();
                    navigator.currentState!.pushNamed('Update');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('حول البرنامج'),
                onTap: () async {
                  mainScfld.currentState!.openEndDrawer();
                  showAboutDialog(
                    context: context,
                    applicationIcon: Image.asset(
                      'assets/Logo2.png',
                      width: 100,
                      height: 100,
                    ),
                    applicationName: 'بيانات الكنيسة',
                    applicationLegalese:
                        'جميع الحقوق محفوظة: كنيسة السيدة العذراء مريم بالاسماعيلية',
                    applicationVersion:
                        (await PackageInfo.fromPlatform()).version,
                    children: [
                      TextButton(
                        onPressed: () async {
                          const url =
                              'https://church-data.flycricket.io/terms.html';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                        child: const Text('شروط الاستخدام'),
                      ),
                      TextButton(
                        onPressed: () async {
                          const url =
                              'https://church-data.flycricket.io/privacy.html';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                        child: const Text('سياسة الخصوصية'),
                      ),
                    ],
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('تسجيل الخروج'),
                onTap: () async {
                  mainScfld.currentState!.openEndDrawer();
                  await User.instance.signOut();
                  await Hive.box('Settings').put('FCM_Token_Registered', false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangePlatformBrightness() {
    GetIt.I<CDThemingService>().switchTheme(
      PlatformDispatcher.instance.platformBrightness == Brightness.dark,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_timeout && !_pushed) {
          _pushed = true;
          navigator.currentState!
              .push(
            MaterialPageRoute(
              builder: (_) => const PopScope(
                canPop: false,
                child: AuthScreen(),
              ),
            ),
          )
              .then((value) {
            _pushed = false;
            _timeout = false;
          });
        }
        _keepAlive(true);
        _recordActive();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _keepAlive(false);
        _recordLastSeen();
    }
  }

  Future<void> _recordLastSeen() async {
    await User.instance.recordLastSeen();
  }

  Future<void> _recordActive() async {
    await User.instance.recordActive();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);

    await _areasOptions.dispose();
    await _streetsOptions.dispose();
    await _familiesOptions.dispose();
    await _personsOptions.dispose();

    await _areasOrder.close();
    await _familiesOrder.close();
    await _streetsOrder.close();
    await _personsOrder.close();

    await _showSearch.close();
    await _searchQuery.close();
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar_EG');
    _tabController = TabController(vsync: this, length: 4);
    WidgetsBinding.instance.addObserver(this);
    _keepAlive(true);
    _areasOptions = DataObjectListController<Area>(
      searchQuery: _searchQuery,
      //Listen to Ordering options and combine it
      //with the Data Stream from Firestore
      itemsStream: _areasOrder.switchMap(
        (order) =>
            Area.getAllForUser(orderBy: order.orderBy, descending: !order.asc)
                .map(
          (s) => s.docs.map(Area.fromQueryDoc).toList(),
        ),
      ),
    );
    _streetsOptions = DataObjectListController<Street>(
      searchQuery: _searchQuery,
      itemsStream: _streetsOrder.switchMap(
        (order) =>
            Street.getAllForUser(orderBy: order.orderBy, descending: !order.asc)
                .map(
          (s) => s.docs.map(Street.fromQueryDoc).toList(),
        ),
      ),
    );
    _familiesOptions = DataObjectListController<Family>(
      searchQuery: _searchQuery,
      itemsStream: _familiesOrder.switchMap(
        (order) =>
            Family.getAllForUser(orderBy: order.orderBy, descending: !order.asc)
                .map(
          (s) => s.docs.map(Family.fromQueryDoc).toList(),
        ),
      ),
    );
    _personsOptions = DataObjectListController<Person>(
      searchQuery: _searchQuery,
      itemsStream: _personsOrder.switchMap(
        (order) =>
            Person.getAllForUser(orderBy: order.orderBy, descending: !order.asc)
                .map(
          (s) => s.docs.map(Person.fromQueryDoc).toList(),
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showPendingUIDialogs();
    });
  }

  Future showDynamicLink() async {
    final PendingDynamicLinkData? data =
        await firebaseDynamicLinks.getInitialLink();

    firebaseDynamicLinks.onLink.listen(
      (dynamicLink) async {
        final Uri deepLink = dynamicLink.link;

        await processLink(deepLink);
      },
      onError: (e) async {
        debugPrint('DynamicLinks onError $e');
      },
    );
    if (data == null) return;
    final Uri deepLink = data.link;
    await processLink(deepLink);
  }

  Future<void> showPendingUIDialogs() async {
    if (!kIsWeb) {
      await showDynamicLink();
      await GetIt.I<CDNotificationsService>().showInitialNotification(context);
      await showBatteryOptimizationDialog();
    }

    if (!await User.instance.userDataUpToDate()) {
      await showErrorUpdateDataDialog(context: context, pushApp: false);
    }

    if (!kDebugMode && mounted)
      FeatureDiscovery.discoverFeatures(context, [
        'Areas',
        'Streets',
        'Families',
        'Persons',
        'Search',
        'MyAccount',
        if (User.instance.manageUsers || User.instance.manageAllowedUsers)
          'ManageUsers',
        if (User.instance.manageUsers || User.instance.manageAllowedUsers)
          'ActivityAnalysis',
        'SpiritualAnalysis',
        'DataMap',
        'AdvancedSearch',
        if (User.instance.manageDeleted) 'ManageDeleted',
        'Settings',
      ]);
  }

  Future<void> showBatteryOptimizationDialog() async {
    if (!kIsWeb &&
        (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 23 &&
        !(await Permission.ignoreBatteryOptimizations.status).isGranted &&
        Hive.box('Settings').get('ShowBatteryDialog', defaultValue: true)) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text(
            'برجاء الغاء تفعيل حفظ الطاقة للبرنامج لإظهار الاشعارات في الخلفية',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                navigator.currentState!.pop();
                await Permission.ignoreBatteryOptimizations.request();
              },
              child: const Text('الغاء حفظ الطاقة للبرنامج'),
            ),
            TextButton(
              onPressed: () async {
                await Hive.box('Settings').put('ShowBatteryDialog', false);
                navigator.currentState!.pop();
              },
              child: const Text('عدم الاظهار مجددًا'),
            ),
          ],
        ),
      );
    }
  }

  void _keepAlive(bool visible) {
    _keepAliveTimer?.cancel();
    if (visible) {
      _keepAliveTimer = null;
    } else {
      _keepAliveTimer = Timer(
        const Duration(minutes: 1),
        () => _timeout = true,
      );
    }
  }
}
