import 'package:churchdata/views/MiniLists/ColorsList.dart';
import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:churchdata/views/utils/SearchFilters.dart';
import 'package:churchdata/views/utils/List.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import '../../Models.dart';
import '../../Models/MiniModels.dart';
import '../../Models/User.dart';
import '../../utils/Helpers.dart';
import '../../utils/globals.dart';
import 'Lists.dart';

class SearchQuery extends StatefulWidget {
  final Map<String, dynamic> query;

  SearchQuery({Key key, this.query}) : super(key: key);

  @override
  _SearchQueryState createState() => _SearchQueryState();
}

class _SearchQueryState extends State<SearchQuery> {
  static int parentIndex = 0;
  static int childIndex = 0;
  static int operatorIndex = 0;

  static dynamic queryValue = '';
  static String queryText = '';
  static bool birthDate = false;

  bool descending = false;
  String orderBy = 'Name';

  List<DropdownMenuItem> operatorItems = <DropdownMenuItem>[
    DropdownMenuItem(
      value: 0,
      child: Text('='),
    ),
    DropdownMenuItem(
      value: 1,
      child: Text('قائمة تحتوي على'),
    ),
    DropdownMenuItem(
      value: 2,
      child: Text('أكبر من'),
    ),
    DropdownMenuItem(
      value: 3,
      child: Text('أصغر من'),
    ),
  ];

  List<List<DropdownMenuItem>> childItems = <List<DropdownMenuItem>>[
    <DropdownMenuItem>[
      DropdownMenuItem(
        value: MapEntry(1, 'Name'),
        child: Text('اسم المنطقة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          1,
          'Address',
        ),
        child: Text('عنوان المنطقة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          0,
          'LastVisit',
        ),
        child: Text('تاريخ أخر زيارة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          0,
          'FatherLastVisit',
        ),
        child: Text('تاريخ أخر زيارة للأب الكاهن'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          14,
          'Color',
        ),
        child: Text('اللون'),
      ),
    ],
    <DropdownMenuItem>[
      DropdownMenuItem(
        value: MapEntry(1, 'Name'),
        child: Text('اسم الشارع'),
      ),
      DropdownMenuItem(
        value: MapEntry(0, 'LastVisit'),
        child: Text('تاريخ أخر زيارة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          0,
          'FatherLastVisit',
        ),
        child: Text('تاريخ أخر زيارة للأب الكاهن'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          2,
          'AreaId',
        ),
        child: Text('داخل منطقة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          14,
          'Color',
        ),
        child: Text('اللون'),
      ),
    ],
    <DropdownMenuItem>[
      DropdownMenuItem(
        value: MapEntry(
          1,
          'Name',
        ),
        child: Text('اسم العائلة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          1,
          'Address',
        ),
        child: Text('عنوان العائلة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          0,
          'LastVisit',
        ),
        child: Text('تاريخ أخر زيارة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          0,
          'FatherLastVisit',
        ),
        child: Text('تاريخ أخر زيارة للأب الكاهن'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          3,
          'StreetId',
        ),
        child: Text('داخل شارع'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          2,
          'AreaId',
        ),
        child: Text('داخل منطقة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          14,
          'Color',
        ),
        child: Text('اللون'),
      ),
    ],
    <DropdownMenuItem>[
      DropdownMenuItem(
        value: MapEntry(
          1,
          'Name',
        ),
        child: Text('اسم الشخص'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          1,
          'Phone',
        ),
        child: Text('رقم الهاتف'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          11,
          'BirthDate',
        ),
        child: Text('تاريخ الميلاد'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          5,
          'IsStudent',
        ),
        child: Text('طالب؟'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          7,
          'Job',
        ),
        child: Text('الوظيفة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          1,
          'JobDescription',
        ),
        child: Text('تفاصيل الوظيفة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          1,
          'Qualification',
        ),
        child: Text('المؤهل'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          10,
          'StudyYear',
        ),
        child: Text('السنة الدراسية'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          15,
          'College',
        ),
        child: Text('الكلية'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          6,
          'Type',
        ),
        child: Text('نوع الفرد'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          8,
          'Church',
        ),
        child: Text('الكنيسة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          1,
          'Meeting',
        ),
        child: Text('الاجتماع المشارك به'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          9,
          'CFather',
        ),
        child: Text('اب الاعتراف'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          12,
          'State',
        ),
        child: Text('الحالة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          0,
          'LastTanawol',
        ),
        child: Text('أخر تناول'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          0,
          'LastConfession',
        ),
        child: Text('أخر اعتراف'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          1,
          'Notes',
        ),
        child: Text('ملاحظات'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          5,
          'IsServant',
        ),
        child: Text('خادم؟'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          2,
          'ServingAreaId',
        ),
        child: Text('منطقة الخدمة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          13,
          'ServingType',
        ),
        child: Text('نوع الخدمة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          4,
          'FamilyId',
        ),
        child: Text('داخل عائلة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          3,
          'StreetId',
        ),
        child: Text('داخل شارع'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          2,
          'AreaId',
        ),
        child: Text('داخل منطقة'),
      ),
      DropdownMenuItem(
        value: MapEntry(
          14,
          'Color',
        ),
        child: Text('اللون'),
      ),
    ],
  ];

