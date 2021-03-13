import 'package:churchdata/models/list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:churchdata/models/invitation.dart';
import 'package:provider/provider.dart';

class InvitationsPage extends StatefulWidget {
  InvitationsPage({Key key}) : super(key: key);

  @override
  _InvitationsPageState createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('لينكات الدعوة')),
      body: ListenableProvider<SearchString>(
        create: (_) => SearchString(),
        builder: (context, _) => DataObjectList<Invitation>(
          options: ListOptions(
            documentsData: FirebaseFirestore.instance
                .collection('Invitations')
                .snapshots()
                .map((s) => s.docs.map(Invitation.fromDoc).toList()),
            floatingActionButton: FloatingActionButton(
              tooltip: 'اضافة دعوة',
              onPressed: () =>
                  Navigator.of(context).pushNamed('EditInvitation'),
              child: Icon(Icons.add_link),
            ),
            tap: (i) =>
                Navigator.of(context).pushNamed('InvitationInfo', arguments: i),
          ),
        ),
      ),
    );
  }
}
