import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/views/mini_lists/colors_list.dart';
import 'package:churchdata/views/mini_model_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

import '../models/mini_models.dart';
import '../models/user.dart';
import '../utils/globals.dart';
import '../utils/helpers.dart';

class SearchQuery extends StatefulWidget {
  final Json? query;

  const SearchQuery({Key? key, this.query}) : super(key: key);

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
    const DropdownMenuItem(
      value: 0,
      child: Text('='),
    ),
    const DropdownMenuItem(
      value: 1,
      child: Text('قائمة تحتوي على'),
    ),
    const DropdownMenuItem(
      value: 2,
      child: Text('أكبر من'),
    ),
    const DropdownMenuItem(
      value: 3,
      child: Text('أصغر من'),
    ),
  ];

  List<List<DropdownMenuItem>> childItems = <List<DropdownMenuItem>>[
    <DropdownMenuItem>[
      const DropdownMenuItem(
        value: MapEntry(1, 'Name'),
        child: Text('اسم المنطقة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          1,
          'Address',
        ),
        child: Text('عنوان المنطقة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          0,
          'LastVisit',
        ),
        child: Text('تاريخ أخر زيارة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          0,
          'FatherLastVisit',
        ),
        child: Text('تاريخ أخر زيارة للأب الكاهن'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          14,
          'Color',
        ),
        child: Text('اللون'),
      ),
    ],
    <DropdownMenuItem>[
      const DropdownMenuItem(
        value: MapEntry(1, 'Name'),
        child: Text('اسم الشارع'),
      ),
      const DropdownMenuItem(
        value: MapEntry(0, 'LastVisit'),
        child: Text('تاريخ أخر زيارة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          0,
          'FatherLastVisit',
        ),
        child: Text('تاريخ أخر زيارة للأب الكاهن'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          2,
          'AreaId',
        ),
        child: Text('داخل منطقة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          14,
          'Color',
        ),
        child: Text('اللون'),
      ),
    ],
    <DropdownMenuItem>[
      const DropdownMenuItem(
        value: MapEntry(
          1,
          'Name',
        ),
        child: Text('اسم العائلة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          1,
          'Address',
        ),
        child: Text('عنوان العائلة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          0,
          'LastVisit',
        ),
        child: Text('تاريخ أخر زيارة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          0,
          'FatherLastVisit',
        ),
        child: Text('تاريخ أخر زيارة للأب الكاهن'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          3,
          'StreetId',
        ),
        child: Text('داخل شارع'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          2,
          'AreaId',
        ),
        child: Text('داخل منطقة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          14,
          'Color',
        ),
        child: Text('اللون'),
      ),
    ],
    <DropdownMenuItem>[
      const DropdownMenuItem(
        value: MapEntry(
          1,
          'Name',
        ),
        child: Text('اسم الشخص'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          1,
          'Phone',
        ),
        child: Text('رقم الهاتف'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          11,
          'BirthDate',
        ),
        child: Text('تاريخ الميلاد'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          5,
          'IsStudent',
        ),
        child: Text('طالب؟'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          7,
          'Job',
        ),
        child: Text('الوظيفة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          1,
          'JobDescription',
        ),
        child: Text('تفاصيل الوظيفة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          1,
          'Qualification',
        ),
        child: Text('المؤهل'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          10,
          'StudyYear',
        ),
        child: Text('السنة الدراسية'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          15,
          'College',
        ),
        child: Text('الكلية'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          6,
          'Type',
        ),
        child: Text('نوع الفرد'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          8,
          'Church',
        ),
        child: Text('الكنيسة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          1,
          'Meeting',
        ),
        child: Text('الاجتماع المشارك به'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          9,
          'CFather',
        ),
        child: Text('اب الاعتراف'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          12,
          'State',
        ),
        child: Text('الحالة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          0,
          'LastTanawol',
        ),
        child: Text('أخر تناول'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          0,
          'LastConfession',
        ),
        child: Text('أخر اعتراف'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          1,
          'Notes',
        ),
        child: Text('ملاحظات'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          5,
          'IsServant',
        ),
        child: Text('خادم؟'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          2,
          'ServingAreaId',
        ),
        child: Text('منطقة الخدمة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          13,
          'ServingType',
        ),
        child: Text('نوع الخدمة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          4,
          'FamilyId',
        ),
        child: Text('داخل عائلة'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          3,
          'StreetId',
        ),
        child: Text('داخل شارع'),
      ),
      const DropdownMenuItem(
        value: MapEntry(
          2,
          'AreaId',
        ),
        child: Text('داخل منطقة'),
      ),
      const DropdownMenuItem(
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
    final Widget equal = IndexedStack(
      alignment: AlignmentDirectional.center,
      index: getWidgetIndex(),
      children: <Widget>[
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'اختيار تاريخ',
            ),
            child: Text(DateFormat('yyyy/M/d').format(
              queryValue is Timestamp
                  ? (queryValue as Timestamp).toDate()
                  : DateTime.now(),
            )),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'قيمة',
            ),
            textInputAction: TextInputAction.done,
            // ignore: unnecessary_type_check
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
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'اختيار منطقة',
              ),
              child: Text(queryValue != null && queryValue is JsonRef
                  ? queryText
                  : 'اختيار منطقة'),
            ),
          ),
        ),
        InkWell(
          onTap: _selectStreet,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'اختيار شارع',
              ),
              child: Text(queryValue != null && queryValue is JsonRef
                  ? queryText
                  : 'اختيار شارع'),
            ),
          ),
        ),
        InkWell(
          onTap: _selectFamily,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'اختيار عائلة',
              ),
              child: Text(queryValue != null && queryValue is JsonRef
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
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'اختيار نوع الفرد',
              ),
              child: Text(queryValue != null && queryValue is String
                  ? queryText
                  : 'اختيار نوع الفرد'),
            ),
          ),
        ),
        FutureBuilder<JsonQuery>(
            //7
            future: Job.getAllForUser(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField<JsonRef?>(
                  value: queryValue != null &&
                          queryValue is JsonRef &&
                          queryValue.path.startsWith('Jobs/')
                      ? queryValue
                      : null,
                  items: data.data!.docs
                      .map(
                        (item) => DropdownMenuItem<JsonRef?>(
                          value: item.reference,
                          child: Text(item.data()['Name']),
                        ),
                      )
                      .toList()
                    ..insert(
                      0,
                      const DropdownMenuItem(
                        value: null,
                        child: Text(''),
                      ),
                    ),
                  onChanged: (value) async {
                    queryValue = value;
                    queryText = (await value?.get())?.data()?['Name'] ?? '';
                  },
                  decoration: const InputDecoration(labelText: 'الوظيفة'),
                );
              }
              return const LinearProgressIndicator();
            }),
        FutureBuilder<JsonQuery>(
            //8
            future: Church.getAllForUser(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField<JsonRef?>(
                  value: queryValue != null &&
                          queryValue is JsonRef &&
                          queryValue.path.startsWith('Churches/')
                      ? queryValue
                      : null,
                  items: data.data!.docs
                      .map(
                        (item) => DropdownMenuItem<JsonRef?>(
                          value: item.reference,
                          child: Text(item.data()['Name']),
                        ),
                      )
                      .toList()
                    ..insert(
                      0,
                      const DropdownMenuItem(
                        value: null,
                        child: Text(''),
                      ),
                    ),
                  onChanged: (value) async {
                    queryValue = value;
                    queryText = (await value?.get())?.data()?['Name'] ?? '';
                  },
                  decoration: const InputDecoration(labelText: 'الكنيسة'),
                );
              }
              return const LinearProgressIndicator();
            }),
        FutureBuilder<JsonQuery>(
            //9
            future: Father.getAllForUser(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField<JsonRef?>(
                  value: queryValue != null &&
                          queryValue is JsonRef &&
                          queryValue.path.startsWith('Fathers/')
                      ? queryValue
                      : null,
                  items: data.data!.docs
                      .map(
                        (item) => DropdownMenuItem<JsonRef?>(
                          value: item.reference,
                          child: Text(item.data()['Name']),
                        ),
                      )
                      .toList()
                    ..insert(
                      0,
                      const DropdownMenuItem(
                        value: null,
                        child: Text(''),
                      ),
                    ),
                  onChanged: (value) async {
                    queryValue = value;
                    queryText = (await value?.get())?.data()?['Name'] ?? '';
                  },
                  decoration: const InputDecoration(labelText: 'اب الاعتراف'),
                );
              }
              return const LinearProgressIndicator();
            }),
        FutureBuilder<JsonQuery>(
            //10
            future: StudyYear.getAllForUser(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField<JsonRef?>(
                  value: queryValue != null &&
                          queryValue is JsonRef &&
                          queryValue.path.startsWith('StudyYears/')
                      ? queryValue
                      : null,
                  items: data.data!.docs
                      .map(
                        (item) => DropdownMenuItem<JsonRef?>(
                          value: item.reference,
                          child: Text(item.data()['Name']),
                        ),
                      )
                      .toList()
                    ..insert(
                      0,
                      const DropdownMenuItem(
                        value: null,
                        child: Text(''),
                      ),
                    ),
                  onChanged: (value) async {
                    queryValue = value;
                    queryText = (await value?.get())?.data()?['Name'] ?? '';
                  },
                  decoration: const InputDecoration(labelText: 'سنة الدراسة'),
                );
              }
              return const LinearProgressIndicator();
            }),
        Column(
          children: <Widget>[
            InkWell(
              //11
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'اختيار تاريخ',
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
                const Text('بحث باليوم والشهر فقط'),
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
                const Text('(تاريخ فارغ)'),
                Switch(
                  value: queryValue == null,
                  onChanged: (v) => setState(() {
                    if (v) {
                      queryValue = null;
                      queryText = 'فارغ';
                    } else {
                      final now = DateTime.now().millisecondsSinceEpoch;
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
        StreamBuilder<JsonQuery>(
          //12
          stream: firestore.collection('States').orderBy('Name').snapshots(),
          builder: (context, data) {
            if (data.hasData) {
              return DropdownButtonFormField<JsonRef?>(
                value: queryValue != null &&
                        queryValue is JsonRef &&
                        queryValue.path.startsWith('States/')
                    ? queryValue
                    : null,
                items: data.data!.docs
                    .map(
                      (item) => DropdownMenuItem<JsonRef?>(
                        value: item.reference,
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
                      ),
                    )
                    .toList()
                  ..insert(
                    0,
                    const DropdownMenuItem<JsonRef?>(
                      child: Text(''),
                    ),
                  ),
                onChanged: (value) async {
                  queryValue = value;
                  queryText = (await value?.get())?.data()?['Name'] ?? '';
                },
                decoration: const InputDecoration(
                  labelText: 'الحالة',
                ),
              );
            } else
              return Container();
          },
        ),
        StreamBuilder<JsonQuery>(
            //13
            stream: firestore
                .collection('ServingTypes')
                .orderBy('Name')
                .snapshots(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField<JsonRef?>(
                  value: queryValue != null &&
                          queryValue is JsonRef &&
                          queryValue.path.startsWith('ServingTypes/')
                      ? queryValue
                      : null,
                  items: data.data!.docs
                      .map(
                        (item) => DropdownMenuItem<JsonRef?>(
                          value: item.reference,
                          child: Text(item.data()['Name']),
                        ),
                      )
                      .toList()
                    ..insert(
                      0,
                      const DropdownMenuItem(
                        value: null,
                        child: Text(''),
                      ),
                    ),
                  onChanged: (value) async {
                    queryValue = value;
                    queryText = (await value?.get())?.data()?['Name'] ?? '';
                  },
                  decoration: const InputDecoration(labelText: 'نوع الخدمة'),
                );
              }
              return const LinearProgressIndicator();
            }),
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              primary: Color(
                  queryValue is int ? queryValue : Colors.transparent.value),
            ),
            icon: const Icon(Icons.color_lens),
            label: const Text('اختيار لون'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DataDialog(
                  content: ColorsList(
                    selectedColor: Color(queryValue is int
                        ? queryValue
                        : Colors.transparent.value),
                    onSelect: (color) {
                      navigator.currentState!.pop();
                      setState(() {
                        queryValue = color.value;
                      });
                    },
                  ),
                ),
              );
            }),
        StreamBuilder<JsonQuery>(
            //15
            stream:
                firestore.collection('Colleges').orderBy('Name').snapshots(),
            builder: (context, data) {
              if (data.hasData) {
                return DropdownButtonFormField<JsonRef?>(
                  value: queryValue != null &&
                          queryValue is JsonRef &&
                          queryValue.path.startsWith('Colleges/')
                      ? queryValue
                      : null,
                  items: data.data!.docs
                      .map(
                        (item) => DropdownMenuItem<JsonRef?>(
                          value: item.reference,
                          child: Text(item.data()['Name']),
                        ),
                      )
                      .toList()
                    ..insert(
                      0,
                      const DropdownMenuItem(
                        value: null,
                        child: Text(''),
                      ),
                    ),
                  onChanged: (value) async {
                    queryValue = value;
                    queryText = (await value?.get())?.data()?['Name'] ?? '';
                  },
                  decoration: const InputDecoration(labelText: 'الكلية'),
                );
              }
              return const LinearProgressIndicator();
            }),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('بحث مفصل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text('عرض كل: '),
                DropdownButton(
                  items: const <DropdownMenuItem>[
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
              children: <Widget>[
                const Text('حيث أن: '),
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
                const Text('ترتيب حسب:'),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: orderBy,
                    items: getOrderByItems(),
                    onChanged: (value) {
                      setState(() {
                        orderBy = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButton<bool>(
                    isExpanded: true,
                    value: descending,
                    items: const [
                      DropdownMenuItem(
                        value: false,
                        child: Text('تصاعدي'),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text('تنازلي'),
                      )
                    ],
                    onChanged: (value) {
                      setState(() {
                        descending = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.done),
              onPressed: execute,
              label: const Text('تنفيذ'),
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
    late DataObjectList body;
    final String userId = User.instance.uid!;

    final bool isAdmin = User.instance.superAccess;

    Query<Json> areas = firestore.collection('Areas');
    Query<Json> streets = firestore.collection('Streets');
    Query<Json> families = firestore.collection('Families');
    Query<Json> persons = firestore.collection('Persons');

    if (!isAdmin) {
      areas = areas.where('Allowed', arrayContains: userId);
      streets = streets.where(
        'AreaId',
        whereIn: (await firestore
                .collection('Areas')
                .where('Allowed', arrayContains: userId)
                .get())
            .docs
            .map((e) => e.reference)
            .toList(),
      );
      families = families.where(
        'AreaId',
        whereIn: (await firestore
                .collection('Areas')
                .where('Allowed', arrayContains: userId)
                .get())
            .docs
            .map((e) => e.reference)
            .toList(),
      );
      persons = persons.where(
        'AreaId',
        whereIn: (await firestore
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
            autoDisposeController: true,
            options: DataObjectListController<Area>(
              tap: areaTap,
              itemsStream: areas
                  .where(childItems[parentIndex][childIndex].value.value,
                      isEqualTo: queryValue,
                      isNull: queryValue == null ? true : null)
                  .snapshots()
                  .map((s) => s.docs.map(Area.fromQueryDoc).toList()),
            ),
          );
          break;
        } else if (parentIndex == 1) {
          body = DataObjectList<Street>(
            autoDisposeController: true,
            options: DataObjectListController<Street>(
              tap: streetTap,
              itemsStream: streets
                  .where(childItems[parentIndex][childIndex].value.value,
                      isEqualTo: queryValue,
                      isNull: queryValue == null ? true : null)
                  .snapshots()
                  .map((s) => s.docs.map(Street.fromQueryDoc).toList()),
            ),
          );
          break;
        } else if (parentIndex == 2) {
          body = DataObjectList<Family>(
            autoDisposeController: true,
            options: DataObjectListController<Family>(
              tap: familyTap,
              itemsStream: families
                  .where(childItems[parentIndex][childIndex].value.value,
                      isEqualTo: queryValue,
                      isNull: queryValue == null ? true : null)
                  .snapshots()
                  .map((s) => s.docs.map(Family.fromQueryDoc).toList()),
            ),
          );
          break;
        }
        if (!birthDate && childIndex == 2) {
          body = DataObjectList<Person>(
            autoDisposeController: true,
            options: DataObjectListController<Person>(
              tap: personTap,
              itemsStream: persons
                  .where('BirthDay',
                      isGreaterThanOrEqualTo: queryValue != null
                          ? Timestamp.fromDate(
                              DateTime(1970, queryValue.toDate().month,
                                  queryValue.toDate().day),
                            )
                          : null)
                  .where('BirthDay',
                      isLessThan: queryValue != null
                          ? Timestamp.fromDate(
                              DateTime(1970, queryValue.toDate().month,
                                  queryValue.toDate().day + 1),
                            )
                          : null)
                  .snapshots()
                  .map((s) => s.docs.map(Person.fromQueryDoc).toList()),
            ),
          );
          break;
        }
        body = DataObjectList<Person>(
          autoDisposeController: true,
          options: DataObjectListController<Person>(
            tap: personTap,
            itemsStream: persons
                .where(childItems[parentIndex][childIndex].value.value,
                    isEqualTo: queryValue,
                    isNull: queryValue == null ? true : null)
                .snapshots()
                .map((s) => s.docs.map(Person.fromQueryDoc).toList()),
          ),
        );
        break;
      case 1:
        // ignore: invariant_booleans
        if (parentIndex == 0) {
          body = DataObjectList<Area>(
            autoDisposeController: true,
            options: DataObjectListController<Area>(
              tap: areaTap,
              itemsStream: areas
                  .where(childItems[parentIndex][childIndex].value.value,
                      arrayContains: queryValue)
                  .snapshots()
                  .map((s) => s.docs.map(Area.fromQueryDoc).toList()),
            ),
          );
          break;
        } else if (parentIndex == 1) {
          body = DataObjectList<Street>(
            autoDisposeController: true,
            options: DataObjectListController<Street>(
              tap: streetTap,
              itemsStream: streets
                  .where(childItems[parentIndex][childIndex].value.value,
                      arrayContains: queryValue)
                  .snapshots()
                  .map((s) => s.docs.map(Street.fromQueryDoc).toList()),
            ),
          );
          break;
        } else if (parentIndex == 2) {
          body = DataObjectList<Family>(
            autoDisposeController: true,
            options: DataObjectListController<Family>(
              tap: familyTap,
              itemsStream: families
                  .where(childItems[parentIndex][childIndex].value.value,
                      arrayContains: queryValue)
                  .snapshots()
                  .map((s) => s.docs.map(Family.fromQueryDoc).toList()),
            ),
          );
          break;
        }
        if (!birthDate && childIndex == 2) {
          body = DataObjectList<Person>(
            autoDisposeController: true,
            options: DataObjectListController<Person>(
              tap: personTap,
              itemsStream: persons
                  .where('BirthDay',
                      arrayContains: queryValue != null
                          ? Timestamp.fromDate(
                              DateTime(1970, queryValue.toDate().month,
                                  queryValue.toDate().day),
                            )
                          : null)
                  .snapshots()
                  .map((s) => s.docs.map(Person.fromQueryDoc).toList()),
            ),
          );
          break;
        }
        body = DataObjectList<Person>(
          autoDisposeController: true,
          options: DataObjectListController<Person>(
            tap: personTap,
            itemsStream: persons
                .where(childItems[parentIndex][childIndex].value.value,
                    arrayContains: queryValue)
                .snapshots()
                .map((s) => s.docs.map(Person.fromQueryDoc).toList()),
          ),
        );
        break;
      case 2:
        // ignore: invariant_booleans
        if (parentIndex == 0) {
          body = DataObjectList<Area>(
            autoDisposeController: true,
            options: DataObjectListController<Area>(
              tap: areaTap,
              itemsStream: areas
                  .where(childItems[parentIndex][childIndex].value.value,
                      isGreaterThanOrEqualTo: queryValue)
                  .snapshots()
                  .map((s) => s.docs.map(Area.fromQueryDoc).toList()),
            ),
          );
          break;
        } else if (parentIndex == 1) {
          body = DataObjectList<Street>(
            autoDisposeController: true,
            options: DataObjectListController<Street>(
              tap: streetTap,
              itemsStream: streets
                  .where(childItems[parentIndex][childIndex].value.value,
                      isGreaterThanOrEqualTo: queryValue)
                  .snapshots()
                  .map((s) => s.docs.map(Street.fromQueryDoc).toList()),
            ),
          );
          break;
        } else if (parentIndex == 2) {
          body = DataObjectList<Family>(
            autoDisposeController: true,
            options: DataObjectListController<Family>(
              tap: familyTap,
              itemsStream: families
                  .where(childItems[parentIndex][childIndex].value.value,
                      isGreaterThanOrEqualTo: queryValue)
                  .snapshots()
                  .map((s) => s.docs.map(Family.fromQueryDoc).toList()),
            ),
          );
          break;
        }
        if (!birthDate && childIndex == 2) {
          body = DataObjectList<Person>(
            autoDisposeController: true,
            options: DataObjectListController<Person>(
              tap: personTap,
              itemsStream: persons
                  .where('BirthDay',
                      isGreaterThanOrEqualTo: queryValue != null
                          ? Timestamp.fromDate(
                              DateTime(1970, queryValue.toDate().month,
                                  queryValue.toDate().day),
                            )
                          : null)
                  .snapshots()
                  .map((s) => s.docs.map(Person.fromQueryDoc).toList()),
            ),
          );
          break;
        }
        body = DataObjectList<Person>(
          autoDisposeController: true,
          options: DataObjectListController<Person>(
            tap: personTap,
            itemsStream: persons
                .where(childItems[parentIndex][childIndex].value.value,
                    isGreaterThanOrEqualTo: queryValue)
                .snapshots()
                .map((s) => s.docs.map(Person.fromQueryDoc).toList()),
          ),
        );
        break;
      case 3:
        // ignore: invariant_booleans
        if (parentIndex == 0) {
          body = DataObjectList<Area>(
            autoDisposeController: true,
            options: DataObjectListController<Area>(
              tap: areaTap,
              itemsStream: areas
                  .where(childItems[parentIndex][childIndex].value.value,
                      isLessThanOrEqualTo: queryValue)
                  .snapshots()
                  .map((s) => s.docs.map(Area.fromQueryDoc).toList()),
            ),
          );
          break;
        } else if (parentIndex == 1) {
          body = DataObjectList<Street>(
            autoDisposeController: true,
            options: DataObjectListController<Street>(
              tap: streetTap,
              itemsStream: streets
                  .where(childItems[parentIndex][childIndex].value.value,
                      isLessThanOrEqualTo: queryValue)
                  .snapshots()
                  .map((s) => s.docs.map(Street.fromQueryDoc).toList()),
            ),
          );
          break;
        } else if (parentIndex == 2) {
          body = DataObjectList<Family>(
            autoDisposeController: true,
            options: DataObjectListController<Family>(
              tap: familyTap,
              itemsStream: families
                  .where(childItems[parentIndex][childIndex].value.value,
                      isLessThanOrEqualTo: queryValue)
                  .snapshots()
                  .map((s) => s.docs.map(Family.fromQueryDoc).toList()),
            ),
          );
          break;
        }
        if (!birthDate && childIndex == 2) {
          body = DataObjectList<Person>(
            autoDisposeController: true,
            options: DataObjectListController<Person>(
              tap: personTap,
              itemsStream: persons
                  .where('BirthDay',
                      isLessThanOrEqualTo: queryValue != null
                          ? Timestamp.fromDate(
                              DateTime(1970, queryValue.toDate().month,
                                  queryValue.toDate().day),
                            )
                          : null)
                  .snapshots()
                  .map((s) => s.docs.map(Person.fromQueryDoc).toList()),
            ),
          );
          break;
        }
        body = DataObjectList<Person>(
          autoDisposeController: true,
          options: DataObjectListController<Person>(
            tap: personTap,
            itemsStream: persons
                .where(childItems[parentIndex][childIndex].value.value,
                    isLessThanOrEqualTo: queryValue)
                .snapshots()
                .map((s) => s.docs.map(Person.fromQueryDoc).toList()),
          ),
        );
        break;
    }
    await navigator.currentState!.push(
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    await Share.share(
                      await shareQuery({
                        'parentIndex': parentIndex.toString(),
                        'childIndex': childIndex.toString(),
                        'operatorIndex': operatorIndex.toString(),
                        'queryValue': queryValue is JsonRef
                            ? 'D' + (queryValue as JsonRef).path
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
              title: SearchFilters(parentIndex,
                  options: body.options!,
                  disableOrdering: true,
                  textStyle: Theme.of(context).textTheme.bodyText2),
            ),
            extendBody: true,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,
            bottomNavigationBar: BottomAppBar(
              child: StreamBuilder<List>(
                stream: body.options!.objectsData,
                builder: (context, snapshot) {
                  return Text(
                    (snapshot.data?.length ?? 0).toString() +
                        ' ' +
                        (parentIndex == 0
                            ? 'منطقة'
                            : parentIndex == 1
                                ? 'شارع'
                                : parentIndex == 2
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
            body: body,
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>>? getOrderByItems() {
    if (parentIndex == 0) {
      return Area.getStaticHumanReadableMap()
          .entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList();
    } else if (parentIndex == 1) {
      return Street.getHumanReadableMap2()
          .entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList();
    } else if (parentIndex == 2) {
      return Family.getHumanReadableMap2()
          .entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList();
    } else if (parentIndex == 3) {
      return Person.getHumanReadableMap2()
          .entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            ),
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
      parentIndex = int.parse(widget.query!['parentIndex']);
      childIndex = int.parse(widget.query!['childIndex']);
      operatorIndex = int.parse(widget.query!['operatorIndex']);
      queryText = widget.query!['queryText'];
      birthDate = widget.query!['birthDate'] == 'true';
      queryValue = widget.query!['queryValue'] != null
          ? widget.query!['queryValue'].toString().startsWith('D')
              ? firestore.doc(
                  widget.query!['queryValue'].toString().substring(1),
                )
              : widget.query!['queryValue'].toString().startsWith('T')
                  ? Timestamp.fromMillisecondsSinceEpoch(int.parse(
                      widget.query!['queryValue'].toString().substring(1),
                    ))
                  : widget.query!['queryValue'].toString().startsWith('I')
                      ? int.parse(
                          widget.query!['queryValue'].toString().substring(1),
                        )
                      : widget.query!['queryValue'].toString().substring(1)
          : null;
      WidgetsBinding.instance!.addPostFrameCallback(
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

  void _selectArea() async {
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(const OrderOptions());

    final listOptions = DataObjectListController<Area>(
      tap: (areaSelected) {
        navigator.currentState!.pop();
        queryValue = firestore.collection('Areas').doc(areaSelected.id);
        queryText = areaSelected.name;
      },
      itemsStream: _orderOptions
          .switchMap((value) => Area.getAllForUser(
              orderBy: value.orderBy, descending: !value.asc))
          .map((s) => s.docs.map(Area.fromQueryDoc).toList()),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Scaffold(
            body: SizedBox(
              width: MediaQuery.of(context).size.width - 55,
              height: MediaQuery.of(context).size.height - 110,
              child: Column(
                children: [
                  SearchFilters(
                    1,
                    options: listOptions,
                    orderOptions: BehaviorSubject<OrderOptions>.seeded(
                      const OrderOptions(),
                    ),
                    textStyle: Theme.of(context).textTheme.bodyText2,
                  ),
                  Expanded(
                    child: DataObjectList<Area>(
                      autoDisposeController: true,
                      options: listOptions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    await _orderOptions.close();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          queryValue is! Timestamp ? DateTime.now() : queryValue.toDate(),
      firstDate: DateTime(1500),
      lastDate: DateTime(2201),
    );
    if (picked != null)
      setState(() {
        queryValue = Timestamp.fromDate(picked);
      });
  }

  void _selectFamily() async {
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(const OrderOptions());
    final listOptions = DataObjectListController<Family>(
      tap: (familySelected) {
        navigator.currentState!.pop();
        setState(() {
          queryValue = firestore.collection('Families').doc(familySelected.id);
          queryText = familySelected.name;
        });
      },
      itemsStream: _orderOptions
          .switchMap((value) => Family.getAllForUser(
              orderBy: value.orderBy, descending: !value.asc))
          .map((s) => s.docs.map(Family.fromQueryDoc).toList()),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Scaffold(
            body: SizedBox(
              width: MediaQuery.of(context).size.width - 55,
              height: MediaQuery.of(context).size.height - 110,
              child: Column(
                children: [
                  SearchFilters(
                    1,
                    options: listOptions,
                    orderOptions: BehaviorSubject<OrderOptions>.seeded(
                      const OrderOptions(),
                    ),
                    textStyle: Theme.of(context).textTheme.bodyText2,
                  ),
                  Expanded(
                    child: DataObjectList<Family>(
                      autoDisposeController: true,
                      options: listOptions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    await _orderOptions.close();
  }

  Future<void> _selectStreet() async {
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(const OrderOptions());

    await showDialog(
      context: context,
      builder: (context) {
        final listOptions = DataObjectListController<Street>(
          tap: (streetSelected) {
            navigator.currentState!.pop();
            setState(() {
              queryValue =
                  firestore.collection('Streets').doc(streetSelected.id);
              queryText = streetSelected.name;
            });
          },
          itemsStream: _orderOptions
              .switchMap((value) => Street.getAllForUser(
                  orderBy: value.orderBy, descending: !value.asc))
              .map((s) => s.docs.map(Street.fromQueryDoc).toList()),
        );
        return Dialog(
          child: Scaffold(
            body: SizedBox(
              width: MediaQuery.of(context).size.width - 55,
              height: MediaQuery.of(context).size.height - 110,
              child: Column(
                children: [
                  SearchFilters(
                    1,
                    options: listOptions,
                    orderOptions: BehaviorSubject<OrderOptions>.seeded(
                      const OrderOptions(),
                    ),
                    textStyle: Theme.of(context).textTheme.bodyText2,
                  ),
                  Expanded(
                    child: DataObjectList<Street>(
                      autoDisposeController: true,
                      options: listOptions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    await _orderOptions.close();
  }

  void _selectType() {
    showDialog(
      context: context,
      builder: (context) {
        return DataDialog(
          content: MiniModelList<PersonType>(
            title: 'أنواع الأشخاص',
            collection: firestore.collection('Types'),
            modify: (type) {
              navigator.currentState!.pop();
              setState(() {
                queryValue = type.id;
                queryText = type.name;
              });
            },
            transformer: PersonType.fromQueryDoc,
          ),
        );
      },
    );
  }
}
