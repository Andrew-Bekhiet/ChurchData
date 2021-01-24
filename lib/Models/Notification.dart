import 'package:churchdata/Models/super_classes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../utils/Helpers.dart';
import 'User.dart';

class Notification extends StatelessWidget {
  final String type;
  final String title;
  final String content;
  final String attachement;
  final String from;
  final int time;
  final void Function() longPress;

  const Notification(this.type, this.title, this.content, this.attachement,
      this.time, this.from,
      [this.longPress]);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getLinkObject(
        Uri.parse(attachement),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: ErrorWidget(snapshot.error));
        return Card(
          child: ListTile(
            leading: snapshot.hasData
                ? snapshot.data is User
                    ? snapshot.data.getPhoto()
                    : snapshot.data is MessageIcon
                        ? snapshot.data
                        : (snapshot.data as PhotoObject)
                            .photoWithHero(snapshot.data)
                : CircularProgressIndicator(),
            title: Text(title),
            subtitle: Text(
              content,
              overflow: content.contains('تم تغيير موقع')
                  ? null
                  : TextOverflow.ellipsis,
              maxLines: content.contains('تم تغيير موقع') ? null : 1,
            ),
            onTap: () => (from == null
                ? processLink(Uri.parse(attachement), context)
                : showMessage(context, this)),
            onLongPress: longPress,
          ),
        );
      },
    );
  }

  static Notification fromMessage(Map<String, dynamic> message,
          [void Function() longPress]) =>
      Notification(
          message['type'],
          message['title'],
          message['content'],
          message['attachement'],
          int.parse(message['time']),
          message['sentFrom'],
          longPress);
}
