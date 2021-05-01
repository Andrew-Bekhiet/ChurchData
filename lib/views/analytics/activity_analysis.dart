import 'package:churchdata/models/models.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' as intl;

import 'analytics_indicators.dart';

class ActivityAnalysis extends StatefulWidget {
  final List<Area> areas;
  ActivityAnalysis({Key key, this.areas}) : super(key: key);

  @override
  _ActivityAnalysisState createState() => _ActivityAnalysisState();
}

class _ActivityAnalysisState extends State<ActivityAnalysis> {
  List<Area> areas;
  DateTimeRange range = DateTimeRange(
      start: DateTime.now().subtract(Duration(days: 30)), end: DateTime.now());
  DateTime minAvaliable = DateTime.now().subtract(Duration(days: 30));
  final _screenKey = GlobalKey();
  bool minAvaliableSet = false;

  Future<void> _setRangeStart() async {
    if (minAvaliableSet) return;
    if (User.instance.superAccess)
      minAvaliable = ((await FirebaseFirestore.instance
                  .collectionGroup('EditHistory')
                  .orderBy('Time')
                  .limit(1)
                  .get(dataSource))
              .docs[0]
              .data()['Time'] as Timestamp)
          .toDate();
    else
      minAvaliable = ((await FirebaseFirestore.instance
                  .collectionGroup('EditHistory')
                  .where('AreaId', whereIn: await Area.getAllAreasForUser())
                  .orderBy('Time')
                  .limit(1)
                  .get(dataSource))
              .docs[0]
              .data()['Time'] as Timestamp)
          .toDate();
    minAvaliableSet = true;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _screenKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الاحصائيات'),
          actions: [
            IconButton(
              icon: Icon(Icons.mobile_screen_share),
              onPressed: () => takeScreenshot(_screenKey),
              tooltip: 'حفظ كصورة',
            ),
          ],
        ),
        body: FutureBuilder(
          future: _setRangeStart(),
          builder: (context, _) {
            if (_.connectionState == ConnectionState.done) {
              return StreamBuilder<List<Area>>(
                initialData: widget.areas,
                stream: Area.getAllForUser()
                    .map((s) => s.docs.map(Area.fromDoc).toList()),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return ErrorWidget(snapshot.error);
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  areas ??= snapshot.data;
                  final areasByRef = {for (var a in areas) a.ref.path: a};

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                              'احصائيات الخدمة من ' +
                                  intl.DateFormat.yMMMEd('ar_EG')
                                      .format(range.start) +
                                  ' الى ' +
                                  intl.DateFormat.yMMMEd('ar_EG')
                                      .format(range.end),
                              style: Theme.of(context).textTheme.bodyText1),
                          trailing: IconButton(
                            icon: Icon(Icons.date_range),
                            tooltip: 'اختيار نطاق السجل',
                            onPressed: () async {
                              var rslt = await showDateRangePicker(
                                builder: (context, dialog) => Theme(
                                  data: Theme.of(context).copyWith(
                                    textTheme:
                                        Theme.of(context).textTheme.copyWith(
                                              overline: TextStyle(
                                                fontSize: 0,
                                              ),
                                            ),
                                  ),
                                  child: dialog,
                                ),
                                helpText: null,
                                context: context,
                                confirmText: 'حفظ',
                                saveText: 'حفظ',
                                initialDateRange:
                                    range.start.millisecondsSinceEpoch <=
                                            minAvaliable.millisecondsSinceEpoch
                                        ? range
                                        : DateTimeRange(
                                            start: DateTime.now()
                                                .subtract(Duration(days: 1)),
                                            end: range.end),
                                firstDate: minAvaliable,
                                lastDate: DateTime.now(),
                              );
                              if (rslt != null) {
                                range = rslt;
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        ListTile(
                          title: Text('لمناطق: '),
                          subtitle: Text(
                            areas.map((c) => c.name).toList().join(', '),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.list_alt),
                            tooltip: 'اختيار المناطق',
                            onPressed: () async {
                              var rslt = await selectAreas(context, areas);
                              if (rslt != null && rslt.isNotEmpty)
                                setState(() => areas = rslt);
                              else if (rslt.isNotEmpty)
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    content: Text(
                                        'برجاء اختيار منطقة واحدة على الأقل'),
                                  ),
                                );
                            },
                          ),
                        ),
                        HistoryAnalysisWidget(
                          range: range,
                          areas: areas,
                          areasByRef: areasByRef,
                          collectionGroup: 'VisitHistory',
                          title: 'خدمة الافتقاد',
                        ),
                        HistoryAnalysisWidget(
                          range: range,
                          areas: areas,
                          areasByRef: areasByRef,
                          collectionGroup: 'EditHistory',
                          title: 'تحديث البيانات',
                        ),
                        HistoryAnalysisWidget(
                          range: range,
                          areas: areas,
                          areasByRef: areasByRef,
                          collectionGroup: 'CallHistory',
                          title: 'خدمة المكالمات',
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
