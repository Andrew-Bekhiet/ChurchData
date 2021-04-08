import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'lists.dart';
import '../models/super_classes.dart';

class Trash extends StatelessWidget {
  const Trash({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listOptions = DataObjectListOptions<TrashDay>(
      onLongPress: (_) {},
      tap: (day) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => TrashDayScreen(day)));
      },
      searchQuery: BehaviorSubject<String>.seeded(''),
      itemsStream: FirebaseFirestore.instance
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
    );
    return Scaffold(
      appBar: AppBar(title: Text('سلة المحذوفات')),
      body: DataObjectList<TrashDay>(options: listOptions),
    );
  }
}

class TrashDay extends DataObject {
  final DateTime date;
  TrashDay(this.date, DocumentReference ref)
      : super(ref, date.toUtc().toIso8601String().split('T')[0],
            Colors.transparent);

  @override
  Map<String, dynamic> getHumanReadableMap() {
    return {'Time': toDurationString(Timestamp.fromDate(date))};
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Time': Timestamp.fromDate(date)};
  }

  @override
  Future<String> getSecondLine() async {
    return name;
  }
}

class TrashDayScreen extends StatefulWidget {
  final TrashDay day;
  const TrashDayScreen(this.day, {Key key}) : super(key: key);

  @override
  _TrashDayScreenState createState() => _TrashDayScreenState();
}

class _TrashDayScreenState extends State<TrashDayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController _tabController;
  final BehaviorSubject<bool> _showSearch = BehaviorSubject<bool>.seeded(false);
  final FocusNode searchFocus = FocusNode();

  final BehaviorSubject<String> _searchQuery =
      BehaviorSubject<String>.seeded('');

  @override
  Widget build(BuildContext context) {
    final DataObjectListOptions<Area> _areasOptions =
        DataObjectListOptions<Area>(
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
            (s) => s.docs.map(Area.fromDoc).toList(),
          ),
    );
    final DataObjectListOptions<Street> _streetsOptions =
        DataObjectListOptions<Street>(
      searchQuery: _searchQuery,
      itemsStream: (User.instance.superAccess
              ? widget.day.ref.collection('Streets').snapshots()
              : FirebaseFirestore.instance
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
        (s) => s.docs.map(Street.fromDoc).toList(),
      ),
    );
    final DataObjectListOptions<Family> _familiesOptions =
        DataObjectListOptions<Family>(
      searchQuery: _searchQuery,
      itemsStream: (User.instance.superAccess
              ? widget.day.ref.collection('Families').snapshots()
              : FirebaseFirestore.instance
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
        (s) => s.docs.map(Family.fromDoc).toList(),
      ),
    );
    final DataObjectListOptions<Person> _personsOptions =
        DataObjectListOptions<Person>(
      searchQuery: _searchQuery,
      itemsStream: (User.instance.superAccess
              ? widget.day.ref.collection('Persons').snapshots()
              : FirebaseFirestore.instance
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
        (s) => s.docs.map(Person.fromDoc).toList(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          StreamBuilder<bool>(
            initialData: _showSearch.value,
            stream: _showSearch,
            builder: (context, showSearch) {
              return !showSearch.data
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
            Tab(
              icon: const Icon(Icons.pin_drop),
            ),
            Tab(
              child: Image.asset('assets/streets.png',
                  width: IconTheme.of(context).size,
                  height: IconTheme.of(context).size,
                  color: Theme.of(context).primaryTextTheme.bodyText1.color),
            ),
            Tab(
              icon: Icon(Icons.group),
            ),
            Tab(
              icon: Icon(Icons.person),
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
                : Text(widget.day.name);
          },
        ),
      ),
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
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 4);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
