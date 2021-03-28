import 'dart:async';
import 'dart:io';

import 'package:battery_optimization/battery_optimization.dart';
import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/street.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart' hide ListOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/list_options.dart';
import '../models/order_options.dart';
import '../models/user.dart';
import '../main.dart';
import '../utils/helpers.dart';
import '../utils/globals.dart';
import 'auth_screen.dart';
import 'edit_users.dart';
import '../models/list.dart';

class Root extends StatefulWidget {
  const Root({Key key}) : super(key: key);

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController _tabController;
  Timer _keepAliveTimer;
  bool _timeout = false;
  bool _pushed = false;
  final BehaviorSubject<bool> _showSearch = BehaviorSubject<bool>.seeded(false);
  final FocusNode searchFocus = FocusNode();

  final BehaviorSubject<OrderOptions> _areasOrder =
      BehaviorSubject.seeded(OrderOptions());
  final BehaviorSubject<OrderOptions> _familiesOrder =
      BehaviorSubject.seeded(OrderOptions());
  final BehaviorSubject<OrderOptions> _streetsOrder =
      BehaviorSubject.seeded(OrderOptions());
  final BehaviorSubject<OrderOptions> _personsOrder =
      BehaviorSubject.seeded(OrderOptions());

  final BehaviorSubject<String> _searchQuery =
      BehaviorSubject<String>.seeded('');

  void addTap([bool type = false]) {
    if (_tabController.index == 0) {
      Navigator.of(context).pushNamed('Data/EditArea');
    } else if (_tabController.index == 1) {
      Navigator.of(context).pushNamed('Data/EditStreet');
    } else if (_tabController.index == 2) {
      Navigator.of(context).pushNamed(
        'Data/EditFamily',
        arguments: {'IsStore': type},
      );
    } else if (_tabController.index == 3) {
      Navigator.of(context).pushNamed('Data/EditPerson');
    }
  }