  List<dynamic> defaultValues = [
    tranucateToDay(),
    '',
    null,
    null,
    null,
    false,
    null,
    null,
    null,
    null,
    null,
    tranucateToDay(),
    null,
    null,
    0,
    null,
  ];

  @override
  Widget build(BuildContext context) {
    Widget equal = IndexedStack(
      alignment: AlignmentDirectional.center,
      index: getWidgetIndex(),
      children: <Widget>[
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'اختيار تاريخ',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            child: Text(DateFormat('yyyy/M/d').format(
              queryValue is Timestamp
                  ? (queryValue as Timestamp).toDate()
                  : DateTime.now(),
            )),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: TextFormField(
            autofocus: false,
            decoration: InputDecoration(
              labelText: 'قيمة',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            textInputAction: TextInputAction.done,
            initialValue: queryText is String ? queryText : '',
            onChanged: queryTextChange,
            onFieldSubmitted: (_) => execute(),
            validator: (value) {
              return null;
            },
          ),
        ),
        InkWell(
          onTap: _selectArea,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'اختيار منطقة',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              child: Text(queryValue != null && queryValue is DocumentReference
                  ? queryText
                  : 'اختيار منطقة'),
            ),
          ),
        ),
        InkWell(
          onTap: _selectStreet,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'اختيار شارع',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              child: Text(queryValue != null && queryValue is DocumentReference
                  ? queryText
                  : 'اختيار شارع'),
            ),
          ),
        ),
        InkWell(
          onTap: _selectFamily,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'اختيار عائلة',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              child: Text(queryValue != null && queryValue is DocumentReference
                  ? queryText
                  : 'اختيار عائلة'),
            ),
          ),
        ),
        Switch(
            //5
            value: queryValue == true ? true : false,
            onChanged: (v) {
              setState(() {
                queryText = v ? 'نعم' : 'لا';
                queryValue = v;
              });
            }),
        InkWell(
          onTap: _selectType,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'اختيار نوع الفرد',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              child: Text(queryValue != null && queryValue is DocumentReference
                  ? queryText
                  : 'اختيار نوع الفرد'),
            ),
          ),
        ),
        FutureBuilder<QuerySnapshot>(
            //7
            future: Job.getAllForUser(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField(
                  value: (queryValue != null &&
                          queryValue is DocumentReference &&
                          queryValue.path.startsWith('Jobs/')
                      ? queryValue.path
                      : null),
                  items: data.data.docs
                      .map(
                        (item) => DropdownMenuItem(
                          child: Text(item.data()['Name']),
                          value: item.reference.path,
                        ),
                      )
                      .toList()
                        ..insert(
                          0,
                          DropdownMenuItem(
                            child: Text(''),
                            value: null,
                          ),
                        ),
                  onChanged: (value) async {
                    queryValue = FirebaseFirestore.instance.doc(value);
                    queryText = (await FirebaseFirestore.instance
                            .doc(value)
                            .get(dataSource))
                        .data()['Name'];
                  },
                  decoration: InputDecoration(labelText: 'الوظيفة'),
                );
              }
              return LinearProgressIndicator();
            }),
        FutureBuilder<QuerySnapshot>(
            //8
            future: Church.getAllForUser(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField(
                  value: (queryValue != null &&
                          queryValue is DocumentReference &&
                          queryValue.path.startsWith('Churches/')
                      ? queryValue.path
                      : null),
                  items: data.data.docs
                      .map(
                        (item) => DropdownMenuItem(
                          child: Text(item.data()['Name']),
                          value: item.reference.path,
                        ),
                      )
                      .toList()
                        ..insert(
                          0,
                          DropdownMenuItem(
                            child: Text(''),
                            value: null,
                          ),
                        ),
                  onChanged: (value) async {
                    queryValue = FirebaseFirestore.instance.doc(value);
                    queryText = (await FirebaseFirestore.instance
                            .doc(value)
                            .get(dataSource))
                        .data()['Name'];
                  },
                  decoration: InputDecoration(labelText: 'الكنيسة'),
                );
              }
              return LinearProgressIndicator();
            }),
        FutureBuilder<QuerySnapshot>(
            //9
            future: Father.getAllForUser(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField(
                  value: (queryValue != null &&
                          queryValue is DocumentReference &&
                          queryValue.path.startsWith('Fathers/')
                      ? queryValue.path
                      : null),
                  items: data.data.docs
                      .map(
                        (item) => DropdownMenuItem(
                          child: Text(item.data()['Name']),
                          value: item.reference.path,
                        ),
                      )
                      .toList()
                        ..insert(
                          0,
                          DropdownMenuItem(
                            child: Text(''),
                            value: null,
                          ),
                        ),
                  onChanged: (value) async {
                    queryValue = FirebaseFirestore.instance.doc(value);
                    queryText = (await FirebaseFirestore.instance
                            .doc(value)
                            .get(dataSource))
                        .data()['Name'];
                  },
                  decoration: InputDecoration(labelText: 'اب الاعتراف'),
                );
              }
              return LinearProgressIndicator();
            }),
        FutureBuilder<QuerySnapshot>(
            //10
            future: StudyYear.getAllForUser(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField(
                  value: (queryValue != null &&
                          queryValue is DocumentReference &&
                          queryValue.path.startsWith('StudyYears/')
                      ? queryValue.path
                      : null),
                  items: data.data.docs
                      .map(
                        (item) => DropdownMenuItem(
                          child: Text(item.data()['Name']),
                          value: item.reference.path,
                        ),
                      )
                      .toList()
                        ..insert(
                          0,
                          DropdownMenuItem(
                            child: Text(''),
                            value: null,
                          ),
                        ),
                  onChanged: (value) async {
                    queryValue = FirebaseFirestore.instance.doc(value);
                    queryText = (await FirebaseFirestore.instance
                            .doc(value)
                            .get(dataSource))
                        .data()['Name'];
                  },
                  decoration: InputDecoration(labelText: 'سنة الدراسة'),
                );
              }
              return LinearProgressIndicator();
            }),
        Column(
          children: <Widget>[
            InkWell(
              //11
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'اختيار تاريخ',
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                child: Text(DateFormat('yyyy/M/d').format(
                  queryValue != null && queryValue is Timestamp
                      ? (queryValue as Timestamp).toDate()
                      : DateTime.now(),
                )),
              ),
            ),
            Row(
              children: <Widget>[
                Text('بحث باليوم والشهر فقط'),
                Switch(
                  value: !(birthDate == true),
                  onChanged: (v) => setState(() {
                    birthDate = !v;
                  }),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text('(تاريخ فارغ)'),
                Switch(
                  value: queryValue == null,
                  onChanged: (v) => setState(() {
                    if (v) {
                      queryValue = null;
                      queryText = 'فارغ';
                    } else {
                      var now = DateTime.now().millisecondsSinceEpoch;
                      queryValue = Timestamp.fromMillisecondsSinceEpoch(
                        now - (now % Duration.millisecondsPerDay),
                      );
                      queryText = '';
                    }
                  }),
                ),
              ],
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          //12
          stream: FirebaseFirestore.instance
              .collection('States')
              .orderBy('Name')
              .snapshots(),
          builder: (context, data) {
            if (data.hasData) {
              return DropdownButtonFormField(
                value: (queryValue != null &&
                        queryValue is DocumentReference &&
                        queryValue.path.startsWith('States/')
                    ? queryValue.path
                    : null),
                items: data.data.docs
                    .map(
                      (item) => DropdownMenuItem(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(item.data()['Name']),
                              Container(
                                height: 50,
                                width: 50,
                                color: Color(
                                  int.parse("0xff${item.data()['Color']}"),
                                ),
                              )
                            ],
                          ),
                          value: item.reference.path),
                    )
                    .toList()
                      ..insert(
                        0,
                        DropdownMenuItem(
                          child: Text(''),
                          value: null,
                        ),
                      ),
                onChanged: (value) async {
                  queryValue = FirebaseFirestore.instance.doc(value);
                  queryText = (await FirebaseFirestore.instance
                          .doc(value)
                          .get(dataSource))
                      .data()['Name'];
                },
                decoration: InputDecoration(
                  labelText: 'الحالة',
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              );
            } else
              return Container();
          },
        ),
        StreamBuilder<QuerySnapshot>(
            //13
            stream: FirebaseFirestore.instance
                .collection('ServingTypes')
                .orderBy('Name')
                .snapshots(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField(
                  value: (queryValue != null &&
                          queryValue is DocumentReference &&
                          queryValue.path.startsWith('ServingTypes/')
                      ? queryValue.path
                      : null),
                  items: data.data.docs
                      .map(
                        (item) => DropdownMenuItem(
                          child: Text(item.data()['Name']),
                          value: item.reference.path,
                        ),
                      )
                      .toList()
                        ..insert(
                          0,
                          DropdownMenuItem(
                            child: Text(''),
                            value: null,
                          ),
                        ),
                  onChanged: (value) async {
                    queryValue = FirebaseFirestore.instance.doc(value);
                    queryText = (await FirebaseFirestore.instance
                            .doc(value)
                            .get(dataSource))
                        .data()['Name'];
                  },
                  decoration: InputDecoration(labelText: 'نوع الخدمة'),
                );
              }
              return LinearProgressIndicator();
            }),
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              primary: Color(
                  queryValue is int ? queryValue : Colors.transparent.value),
            ),
            icon: Icon(Icons.color_lens),
            label: Text('اختيار لون'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DataDialog(
                  content: ColorsList(
                    selectedColor: Color(queryValue is int
                        ? queryValue
                        : Colors.transparent.value),
                    onSelect: (color, _) {
                      Navigator.of(context).pop();
                      setState(() {
                        queryValue = color.value;
                      });
                    },
                  ),
                ),
              );
            }),
        StreamBuilder<QuerySnapshot>(
            //15
            stream: FirebaseFirestore.instance
                .collection('Colleges')
                .orderBy('Name')
                .snapshots(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField(
                  value: (queryValue != null &&
                          queryValue is DocumentReference &&
                          queryValue.path.startsWith('Colleges/')
                      ? queryValue.path
                      : null),
                  items: data.data.docs
                      .map(
                        (item) => DropdownMenuItem(
                          child: Text(item.data()['Name']),
                          value: item.reference.path,
                        ),
                      )
                      .toList()
                        ..insert(
                          0,
                          DropdownMenuItem(
                            child: Text(''),
                            value: null,
                          ),
                        ),
                  onChanged: (value) async {
                    queryValue = FirebaseFirestore.instance.doc(value);
                    queryText = (await FirebaseFirestore.instance
                            .doc(value)
                            .get(dataSource))
                        .data()['Name'];
                  },
                  decoration: InputDecoration(labelText: 'الكلية'),
                );
              }
              return LinearProgressIndicator();
            }),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('بحث مفصل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text('عرض كل: '),
                DropdownButton(
                  items: <DropdownMenuItem>[
                    DropdownMenuItem(
                      value: 0,
                      child: Text('المناطق'),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text('الشوارع'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('العائلات'),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text('الأشخاص'),
                    ),
                  ],
                  value: parentIndex,
                  onChanged: parentChanged,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text('حيث أن: '),
                Expanded(
                  child: DropdownButton(
                      isExpanded: true,
                      items: childItems[parentIndex],
                      onChanged: childChange,
                      value: childItems[parentIndex][childIndex].value),
                ),
                Expanded(
                  child: DropdownButton(
                    isExpanded: true,
                    items: operatorItems,
                    onChanged: operatorChange,
                    value: operatorIndex,
                  ),
                ),
              ],
            ),
            equal,
            Row(
              children: <Widget>[
                Text('ترتيب حسب:'),
                Expanded(
                  child: DropdownButton(
                    isExpanded: true,
                    value: orderBy,
                    items: getOrderByItems(),
                    onChanged: (value) {
                      setState(() {
                        orderBy = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButton(
                    isExpanded: true,
                    value: descending,
                    items: [
                      DropdownMenuItem(child: Text('تصاعدي'), value: false),
                      DropdownMenuItem(child: Text('تنازلي'), value: true)
                    ],
                    onChanged: (value) {
                      setState(() {
                        descending = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.done),
              onPressed: execute,
              label: Text('تنفيذ'),
            )
          ],
        ),
      ),
    );
  }

  void childChange(value) {
    setState(() {
      childIndex = childItems[parentIndex].indexOf(
        childItems[parentIndex].firstWhere((e) => e.value == value),
      );
      queryValue = defaultValues[getWidgetIndex()];
    });
  }

  void execute() async {
    Widget body;
    String userId = auth.FirebaseAuth.instance.currentUser.uid;
    bool isAdmin = context.read<User>().superAccess;
    Query areas = FirebaseFirestore.instance.collection('Areas');
    Query streets = FirebaseFirestore.instance.collection('Streets');
    Query families = FirebaseFirestore.instance.collection('Families');
    Query persons = FirebaseFirestore.instance.collection('Persons');
    if (!isAdmin) {
      areas = areas.where('Allowed', arrayContains: userId);
      streets = streets.where(
        'AreaId',
        whereIn: (await FirebaseFirestore.instance
                .collection('Areas')
                .where('Allowed', arrayContains: userId)
                .get())
            .docs
            .map((e) => e.reference)
            .toList(),
      );
      families = families.where(
        'AreaId',
        whereIn: (await FirebaseFirestore.instance
                .collection('Areas')
                .where('Allowed', arrayContains: userId)
                .get())
            .docs
            .map((e) => e.reference)
            .toList(),
      );
      persons = persons.where(
        'AreaId',
        whereIn: (await FirebaseFirestore.instance
                .collection('Areas')
                .where('Allowed', arrayContains: userId)
                .get())
            .docs
            .map((e) => e.reference)
            .toList(),
      );
    }
    switch (operatorIndex) {
      case 0:
        if (parentIndex == 0) {
          body = DataObjectList<Area>(
            options: ListOptions<Area>(
              tap: areaTap,
              generate: Area.fromDocumentSnapshot,
              documentsData: () => Future(
                () => areas
                    .where(childItems[parentIndex][childIndex].value.value,
                        isEqualTo: queryValue,
                        isNull: queryValue == null ? true : null)
                    .snapshots(),
              ),
            ),
          );
          break;
        } else if (parentIndex == 1) {
          body = DataObjectList<Street>(
            options: ListOptions<Street>(
              tap: streetTap,
              generate: Street.fromDocumentSnapshot,
              documentsData: () => Future(
                () => streets
                    .where(childItems[parentIndex][childIndex].value.value,
                        isEqualTo: queryValue,
                        isNull: queryValue == null ? true : null)
                    .snapshots(),
              ),
            ),
          );
          break;
        } else if (parentIndex == 2) {
          body = DataObjectList<Family>(
            options: ListOptions<Family>(
              tap: familyTap,
              generate: Family.fromDocumentSnapshot,
              documentsData: () => Future(
                () => families
                    .where(childItems[parentIndex][childIndex].value.value,
                        isEqualTo: queryValue,
                        isNull: queryValue == null ? true : null)
                    .snapshots(),
              ),
            ),
          );
          break;
        }
        if (!birthDate && childIndex == 2) {
          body = DataObjectList<Person>(
            options: ListOptions<Person>(
              tap: personTap,
              generate: Person.fromDocumentSnapshot,
              documentsData: () => Future(
                () => persons
                    .where('BirthDay',
                        isGreaterThanOrEqualTo: queryValue != null
                            ? Timestamp.fromDate(
                                DateTime(1970, queryValue.toDate().month,
                                    queryValue.toDate().day),
                              )
                            : null)
                    .where('BirthDay',
                        isLessThanOrEqualTo: queryValue != null
                            ? Timestamp.fromDate(
                                DateTime(1970, queryValue.toDate().month,
                                    queryValue.toDate().day + 1),
                              )
                            : null)
                    .snapshots(),
              ),
            ),
          );
          break;
        }
        body = DataObjectList<Person>(
          options: ListOptions<Person>(
            tap: personTap,
            generate: Person.fromDocumentSnapshot,
            documentsData: () => Future(
              () => persons
                  .where(childItems[parentIndex][childIndex].value.value,
                      isEqualTo: queryValue,
                      isNull: queryValue == null ? true : null)
                  .snapshots(),
            ),
          ),
        );
        break;
      case 1:
        if (parentIndex == 0) {
          body = DataObjectList<Area>(
            options: ListOptions<Area>(
              tap: areaTap,
              generate: Area.fromDocumentSnapshot,
              documentsData: () => Future(
                () => areas
                    .where(childItems[parentIndex][childIndex].value.value,
                        arrayContains: queryValue)
                    .snapshots(),
              ),
            ),
          );
          break;
        } else if (parentIndex == 1) {
          body = DataObjectList<Street>(
            options: ListOptions<Street>(
              tap: streetTap,
              generate: Street.fromDocumentSnapshot,
              documentsData: () => Future(
                () => streets
                    .where(childItems[parentIndex][childIndex].value.value,
                        arrayContains: queryValue)
                    .snapshots(),
              ),
            ),
          );
          break;
        } else if (parentIndex == 2) {
          body = DataObjectList<Family>(
            options: ListOptions<Family>(
              tap: familyTap,
              generate: Family.fromDocumentSnapshot,
              documentsData: () => Future(
                () => families
                    .where(childItems[parentIndex][childIndex].value.value,
                        arrayContains: queryValue)
                    .snapshots(),
              ),
            ),
          );
          break;
        }
        if (!birthDate && childIndex == 2) {
          body = DataObjectList<Person>(
            options: ListOptions<Person>(
              tap: personTap,
              generate: Person.fromDocumentSnapshot,
              documentsData: () => Future(
                () => persons
                    .where('BirthDay',
                        arrayContains: queryValue != null
                            ? Timestamp.fromDate(
                                DateTime(1970, queryValue.toDate().month,
                                    queryValue.toDate().day),
                              )
                            : null)
                    .snapshots(),
              ),
            ),
          );
          break;
        }
        body = DataObjectList<Person>(
          options: ListOptions<Person>(
            tap: personTap,
            generate: Person.fromDocumentSnapshot,
            documentsData: () => Future(
              () => persons
                  .where(childItems[parentIndex][childIndex].value.value,
                      arrayContains: queryValue)
                  .snapshots(),
            ),
          ),
        );
        break;
      case 2:
        if (parentIndex == 0) {
          body = DataObjectList<Area>(
            options: ListOptions<Area>(
              tap: areaTap,
              generate: Area.fromDocumentSnapshot,
              documentsData: () => Future(
                () => areas
                    .where(childItems[parentIndex][childIndex].value.value,
                        isGreaterThanOrEqualTo: queryValue)
                    .snapshots(),
              ),
            ),
          );
          break;
        } else if (parentIndex == 1) {
          body = DataObjectList<Street>(
            options: ListOptions<Street>(
              tap: streetTap,
              generate: Street.fromDocumentSnapshot,
              documentsData: () => Future(
                () => streets
                    .where(childItems[parentIndex][childIndex].value.value,
                        isGreaterThanOrEqualTo: queryValue)
                    .snapshots(),
              ),
            ),
          );
          break;
        } else if (parentIndex == 2) {
          body = DataObjectList<Family>(
            options: ListOptions<Family>(
              tap: familyTap,
              generate: Family.fromDocumentSnapshot,
              documentsData: () => Future(
                () => families
                    .where(childItems[parentIndex][childIndex].value.value,
                        isGreaterThanOrEqualTo: queryValue)
                    .snapshots(),
              ),
            ),
          );
          break;
        }
        if (!birthDate && childIndex == 2) {
          body = DataObjectList<Person>(
            options: ListOptions<Person>(
              tap: personTap,
              generate: Person.fromDocumentSnapshot,
              documentsData: () => Future(
                () => persons
                    .where('BirthDay',
                        isGreaterThanOrEqualTo: queryValue != null
                            ? Timestamp.fromDate(
                                DateTime(1970, queryValue.toDate().month,
                                    queryValue.toDate().day),
                              )
                            : null)
                    .snapshots(),
              ),
            ),
          );
          break;
        }
        body = DataObjectList<Person>(
          options: ListOptions<Person>(
            tap: personTap,
            generate: Person.fromDocumentSnapshot,
            documentsData: () => Future(
              () => persons
                  .where(childItems[parentIndex][childIndex].value.value,
                      isGreaterThanOrEqualTo: queryValue)
                  .snapshots(),
            ),
          ),
        );
        break;
      case 3:
        if (parentIndex == 0) {
          body = DataObjectList<Area>(
            options: ListOptions<Area>(
              tap: areaTap,
              generate: Area.fromDocumentSnapshot,
              documentsData: () => Future(
                () => areas
                    .where(childItems[parentIndex][childIndex].value.value,
                        isLessThanOrEqualTo: queryValue)
                    .snapshots(),
              ),
            ),
          );
          break;
        } else if (parentIndex == 1) {
          body = DataObjectList<Street>(
            options: ListOptions<Street>(
              tap: streetTap,
              generate: Street.fromDocumentSnapshot,
              documentsData: () => Future(
                () => streets
                    .where(childItems[parentIndex][childIndex].value.value,
                        isLessThanOrEqualTo: queryValue)
                    .snapshots(),
              ),
            ),
          );
          break;
        } else if (parentIndex == 2) {
          body = DataObjectList<Family>(
            options: ListOptions<Family>(
              tap: familyTap,
              generate: Family.fromDocumentSnapshot,
              documentsData: () => Future(
                () => families
                    .where(childItems[parentIndex][childIndex].value.value,
                        isLessThanOrEqualTo: queryValue)
                    .snapshots(),
              ),
            ),
          );
          break;
        }
        if (!birthDate && childIndex == 2) {
          body = DataObjectList<Person>(
            options: ListOptions<Person>(
              tap: personTap,
              generate: Person.fromDocumentSnapshot,
              documentsData: () => Future(
                () => persons
                    .where('BirthDay',
                        isLessThanOrEqualTo: queryValue != null
                            ? Timestamp.fromDate(
                                DateTime(1970, queryValue.toDate().month,
                                    queryValue.toDate().day),
                              )
                            : null)
                    .snapshots(),
              ),
            ),
          );
          break;
        }
        body = DataObjectList<Person>(
          options: ListOptions<Person>(
            tap: personTap,
            generate: Person.fromDocumentSnapshot,
            documentsData: () => Future(
              () => persons
                  .where(childItems[parentIndex][childIndex].value.value,
                      isLessThanOrEqualTo: queryValue)
                  .snapshots(),
            ),
          ),
        );
        break;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ListenableProvider<SearchString>(
            create: (_) => SearchString(''),
            builder: (context, child) => Scaffold(
              appBar: AppBar(
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () async {
                      await Share.share(
                        await shareQuery({
                          'parentIndex': parentIndex.toString(),
                          'childIndex': childIndex.toString(),
                          'operatorIndex': operatorIndex.toString(),
                          'queryValue': queryValue is DocumentReference
                              ? 'D' + (queryValue as DocumentReference).path
                              : (queryValue is Timestamp
                                  ? 'T' +
                                      (queryValue as Timestamp)
                                          .millisecondsSinceEpoch
                                          .toString()
                                  : (queryValue is int
                                      ? 'I' + queryValue.toString()
                                      : 'S' + queryValue.toString())),
                          'queryText': queryText,
                          'birthDate': birthDate.toString(),
                          'descending': descending.toString(),
                          'orderBy': orderBy
                        }),
                      );
                    },
                    tooltip: 'مشاركة النتائج برابط',
                  ),
                ],
                title: SearchFilters(parentIndex),
              ),
              body: body,
            ),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> getOrderByItems() {
    if (parentIndex == 0) {
      return Area.getStaticHumanReadableMap()
          .entries
          .map(
            (e) => DropdownMenuItem(child: Text(e.value), value: e.key),
          )
          .toList();
    } else if (parentIndex == 1) {
      return Street.getHumanReadableMap2()
          .entries
          .map(
            (e) => DropdownMenuItem(child: Text(e.value), value: e.key),
          )
          .toList();
    } else if (parentIndex == 2) {
      return Family.getHumanReadableMap2()
          .entries
          .map(
            (e) => DropdownMenuItem(child: Text(e.value), value: e.key),
          )
          .toList();
    } else if (parentIndex == 3) {
      return Person.getHumanReadableMap2()
          .entries
          .map(
            (e) => DropdownMenuItem(child: Text(e.value), value: e.key),
          )
          .toList();
    }
    return null;
  }

  int getWidgetIndex() {
    return childItems[parentIndex][childIndex].value.key;
  }

  @override
  void initState() {
    super.initState();
    if (widget.query != null) {
      parentIndex = int.parse(widget.query['parentIndex']);
      childIndex = int.parse(widget.query['childIndex']);
      operatorIndex = int.parse(widget.query['operatorIndex']);
      queryText = widget.query['queryText'];
      birthDate = widget.query['birthDate'] == 'true';
      queryValue = widget.query['queryValue'] != null
          ? widget.query['queryValue'].toString().startsWith('D')
              ? FirebaseFirestore.instance.doc(
                  widget.query['queryValue'].toString().substring(1),
                )
              : widget.query['queryValue'].toString().startsWith('T')
                  ? Timestamp.fromMillisecondsSinceEpoch(int.parse(
                      widget.query['queryValue'].toString().substring(1),
                    ))
                  : widget.query['queryValue'].toString().startsWith('I')
                      ? int.parse(
                          widget.query['queryValue'].toString().substring(1),
                        )
                      : widget.query['queryValue'].toString().substring(1)
          : null;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => execute(),
      );
    }
  }

  void operatorChange(value) {
    setState(() {
      operatorIndex = value;
    });
  }

  void parentChanged(value) {
    setState(() {
      orderBy = 'Name';
      childIndex = 0;
      parentIndex = value;
    });
  }

  void queryTextChange(String value) {
    queryValue = value;
    queryText = value;
  }

  void _selectArea() {
    showDialog(
      context: context,
      builder: (context) {
        return DataDialog(
          content: ListenableProvider<SearchString>(
            create: (_) => SearchString(''),
            builder: (context, child) => Column(
              children: [
                SearchFilters(0),
                Expanded(
                  child: Selector<OrderOptions, Tuple2<String, bool>>(
                    selector: (_, o) =>
                        Tuple2<String, bool>(o.areaOrderBy, o.areaASC),
                    builder: (context, options, child) => DataObjectList<Area>(
                      options: ListOptions<Area>(
                        showNull: true,
                        empty: (Area.empty()..name = 'لا يوجد')..id = 'null',
                        tap: (areaSelected, _) {
                          Navigator.of(context).pop();
                          setState(() {
                            queryValue = FirebaseFirestore.instance
                                .collection('Areas')
                                .doc(areaSelected.id);
                            queryText = areaSelected.name;
                          });
                        },
                        generate: Area.fromDocumentSnapshot,
                        documentsData: () => Area.getAllForUser(
                            orderBy: options.item1, descending: !options.item2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectDate() async {
    DateTime picked = await showDatePicker(
      context: context,
      initialDate:
          !(queryValue is Timestamp) ? DateTime.now() : queryValue.toDate(),
      firstDate: DateTime(1500),
      lastDate: DateTime(2201),
    );
    if (picked != null)
      setState(() {
        queryValue = Timestamp.fromDate(picked);
      });
  }

  void _selectFamily() {
    showDialog(
      context: context,
      builder: (context) {
        return DataDialog(
          content: ListenableProvider<SearchString>(
            create: (_) => SearchString(''),
            builder: (context, child) => Column(
              children: [
                SearchFilters(2),
                Expanded(
                  child: Selector<OrderOptions, Tuple2<String, bool>>(
                    selector: (_, o) =>
                        Tuple2<String, bool>(o.familyOrderBy, o.familyASC),
                    builder: (context, options, child) =>
                        DataObjectList<Family>(
                      options: ListOptions<Family>(
                        showNull: true,
                        empty: (Family.empty()..name = 'لا يوجد')..id = 'null',
                        tap: (familySelected, _) {
                          Navigator.of(context).pop();
                          setState(() {
                            queryValue = FirebaseFirestore.instance
                                .collection('Families')
                                .doc(familySelected.id);
                            queryText = familySelected.name;
                          });
                        },
                        generate: Family.fromDocumentSnapshot,
                        documentsData: () => Family.getAllForUser(
                            orderBy: options.item1, descending: !options.item2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectStreet() {
    showDialog(
      context: context,
      builder: (context) {
        return DataDialog(
          content: ListenableProvider<SearchString>(
            create: (_) => SearchString(''),
            builder: (context, child) => Column(
              children: [
                SearchFilters(1),
                Expanded(
                  child: Selector<OrderOptions, Tuple2<String, bool>>(
                    selector: (_, o) =>
                        Tuple2<String, bool>(o.streetOrderBy, o.streetASC),
                    builder: (context, options, child) =>
                        DataObjectList<Street>(
                      options: ListOptions<Street>(
                        showNull: true,
                        empty: (Street.empty()..name = 'لا يوجد')..id = 'null',
                        tap: (streetSelected, _) {
                          Navigator.of(context).pop();
                          setState(() {
                            queryValue = FirebaseFirestore.instance
                                .collection('Streets')
                                .doc(streetSelected.id);
                            queryText = streetSelected.name;
                          });
                        },
                        generate: Street.fromDocumentSnapshot,
                        documentsData: () => Street.getAllForUser(
                            orderBy: options.item1, descending: !options.item2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectType() {
    showDialog(
      context: context,
      builder: (context) {
        return DataDialog(
          content: TypesList(
            list:
                FirebaseFirestore.instance.collection('Types').get(dataSource),
            tap: (type, _) {
              Navigator.of(context).pop();
              setState(() {
                queryValue = type.ref;
                queryText = type.name;
              });
            },
            showNull: true,
          ),
        );
      },
    );
  }
}
