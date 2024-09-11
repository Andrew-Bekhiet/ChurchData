import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata_core/churchdata_core.dart'
    show
        DateTimeX,
        NotificationSetting,
        NotificationSettingWidget,
        TappableFormField,
        ThemingService;
import 'package:expandable/expandable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../utils/globals.dart';

enum DateType {
  month,
  week,
  day,
}

class Settings extends StatefulWidget {
  const Settings({super.key});
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

  var notificationsSettings =
      Hive.box<NotificationSetting>('NotificationsSettings');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاعدادات'),
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
                  header: const Text(
                    'المظهر',
                    style: TextStyle(fontSize: 24),
                  ),
                  collapsed: const Text('المظهر العام للبرنامج'),
                  expanded: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          ChoiceChip(
                            label: const Text('المظهر الداكن'),
                            selected: darkTheme ?? false,
                            onSelected: (v) => setState(() => darkTheme = true),
                          ),
                          ChoiceChip(
                            label: const Text('المظهر الفاتح'),
                            selected: darkTheme == false,
                            onSelected: (v) =>
                                setState(() => darkTheme = false),
                          ),
                          ChoiceChip(
                            label: const Text('حسب النظام'),
                            selected: darkTheme == null,
                            onSelected: (v) => setState(() => darkTheme = null),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: greatFeastTheme,
                        onChanged: (v) => setState(() => greatFeastTheme = v),
                        title: const Text(
                          'تغيير لون البرنامج حسب أسبوع الآلام وفترة الخمسين',
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Hive.box('Settings')
                              .put('DarkTheme', darkTheme);
                          await Hive.box('Settings')
                              .put('GreatFeastTheme', greatFeastTheme);

                          GetIt.I<ThemingService>().switchTheme(
                            darkTheme ??
                                PlatformDispatcher
                                        .instance.platformBrightness ==
                                    Brightness.dark,
                          );
                        },
                        icon: const Icon(Icons.done),
                        label: const Text('تغيير'),
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
                  header: const Text(
                    'بيانات إضافية',
                    style: TextStyle(fontSize: 24),
                  ),
                  collapsed: const Text(
                    'الكنائس، الأباء الكهنة، الوظائف، السنوات الدراسية، أنواع الخدمات، أنواع الأشخاص',
                    overflow: TextOverflow.ellipsis,
                  ),
                  expanded: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/Churches'),
                        child: const Text('الكنائس'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/Fathers'),
                        child: const Text('الأباء الكهنة'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            navigator.currentState!.pushNamed('Settings/Jobs'),
                        child: const Text('الوظائف'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/StudyYears'),
                        child: const Text('السنوات الدراسية'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/Colleges'),
                        child: const Text('الكليات'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/ServingTypes'),
                        child: const Text('أنواع الخدمات'),
                      ),
                      ElevatedButton(
                        onPressed: () => navigator.currentState!
                            .pushNamed('Settings/PersonTypes'),
                        child: const Text('أنواع الأشخاص'),
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
                  header: const Text(
                    'مظهر البيانات',
                    style: TextStyle(fontSize: 24),
                  ),
                  collapsed: const Text(
                    'السطر الثاني للمنطقة، السطر الثاني للشارع، السطر الثاني للعائلة، السطر الثاني للشخص',
                    overflow: TextOverflow.ellipsis,
                  ),
                  expanded: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                            ..removeWhere((element) => element.value == 'Color')
                            ..add(
                              const DropdownMenuItem(
                                value: 'Members',
                                child: Text('الشوارع بالمنطقة'),
                              ),
                            ),
                          onSaved: (value) async {
                            await settings.put('AreaSecondLine', value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'السطر الثاني للمنطقة:',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                            ..removeWhere((element) => element.value == 'Color')
                            ..add(
                              const DropdownMenuItem(
                                value: 'Members',
                                child: Text('العائلات بالشارع'),
                              ),
                            ),
                          onSaved: (value) async {
                            await settings.put('StreetSecondLine', value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'السطر الثاني للشارع:',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                            ..removeWhere((element) => element.value == 'Color')
                            ..add(
                              const DropdownMenuItem(
                                value: 'Members',
                                child: Text('الأشخاص بالعائلة'),
                              ),
                            ),
                          onSaved: (value) async {
                            await settings.put('FamilySecondLine', value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'السطر الثاني للعائلة:',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                              (element) => element.value == 'Color',
                            ),
                          onSaved: (value) async {
                            await settings.put('PersonSecondLine', value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'السطر الثاني للشخص:',
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          const Text('إظهار الحالة بجانب كل شخص'),
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
                          bodyAlignment: ExpandablePanelBodyAlignment.right,
                        ),
                        header: const Text(
                          'الاشعارات',
                          style: TextStyle(fontSize: 24),
                        ),
                        collapsed: const Text('اعدادات الاشعارات'),
                        expanded: _getNotificationsContent(permission),
                      );
                    }
                    return Container();
                  },
                ),
                ExpandablePanel(
                  theme: ExpandableThemeData(
                    useInkWell: true,
                    iconColor: Theme.of(context).iconTheme.color,
                    bodyAlignment: ExpandablePanelBodyAlignment.right,
                  ),
                  header: const Text(
                    'أخرى',
                    style: TextStyle(fontSize: 24),
                  ),
                  collapsed: const Text('إعدادات أخرى'),
                  expanded: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'الحجم الأقصى للبيانات المؤقتة (MB):',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      initialValue: ((settings.get(
                                    'cacheSize',
                                    defaultValue: 300 * 1024 * 1024,
                                  ) /
                                  1024) /
                              1024)
                          .truncate()
                          .toString(),
                      onSaved: (c) async {
                        await settings.put(
                          'cacheSize',
                          int.parse(c!) * 1024 * 1024,
                        );
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
            const SnackBar(
              content: Text('تم الحفظ'),
            ),
          );
        },
        tooltip: 'حفظ',
        child: const Icon(Icons.save),
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
        if (notifications['birthdayNotify']!)
          Row(
            children: <Widget>[
              const Text('التذكير بأعياد الميلاد كل يوم الساعة: '),
              Expanded(
                child: TappableFormField<DateTime>(
                  initialValue: DateTime(
                    2021,
                    1,
                    1,
                    notificationsSettings
                        .get(
                          'BirthDayTime',
                          defaultValue: const NotificationSetting(11, 0, 1),
                        )!
                        .hours,
                    notificationsSettings
                        .get(
                          'BirthDayTime',
                          defaultValue: const NotificationSetting(11, 0, 1),
                        )!
                        .minutes,
                  ),
                  onTap: (state) async {
                    final selected = await showTimePicker(
                      initialTime: TimeOfDay.fromDateTime(state.value!),
                      context: context,
                    );
                    state.didChange(
                      DateTime(
                        2020,
                        1,
                        1,
                        selected?.hour ?? state.value!.hour,
                        selected?.minute ?? state.value!.minute,
                      ),
                    );
                  },
                  builder: (context, state) => state.value != null
                      ? Text(
                          DateFormat(
                            'h:m' +
                                (MediaQuery.of(context).alwaysUse24HourFormat
                                    ? ''
                                    : ' a'),
                            'ar-EG',
                          ).format(state.value!),
                        )
                      : const Text(''),
                  onSaved: (value) async {
                    final current = notificationsSettings.get(
                      'BirthDayTime',
                      defaultValue: const NotificationSetting(11, 0, 1),
                    )!;

                    if (current.hours == value!.hour &&
                        current.minutes == value.minute) return;
                    await notificationsSettings.put(
                      'BirthDayTime',
                      NotificationSetting(value.hour, value.minute, 1),
                    );
                    await AndroidAlarmManager.periodic(
                      const Duration(days: 1),
                      'BirthDay'.hashCode,
                      showBirthDayNotification,
                      exact: true,
                      allowWhileIdle: true,
                      startAt: DateTime.now().replaceTime(value),
                      wakeup: true,
                      rescheduleOnReboot: true,
                    );
                  },
                ),
              ),
            ],
          ),
        if (notifications['confessionsNotify']!) const SizedBox(height: 20),
        if (notifications['confessionsNotify']!)
          NotificationSettingWidget(
            label: 'ارسال انذار الاعتراف كل ',
            hiveKey: 'ConfessionTime',
            alarmId: 'Confessions'.hashCode,
            notificationCallback: showConfessionNotification,
          ),
        if (notifications['tanawolNotify']!) const SizedBox(height: 20),
        if (notifications['tanawolNotify']!)
          NotificationSettingWidget(
            label: 'ارسال انذار التناول كل ',
            hiveKey: 'TanawolTime',
            alarmId: 'Tanawol'.hashCode,
            notificationCallback: showTanawolNotification,
          ),
      ],
    );
  }
}
