import 'package:churchdata/services/notifications_service.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata_core/churchdata_core.dart' as core;
import 'package:churchdata_core/churchdata_core.dart' hide Notification;
import 'package:flutter/material.dart' hide Notification;
import 'package:get_it/get_it.dart';

import 'user.dart';

class NotificationWidget extends StatelessWidget {
  final _Notification notification;
  final void Function()? longPress;

  NotificationWidget(
    core.Notification notification, {
    super.key,
    this.longPress,
  }) : notification = _Notification.fromCoreNotification(notification);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Viewable?>(
      future: notification.attachmentLink != null
          ? GetIt.I<DatabaseRepository>().getObjectFromLink(
              Uri.parse(notification.attachmentLink!),
            )
          : null,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: ErrorWidget(snapshot.error!));
        }
        return Card(
          child: ListTile(
            leading: () {
              if (snapshot.hasData) {
                if (snapshot.data is User) {
                  return (snapshot.data! as User).getPhoto();
                } else if (snapshot.data is MessageIcon) {
                  return snapshot.data! as MessageIcon;
                } else if (snapshot.data is PhotoObjectBase) {
                  return PhotoObjectWidget(
                    snapshot.data! as PhotoObjectBase,
                    heroTag: snapshot.data,
                  );
                }
              } else if (notification.additionalData?['Query'] != null) {
                final query =
                    (notification.additionalData!['Query'] as Map).cast();

                if (query['birthDate'].toString() == 'true') {
                  return Container(
                    width:
                        Theme.of(context).listTileTheme.minLeadingWidth ?? 40,
                    alignment: Alignment.center,
                    child: const Icon(Icons.cake),
                  );
                } else {
                  return Container(
                    width:
                        Theme.of(context).listTileTheme.minLeadingWidth ?? 40,
                    alignment: Alignment.center,
                    child: const Icon(Icons.warning),
                  );
                }
              }

              return Container(
                width: Theme.of(context).listTileTheme.minLeadingWidth ?? 40,
                alignment: Alignment.center,
                child: const Icon(Icons.notifications),
              );
            }(),
            title: Text(notification.title),
            subtitle: Text(
              notification.body,
              overflow: notification.body.contains('تم تغيير موقع')
                  ? null
                  : TextOverflow.ellipsis,
              maxLines: notification.body.contains('تم تغيير موقع') ? null : 1,
            ),
            onTap: () => GetIt.I<CDNotificationsService>()
                .showNotificationContents(context, notification),
            onLongPress: longPress,
          ),
        );
      },
    );
  }
}

class _Notification extends core.Notification {
  _Notification.fromCoreNotification(core.Notification notification)
      : super(
          type: notification.type,
          title: notification.title,
          body: notification.body,
          sentTime: notification.sentTime,
          additionalData: notification.additionalData,
          attachmentLink: notification.additionalData?['attachement'] ??
              notification.attachmentLink,
          id: notification.id,
          senderUID: notification.senderUID,
        );
}
