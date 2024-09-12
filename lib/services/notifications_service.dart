import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata/main.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata/views/search_query.dart';
import 'package:churchdata_core/churchdata_core.dart' hide Timestamp;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class CDNotificationsService extends NotificationsService {
  static CDNotificationsService get instance =>
      GetIt.I<CDNotificationsService>();
  static CDNotificationsService get I => GetIt.I<CDNotificationsService>();

  @override
  @protected
  Future<void> initPlugins() async {
    if (!kIsWeb) await AndroidAlarmManager.initialize();

    await GetIt.I<FlutterLocalNotificationsPlugin>().initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('warning'),
      ),
      onDidReceiveBackgroundNotificationResponse: onNotificationClicked,
      onDidReceiveNotificationResponse: onNotificationClicked,
    );

    GetIt.I.signalReady(this);
  }

  @override
  Future<void> listenToUserStream() async {
    await User.instance.initialized;

    unawaited(
      User.instance.stream.first.then((_) => maybeSetupUserNotifications(null)),
    );
  }

  @override
  Future<void> maybeSetupUserNotifications(UID? uid) async {
    final user = User.instance;

    if (user.getNotificationsPermissions().values.toList().any((e) => e)) {
      final notificationsSettings =
          Hive.box<NotificationSetting>('NotificationsSettings');

      if (user.confessionsNotify) {
        if (notificationsSettings.get('ConfessionTime') == null) {
          await notificationsSettings.put(
            'ConfessionTime',
            const NotificationSetting(11, 0, 7),
          );
        }

        await schedulePeriodic(
          const Duration(days: 7),
          'Confessions'.hashCode,
          showConfessionNotification,
          exact: true,
          startAt: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            11,
          ),
          rescheduleOnReboot: true,
        );
      }

      if (user.tanawolNotify) {
        if (notificationsSettings.get('TanawolTime') == null) {
          await notificationsSettings.put(
            'TanawolTime',
            const NotificationSetting(11, 0, 7),
          );
        }

        await schedulePeriodic(
          const Duration(days: 7),
          'Tanawol'.hashCode,
          showTanawolNotification,
          exact: true,
          startAt: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            11,
          ),
          rescheduleOnReboot: true,
        );
      }

      if (user.birthdayNotify) {
        if (notificationsSettings.get('BirthDayTime') == null) {
          await notificationsSettings.put(
            'BirthDayTime',
            const NotificationSetting(11, 0, 1),
          );
        }

        await schedulePeriodic(
          const Duration(days: 1),
          'BirthDay'.hashCode,
          showBirthDayNotification,
          exact: true,
          startAt: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            11,
          ),
          wakeup: true,
          rescheduleOnReboot: true,
        );
      }
    }

    await registerFCMToken();
  }

  @override
  Future<bool> registerFCMToken({String? cachedToken}) async {
    if (GetIt.I<AuthRepository>().currentUser == null ||
        !await GetIt.I<FirebaseMessaging>().isSupported() ||
        WidgetsBinding.instance.rootElement == null) return false;

    final status = await Permission.notification.request();

    if (!status.isGranted) return false;

    return super.registerFCMToken(cachedToken: cachedToken);
  }

  @override
  Future<bool> schedulePeriodic(
    Duration duration,
    int id,
    Function callback, {
    DateTime? startAt,
    bool allowWhileIdle = false,
    bool exact = false,
    bool wakeup = false,
    bool rescheduleOnReboot = false,
  }) async {
    if (kIsWeb || WidgetsBinding.instance.rootElement == null) return false;

    await Permission.notification.request();

    return super.schedulePeriodic(
      duration,
      id,
      callback,
      startAt: startAt,
      allowWhileIdle: allowWhileIdle,
      exact: exact
          ? (await DeviceInfoPlugin().androidInfo).version.sdkInt < 31 ||
              (await Permission.scheduleExactAlarm.request()).isGranted
          : false,
      wakeup: wakeup,
      rescheduleOnReboot: rescheduleOnReboot,
    );
  }

  @override
  void listenToFirebaseMessaging() {
    FirebaseMessaging.onBackgroundMessage(
      NotificationsService.onBackgroundMessageReceived,
    );
    FirebaseMessaging.onMessage.listen(onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      showNotificationContents(
        mainScfld.currentContext!,
        Notification.fromRemoteMessage(m),
      );
    });
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationClicked(
    NotificationResponse response,
  ) async {
    final payload = response.payload;

    if (WidgetsBinding.instance.rootElement != null &&
        GetIt.I.isRegistered<CDNotificationsService>() &&
        payload != null &&
        int.tryParse(payload) != null &&
        GetIt.I<CacheRepository>()
                .box<Notification>('Notifications')
                .getAt(int.parse(payload)) !=
            null) {
      await GetIt.I<CDNotificationsService>().showNotificationContents(
        mainScfld.currentContext!,
        GetIt.I<CacheRepository>()
            .box<Notification>('Notifications')
            .getAt(int.parse(payload))!,
      );
    }
  }

  @override
  Future<void> showNotificationContents(
    BuildContext context,
    Notification notification, {
    List<Widget>? actions,
  }) async {
    if (notification.type == NotificationType.LocalNotification &&
        notification.additionalData?['Query'] != null) {
      await navigator.currentState!.push(
        MaterialPageRoute(
          builder: (c) => SearchQuery(
            query: (notification.additionalData!['Query'] as Map).cast(),
          ),
        ),
      );
      return;
    }

    final dynamic attachment = notification.attachmentLink != null
        ? await getLinkObject(Uri.parse(notification.attachmentLink!))
        : null;
    final String scndLine = await attachment?.getSecondLine() ?? '';

    final user = notification.senderUID != ''
        ? await firestore.doc('Users/${notification.senderUID}').get()
        : null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: actions,
        title: Text(notification.title),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 85 / 100,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification.body,
                  style: const TextStyle(fontSize: 18),
                ),
                if (attachment != null)
                  Card(
                    color: attachment.color != Colors.transparent
                        ? attachment.color
                        : null,
                    child: ListTile(
                      title: Text(attachment.name),
                      subtitle: Text(scndLine),
                      leading: (attachment is PhotoObject
                          ? attachment.photo(
                              cropToCircle:
                                  attachment is Person || attachment is User,
                            )
                          : null),
                      onTap: () {
                        if (attachment is Area) {
                          areaTap(attachment);
                        } else if (attachment is Street) {
                          streetTap(attachment);
                        } else if (attachment is Family) {
                          familyTap(attachment);
                        } else if (attachment is Person) {
                          personTap(attachment);
                        } else if (attachment is User) {
                          userTap(attachment);
                        }
                      },
                    ),
                  )
                else if (notification.attachmentLink != null)
                  CachedNetworkImage(
                    useOldImageOnUrlChange: true,
                    imageUrl: notification.attachmentLink!,
                  ),
                if (user != null)
                  Text(
                    'من: ' + (user.data()?['Name'] ?? 'مسؤلو البرنامج'),
                  ),
                Text(
                  DateFormat('yyyy/M/d h:m a', 'ar-EG').format(
                    notification.sentTime,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @pragma('vm:entry-point')
  Future<void> onForegroundMessage(RemoteMessage message) async {
    await NotificationsService.storeNotification(message);

    scaffoldMessenger.currentState!.showSnackBar(
      SnackBar(
        content: Text(message.notification!.body!),
        action: SnackBarAction(
          label: 'فتح الاشعارات',
          onPressed: () => navigator.currentState!.pushNamed('Notifications'),
        ),
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> showBirthDayNotification() async {
    await initConfigs();

    if (firebaseAuth.currentUser == null) return;
    await User.instance.initialized;
    final user = User.instance;

    final source = GetOptions(
      source: (await Connectivity().checkConnectivity()).isNotConnected
          ? Source.cache
          : Source.serverAndCache,
    );
    JsonQuery docs;
    if (user.superAccess) {
      docs = await firestore
          .collection('Persons')
          .where(
            'BirthDay',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(1970, DateTime.now().month, DateTime.now().day),
            ),
          )
          .where(
            'BirthDay',
            isLessThan: Timestamp.fromDate(
              DateTime(1970, DateTime.now().month, DateTime.now().day + 1),
            ),
          )
          .limit(20)
          .get(source);
    } else {
      docs = await firestore
          .collection('Persons')
          .where(
            'AreaId',
            whereIn: (await firestore
                    .collection('Areas')
                    .where('Allowed', arrayContains: User.instance.uid)
                    .get(source))
                .docs
                .map((e) => e.reference)
                .toList(),
          )
          .where(
            'BirthDay',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(1970, DateTime.now().month, DateTime.now().day),
            ),
          )
          .where(
            'BirthDay',
            isLessThan: Timestamp.fromDate(
              DateTime(1970, DateTime.now().month, DateTime.now().day + 1),
            ),
          )
          .limit(20)
          .get(source);
    }

    if (docs.docs.isEmpty && kReleaseMode) return;

    final now = DateTime.now();

    final body = docs.docs.map((e) => e.data()['Name']).join(', ');
    final notification = Notification(
      body: body,
      title: 'أعياد الميلاد',
      sentTime: now,
      type: NotificationType.LocalNotification,
      additionalData: {
        'Query': {
          'parentIndex': '3',
          'childIndex': '2',
          'operatorIndex': '0',
          'queryText': '',
          'queryValue': 'T' +
              (now.millisecondsSinceEpoch -
                      (now.millisecondsSinceEpoch %
                          Duration.millisecondsPerDay))
                  .toString(),
          'birthDate': 'true',
          'descending': 'false',
          'orderBy': 'BirthDay',
        },
      },
    );

    final i = await GetIt.I<CacheRepository>()
        .box<Notification>('Notifications')
        .add(notification);

    await FlutterLocalNotificationsPlugin().show(
      2,
      'أعياد الميلاد',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'Birthday',
          'إشعارات أعياد الميلاد',
          channelDescription: 'إشعارات أعياد الميلاد',
          icon: 'birthday',
          autoCancel: false,
          visibility: NotificationVisibility.secret,
          showWhen: false,
        ),
      ),
      payload: i.toString(),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> showConfessionNotification() async {
    await initConfigs();

    if (firebaseAuth.currentUser == null) return;

    await User.instance.initialized;
    final user = User.instance;

    final source = GetOptions(
      source: (await Connectivity().checkConnectivity()).isNotConnected
          ? Source.cache
          : Source.serverAndCache,
    );
    JsonQuery docs;
    if (user.superAccess) {
      docs = await firestore
          .collection('Persons')
          .where('LastConfession', isLessThan: Timestamp.now())
          .limit(20)
          .get(source);
    } else {
      docs = await firestore
          .collection('Persons')
          .where(
            'AreaId',
            whereIn: (await firestore
                    .collection('Areas')
                    .where('Allowed', arrayContains: User.instance.uid)
                    .get(source))
                .docs
                .map((e) => e.reference)
                .toList(),
          )
          .where('LastConfession', isLessThan: Timestamp.now())
          .limit(20)
          .get(source);
    }
    if (docs.docs.isEmpty && kReleaseMode) return;

    final now = DateTime.now();

    final body = docs.docs.map((e) => e.data()['Name']).join(', ');
    final notification = Notification(
      body: body,
      title: 'انذار الاعتراف',
      sentTime: DateTime.now(),
      type: NotificationType.LocalNotification,
      additionalData: {
        'Query': {
          'parentIndex': '3',
          'childIndex': '15',
          'operatorIndex': '3',
          'queryText': '',
          'queryValue': 'T' +
              ((now.millisecondsSinceEpoch -
                          (now.millisecondsSinceEpoch %
                              Duration.millisecondsPerDay)) -
                      (Duration.millisecondsPerDay * 30))
                  .toString(),
          'birthDate': 'false',
          'descending': 'false',
          'orderBy': 'LastConfession',
        },
      },
    );

    final i = await GetIt.I<CacheRepository>()
        .box<Notification>('Notifications')
        .add(notification);

    await FlutterLocalNotificationsPlugin().show(
      0,
      'انذار الاعتراف',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'Confessions',
          'إشعارات الاعتراف',
          channelDescription: 'إشعارات الاعتراف',
          icon: 'warning',
          autoCancel: false,
          visibility: NotificationVisibility.secret,
          showWhen: false,
        ),
      ),
      payload: i.toString(),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> showTanawolNotification() async {
    await initConfigs();

    if (firebaseAuth.currentUser == null) return;

    await User.instance.initialized;
    final user = User.instance;

    final source = GetOptions(
      source: (await Connectivity().checkConnectivity()).isNotConnected
          ? Source.cache
          : Source.serverAndCache,
    );
    JsonQuery docs;
    if (user.superAccess) {
      docs = await firestore
          .collection('Persons')
          .where('LastTanawol', isLessThan: Timestamp.now())
          .limit(20)
          .get(source);
    } else {
      docs = await firestore
          .collection('Persons')
          .where(
            'AreaId',
            whereIn: (await firestore
                    .collection('Areas')
                    .where('Allowed', arrayContains: User.instance.uid)
                    .get(source))
                .docs
                .map((e) => e.reference)
                .toList(),
          )
          .where('LastTanawol', isLessThan: Timestamp.now())
          .limit(20)
          .get(source);
    }
    if (docs.docs.isEmpty && kReleaseMode) return;

    final now = DateTime.now();

    final body = docs.docs.map((e) => e.data()['Name']).join(', ');
    final notification = Notification(
      body: body,
      title: 'انذار التناول',
      sentTime: DateTime.now(),
      type: NotificationType.LocalNotification,
      additionalData: {
        'Query': {
          'parentIndex': '3',
          'childIndex': '14',
          'operatorIndex': '3',
          'queryText': '',
          'queryValue': 'T' +
              ((now.millisecondsSinceEpoch -
                          (now.millisecondsSinceEpoch %
                              Duration.millisecondsPerDay)) -
                      (Duration.millisecondsPerDay * 30))
                  .toString(),
          'birthDate': 'false',
          'descending': 'false',
          'orderBy': 'BirthDay',
        },
      },
    );

    final i = await GetIt.I<CacheRepository>()
        .box<Notification>('Notifications')
        .add(notification);

    await FlutterLocalNotificationsPlugin().show(
      1,
      'انذار التناول',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'Tanawol',
          'إشعارات التناول',
          channelDescription: 'إشعارات التناول',
          icon: 'warning',
          autoCancel: false,
          visibility: NotificationVisibility.secret,
          showWhen: false,
        ),
      ),
      payload: i.toString(),
    );
  }
}
