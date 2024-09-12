import 'package:churchdata/utils/globals.dart';
import 'package:churchdata_core/churchdata_core.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/notification_widget.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void dispose() {
    Hive.box<Notification>('Notifications').close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
      ),
      body: FutureBuilder(
        future: Hive.openBox<Notification>('Notifications'),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: Hive.box<Notification>('Notifications').length,
            itemBuilder: (context, i) {
              return NotificationWidget(
                Hive.box<Notification>('Notifications').getAt(
                  Hive.box<Notification>('Notifications').length - i - 1,
                )!,
                longPress: () async {
                  if (await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          actions: <Widget>[
                            TextButton(
                              onPressed: () =>
                                  navigator.currentState!.pop(true),
                              child: const Text('نعم'),
                            ),
                          ],
                          content: const Text('هل تريد حذف هذا الاشعار؟'),
                        ),
                      ) ==
                      true) {
                    await Hive.box<Notification>('Notifications').deleteAt(
                      Hive.box<Notification>('Notifications').length - i - 1,
                    );

                    setState(() {});
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
