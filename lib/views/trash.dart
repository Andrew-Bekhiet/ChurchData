import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../models/super_classes.dart';

class Trash extends StatelessWidget {
  const Trash({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سلة المحذوفات')),
      body: DataObjectList<TrashDay>(
        autoDisposeController: true,
        options: DataObjectListController<TrashDay>(
          onLongPress: (_) {},
          tap: (day) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => TrashDayScreen(day)));
          },
          itemsStream: firestore
              .collection('Deleted')
              .orderBy('Time', descending: true)
              .snapshots()
              .map(
                (s) => s.docs
                    .map(
                      (d) => TrashDay(d.data()['Time'].toDate(), d.reference),
                    )
                    .toList(),
              ),
        ),
      ),
    );
  }
}

class TrashDay extends DataObject {
  final DateTime date;
  TrashDay(this.date, JsonRef ref)
      : super(ref, date.toUtc().toIso8601String().split('T')[0],
            Colors.transparent);

  @override
  Json getHumanReadableMap() {
    return {'Time': toDurationString(Timestamp.fromDate(date))};
  }

  @override
  Json getMap() {
    return {'Time': Timestamp.fromDate(date)};
  }

  @override
  Future<String> getSecondLine() async {
    return name;
  }

  @override
  TrashDay copyWith() {
    throw UnimplementedError();
  }
}

class TrashDayScreen extends StatefulWidget {
  final TrashDay day;
  const TrashDayScreen(this.day, {Key? key}) : super(key: key);

  @override
  _TrashDayScreenState createState() => _TrashDayScreenState();
}

class _TrashDayScreenState extends State<TrashDayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final BehaviorSubject<bool> _showSearch = BehaviorSubject<bool>.seeded(false);
  final FocusNode searchFocus = FocusNode();

  late final DataObjectListController<Area> _areasOptions;
  late final DataObjectListController<Street> _streetsOptions;
  late final DataObjectListController<Family> _familiesOptions;
  late final DataObjectListController<Person> _personsOptions;

  final BehaviorSubject<String> _searchQuery =
      BehaviorSubject<String>.seeded('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          StreamBuilder<bool>(
            initialData: _showSearch.value,
            stream: _showSearch,
            builder: (context, showSearch) {
              return !showSearch.data!
                  ? IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        searchFocus.requestFocus();
                        _showSearch.add(true);
                      },
                    )
                  : Container();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.pin_drop),
            ),
            Tab(
              child: Image.asset('assets/streets.png',
                  width: IconTheme.of(context).size,
                  height: IconTheme.of(context).size,
                  color: Theme.of(context).primaryTextTheme.bodyText1?.color),
            ),
            const Tab(
              icon: Icon(Icons.group),
            ),
            const Tab(
              icon: Icon(Icons.person),
            ),
          ],
        ),
        title: StreamBuilder<bool>(
          initialData: _showSearch.value,
          stream: _showSearch,
          builder: (context, showSearch) {
            return showSearch.data!
                ? TextField(
                    focusNode: searchFocus,
                    decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(Icons.close,
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .headline6
                                  ?.color),
                          onPressed: () {
                            _searchQuery.add('');
                            _showSearch.add(false);
                          },
                        ),
                        hintText: 'بحث ...'),
                    onChanged: _searchQuery.add,
                  )
                : Text(widget.day.name);
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
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
                style: Theme.of(context).primaryTextTheme.bodyText1,
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DataObjectList<Area>(
            autoDisposeController: false,
            options: _areasOptions,
          ),
          DataObjectList<Street>(
            autoDisposeController: false,
            options: _streetsOptions,
          ),
          DataObjectList<Family>(
            autoDisposeController: false,
            options: _familiesOptions,
          ),
          DataObjectList<Person>(
            autoDisposeController: false,
            options: _personsOptions,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _tabController = TabController(vsync: this, length: 4);

    _areasOptions = DataObjectListController<Area>(
      searchQuery: _searchQuery,
      //Listen to Ordering options and combine it
      //with the Data Stream from Firestore
      itemsStream: (User.instance.superAccess
              ? widget.day.ref.collection('Areas')
              : widget.day.ref
                  .collection('Areas')
                  .where('Allowed', arrayContains: User.instance.uid))
          .snapshots()
          .map(
            (s) => s.docs.map(Area.fromQueryDoc).toList(),
          ),
    );
    _streetsOptions = DataObjectListController<Street>(
      searchQuery: _searchQuery,
      itemsStream: (User.instance.superAccess
              ? widget.day.ref.collection('Streets').snapshots()
              : firestore
                  .collection('Areas')
                  .where('Allowed', arrayContains: User.instance.uid)
                  .snapshots()
                  .switchMap(
                    (areas) => widget.day.ref
                        .collection('Streets')
                        .where('AreaId',
                            whereIn:
                                areas.docs.map((e) => e.reference).toList())
                        .snapshots(),
                  ))
          .map(
        (s) => s.docs.map(Street.fromQueryDoc).toList(),
      ),
    );
    _familiesOptions = DataObjectListController<Family>(
      searchQuery: _searchQuery,
      itemsStream: (User.instance.superAccess
              ? widget.day.ref.collection('Families').snapshots()
              : firestore
                  .collection('Areas')
                  .where('Allowed', arrayContains: User.instance.uid)
                  .snapshots()
                  .switchMap(
                    (areas) => widget.day.ref
                        .collection('Families')
                        .where('AreaId',
                            whereIn:
                                areas.docs.map((e) => e.reference).toList())
                        .snapshots(),
                  ))
          .map(
        (s) => s.docs.map(Family.fromQueryDoc).toList(),
      ),
    );
    _personsOptions = DataObjectListController<Person>(
      searchQuery: _searchQuery,
      itemsStream: (User.instance.superAccess
              ? widget.day.ref.collection('Persons').snapshots()
              : firestore
                  .collection('Areas')
                  .where('Allowed', arrayContains: User.instance.uid)
                  .snapshots()
                  .switchMap(
                    (areas) => widget.day.ref
                        .collection('Persons')
                        .where('AreaId',
                            whereIn:
                                areas.docs.map((e) => e.reference).toList())
                        .snapshots(),
                  ))
          .map(
        (s) => s.docs.map(Person.fromQueryDoc).toList(),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    WidgetsBinding.instance!.removeObserver(this);

    await _areasOptions.dispose();
    await _streetsOptions.dispose();
    await _familiesOptions.dispose();
    await _personsOptions.dispose();

    await _showSearch.close();
    await _searchQuery.close();
  }
}
