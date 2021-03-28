import 'package:churchdata/models/list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:churchdata/models/invitation.dart';
import 'package:churchdata/models/list_options.dart';

class InvitationsPage extends StatefulWidget {
  InvitationsPage({Key key}) : super(key: key);

  @override
  _InvitationsPageState createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  @override
  Widget build(BuildContext context) {
    final options = DataObjectListOptions(
      searchQuery: Stream.value(''),
      itemsStream: FirebaseFirestore.instance
          .collection('Invitations')
          .snapshots()
          .map((s) => s.docs.map(Invitation.fromDoc).toList()),
      tap: (i) =>
          Navigator.of(context).pushNamed('InvitationInfo', arguments: i),
    );
    return Scaffold(
      appBar: AppBar(title: Text('لينكات الدعوة')),
      body: DataObjectList<Invitation>(
        options: options,
      ),
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: CircularNotchedRectangle(),
        child: StreamBuilder<List<Invitation>>(
          stream: options.objectsData,
          builder: (context, snapshot) {
            return Text((snapshot.data?.length ?? 0).toString() + ' دعوة',
                textAlign: TextAlign.center,
                strutStyle:
                    StrutStyle(height: IconTheme.of(context).size / 7.5),
                style: Theme.of(context).primaryTextTheme.bodyText1);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'اضافة دعوة',
        onPressed: () => Navigator.of(context).pushNamed('EditInvitation'),
        child: Icon(Icons.add_link),
      ),
    );
  }
}
