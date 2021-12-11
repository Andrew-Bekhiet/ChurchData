import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/typedefs.dart';
import 'package:flutter/material.dart';

import '../utils/helpers.dart';
import 'user.dart';

class Notification extends StatelessWidget {
  final String? type;
  final String? title;
  final String? content;
  final String? attachement;
  final String? from;
  final int? time;
  final void Function()? longPress;

  const Notification(this.type, this.title, this.content, this.attachement,
      this.time, this.from,
      {Key? key, this.longPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getLinkObject(
        Uri.parse(attachement!),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: ErrorWidget(snapshot.error!));

        return Card(
          child: ListTile(
            leading: snapshot.hasData
                ? snapshot.data is User
                    ? (snapshot.data! as User).getPhoto()
                    : snapshot.data is MessageIcon
                        ? snapshot.data! as MessageIcon
                        : DataObjectPhoto(
                            snapshot.data! as PhotoObject,
                            heroTag: snapshot.data,
                          )
                : const CircularProgressIndicator(),
            title: Text(title ?? ''),
            subtitle: Text(
              content ?? '',
              overflow: (content ?? '').contains('تم تغيير موقع')
                  ? null
                  : TextOverflow.ellipsis,
              maxLines: (content ?? '').contains('تم تغيير موقع') ? null : 1,
            ),
            onTap: () => from == null
                ? processLink(Uri.parse(attachement!))
                : showMessage(context, this),
            onLongPress: longPress,
          ),
        );
      },
    );
  }

  static Notification fromMessage(Json message, [void Function()? longPress]) =>
      Notification(
          message['type'],
          message['title'],
          message['content'],
          message['attachement'],
          int.parse(message['time']),
          message['sentFrom'],
          longPress: longPress);
}
