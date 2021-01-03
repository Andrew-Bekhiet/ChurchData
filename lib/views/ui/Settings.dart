import 'package:churchdata/views/MiniLists/ColorsList.dart';
import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Models.dart';
import '../../Models/User.dart';
import '../../utils/Helpers.dart';
import '../../utils/globals.dart';

enum DateType {
  month,
  week,
  day,
}

class Settings extends StatefulWidget {
  Settings({Key key}) : super(key: key);
  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  Color color;
  bool darkTheme;

  bool state;

  int reminderTimeHours;
  int reminderTimeMinutes;

  TextEditingController confessionValue = TextEditingController();
  TextEditingController confessionPValue = TextEditingController();

  TextEditingController tanawolValue = TextEditingController();
  TextEditingController tanawolPValue = TextEditingController();

  int confessionsN;
  int confessionsPN;

  int tanawolN;
  int tanawolPN;
  void Function() _save;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
      appBar: AppBar(
        title: Text('الاعدادات'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: Builder(
              builder: (context) {
                _save = () {
                  Form.of(context).save();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم الحفظ'),
                    ),
                  );
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ExpandablePanel(
                      theme: ExpandableThemeData(
                          useInkWell: true,
                          iconColor: Theme.of(context).iconTheme?.color,
                          bodyAlignment: ExpandablePanelBodyAlignment.right),
                      header: Text(
                        'المظهر',
                        style: TextStyle(fontSize: 24),
                      ),
                      collapsed: Text('المظهر العام للبرنامج'),
                      expanded: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ElevatedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => DataDialog(
                                content: ColorsList(
                                  colors: primaries,
                                  selectedColor: color,
                                  onSelect: (color, _) {
                                    Navigator.of(context).pop();
                                    setState(() {
                                      this.color = color;
                                    });
                                  },
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(primary: color),
                            icon: Icon(Icons.color_lens),
                            label: Text('اللون'),
                          ),
                          FutureBuilder(
                            future: settingsInstance,
                            builder: (context, data) {
                              return data.hasData
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        ChoiceChip(
                                          label: Text('المظهر الداكن'),
                                          selected: darkTheme == true,
                                          onSelected: (v) =>
                                              setState(() => darkTheme = true),
                                        ),
                                        ChoiceChip(
                                          label: Text('المظهر الفاتح'),
                                          selected: darkTheme == false,
                                          onSelected: (v) =>
                                              setState(() => darkTheme = false),
                                        ),
                                        ChoiceChip(
                                          label: Text('حسب النظام'),
                                          selected: darkTheme == null,
                                          onSelected: (v) =>
                                              setState(() => darkTheme = null),
                                        ),
                                      ],
                                    )
                                  : Switch(
                                      value: false,
                                      onChanged: null,
                                    );
                            },
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await (await settingsInstance)
                                  .setBool('Theme', darkTheme);
                              await (await settingsInstance).setInt(
                                'Theme.of(context).primaryColorIndex',
                                primaries.indexOf(color),
                              );
                              changeTheme(context: context);
                            },
                            child: Text('تغيير'),
                          ),
                        ],
                      ),
                    ),
                    ExpandablePanel(
                      theme: ExpandableThemeData(
                          useInkWell: true,
                          iconColor: Theme.of(context).iconTheme?.color,
                          bodyAlignment: ExpandablePanelBodyAlignment.right),
                      header: Text(
                        'بيانات إضافية',
                        style: TextStyle(fontSize: 24),
                      ),
                      collapsed: Text(
                          'الكنائس، الأباء الكهنة، الوظائف، السنوات الدراسية، أنواع الخدمات، أنواع الأشخاص',
                          overflow: TextOverflow.ellipsis),
                      expanded: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('Settings/Churches'),
                            child: Text('الكنائس'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('Settings/Fathers'),
                            child: Text('الأباء الكهنة'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('Settings/Jobs'),
                            child: Text('الوظائف'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('Settings/StudyYears'),
                            child: Text('السنوات الدراسية'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('Settings/Colleges'),
                            child: Text('الكليات'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('Settings/ServingTypes'),
                            child: Text('أنواع الخدمات'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('Settings/PersonTypes'),
                            child: Text('أنواع الأشخاص'),
                          ),
                        ],
                      ),
                    ),
                    ExpandablePanel(
                      theme: ExpandableThemeData(
                          useInkWell: true,
                          iconColor: Theme.of(context).iconTheme?.color,
                          bodyAlignment: ExpandablePanelBodyAlignment.right),
                      header: Text(
                        'مظهر البيانات',
                        style: TextStyle(fontSize: 24),
                      ),
                      collapsed: Text(
                          'السطر الثاني للمنطقة، السطر الثاني للشارع، السطر الثاني للعائلة، السطر الثاني للشخص',
                          overflow: TextOverflow.ellipsis),
                      expanded: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          FutureBuilder<SharedPreferences>(
                              future: settingsInstance,
                              builder: (context, d) {
                                if (d.connectionState != ConnectionState.done)
                                  return LinearProgressIndicator();
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 4.0),
                                  child: DropdownButtonFormField(
                                    value: d.data.getString('AreaSecondLine'),
                                    items: Area.getStaticHumanReadableMap()
                                        .entries
                                        .map(
                                          (e) => DropdownMenuItem(
                                              child: Text(e.value),
                                              value: e.key),
                                        )
                                        .toList()
                                          ..removeWhere((element) =>
                                              element.value == 'Color')
                                          ..add(
                                            DropdownMenuItem(
                                                child: Text('الشوارع بالمنطقة'),
                                                value: 'Members'),
                                          ),
                                    onChanged: (value) {},
                                    onSaved: (value) {
                                      d.data.setString('AreaSecondLine', value);
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'السطر الثاني للمنطقة:',
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          FutureBuilder<SharedPreferences>(
                              future: settingsInstance,
                              builder: (context, d) {
                                if (d.connectionState != ConnectionState.done)
                                  return LinearProgressIndicator();
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 4.0),
                                  child: DropdownButtonFormField(
                                    value: d.data.getString('StreetSecondLine'),
                                    items: Street.getHumanReadableMap2()
                                        .entries
                                        .map(
                                          (e) => DropdownMenuItem(
                                              child: Text(e.value),
                                              value: e.key),
                                        )
                                        .toList()
                                          ..removeWhere((element) =>
                                              element.value == 'Color')
                                          ..add(
                                            DropdownMenuItem(
                                                child: Text('العائلات بالشارع'),
                                                value: 'Members'),
                                          ),
                                    onChanged: (value) {},
                                    onSaved: (value) {
                                      d.data
                                          .setString('StreetSecondLine', value);
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'السطر الثاني للشارع:',
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          FutureBuilder<SharedPreferences>(
                              future: settingsInstance,
                              builder: (context, d) {
                                if (d.connectionState != ConnectionState.done)
                                  return LinearProgressIndicator();
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 4.0),
                                  child: DropdownButtonFormField(
                                    value: d.data.getString('FamilySecondLine'),
                                    items: Family.getHumanReadableMap2()
                                        .entries
                                        .map(
                                          (e) => DropdownMenuItem(
                                              child: Text(e.value),
                                              value: e.key),
                                        )
                                        .toList()
                                          ..removeWhere((element) =>
                                              element.value == 'Color')
                                          ..add(
                                            DropdownMenuItem(
                                                child: Text('الأشخاص بالعائلة'),
                                                value: 'Members'),
                                          ),
                                    onChanged: (value) {},
                                    onSaved: (value) {
                                      d.data
                                          .setString('FamilySecondLine', value);
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'السطر الثاني للعائلة:',
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          FutureBuilder<SharedPreferences>(
                              future: settingsInstance,
                              builder: (context, d) {
                                if (d.connectionState != ConnectionState.done)
                                  return LinearProgressIndicator();
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 4.0),
                                  child: DropdownButtonFormField(
                                    value: d.data.getString('PersonSecondLine'),
                                    items: Person.getHumanReadableMap2()
                                        .entries
                                        .map(
                                          (e) => DropdownMenuItem(
                                              child: Text(e.value),
                                              value: e.key),
                                        )
                                        .toList()
                                          ..removeWhere((element) =>
                                              element.value == 'Color'),
                                    onChanged: (value) {},
                                    onSaved: (value) {
                                      d.data
                                          .setString('PersonSecondLine', value);
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'السطر الثاني للشخص:',
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          FutureBuilder<SharedPreferences>(
                              future: settingsInstance,
                              builder: (context, d) {
                                if (d.connectionState != ConnectionState.done)
                                  return LinearProgressIndicator();
                                return Row(
                                  children: <Widget>[
                                    Text('إظهار الحالة بجانب كل شخص'),
                                    FormField(
                                      builder: (context) => Switch(
                                        value: state,
                                        onChanged: (v) => setState(() {
                                          state = v;
                                        }),
                                      ),
                                      onSaved: (_) => d.data
                                          .setBool('ShowPersonState', state),
                                    ),
                                  ],
                                );
                              }),
                        ],
                      ),
                    ),
                    Selector<User, Map<String, bool>>(
                        selector: (_, user) =>
                            user.getNotificationsPermissions(),
                        builder: (context, permission, _) {
                          if (permission.containsValue(true)) {
                            return ExpandablePanel(
                              theme: ExpandableThemeData(
                                  useInkWell: true,
                                  iconColor: Theme.of(context).iconTheme?.color,
                                  bodyAlignment:
                                      ExpandablePanelBodyAlignment.right),
                              header: Text(
                                'الاشعارات',
                                style: TextStyle(fontSize: 24),
                              ),
                              collapsed: Text('اعدادات الاشعارات'),
                              expanded: _getNotificationsContent(permission),
                            );
                          }
                          return Container();
                        }),
                    ExpandablePanel(
                      theme: ExpandableThemeData(
                          useInkWell: true,
                          iconColor: Theme.of(context).iconTheme?.color,
                          bodyAlignment: ExpandablePanelBodyAlignment.right),
                      header: Text(
                        'أخرى',
                        style: TextStyle(fontSize: 24),
                      ),
                      collapsed: Text('إعدادات أخرى'),
                      expanded: FutureBuilder<SharedPreferences>(
                        future: settingsInstance,
                        builder: (context, d) {
                          if (d.connectionState != ConnectionState.done)
                            return LinearProgressIndicator();
                          return Container(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText:
                                    'الحجم الأقصى للبيانات المؤقتة (MB):',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              initialValue: d.hasData &&
                                      d.data.getString('cacheSize') != null
                                  ? ((num.parse(
                                                d.data.getString('cacheSize'),
                                              ) /
                                              1024) /
                                          1024)
                                      .truncate()
                                      .toString()
                                  : '300',
                              onSaved: (t) async {
                                await (await settingsInstance).setString(
                                  'cacheSize',
                                  (num.parse(t) * 1024 * 1024).toString(),
                                );
                              },
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'هذا الحقل مطلوب';
                                }
                                return null;
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () => _save(),
        tooltip: 'حفظ',
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    color = Theme.of(context).primaryColor;
    settingsInstance.then((value) {
      setState(() {
        darkTheme = value.getBool('Theme');
        state = value.getBool('ShowPersonState') ?? false;
        reminderTimeHours = value.getString('ReminderTimeHours') != null
            ? int.parse(
                value.getString('ReminderTimeHours'),
              )
            : 11;
        reminderTimeMinutes = value.getString('ReminderTimeMinutes') != null
            ? int.parse(
                value.getString('ReminderTimeMinutes'),
              )
            : 0;

        confessionsN = value.getString('ConfessionsInterval') != null
            ? int.parse(
                value.getString('ConfessionsInterval'),
              )
            : Duration.millisecondsPerDay * 7;
        confessionsPN = value.getString('ConfessionsPInterval') != null
            ? int.parse(
                value.getString('ConfessionsPInterval'),
              )
            : Duration.millisecondsPerDay * 7;

        tanawolN = value.getString('TanawolInterval') != null
            ? int.parse(
                value.getString('TanawolInterval'),
              )
            : Duration.millisecondsPerDay * 7;
        tanawolPN = value.getString('TanawolPInterval') != null
            ? int.parse(
                value.getString('TanawolPInterval'),
              )
            : Duration.millisecondsPerDay * 7;
      });
    });
  }

  Widget _getNotificationsContent(Map<String, bool> notifications) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (notifications['birthdayNotify'])
          Row(
            children: <Widget>[
              Text('التذكير بأعياد الميلاد كل يوم الساعة: '),
              FormField(
                onSaved: (test) async {
                  await (await settingsInstance).setString(
                    'ReminderTimeHours',
                    reminderTimeHours.toString(),
                  );
                  await (await settingsInstance).setString(
                    'ReminderTimeMinutes',
                    reminderTimeMinutes.toString(),
                  );
                  await notifChannel.invokeMethod('startBirthDay');
                },
                builder: (context) => TextButton(
                  onPressed: () async {
                    var selected = await showTimePicker(
                      initialTime: TimeOfDay.fromDateTime(
                        DateTime(
                            1970, 1, 1, reminderTimeHours, reminderTimeMinutes),
                      ),
                      context: this.context,
                      /*useRootNavigator: false*/
                    );
                    if (selected == null ||
                        reminderTimeMinutes == selected.minute &&
                            reminderTimeHours == selected.hour) {
                      return;
                    }
                    reminderTimeHours = selected.hour;
                    reminderTimeMinutes = selected.minute;
                    setState(() {});
                  },
                  child: Text(
                    Duration(
                          hours: reminderTimeHours > 12
                              ? reminderTimeHours - 12
                              : reminderTimeHours,
                          minutes: reminderTimeMinutes,
                        ).toString().replaceAll(':00.000000', '') +
                        (reminderTimeHours > 12 ? ' م' : ' ص'),
                  ),
                ),
              ),
            ],
          ),
        if (notifications['confessionsNotify'])
          Divider(
            thickness: 2,
            height: 30,
          ),
        if (notifications['confessionsNotify'])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'ارسال انذار الاعتراف كل ',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  controller: confessionValue
                    ..text = _totalDays(confessionsN).toInt().toString(),
                ),
              ),
              Container(width: 20),
              Expanded(
                child: DropdownButtonFormField(
                  items: [
                    DropdownMenuItem(child: Text('يوم'), value: DateType.day),
                    DropdownMenuItem(
                        child: Text('اسبوع'), value: DateType.week),
                    DropdownMenuItem(child: Text('شهر'), value: DateType.month)
                  ],
                  value: _largestPossible(
                      confessionsN ?? Duration.millisecondsPerDay * 7),
                  onChanged: (v) {
                    if ((v as DateType) == DateType.month) {
                      confessionsN = int.parse(confessionValue.text) *
                          30 *
                          Duration.millisecondsPerDay;
                    } else if ((v as DateType) == DateType.week) {
                      confessionsN = int.parse(confessionValue.text) *
                          7 *
                          Duration.millisecondsPerDay;
                    } else if ((v as DateType) == DateType.day) {
                      confessionsN = int.parse(confessionValue.text) *
                          Duration.millisecondsPerDay;
                    }
                  },
                  onSaved: (value) async {
                    if (value as DateType == DateType.month) {
                      await (await settingsInstance).setString(
                        'ConfessionsInterval',
                        (int.parse(confessionValue.text) *
                                30 *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    } else if (value as DateType == DateType.week) {
                      await (await settingsInstance).setString(
                        'ConfessionsInterval',
                        (int.parse(confessionValue.text) *
                                7 *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    } else if (value as DateType == DateType.day) {
                      await (await settingsInstance).setString(
                        'ConfessionsInterval',
                        (int.parse(confessionValue.text) *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        if (notifications['confessionsNotify']) Container(height: 20),
        if (notifications['confessionsNotify'])
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'لمن يمر عليه مدة ',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  controller: confessionPValue
                    ..text = _totalDays(confessionsPN).toInt().toString(),
                ),
                flex: 2,
              ),
              Container(width: 20),
              Expanded(
                child: DropdownButtonFormField(
                  items: [
                    DropdownMenuItem(child: Text('يوم'), value: DateType.day),
                    DropdownMenuItem(
                        child: Text('اسبوع'), value: DateType.week),
                    DropdownMenuItem(child: Text('شهر'), value: DateType.month)
                  ],
                  value: _largestPossible(
                      confessionsPN ?? Duration.millisecondsPerDay * 7),
                  onChanged: (v) {
                    if ((v as DateType) == DateType.month) {
                      confessionsPN = int.parse(confessionPValue.text) *
                          30 *
                          Duration.millisecondsPerDay;
                    } else if ((v as DateType) == DateType.week) {
                      confessionsPN = int.parse(confessionPValue.text) *
                          7 *
                          Duration.millisecondsPerDay;
                    } else if ((v as DateType) == DateType.day) {
                      confessionsPN = int.parse(confessionPValue.text) *
                          Duration.millisecondsPerDay;
                    }
                  },
                  onSaved: (value) async {
                    if (value as DateType == DateType.month) {
                      await (await settingsInstance).setString(
                        'ConfessionsPInterval',
                        (int.parse(confessionPValue.text) *
                                30 *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    } else if (value as DateType == DateType.week) {
                      await (await settingsInstance).setString(
                        'ConfessionsPInterval',
                        (int.parse(confessionPValue.text) *
                                7 *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    } else if (value as DateType == DateType.day) {
                      await (await settingsInstance).setString(
                        'ConfessionsPInterval',
                        (int.parse(confessionPValue.text) *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    }
                    await notifChannel.invokeMethod('startConfessions');
                  },
                ),
              ),
            ],
          ),
        Divider(
          thickness: 2,
          height: 30,
        ),
        if (notifications['tanawolNotify'])
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'ارسال انذار التناول كل ',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  controller: tanawolValue
                    ..text = _totalDays(tanawolN).toInt().toString(),
                ),
                flex: 2,
              ),
              Container(width: 20),
              Expanded(
                child: DropdownButtonFormField(
                  items: [
                    DropdownMenuItem(child: Text('يوم'), value: DateType.day),
                    DropdownMenuItem(
                        child: Text('اسبوع'), value: DateType.week),
                    DropdownMenuItem(child: Text('شهر'), value: DateType.month)
                  ],
                  value: _largestPossible(
                      tanawolN ?? Duration.millisecondsPerDay * 7),
                  onChanged: (v) {
                    if ((v as DateType) == DateType.month) {
                      tanawolN = int.parse(tanawolValue.text) *
                          30 *
                          Duration.millisecondsPerDay;
                    } else if ((v as DateType) == DateType.week) {
                      tanawolN = int.parse(tanawolValue.text) *
                          7 *
                          Duration.millisecondsPerDay;
                    } else if ((v as DateType) == DateType.day) {
                      tanawolN = int.parse(tanawolValue.text) *
                          Duration.millisecondsPerDay;
                    }
                  },
                  onSaved: (value) async {
                    if (value as DateType == DateType.month) {
                      await (await settingsInstance).setString(
                        'TanawolInterval',
                        (int.parse(tanawolValue.text) *
                                30 *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    } else if (value as DateType == DateType.week) {
                      await (await settingsInstance).setString(
                        'TanawolInterval',
                        (int.parse(tanawolValue.text) *
                                7 *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    } else if (value as DateType == DateType.day) {
                      await (await settingsInstance).setString(
                        'TanawolInterval',
                        (int.parse(tanawolValue.text) *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        if (notifications['tanawolNotify']) Container(height: 20),
        if (notifications['tanawolNotify'])
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'لمن يمر عليه مدة ',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  controller: tanawolPValue
                    ..text =
                        _totalDays(tanawolPN ?? Duration.millisecondsPerDay * 7)
                            .toInt()
                            .toString(),
                ),
                flex: 2,
              ),
              Container(width: 20),
              Expanded(
                child: DropdownButtonFormField(
                  items: [
                    DropdownMenuItem(child: Text('يوم'), value: DateType.day),
                    DropdownMenuItem(
                        child: Text('اسبوع'), value: DateType.week),
                    DropdownMenuItem(child: Text('شهر'), value: DateType.month)
                  ],
                  value: _largestPossible(
                      tanawolPN ?? Duration.millisecondsPerDay * 7),
                  onChanged: (v) {
                    if ((v as DateType) == DateType.month) {
                      tanawolPN = int.parse(tanawolPValue.text) *
                          30 *
                          Duration.millisecondsPerDay;
                    } else if ((v as DateType) == DateType.week) {
                      tanawolPN = int.parse(tanawolPValue.text) *
                          7 *
                          Duration.millisecondsPerDay;
                    } else if ((v as DateType) == DateType.day) {
                      tanawolPN = int.parse(tanawolPValue.text) *
                          Duration.millisecondsPerDay;
                    }
                  },
                  onSaved: (value) async {
                    if (value as DateType == DateType.month) {
                      await (await settingsInstance).setString(
                        'TanawolPInterval',
                        (int.parse(tanawolPValue.text) *
                                30 *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    } else if (value as DateType == DateType.week) {
                      await (await settingsInstance).setString(
                        'TanawolPInterval',
                        (int.parse(tanawolPValue.text) *
                                7 *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    } else if (value as DateType == DateType.day) {
                      await (await settingsInstance).setString(
                        'TanawolPInterval',
                        (int.parse(tanawolPValue.text) *
                                Duration.millisecondsPerDay)
                            .toString(),
                      );
                    }
                    await notifChannel.invokeMethod('startTanawol');
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  static DateType _largestPossible(int milliseconds) {
    Duration time = Duration(milliseconds: milliseconds);
    if (time.inDays % 30 == 0) {
      return DateType.month;
    } else if (time.inDays % 7 == 0) {
      return DateType.week;
    }
    return DateType.day;
  }

  static double _totalDays(int milliseconds) {
    if (milliseconds == null) return 1;
    Duration time = Duration(milliseconds: milliseconds);
    if (time.inDays % 30 == 0) {
      return time.inDays / 30;
    } else if (time.inDays % 7 == 0) {
      return time.inDays / 7;
    }
    return time.inDays.toDouble();
  }
}
