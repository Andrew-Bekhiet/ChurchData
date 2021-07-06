import 'package:churchdata/models/invitation.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:flutter/material.dart';

class InvitationsPage extends StatefulWidget {
  InvitationsPage({Key? key}) : super(key: key);

  @override
  _InvitationsPageState createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  final options = DataObjectListController<Invitation>(
    itemsStream: firestore
        .collection('Invitations')
        .snapshots()
        .map((s) => s.docs.map(Invitation.fromQueryDoc).toList()),
    tap: (i) =>
        navigator.currentState!.pushNamed('InvitationInfo', arguments: i),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('لينكات الدعوة')),
      body: DataObjectList<Invitation>(
        autoDisposeController: false,
        options: options,
      ),
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        child: StreamBuilder<List<Invitation>>(
          stream: options.objectsData,
          builder: (context, snapshot) {
            return Text((snapshot.data?.length ?? 0).toString() + ' دعوة',
                textAlign: TextAlign.center,
                strutStyle:
                    StrutStyle(height: IconTheme.of(context).size! / 7.5),
                style: Theme.of(context).primaryTextTheme.bodyText1);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'اضافة دعوة',
        onPressed: () => navigator.currentState!.pushNamed('EditInvitation'),
        child: Icon(Icons.add_link),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await options.dispose();
  }
}
