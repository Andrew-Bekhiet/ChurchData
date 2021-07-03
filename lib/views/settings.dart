import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/notification_setting.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/typedefs.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../utils/globals.dart';
import '../utils/helpers.dart';

enum DateType {
  month,
  week,
  day,
}

class Settings extends StatefulWidget {
  Settings({Key? key}) : super(key: key);
  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  Color? color;
  bool? darkTheme;
  late bool greatFeastTheme;

  bool? state;

  GlobalKey<FormState> formKey = GlobalKey();

  var settings = Hive.box('Settings');

  var notificationsSettings = Hive.box<Map>('NotificationsSettings');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الاعدادات'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ExpandablePanel(
                  theme: ExpandableThemeData(
                    useInkWell: true,
                    iconColor: Theme.of(context).iconTheme.color,
                    bodyAlignment: ExpandablePanelBodyAlignment.right,
                  ),
                  header: Text(
                    'المظهر',
                    style: TextStyle(fontSize: 24),
                  ),
                  collapsed: Text('المظهر العام للبرنامج'),
                  expanded: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          ChoiceChip(
                            label: Text('المظهر الداكن'),
                            selected: darkTheme == true,
                            onSelected: (v) => setState(() => darkTheme = true),
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
                            onSelected: (v) => setState(() => darkTheme = null),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: greatFeastTheme,
                        onChanged: (v) => setState(() => greatFeastTheme = v),
                        title: Text(
                            'تغيير لون البرنامج حسب أسبوع الآلام وفترة الخمسين'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Hive.box('Settings')
                              .put('DarkTheme', darkTheme);
                          await Hive.box('Settings')
                              .put('GreatFeastTheme', greatFeastTheme);

                          changeTheme(context: context);
                        },
                        icon: Icon(Icons.done),
                        label: Text('تغيير'),
                      ),
                    ],
                  ),
                ),
                ExpandablePanel(
                  theme: ExpandableThemeData(
                    useInkWell: true,
                    iconColor: Theme.of(context).iconTheme.color,
                    bodyAlignment: ExpandablePanelBodyAlignment.right,
                  ),
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
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/Churches'),
                        child: Text('الكنائس'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/Fathers'),
                        child: Text('الأباء الكهنة'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            navigator.currentState!.pushNamed('Settings/Jobs'),
                        child: Text('الوظائف'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/StudyYears'),
                        child: Text('السنوات الدراسية'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/Colleges'),
                        child: Text('الكليات'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/ServingTypes'),
                        child: Text('أنواع الخدمات'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/PersonTypes'),
                        child: Text('أنواع الأشخاص'),
                      ),
                    ],
                  ),
                ),
                ExpandablePanel(
                  theme: ExpandableThemeData(
                    useInkWell: true,
                    iconColor: Theme.of(context).iconTheme.color,
                    bodyAlignment: ExpandablePanelBodyAlignment.right,
                  ),
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
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: DropdownButtonFormField(
                          onChanged: (_) {},
                          value: settings.get('AreaSecondLine'),
                          items: Area.getStaticHumanReadableMap()
                              .entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList()
                                ..removeWhere(
                                    (element) => element.value == 'Color')
                                ..add(
                                  DropdownMenuItem(
                                    value: 'Members',
                                    child: Text('الشوارع بالمنطقة'),
                                  ),
                                ),
                          onSaved: (value) async {
                            await settings.put('AreaSecondLine', value);
                          },
                          decoration: InputDecoration(
                            labelText: 'السطر الثاني للمنطقة:',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: DropdownButtonFormField(
                          onChanged: (_) {},
                          value: settings.get('StreetSecondLine'),
                          items: Street.getHumanReadableMap2()
                              .entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList()
                                ..removeWhere(
                                    (element) => element.value == 'Color')
                                ..add(
                                  DropdownMenuItem(
                                    value: 'Members',
                                    child: Text('العائلات بالشارع'),
                                  ),
                                ),
                          onSaved: (value) async {
                            await settings.put('StreetSecondLine', value);
                          },
                          decoration: InputDecoration(
                            labelText: 'السطر الثاني للشارع:',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: DropdownButtonFormField(
                          onChanged: (_) {},
                          value: settings.get('FamilySecondLine'),
                          items: Family.getHumanReadableMap2()
                              .entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList()
                                ..removeWhere(
                                    (element) => element.value == 'Color')
                                ..add(
                                  DropdownMenuItem(
                                    value: 'Members',
                                    child: Text('الأشخاص بالعائلة'),
                                  ),
                                ),
                          onSaved: (value) async {
                            await settings.put('FamilySecondLine', value);
                          },
                          decoration: InputDecoration(
                            labelText: 'السطر الثاني للعائلة:',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: DropdownButtonFormField(
                          onChanged: (_) {},
                          value: settings.get('PersonSecondLine'),
                          items: Person.getHumanReadableMap2()
                              .entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList()
                                ..removeWhere(
                                    (element) => element.value == 'Color'),
                          onSaved: (value) async {
                            await settings.put('PersonSecondLine', value);
                          },
                          decoration: InputDecoration(
                            labelText: 'السطر الثاني للشخص:',
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Text('إظهار الحالة بجانب كل شخص'),
                          FormField(
                            builder: (context) => Switch(
                              value: state ?? false,
                              onChanged: (v) => setState(() {
                                state = v;
                              }),
                            ),
                            onSaved: (_) =>
                                settings.put('ShowPersonState', state),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Selector<User, Map<String, bool>>(
                    selector: (_, user) => user.getNotificationsPermissions(),
                    builder: (context, permission, _) {
                      if (permission.containsValue(true) && !kIsWeb) {
                        return ExpandablePanel(
                          theme: ExpandableThemeData(
                              useInkWell: true,
                              iconColor: Theme.of(context).iconTheme.color,
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
                      iconColor: Theme.of(context).iconTheme.color,
                      bodyAlignment: ExpandablePanelBodyAlignment.right),
                  header: Text(
                    'أخرى',
                    style: TextStyle(fontSize: 24),
                  ),
                  collapsed: Text('إعدادات أخرى'),
                  expanded: Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'الحجم الأقصى للبيانات المؤقتة (MB):',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      initialValue: ((settings.get('cacheSize',
                                      defaultValue: 300 * 1024 * 1024) /
                                  1024) /
                              1024)
                          .truncate()
                          .toString(),
                      onSaved: (c) async {
                        await settings.put(
                            'cacheSize', int.parse(c!) * 1024 * 1024);
                      },
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'هذا الحقل مطلوب';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          formKey.currentState!.save();
          scaffoldMessenger.currentState!.showSnackBar(
            SnackBar(
              content: Text('تم الحفظ'),
            ),
          );
        },
        tooltip: 'حفظ',
        child: Icon(Icons.save),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    color = Theme.of(context).primaryColor;
    darkTheme = Hive.box('Settings').get('DarkTheme');
    greatFeastTheme =
        Hive.box('Settings').get('GreatFeastTheme', defaultValue: true);
    state = Hive.box('Settings').get('ShowPersonState', defaultValue: false);
  }

  Widget _getNotificationsContent(Map<String, bool> notifications) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (notifications['birthdayNotify'] ?? false)
          Row(
            children: <Widget>[
              Text('التذكير بأعياد الميلاد كل يوم الساعة: '),
              Expanded(
                child: DateTimeField(
                  format: DateFormat(
                      'h:m' +
                          (MediaQuery.of(context).alwaysUse24HourFormat
                              ? ''
                              : ' a'),
                      'ar-EG'),
                  initialValue: DateTime(
                    2021,
                    1,
                    1,
                    notificationsSettings.get('BirthDayTime',
                        defaultValue: <String, int>{
                          'Hours': 11
                        })!.cast<String, int>()['Hours']!,
                    notificationsSettings.get('BirthDayTime', defaultValue: {
                      'Minutes': 0
                    })!.cast<String, int>()['Minutes']!,
                  ),
                  resetIcon: null,
                  onShowPicker: (context, initialValue) async {
                    var selected = await showTimePicker(
                      initialTime: TimeOfDay.fromDateTime(initialValue!),
                      context: context,
                    );
                    return DateTime(
                        2020,
                        1,
                        1,
                        selected?.hour ?? initialValue.hour,
                        selected?.minute ?? initialValue.minute);
                  },
                  onSaved: (value) async {
                    var current = notificationsSettings.get('BirthDayTime',
                        defaultValue: {
                          'Hours': 11,
                          'Minutes': 0
                        })!.cast<String, int>();
                    if (current['Hours'] == value?.hour &&
                        current['Minutes'] == value?.minute) return;
                    await notificationsSettings.put(
                      'BirthDayTime',
                      <String, int>{
                        'Hours': value!.hour,
                        'Minutes': value.minute
                      },
                    );
                    await AndroidAlarmManager.periodic(Duration(days: 1),
                        'BirthDay'.hashCode, showBirthDayNotification,
                        exact: true,
                        startAt: DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            value.hour,
                            value.minute),
                        wakeup: true,
                        rescheduleOnReboot: true);
                  },
                ),
              ),
            ],
          ),
        if (notifications['confessionsNotify'] ?? false)
          Divider(
            thickness: 2,
            height: 30,
          ),
        if (notifications['confessionsNotify'] ?? false)
          NotificationSetting(
            label: 'ارسال انذار الاعتراف كل ',
            hiveKey: 'ConfessionTime',
            alarmId: 'Confessions'.hashCode,
            notificationCallback: showConfessionNotification,
          ),
        if (notifications['tanawolNotify'] ?? false)
          Divider(
            thickness: 2,
            height: 30,
          ),
        if (notifications['tanawolNotify'] ?? false)
          NotificationSetting(
            label: 'ارسال انذار التناول كل ',
            hiveKey: 'TtanawolTime',
            alarmId: 'Tanawol'.hashCode,
            notificationCallback: showTanawolNotification,
          ),
      ],
    );
  }
}
