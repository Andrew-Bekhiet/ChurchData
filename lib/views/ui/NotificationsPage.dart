import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../Models/Notification.dart' as n;

class NotificationsPage extends StatefulWidget {
  NotificationsPage({Key key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات'),
      ),
      body: ListView.builder(
        itemCount: Hive.box<Map<dynamic, dynamic>>('Notifications').length,
        itemBuilder: (context, i) {
          return n.Notification.fromMessage(
            Hive.box<Map<dynamic, dynamic>>('Notifications')
                .getAt(i)
                .cast<String, dynamic>(),
            () async {
              if (await showDialog(
                    context: context,
                    builder: (context) => DataDialog(
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('نعم'),
                        )
                      ],
                      content: Text('هل تريد حذف هذا الاشعار؟'),
                    ),
                  ) ==
                  true) {
                await Hive.box<Map<dynamic, dynamic>>('Notifications')
                    .deleteAt(i);
                setState(() {});
              }
            },
          );
        },
      ),
    );
  }
}