  @override
  Widget build(BuildContext context) {
    var _areasOptions = DataObjectListOptions<Area>(
      searchQuery: _searchQuery,
      //Listen to Ordering options and combine it
      //with the Data Stream from Firestore
      itemsStream: _areasOrder.flatMap(
        (order) =>
            Area.getAllForUser(orderBy: order.orderBy, descending: !order.asc)
                .map(
          (s) => s.docs.map(Area.fromDoc).toList(),
        ),
      ),
    );
    var _streetsOptions = DataObjectListOptions<Street>(
      searchQuery: _searchQuery,
      itemsStream: _streetsOrder.flatMap(
        (order) =>
            Street.getAllForUser(orderBy: order.orderBy, descending: !order.asc)
                .map(
          (s) => s.docs.map(Street.fromDoc).toList(),
        ),
      ),
    );
    var _familiesOptions = DataObjectListOptions<Family>(
      searchQuery: _searchQuery,
      itemsStream: _familiesOrder.flatMap(
        (order) =>
            Family.getAllForUser(orderBy: order.orderBy, descending: !order.asc)
                .map(
          (s) => s.docs.map(Family.fromDoc).toList(),
        ),
      ),
    );
    var _personsOptions = DataObjectListOptions<Person>(
      searchQuery: _searchQuery,
      itemsStream: _personsOrder.flatMap(
        (order) =>
            Person.getAllForUser(orderBy: order.orderBy, descending: !order.asc)
                .map(
          (s) => s.docs.map(Person.fromDoc).toList(),
        ),
      ),
    );

    return WillPopScope(
      onWillPop: () async =>
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text('هل تريد الخروج؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('نعم'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('لا'),
                )
              ],
            ),
          ) ??
          false,
      child: Scaffold(
        key: mainScfld,
        appBar: AppBar(
            actions: <Widget>[
              StreamBuilder<bool>(
                  initialData: _showSearch.value,
                  stream: _showSearch,
                  builder: (context, showSearch) {
                    return showSearch.data
                        ? IconButton(
                            icon: Icon(Icons.filter_list),
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (context) => SimpleDialog(
                                  children: [
                                    TextButton.icon(
                                      icon: Icon(Icons.select_all),
                                      label: Text('تحديد الكل'),
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
                                        Navigator.pop(context);
                                      },
                                    ),
                                    TextButton.icon(
                                      icon: Icon(Icons.select_all),
                                      label: Text('تحديد لا شئ'),
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
                                        Navigator.pop(context);
                                      },
                                    ),
                                    Text('ترتيب حسب:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    ...getOrderingOptions(
                                        context,
                                        _tabController.index == 0
                                            ? _areasOrder
                                            : _tabController.index == 1
                                                ? _streetsOrder
                                                : _tabController.index == 2
                                                    ? _familiesOrder
                                                    : _personsOrder,
                                        _tabController.index),
                                  ],
                                ),
                              );
                            },
                          )
                        : IconButton(
                            icon: DescribedFeatureOverlay(
                              backgroundDismissible: false,
                              barrierDismissible: false,
                              contentLocation: ContentLocation.below,
                              featureId: 'Search',
                              onComplete: () async {
                                mainScfld.currentState.openDrawer();
                                return true;
                              },
                              tapTarget: Icon(Icons.search),
                              title: Text('البحث'),
                              description: Column(
                                children: <Widget>[
                                  Text(
                                      'يمكنك في أي وقت عمل بحث سريع عن أسماء المناطق، الشوارع، العائلات أو الأشخاص'),
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
                                    onPressed: () {
                                      FeatureDiscovery.completeCurrentStep(
                                          context);
                                      mainScfld.currentState.openDrawer();
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
                              child: const Icon(Icons.search),
                            ),
                            onPressed: () {
                              searchFocus.requestFocus();
                              _showSearch.add(true);
                            },
                          );
                  }),
              IconButton(
                icon: Icon(Icons.notifications),
                tooltip: 'الإشعارات',
                onPressed: () {
                  Navigator.of(context).pushNamed('Notifications');
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'المناطق',
                  icon: DescribedFeatureOverlay(
                    backgroundDismissible: false,
                    barrierDismissible: false,
                    contentLocation: ContentLocation.below,
                    featureId: 'Areas',
                    tapTarget: const Icon(Icons.pin_drop),
                    title: Text('المناطق'),
                    description: Column(
                      children: <Widget>[
                        Text('هنا تجد قائمة بكل المناطق بالبرنامج'),
                        OutlinedButton.icon(
                          icon: Icon(Icons.forward),
                          label: Text(
                            'التالي',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText2.color,
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
                                  Theme.of(context).textTheme.bodyText2.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Theme.of(context).accentColor,
                    targetColor: Colors.transparent,
                    textColor:
                        Theme.of(context).primaryTextTheme.bodyText1.color,
                    child: const Icon(Icons.pin_drop),
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        flex: 11,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          child: DescribedFeatureOverlay(
                            backgroundDismissible: false,
                            barrierDismissible: false,
                            contentLocation: ContentLocation.below,
                            featureId: 'Streets',
                            tapTarget: Image.asset('assets/streets.png',
                                width: IconTheme.of(context).size,
                                height: IconTheme.of(context).size,
                                color: Theme.of(context).iconTheme.color),
                            title: Text('الشوارع'),
                            description: Column(
                              children: [
                                Text('هنا تجد قائمة بكل الشوارع بالبرنامج'),
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
                            child: Image.asset('assets/streets.png',
                                width: IconTheme.of(context).size,
                                height: IconTheme.of(context).size,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .bodyText1
                                    .color),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 15,
                        child: Text('الشوارع',
                            softWrap: false, overflow: TextOverflow.fade),
                      ),
                    ],
                  ),
                ),
                Tab(
                  text: 'العائلات',
                  icon: DescribedFeatureOverlay(
                    backgroundDismissible: false,
                    barrierDismissible: false,
                    contentLocation: ContentLocation.below,
                    featureId: 'Families',
                    tapTarget: const Icon(Icons.group),
                    title: Text('العائلات'),
                    description: Column(
                      children: <Widget>[
                        Text('وهنا تجد قائمة بكل العائلات بالبرنامج'),
                        OutlinedButton.icon(
                          icon: Icon(Icons.forward),
                          label: Text(
                            'التالي',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText2.color,
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
                                  Theme.of(context).textTheme.bodyText2.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Theme.of(context).accentColor,
                    targetColor: Colors.transparent,
                    textColor:
                        Theme.of(context).primaryTextTheme.bodyText1.color,
                    child: const Icon(Icons.group),
                  ),
                ),
                Tab(
                  text: 'الأشخاص',
                  icon: DescribedFeatureOverlay(
                    backgroundDismissible: false,
                    barrierDismissible: false,
                    contentLocation: ContentLocation.below,
                    featureId: 'Persons',
                    tapTarget: const Icon(Icons.person),
                    title: Text('الأشخاص'),
                    description: Column(
                      children: <Widget>[
                        Text('هنا تجد قائمة بكل الأشخاص بالبرنامج'),
                        OutlinedButton.icon(
                          icon: Icon(Icons.forward),
                          label: Text(
                            'التالي',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText2.color,
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
                                  Theme.of(context).textTheme.bodyText2.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Theme.of(context).accentColor,
                    targetColor: Colors.transparent,
                    textColor:
                        Theme.of(context).primaryTextTheme.bodyText1.color,
                    child: const Icon(Icons.person),
                  ),
                ),
              ],
            ),
            title: StreamBuilder<bool>(
                initialData: _showSearch.value,
                stream: _showSearch,
                builder: (context, showSearch) {
                  return showSearch.data
                      ? TextField(
                          focusNode: searchFocus,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.close,
                                    color: Theme.of(context)
                                        .primaryTextTheme
                                        .headline6
                                        .color),
                                onPressed: () {
                                  _searchQuery.add('');
                                  _showSearch.add(false);
                                },
                              ),
                              hintText: 'بحث ...'),
                          onChanged: _searchQuery.add,
                        )
                      : Text('البيانات');
                })),
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
                        builder: (context, _) => Icon(_tabController.index == 0
                            ? Icons.add_location
                            : _tabController.index == 1
                                ? Icons.add_road
                                : _tabController.index == 2
                                    ? Icons.group_add
                                    : Icons.person_add),
                      ),
                    )
                  : Container(width: 1, height: 1);
            }),
        bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).primaryColor,
          shape: CircularNotchedRectangle(),
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) => StreamBuilder(
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
                      StrutStyle(height: IconTheme.of(context).size / 7.5),
                  style: Theme.of(context).primaryTextTheme.bodyText1,
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            DataObjectList<Area>(options: _areasOptions),
            DataObjectList<Street>(options: _streetsOptions),
            DataObjectList<Family>(options: _familiesOptions),
            DataObjectList<Person>(options: _personsOptions),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              Consumer<User>(
                builder: (context, user, _) => DrawerHeader(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/Logo.png'),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 86, 213, 170),
                        Color.fromARGB(255, 39, 124, 205)
                      ],
                      stops: [0, 1],
                    ),
                  ),
                  child: Container(),
                ),
              ),
              ListTile(
                leading: Consumer<User>(
                  builder: (context, user, snapshot) {
                    return DescribedFeatureOverlay(
                      backgroundDismissible: false,
                      barrierDismissible: false,
                      contentLocation: ContentLocation.below,
                      featureId: 'MyAccount',
                      tapTarget: user.getPhoto(true, false),
                      title: Text('حسابي'),
                      description: Column(
                        children: <Widget>[
                          Text(
                              'يمكنك الاطلاع على حسابك بالبرنامج وجميع الصلاحيات التي تملكها من خلال حسابي'),
                          OutlinedButton.icon(
                            icon: Icon(Icons.forward),
                            label: Text(
                              'التالي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
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
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyText1.color,
                      child: user.getPhoto(true, false),
                    );
                  },
                ),
                title: Text('حسابي'),
                onTap: () {
                  Navigator.pushNamed(context, 'MyAccount');
                },
              ),
              Selector<User, bool>(
                selector: (_, user) =>
                    user.manageUsers || user.manageAllowedUsers,
                builder: (context, permission, _) {
                  if (!permission)
                    return Container(
                      width: 0,
                      height: 0,
                    );
                  return ListTile(
                    leading: DescribedFeatureOverlay(
                      backgroundDismissible: false,
                      barrierDismissible: false,
                      featureId: 'ManageUsers',
                      tapTarget: Icon(
                          const IconData(0xef3d, fontFamily: 'MaterialIconsR')),
                      contentLocation: ContentLocation.below,
                      title: Text('إدارة المستخدمين'),
                      description: Column(
                        children: <Widget>[
                          Text(
                              'يمكنك دائمًا الاطلاع على مستخدمي البرنامج وتعديل صلاحياتهم من هنا'),
                          OutlinedButton.icon(
                            icon: Icon(Icons.forward),
                            label: Text(
                              'التالي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
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
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyText1.color,
                      child: Icon(
                        const IconData(0xef3d, fontFamily: 'MaterialIconsR'),
                      ),
                    ),
                    onTap: () {
                      mainScfld.currentState.openEndDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthScreen(
                            nextWidget: UsersPage(),
                          ),
                        ),
                      );
                    },
                    title: Text('إدارة المستخدمين'),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: DescribedFeatureOverlay(
                  backgroundDismissible: false,
                  barrierDismissible: false,
                  featureId: 'DataMap',
                  contentLocation: ContentLocation.below,
                  tapTarget: const Icon(Icons.map),
                  title: Text('خريطة الافتقاد'),
                  description: Column(
                    children: [
                      Text(
                          'يمكنك دائمًا الاطلاع على جميع مواقع العائلات بالبرنامج عن طريق خريطة الافتقاد'),
                      OutlinedButton.icon(
                        icon: Icon(Icons.forward),
                        label: Text(
                          'التالي',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText2.color,
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
                            color: Theme.of(context).textTheme.bodyText2.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).accentColor,
                  targetColor: Colors.transparent,
                  textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                  child: Icon(Icons.map),
                ),
                title: Text('عرض خريطة الافتقاد'),
                onTap: () {
                  mainScfld.currentState.openEndDrawer();
                  Navigator.of(context).pushNamed('DataMap');
                },
              ),
              ListTile(
                leading: DescribedFeatureOverlay(
                  backgroundDismissible: false,
                  barrierDismissible: false,
                  contentLocation: ContentLocation.below,
                  featureId: 'AdvancedSearch',
                  tapTarget: Icon(Icons.search),
                  title: Text('البحث المفصل'),
                  description: Column(
                    children: <Widget>[
                      Text(
                          'يمكن عمل بحث مفصل عن البيانات بالبرنامج بالخصائص المطلوبة\nمثال: عرض كل الأشخاص الذين يصادف عيد ميلادهم اليوم\nعرض كل الأشخاص داخل منطقة معينة'),
                      OutlinedButton.icon(
                        icon: Icon(Icons.forward),
                        label: Text(
                          'التالي',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText2.color,
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
                            color: Theme.of(context).textTheme.bodyText2.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).accentColor,
                  targetColor: Colors.transparent,
                  textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                  child: const Icon(Icons.search),
                ),
                title: Text('بحث مفصل'),
                onTap: () {
                  mainScfld.currentState.openEndDrawer();
                  Navigator.of(context).pushNamed('Search');
                },
              ),
              Divider(),
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
                  title: Text('الإعدادات'),
                  description: Column(
                    children: <Widget>[
                      Text(
                          'يمكنك ضبط بعض الاعدادات بالبرنامج مثل مظهر البرنامج ومظهر البيانات وبعض البيانات الاضافية مثل الوظائف والأباء الكهنة'),
                      OutlinedButton(
                        onPressed: () =>
                            FeatureDiscovery.completeCurrentStep(context),
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText2.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).accentColor,
                  targetColor: Colors.transparent,
                  textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                  child: const Icon(Icons.settings),
                ),
                title: Text('الإعدادات'),
                onTap: () {
                  mainScfld.currentState.openEndDrawer();
                  Navigator.of(context).pushNamed('Settings');
                },
              ),
              Selector<User, bool>(
                  selector: (_, user) => user.write,
                  builder: (context2, permission, _) {
                    return permission
                        ? ListTile(
                            leading: Icon(Icons.cloud_upload),
                            title: Text('استيراد من ملف اكسل'),
                            onTap: () {
                              mainScfld.currentState.openEndDrawer();
                              import(context);
                            },
                          )
                        : Container();
                  }),
              Selector<User, bool>(
                selector: (_, user) => user.exportAreas,
                builder: (context2, permission, _) {
                  return permission
                      ? ListTile(
                          leading: Icon(Icons.cloud_download),
                          title: Text('تصدير منطقة إلى ملف اكسل'),
                          onTap: () async {
                            mainScfld.currentState.openEndDrawer();
                            Area rslt = await showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Column(
                                  children: [
                                    Text(
                                        'برجاء اختيار المنطقة التي تريد تصديرها:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5),
                                    Expanded(
                                      child: DataObjectList<Area>(
                                        options: DataObjectListOptions(
                                          searchQuery: Stream.value(''),
                                          itemsStream: Area.getAllForUser().map(
                                              (s) => s.docs
                                                  .map(Area.fromDoc)
                                                  .toList()),
                                          tap: (area) =>
                                              Navigator.pop(context, area),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (rslt != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('جار تصدير ' + rslt.name + '...'),
                                      LinearProgressIndicator(),
                                    ],
                                  ),
                                  duration: Duration(minutes: 9),
                                ),
                              );
                              try {
                                String filename = Uri.decodeComponent(
                                    (await FirebaseFunctions.instance
                                            .httpsCallable('exportToExcel')
                                            .call({'onlyArea': rslt.id}))
                                        .data);
                                var file = await File(
                                        (await getApplicationDocumentsDirectory())
                                                .path +
                                            '/' +
                                            filename.replaceAll(':', ''))
                                    .create(recursive: true);
                                await FirebaseStorage.instance
                                    .ref(filename)
                                    .writeToFile(file);
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم تصدير البيانات ينجاح'),
                                    action: SnackBarAction(
                                      label: 'فتح',
                                      onPressed: () {
                                        OpenFile.open(file.path);
                                      },
                                    ),
                                  ),
                                );
                              } on Exception catch (e, st) {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('فشل تصدير البيانات')),
                                );
                                await FirebaseCrashlytics.instance.setCustomKey(
                                    'LastErrorIn', 'Root.exportOnlyArea');
                                await FirebaseCrashlytics.instance
                                    .recordError(e, st);
                              }
                            }
                          },
                        )
                      : Container();
                },
              ),
              Selector<User, bool>(
                selector: (_, user) => user.exportAreas,
                builder: (context2, permission, _) {
                  return permission
                      ? ListTile(
                          leading: Icon(Icons.file_download),
                          title: Text('تصدير جميع البيانات'),
                          onTap: () async {
                            mainScfld.currentState.openEndDrawer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'جار تصدير جميع البيانات...\nيرجى الانتظار...'),
                                    LinearProgressIndicator(),
                                  ],
                                ),
                                duration: Duration(minutes: 9),
                              ),
                            );
                            try {
                              String filename = Uri.decodeComponent(
                                  (await FirebaseFunctions.instance
                                          .httpsCallable('exportToExcel')
                                          .call())
                                      .data);
                              var file = await File(
                                      (await getApplicationDocumentsDirectory())
                                              .path +
                                          '/' +
                                          filename.replaceAll(':', ''))
                                  .create(recursive: true);
                              await FirebaseStorage.instance
                                  .ref(filename)
                                  .writeToFile(file);
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم تصدير البيانات ينجاح'),
                                  action: SnackBarAction(
                                    label: 'فتح',
                                    onPressed: () {
                                      OpenFile.open(file.path);
                                    },
                                  ),
                                ),
                              );
                            } on Exception catch (e, st) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل تصدير البيانات')),
                              );
                              await FirebaseCrashlytics.instance.setCustomKey(
                                  'LastErrorIn', 'Root.exportAll');
                              await FirebaseCrashlytics.instance
                                  .recordError(e, st);
                            }
                          },
                        )
                      : Container();
                },
              ),
              Divider(),
              if (!kIsWeb)
                ListTile(
                  leading: Icon(Icons.system_update_alt),
                  title: Text('تحديث البرنامج'),
                  onTap: () {
                    mainScfld.currentState.openEndDrawer();
                    Navigator.of(context).pushNamed('Update');
                  },
                ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('حول البرنامج'),
                onTap: () async {
                  mainScfld.currentState.openEndDrawer();
                  showAboutDialog(
                    context: context,
                    applicationIcon: Image.asset('assets/Logo2.png',
                        width: 100, height: 100),
                    applicationName: 'بيانات الكنيسة',
                    applicationLegalese:
                        'جميع الحقوق محفوظة: كنيسة السيدة العذراء مريم بالاسماعيلية',
                    applicationVersion:
                        (await PackageInfo.fromPlatform()).version,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final url =
                              'https://church-data.flycricket.io/terms.html';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                        child: Text('شروط الاستخدام'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final url =
                              'https://church-data.flycricket.io/privacy.html';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                        child: Text('سياسة الخصوصية'),
                      ),
                    ],
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('تسجيل الخروج'),
                onTap: () async {
                  mainScfld.currentState.openEndDrawer();
                  await auth.FirebaseAuth.instance.signOut();
                  await Hive.box('Settings').put('FCM_Token_Registered', false);
                  // ignore: unawaited_futures
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        return App();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_timeout && !_pushed) {
          _pushed = true;
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) => WillPopScope(
                onWillPop: () => Future.delayed(Duration.zero, () => false),
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
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _keepAlive(false);
        _recordLastSeen();
        break;
    }
  }

  void _recordLastSeen() async {
    await User.instance.recordLastSeen();
  }

  void _recordActive() async {
    await User.instance.recordActive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    changeTheme(context: mainScfld.currentContext);
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar_EG', null);
    _tabController = TabController(vsync: this, length: 4);
    WidgetsBinding.instance.addObserver(this);
    _keepAlive(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showPendingUIDialogs();
    });
  }

  Future showDynamicLink() async {
    PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();

    FirebaseDynamicLinks.instance.onLink(
      onSuccess: (dynamicLink) async {
        if (dynamicLink == null) return;
        Uri deepLink = dynamicLink.link;

        await processLink(deepLink, context);
      },
      onError: (e) async {
        debugPrint('DynamicLinks onError $e');
      },
    );
    if (data == null) return;
    Uri deepLink = data.link;
    await processLink(deepLink, context);
  }

  void showPendingUIDialogs() async {
    if (!await User.instance.userDataUpToDate()) {
      await showErrorUpdateDataDialog(context: context, pushApp: false);
    }
    if (!kIsWeb) await showDynamicLink();
    if (!kIsWeb) await showPendingMessage(context);
    if (!kIsWeb) await processClickedNotification(context);
    if (!kIsWeb) await showBatteryOptimizationDialog();
    FeatureDiscovery.discoverFeatures(context, [
      'Areas',
      'Streets',
      'Families',
      'Persons',
      'Search',
      'MyAccount',
      if (User.instance.manageUsers || User.instance.manageAllowedUsers)
        'ManageUsers',
      'DataMap',
      'AdvancedSearch',
      'Settings'
    ]);
  }

  Future<void> showBatteryOptimizationDialog() async {
    if ((await DeviceInfoPlugin().androidInfo).version.sdkInt >= 23 &&
        !await BatteryOptimization.isIgnoringBatteryOptimizations() &&
        Hive.box('Settings').get('ShowBatteryDialog', defaultValue: true)) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(
              'برجاء الغاء تفعيل حفظ الطاقة للبرنامج لإظهار الاشعارات في الخلفية'),
          actions: [
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                await BatteryOptimization.openBatteryOptimizationSettings();
              },
              child: Text('الغاء حفظ الطاقة للبرنامج'),
            ),
            TextButton(
              onPressed: () async {
                await Hive.box('Settings').put('ShowBatteryDialog', false);
                Navigator.pop(context);
              },
              child: Text('عدم الاظهار مجددًا'),
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
        Duration(minutes: 1),
        () => _timeout = true,
      );
    }
  }
}
