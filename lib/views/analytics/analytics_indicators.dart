import 'dart:math';

import 'package:churchdata/models/history_record.dart';
import 'package:churchdata/models/models.dart';
import 'package:collection/collection.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tuple/tuple.dart';

class CartesianChart extends StatelessWidget {
  final String title;
  final DateTimeRange range;
  final Map<Timestamp, List<HistoryRecord>> data;
  final List<Area> areas;

  CartesianChart(
      {Key key,
      this.areas,
      this.range,
      @required this.data,
      @required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Builder(
        builder: (context) {
          if (data.isEmpty) return const Center(child: Text('لا يوجد سجل'));
          return SfCartesianChart(
            title: ChartTitle(text: title),
            enableAxisAnimation: true,
            primaryYAxis: NumericAxis(decimalPlaces: 0),
            primaryXAxis: DateTimeAxis(
              minimum: range.start,
              maximum: range.end,
              dateFormat: intl.DateFormat('d/M/yyy', 'ar-EG'),
              intervalType: DateTimeIntervalType.days,
              labelRotation: 90,
              desiredIntervals: data.keys.length > 25 ? 25 : data.keys.length,
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              duration: 5000,
              tooltipPosition: TooltipPosition.pointer,
              builder: (data, point, series, pointIndex, seriesIndex) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.all(Radius.circular(6.0)),
                  ),
                  height: 120,
                  width: 90,
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(intl.DateFormat('d/M/yyy', 'ar-EG')
                          .format(data.key.toDate())),
                      Text(
                        data.value.length.toString() + ' تعديل',
                      ),
                    ],
                  ),
                );
              },
            ),
            zoomPanBehavior: ZoomPanBehavior(
              enablePinching: true,
              enablePanning: true,
              enableDoubleTapZooming: true,
            ),
            series: [
              StackedAreaSeries<MapEntry<Timestamp, List<HistoryRecord>>,
                  DateTime>(
                markerSettings: MarkerSettings(isVisible: true),
                borderGradient: LinearGradient(
                  colors: [
                    Colors.cyan[300].withOpacity(0.5),
                    Colors.cyan[800].withOpacity(0.5)
                  ],
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.cyan[300].withOpacity(0.5),
                    Colors.cyan[800].withOpacity(0.5)
                  ],
                ),
                borderWidth: 2,
                dataSource: data.entries.toList(),
                xValueMapper: (item, index) => item.key.toDate(),
                yValueMapper: (item, index) => item.value.length,
                name: title,
              ),
            ],
          );
        },
      ),
    );
  }
}

class PieChart extends StatelessWidget {
  const PieChart({
    Key key,
    @required this.data,
    @required this.pieData,
    this.pointColorMapper,
  }) : super(key: key);

  final Color Function(Tuple2<int, String>, int) pointColorMapper;
  final List<HistoryRecord> data;
  final List<Tuple2<int, String>> pieData;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SfCircularChart(
        tooltipBehavior: TooltipBehavior(enable: true),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          isResponsive: false,
        ),
        series: [
          PieSeries<Tuple2<int, String>, String>(
              enableTooltip: true,
              enableSmartLabels: true,
              dataLabelMapper: (entry, _) =>
                  (entry.item2 ?? 'غير معروف') +
                  ': ' +
                  (entry.item1 / data.length * 100).toStringAsFixed(2) +
                  '%',
              pointColorMapper: pointColorMapper,
              dataSource: pieData,
              xValueMapper: (entry, _) => entry.item2 ?? 'غير معروف',
              yValueMapper: (entry, _) => entry.item1),
        ],
      ),
    );
  }
}

class HistoryAnalysisWidget extends StatelessWidget {
  HistoryAnalysisWidget({
    Key key,
    @required this.range,
    @required this.areas,
    @required this.areasByRef,
    @required this.collectionGroup,
    @required this.title,
    this.showUsers = true,
  }) : super(key: key);

  final DateTimeRange range;
  final List<Area> areas;
  final Map<String, Area> areasByRef;
  final String collectionGroup;
  final String title;
  final bool showUsers;

  final rnd = Random();
  final colorsMap = <Tuple2<int, String>, Color>{};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: HistoryRecord.getAllForUser(
          collectionGroup: collectionGroup, range: range, areas: areas),
      builder: (context, daysData) {
        if (daysData.hasError) return ErrorWidget(daysData.error);
        if (!daysData.hasData)
          return const Center(child: CircularProgressIndicator());
        if (daysData.data.isEmpty)
          return const Center(child: Text('لا يوجد سجل'));

        List<HistoryRecord> data =
            daysData.data.map(HistoryRecord.fromDoc).toList();

        mergeSort(data,
            compare: (o, n) => o.time.millisecondsSinceEpoch
                .compareTo(n.time.millisecondsSinceEpoch));
        Map<Timestamp, List<HistoryRecord>> groupedData =
            groupBy<HistoryRecord, Timestamp>(
                data, (d) => tranucateToDay(time: d.time.toDate()));

        var list = groupBy<HistoryRecord, String>(data, (s) => s.areaId?.path)
            .entries
            .toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CartesianChart(
              title: title,
              areas: areas,
              range: range,
              data: groupedData,
            ),
            ListTile(
              title: Text('تحليل ' + title + ' لكل منطقة'),
            ),
            PieChart(
              data: data,
              pieData: list
                  .map((e) => Tuple2<int, String>(
                      e.value.length, areasByRef[e.key]?.name))
                  .toList(),
              pointColorMapper: (entry, _) => areasByRef[entry.item2]?.color,
            ),
            if (showUsers)
              ListTile(
                title: Text('تحليل ' + title + ' لكل خادم'),
              ),
            if (showUsers)
              FutureBuilder<QuerySnapshot>(
                future: User.getAllUsersLive(),
                builder: (context, usersData) {
                  if (usersData.hasError) return ErrorWidget(usersData.error);
                  if (!usersData.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final usersByID = {
                    for (var u in usersData.data.docs) u.id: User.fromDoc(u)
                  };
                  final pieData =
                      groupBy<HistoryRecord, String>(data, (s) => s.by)
                          .entries
                          .toList();
                  return PieChart(
                    pointColorMapper: (entry, __) =>
                        colorsMap[entry] ??= _pickRandomColor(),
                    data: data,
                    pieData: pieData
                        .map((e) => Tuple2<int, String>(
                            e.value.length, usersByID[e.key]?.name))
                        .toList(),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Color _pickRandomColor() {
    return Color(rnd.nextInt(0xFFFFFFFF));
  }
}
