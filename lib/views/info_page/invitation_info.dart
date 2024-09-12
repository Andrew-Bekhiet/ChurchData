import 'package:churchdata/models/invitation.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata_core/churchdata_core.dart'
    show CopiablePropertyWidget;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tinycolor2/tinycolor2.dart';

class InvitationInfo extends StatelessWidget {
  final Invitation invitation;
  const InvitationInfo({required this.invitation, super.key});

  void addTap(BuildContext context) {
    navigator.currentState!
        .pushNamed('Data/EditInvitation', arguments: invitation.ref);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Invitation?>(
      initialData: invitation,
      stream: invitation.ref.snapshots().map(Invitation.fromDoc),
      builder: (context, data) {
        if (!data.hasData)
          return const Scaffold(
            body: Center(
              child: Text('تم حذف الدعوة'),
            ),
          );

        final Invitation invitation = data.data!;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: invitation.color != Colors.transparent
                    ? (Theme.of(context).brightness == Brightness.light
                        ? TinyColor.fromColor(invitation.color).lighten().color
                        : TinyColor.fromColor(invitation.color).darken().color)
                    : null,
                actions: <Widget>[
                  Selector<User, bool>(
                    selector: (_, user) => user.write,
                    builder: (c, permission, data) => permission
                        ? IconButton(
                            icon: Builder(
                              builder: (context) {
                                return Stack(
                                  children: <Widget>[
                                    const Positioned(
                                      left: 1.0,
                                      top: 2.0,
                                      child: Icon(
                                        Icons.edit,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit,
                                      color: IconTheme.of(context).color,
                                    ),
                                  ],
                                );
                              },
                            ),
                            onPressed: () async {
                              final dynamic result =
                                  await navigator.currentState!.pushNamed(
                                'EditInvitation',
                                arguments: invitation,
                              );
                              if (result is JsonRef) {
                                scaffoldMessenger.currentState!.showSnackBar(
                                  const SnackBar(
                                    content: Text('تم الحفظ بنجاح'),
                                  ),
                                );
                              } else if (result == 'deleted')
                                navigator.currentState!.pop();
                            },
                            tooltip: 'تعديل',
                          )
                        : Container(),
                  ),
                  IconButton(
                    icon: Builder(
                      builder: (context) {
                        return Stack(
                          children: <Widget>[
                            const Positioned(
                              left: 1.0,
                              top: 2.0,
                              child: Icon(Icons.share, color: Colors.black54),
                            ),
                            Icon(
                              Icons.share,
                              color: IconTheme.of(context).color,
                            ),
                          ],
                        );
                      },
                    ),
                    onPressed: invitation.link != null
                        ? () async {
                            await Share.share(invitation.link!);
                          }
                        : null,
                    tooltip: 'مشاركة الدعوة',
                  ),
                ],
                expandedHeight: 250.0,
                stretch: true,
                pinned: true,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) => FlexibleSpaceBar(
                    title: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: constraints.biggest.height > kToolbarHeight * 1.7
                          ? 0
                          : 1,
                      child: Text(
                        invitation.name,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                    background: const Icon(Icons.link),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  <Widget>[
                    ListTile(
                      title: Text(
                        invitation.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    CopiablePropertyWidget(
                      'لينك الدعوة',
                      invitation.link,
                      additionalOptions: [
                        IconButton(
                          onPressed: invitation.link != null
                              ? () async {
                                  await Share.share(invitation.link!);
                                }
                              : null,
                          icon: const Icon(Icons.share),
                        ),
                      ],
                    ),
                    ListTile(
                      title: invitation.used
                          ? const Text('تم الاستخدام بواسطة')
                          : const Text('لم يتم الاستخدام بعد'),
                      subtitle: invitation.used
                          ? FutureBuilder<String?>(
                              future: User.onlyName(invitation.usedBy!),
                              builder: (context, data) => data.hasData
                                  ? Text(data.data!)
                                  : const LinearProgressIndicator(),
                            )
                          : null,
                    ),
                    ListTile(
                      title: const Text('تم توليد اللينك بواسطة'),
                      subtitle: FutureBuilder<String?>(
                        future: User.onlyName(invitation.generatedBy),
                        builder: (context, data) => data.hasData
                            ? Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(data.data!),
                                  ),
                                  Text(
                                    invitation.generatedOn != null
                                        ? DateFormat(
                                            'yyyy/M/d   h:m a',
                                            'ar-EG',
                                          ).format(
                                            invitation.generatedOn!.toDate(),
                                          )
                                        : '',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              )
                            : const LinearProgressIndicator(),
                      ),
                    ),
                    ListTile(
                      title: const Text('تاريخ الانتهاء'),
                      subtitle: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              DateFormat('yyyy/M/d', 'ar-EG').format(
                                invitation.expiryDate.toDate(),
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('h:m a', 'ar-EG').format(
                              invitation.expiryDate.toDate(),
                            ),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('صلاحيات المستخدم المدعوو'),
                      subtitle: Column(
                        children: [
                          if (invitation.permissions?['manageUsers'] == true)
                            const ListTile(
                              leading: Icon(
                                IconData(
                                  0xef3d,
                                  fontFamily: 'MaterialIconsR',
                                ),
                              ),
                              title: Text('إدارة المستخدمين'),
                            ),
                          if (invitation.permissions?['manageAllowedUsers'] ==
                              true)
                            const ListTile(
                              leading: Icon(
                                IconData(
                                  0xef3d,
                                  fontFamily: 'MaterialIconsR',
                                ),
                              ),
                              title: Text('إدارة مستخدمين محددين'),
                            ),
                          if (invitation.permissions?['superAccess'] == true)
                            const ListTile(
                              leading: Icon(
                                IconData(
                                  0xef56,
                                  fontFamily: 'MaterialIconsR',
                                ),
                              ),
                              title: Text('رؤية جميع البيانات'),
                            ),
                          if (invitation.permissions?['manageDeleted'] == true)
                            const ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text('استرجاع المحذوفات'),
                            ),
                          if (invitation.permissions?['secretary'] == true)
                            const ListTile(
                              leading: Icon(Icons.shield),
                              title: Text('تسجيل حضور الخدام'),
                            ),
                          if (invitation.permissions?['write'] == true)
                            const ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('تعديل البيانات'),
                            ),
                          if (invitation.permissions?['exportClasses'] == true)
                            const ListTile(
                              leading: Icon(Icons.cloud_download),
                              title: Text('تصدير فصل لملف إكسل'),
                            ),
                          if (invitation.permissions?['birthdayNotify'] == true)
                            const ListTile(
                              leading: Icon(Icons.cake),
                              title: Text('إشعار أعياد الميلاد'),
                            ),
                          if (invitation.permissions?['confessionsNotify'] ==
                              true)
                            const ListTile(
                              leading: Icon(Icons.notifications_active),
                              title: Text('إشعار الاعتراف'),
                            ),
                          if (invitation.permissions?['tanawolNotify'] == true)
                            const ListTile(
                              leading: Icon(Icons.notifications_active),
                              title: Text('إشعار التناول'),
                            ),
                          if (invitation.permissions?['kodasNotify'] == true)
                            const ListTile(
                              leading: Icon(Icons.notifications_active),
                              title: Text('إشعار القداس'),
                            ),
                          if (invitation.permissions?['meetingNotify'] == true)
                            const ListTile(
                              leading: Icon(Icons.notifications_active),
                              title: Text('إشعار حضور الاجتماع'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
