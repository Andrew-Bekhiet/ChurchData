import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:churchdata/views/settings.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class NotificationSetting extends StatefulWidget {
  final String label;
  final String hiveKey;
  final int alarmId;
  final Function notificationCallback;

  NotificationSetting(
      {Key key,
      this.label,
      this.hiveKey,
      this.alarmId,
      this.notificationCallback})
      : super(key: key);

  @override
  _NotificationSettingState createState() => _NotificationSettingState();
}

class _NotificationSettingState extends State<NotificationSetting> {
  int multiplier = 1;
  final TextEditingController period = TextEditingController();
  TimeOfDay time;

  var notificationsSettings =
      Hive.box<Map<dynamic, dynamic>>('NotificationsSettings');

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          flex: 50,
          child: TextField(
            decoration: InputDecoration(
              labelText: widget.label,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            keyboardType: TextInputType.number,
            controller: period
              ..text = _totalDays(notificationsSettings.get(widget.hiveKey,
                      defaultValue: {
                    'Period': 7
                  }).cast<String, int>()['Period'])
                  .toString(),
          ),
        ),
        Container(width: 20),
        Flexible(
          flex: 25,
          child: DropdownButtonFormField(
            items: [
              DropdownMenuItem(
                value: DateType.day,
                child: Text('يوم'),
              ),
              DropdownMenuItem(
                value: DateType.week,
                child: Text('اسبوع'),
              ),
              DropdownMenuItem(
                value: DateType.month,
                child: Text('شهر'),
              )
            ],
            value: _largestPossible(notificationsSettings.get(widget.hiveKey,
                defaultValue: {'Period': 7}).cast<String, int>()['Period']),
            onSaved: (_) => onSave(),
            onChanged: (value) async {
              if (value as DateType == DateType.month) {
                multiplier = 30;
              } else if (value as DateType == DateType.week) {
                multiplier = 7;
              } else if (value as DateType == DateType.day) {
                multiplier = 1;
              }
            },
          ),
        ),
        Flexible(
          flex: 25,
          child: DateTimeField(
            format: DateFormat(
                'h:m' +
                    (MediaQuery.of(context).alwaysUse24HourFormat ? '' : ' a'),
                'ar-EG'),
            resetIcon: null,
            initialValue: DateTime(2021, 1, 1, time.hour, time.minute),
            onShowPicker: (context, initialValue) async {
              var selected = await showTimePicker(
                initialTime: TimeOfDay.fromDateTime(initialValue),
                context: context,
              );
              return DateTime(2020, 1, 1, selected?.hour ?? initialValue.hour,
                  selected?.minute ?? initialValue.minute);
            },
            onChanged: (value) {
              time = TimeOfDay(hour: value.hour, minute: value.minute);
            },
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    time = TimeOfDay(
      hour: notificationsSettings.get(widget.hiveKey,
          defaultValue: {'Hours': 11}).cast<String, int>()['Hours'],
      minute: notificationsSettings.get(widget.hiveKey,
          defaultValue: {'Minutes': 0}).cast<String, int>()['Minutes'],
    );
  }

  void onSave() async {
    var current = notificationsSettings.get(widget.hiveKey, defaultValue: {
      'Hours': 11,
      'Minutes': 0,
      'Period': 7
    }).cast<String, int>();
    if (current['Period'] == int.parse(period.text) * multiplier &&
        current['Hours'] == time.hour &&
        current['Minutes'] == time.minute) return;
    await notificationsSettings.put(widget.hiveKey, <String, int>{
      'Period': int.parse(period.text) * multiplier,
      'Hours': time.hour,
      'Minutes': time.minute
    });
    await AndroidAlarmManager.periodic(
        Duration(days: int.parse(period.text) * multiplier),
        widget.alarmId,
        widget.notificationCallback,
        exact: true,
        startAt: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, time.hour, time.minute),
        rescheduleOnReboot: true);
  }

  static DateType _largestPossible(int days) {
    if (days % 30 == 0) {
      return DateType.month;
    } else if (days % 7 == 0) {
      return DateType.week;
    }
    return DateType.day;
  }

  static int _totalDays(int days) {
    if (days % 30 == 0) {
      return days ~/ 30;
    } else if (days % 7 == 0) {
      return days ~/ 7;
    }
    return days;
  }
}
