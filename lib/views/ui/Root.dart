import 'dart:async';

import 'package:battery_optimization/battery_optimization.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Models.dart';
import '../../Models/ListOptions.dart';
import '../../Models/OrderOptions.dart';
import '../../Models/SearchString.dart';
import '../../Models/User.dart';
import '../../main.dart';
import '../../utils/Helpers.dart';
import '../../utils/globals.dart';
import 'AuthScreen.dart';
import 'EditUsers.dart';
import '../../views/utils/List.dart';

class Root extends StatefulWidget {
  Root({Key key}) : super(key: key);
  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController _tabController;
  Timer _keepAliveTimer;
  bool _timeout = false;
  bool _pushed = false;
  bool _showSearch = false;
  FocusNode searchFocus = FocusNode();

  /*final showCaseCompleter = Completer();
  final GlobalKey _areasKey = GlobalKey();
  final GlobalKey _streetsKey = GlobalKey();
  final GlobalKey _familiesKey = GlobalKey();
  final GlobalKey _personsKey = GlobalKey();*/

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
    return WillPopScope(
      onWillPop: () async =>
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text('هل تريد الخروج؟'),
              actions: [
                TextButton(
                  child: Text('نعم'),
                  onPressed: () => Navigator.pop(context, true),
                ),
                TextButton(
                  child: Text('لا'),
                  onPressed: () => Navigator.pop(context, false),
                )
              ],
            ),
          ) ??
          false,
      child: ListenableProvider<SearchString>(
        create: (_) => SearchString(''),
        builder: (context, child) => Selector<User, bool>(
          selector: (_, user) => user.write,
          builder: (context, write, _) => Scaffold(
            key: mainScfld,
            appBar: AppBar(
              actions: <Widget>[
                if (_showSearch)
                  IconButton(
                    icon: Icon(Icons.filter_list),
                    onPressed: () async {
                      var orderOptions = context.read<OrderOptions>();
                      await showDialog(
                        context: context,
                        builder: (context) => SimpleDialog(
                          children: [
                            TextButton.icon(
                              icon: Icon(Icons.select_all),
                              label: Text('تحديد الكل'),
                              onPressed: () {
                                if (_tabController.index == 0) {
                                  orderOptions.areaSelectAll.add(true);
                                } else if (_tabController.index == 1) {
                                  orderOptions.streetSelectAll.add(true);
                                } else if (_tabController.index == 2) {
                                  orderOptions.familySelectAll.add(true);
                                } else if (_tabController.index == 3) {
                                  orderOptions.personSelectAll.add(true);
                                }
                                Navigator.pop(context);
                              },
                            ),
                            TextButton.icon(
                              icon: Icon(Icons.select_all),
                              label: Text('تحديد لا شئ'),
                              onPressed: () {
                                if (_tabController.index == 0) {
                                  orderOptions.areaSelectAll.add(false);
                                } else if (_tabController.index == 1) {
                                  orderOptions.streetSelectAll.add(false);
                                } else if (_tabController.index == 2) {
                                  orderOptions.familySelectAll.add(false);
                                } else if (_tabController.index == 3) {
                                  orderOptions.personSelectAll.add(false);
                                }
                                Navigator.pop(context);
                              },
                            ),
                            Text('ترتيب حسب:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            ...getOrderingOptions(
                                context, orderOptions, _tabController.index),
                          ],
                        ),
                      );
                      setState(() {});
                    },
                  )
                else
                  IconButton(
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
                                FeatureDiscovery.completeCurrentStep(context);
                                mainScfld.currentState.openDrawer();
                              },
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
                        textColor:
                            Theme.of(context).primaryTextTheme.bodyText1.color,
                        child: const Icon(Icons.search),
                      ),
                      onPressed: () => setState(() {
                            searchFocus.requestFocus();
                            _showSearch = true;
                          })),
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
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () =>
                                FeatureDiscovery.dismissAll(context),
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
                              child: Image.asset('assets/streets.png',
                                  width: IconTheme.of(context).size,
                                  height: IconTheme.of(context).size,
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText1
                                      .color),
                            ),
                            margin: const EdgeInsets.only(bottom: 10.0),
                          ),
                        ),
                        Flexible(
                            child: Text('الشوارع',
                                softWrap: false, overflow: TextOverflow.fade),
                            flex: 15),
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
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () =>
                                FeatureDiscovery.dismissAll(context),
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
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () =>
                                FeatureDiscovery.dismissAll(context),
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
              title: _showSearch
                  ? TextField(
                      focusNode: searchFocus,
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(Icons.close,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .headline6
                                    .color),
                            onPressed: () => setState(
                              () {
                                context.read<SearchString>().value = '';
                                _showSearch = false;
                              },
                            ),
                          ),
                          hintText: 'بحث ...'),
                      onChanged: (t) => context.read<SearchString>().value = t,
                    )
                  : Text('البيانات'),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                Selector<OrderOptions, Tuple2<String, bool>>(
                  selector: (_, o) =>
                      Tuple2<String, bool>(o.areaOrderBy, o.areaASC),
                  builder: (context, options, child) => DataObjectList<Area>(
                    options: ListOptions<Area>(
                      floatingActionButton: write
                          ? FloatingActionButton(
                              heroTag: null,
                              onPressed: addTap,
                              child: Icon(Icons.add_location),
                            )
                          : null,
                      tap: areaTap,
                      generate: Area.fromDocumentSnapshot,
                      documentsData: () => Area.getAllForUser(
                          orderBy: options.item1, descending: !options.item2),
                    ),
                  ),
                ),
                Selector<OrderOptions, Tuple2<String, bool>>(
                  selector: (_, o) =>
                      Tuple2<String, bool>(o.streetOrderBy, o.streetASC),
                  builder: (context, options, child) => DataObjectList<Street>(
                    options: ListOptions<Street>(
                      floatingActionButton: write
                          ? FloatingActionButton(
                              heroTag: null,
                              onPressed: addTap,
                              child: Icon(Icons.add_road),
                            )
                          : null,
                      tap: streetTap,
                      generate: Street.fromDocumentSnapshot,
                      documentsData: () => Street.getAllForUser(
                          orderBy: options.item1, descending: !options.item2),
                    ),
                  ),
                ),
                Selector<OrderOptions, Tuple2<String, bool>>(
                  selector: (_, o) =>
                      Tuple2<String, bool>(o.familyOrderBy, o.familyASC),
                  builder: (context, options, child) => DataObjectList<Family>(
                    options: ListOptions<Family>(
                      floatingActionButton: write
                          ? PopupMenuButton<bool>(
                              child: FloatingActionButton(
                                  child: Icon(Icons.add), onPressed: null),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  child: ListTile(
                                    leading: Icon(Icons.add_business),
                                    title: Text('اضافة محل'),
                                  ),
                                  value: true,
                                ),
                                PopupMenuItem(
                                  child: ListTile(
                                    leading: Icon(Icons.group_add),
                                    title: Text('اضافة عائلة'),
                                  ),
                                  value: false,
                                )
                              ],
                              onSelected: addTap,
                            )
                          : null,
                      tap: familyTap,
                      generate: Family.fromDocumentSnapshot,
                      documentsData: () => Family.getAllForUser(
                          orderBy: options.item1, descending: !options.item2),
                    ),
                  ),
                ),
                Selector<OrderOptions, Tuple2<String, bool>>(
                  selector: (_, o) =>
                      Tuple2<String, bool>(o.personOrderBy, o.personASC),
                  builder: (context, options, child) => DataObjectList<Person>(
                    options: ListOptions<Person>(
                      floatingActionButton: write
                          ? FloatingActionButton(
                              heroTag: null,
                              onPressed: addTap,
                              child: Icon(Icons.person_add),
                            )
                          : null,
                      tap: personTap,
                      generate: Person.fromDocumentSnapshot,
                      documentsData: () => Person.getAllForUser(
                          orderBy: options.item1, descending: !options.item2),
                    ),
                  ),
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                children: <Widget>[
                  Consumer<User>(
                    builder: (context, user, _) => DrawerHeader(
                      child: Container(),
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
                    selector: (_, user) => user.manageUsers,
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
                          tapTarget: Icon(const IconData(0xef3d,
                              fontFamily: 'MaterialIconsR')),
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
                          child: Icon(
                            const IconData(0xef3d,
                                fontFamily: 'MaterialIconsR'),
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
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () =>
                                FeatureDiscovery.completeCurrentStep(context),
                          ),
                          OutlinedButton(
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () =>
                                FeatureDiscovery.dismissAll(context),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyText1.color,
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
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () =>
                                FeatureDiscovery.completeCurrentStep(context),
                          ),
                          OutlinedButton(
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () =>
                                FeatureDiscovery.dismissAll(context),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyText1.color,
                      child: const Icon(Icons.search),
                    ),
                    title: Text('بحث مفصل'),
                    onTap: () {
                      mainScfld.currentState.openEndDrawer();
                      Navigator.of(context).pushNamed('Search');
                    },
                  ),
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
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () =>
                                FeatureDiscovery.completeCurrentStep(context),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyText1.color,
                      child: const Icon(Icons.settings),
                    ),
                    title: Text('الإعدادات'),
                    onTap: () {
                      mainScfld.currentState.openEndDrawer();
                      Navigator.of(context).pushNamed('Settings');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.cloud_upload),
                    title: Text('استيراد من ملف اكسل'),
                    onTap: () {
                      mainScfld.currentState.openEndDrawer();
                      import(context);
                    },
                  ),
                  Selector<User, bool>(
                    selector: (_, user) => user.exportAreas,
                    builder: (context, permission, _) {
                      return permission
                          ? ListTile(
                              leading: Icon(Icons.cloud_download),
                              title: Text('تصدير إلى ملف اكسل'),
                              onTap: () {
                                mainScfld.currentState.openEndDrawer();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'برجاء اختيار المنطقة التي تريد تصدير بياناتها'),
                                  ),
                                );
                                export = !export;
                              },
                            )
                          : Container();
                    },
                  ),
                  Selector<User, bool>(
                    selector: (_, user) => user.exportAreas,
                    builder: (context, permission, _) {
                      return permission
                          ? ListTile(
                              leading: Icon(Icons.analytics),
                              title: Text('تصدير لتحليل البيانات'),
                              onTap: () {
                                mainScfld.currentState.openEndDrawer();
                                analysisExport(context);
                              },
                            )
                          : Container();
                    },
                  ),
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
                            child: Text('شروط الاستخدام'),
                            onPressed: () async {
                              final url =
                                  'https://church-data.flycricket.io/terms.html';
                              if (await canLaunch(url)) {
                                await launch(url);
                              }
                            },
                          ),
                          TextButton(
                            child: Text('سياسة الخصوصية'),
                            onPressed: () async {
                              final url =
                                  'https://church-data.flycricket.io/privacy.html';
                              if (await canLaunch(url)) {
                                await launch(url);
                              }
                            },
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
                      await Hive.box('Settings')
                          .put('FCM_Token_Registered', false);
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
                child: AuthScreen(),
                onWillPop: () => Future.delayed(Duration.zero, () => false),
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
    await mainScfld.currentContext.read<User>().recordLastSeen();
  }

  void _recordActive() async {
    await mainScfld.currentContext.read<User>().recordActive();
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
    startKeepAlive();
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
    if (!await context.read<User>().userDataUpToDate()) {
      await showErrorUpdateDataDialog(context: context, pushApp: false);
    }
    await showDynamicLink();
    await showPendingMessage(context);
    await processClickedNotification(context);
    await showBatteryOptimizationDialog();
    FeatureDiscovery.discoverFeatures(context, [
      'Areas',
      'Streets',
      'Families',
      'Persons',
      'Search',
      'MyAccount',
      if (context.read<User>().manageUsers) 'ManageUsers',
      'DataMap',
      'AdvancedSearch',
      'Settings'
    ]);
  }

  void showBatteryOptimizationDialog() async {
    if (!await BatteryOptimization.isIgnoringBatteryOptimizations() &&
        Hive.box('Settings').get('ShowBatteryDialog', defaultValue: true)) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(
              'برجاء الغاء تفعيل حفظ الطاقة للبرنامج لإظهار الاشعارات في الخلفية'),
          actions: [
            OutlineButton(
              child: Text('الغاء حفظ الطاقة للبرنامج'),
              onPressed: () async {
                await Navigator.pop(context);
                await BatteryOptimization.openBatteryOptimizationSettings();
              },
            ),
            TextButton(
              child: Text('عدم الاظهار مجددًا'),
              onPressed: () async {
                await Hive.box('Settings').put('ShowBatteryDialog', false);
                await Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  void startKeepAlive() {
    assert(_keepAliveTimer == null);
    _keepAlive(true);
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
