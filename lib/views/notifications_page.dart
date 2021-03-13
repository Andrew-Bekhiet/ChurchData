import 'package:churchdata/models/data_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/notification.dart' as n;

class NotificationsPage extends StatefulWidget {
  NotificationsPage({Key key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void dispose() {
    Hive.box<Map>('Notifications').close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات'),
      ),
      body: FutureBuilder(
          future: Hive.openBox<Map>('Notifications'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return Center(child: const CircularProgressIndicator());
            return ListView.builder(
              itemCount:
                  Hive.box<Map<dynamic, dynamic>>('Notifications').length,
              itemBuilder: (context, i) {
                return n.Notification.fromMessage(
                  Hive.box<Map<dynamic, dynamic>>('Notifications')
                      .getAt(Hive.box<Map<dynamic, dynamic>>('Notifications')
                              .length -
                          i -
                          1)
                      .cast<String, dynamic>(),
                  () async {
                    if (await showDialog(
                          context: context,
                          builder: (context) => DataDialog(
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('نعم'),
                              )
                            ],
                            content: Text('هل تريد حذف هذا الاشعار؟'),
                          ),
                        ) ==
                        true) {
                      await Hive.box<Map<dynamic, dynamic>>('Notifications')
                          .deleteAt(
                              Hive.box<Map<dynamic, dynamic>>('Notifications')
                                      .length -
                                  i -
                                  1);
                      setState(() {});
                    }
                  },
                );
              },
            );
          }),
    );
  }
}
