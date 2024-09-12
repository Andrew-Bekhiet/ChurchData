import 'package:churchdata/models/models.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'analytics_indicators.dart';

class SpiritualAnalysis extends StatefulWidget {
  final List<Area>? areas;
  const SpiritualAnalysis({super.key, this.areas});

  @override
  _SpiritualAnalysisState createState() => _SpiritualAnalysisState();
}

class _SpiritualAnalysisState extends State<SpiritualAnalysis> {
  List<Area>? areas;
  DateTimeRange range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  DateTime minAvaliable = DateTime.now().subtract(const Duration(days: 30));
  final _screenKey = GlobalKey();
  bool minAvaliableSet = false;

  Future<void> _setRangeStart() async {
    if (minAvaliableSet) return;
    if (User.instance.superAccess)
      minAvaliable = ((await firestore
                  .collectionGroup('EditHistory')
                  .orderBy('Time')
                  .limit(1)
                  .get())
              .docs[0]
              .data()['Time'] as Timestamp)
          .toDate();
    else
      minAvaliable = ((await firestore
                  .collectionGroup('EditHistory')
                  .where('AreaId', whereIn: await Area.getAllAreasForUser())
                  .orderBy('Time')
                  .limit(1)
                  .get())
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
          title: const Text('الاحصائيات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.mobile_screen_share),
              onPressed: () => takeScreenshot(_screenKey),
              tooltip: 'حفظ كصورة',
            ),
          ],
        ),
        body: FutureBuilder(
          future: _setRangeStart(),
          builder: (context, rangeStartData) {
            if (rangeStartData.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());

            return StreamBuilder<List<Area>>(
              initialData: widget.areas,
              stream: Area.getAllForUser()
                  .map((s) => s.docs.map(Area.fromQueryDoc).toList()),
              builder: (context, snapshot) {
                if (snapshot.hasError) return ErrorWidget(snapshot.error!);
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                areas ??= snapshot.data;
                final areasByRef = {for (final a in areas!) a.ref.path: a};

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          'احصائيات الخدمة من ' +
                              intl.DateFormat.yMMMEd('ar_EG')
                                  .format(range.start) +
                              ' الى ' +
                              intl.DateFormat.yMMMEd('ar_EG').format(range.end),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.date_range),
                          tooltip: 'اختيار نطاق السجل',
                          onPressed: () async {
                            final rslt = await showDateRangePicker(
                              builder: (context, dialog) => Theme(
                                data: Theme.of(context).copyWith(
                                  textTheme:
                                      Theme.of(context).textTheme.copyWith(
                                            labelSmall: const TextStyle(
                                              fontSize: 0,
                                            ),
                                          ),
                                ),
                                child: dialog!,
                              ),
                              context: context,
                              confirmText: 'حفظ',
                              saveText: 'حفظ',
                              initialDateRange: range
                                          .start.millisecondsSinceEpoch <=
                                      minAvaliable.millisecondsSinceEpoch
                                  ? range
                                  : DateTimeRange(
                                      start: DateTime.now()
                                          .subtract(const Duration(days: 1)),
                                      end: range.end,
                                    ),
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
                        title: const Text('لمناطق: '),
                        subtitle: Text(
                          areas!.map((c) => c.name).toList().join(', '),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.list_alt),
                          tooltip: 'اختيار المناطق',
                          onPressed: () async {
                            final rslt = await selectAreas(context, areas!);
                            if (rslt != null && rslt.isNotEmpty)
                              setState(() => areas = rslt);
                            else if (rslt != null)
                              await showDialog(
                                context: context,
                                builder: (context) => const AlertDialog(
                                  content: Text(
                                    'برجاء اختيار منطقة واحدة على الأقل',
                                  ),
                                ),
                              );
                          },
                        ),
                      ),
                      HistoryAnalysisWidget(
                        range: range,
                        areas: areas!,
                        areasByRef: areasByRef,
                        collectionGroup: 'TanawolHistory',
                        title: 'التناول',
                        showUsers: false,
                      ),
                      HistoryAnalysisWidget(
                        range: range,
                        areas: areas!,
                        areasByRef: areasByRef,
                        collectionGroup: 'ConfessionHistory',
                        title: 'الاعتراف',
                        showUsers: false,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
