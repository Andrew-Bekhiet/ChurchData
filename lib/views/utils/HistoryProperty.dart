import 'package:churchdata/Models/MiniModels.dart';
import 'package:churchdata/utils/Helpers.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryProperty extends StatelessWidget {
  const HistoryProperty(this.name, this.value, this.historyRef,
      {Key key, this.showTime = true})
      : assert(name != null),
        super(key: key);

  final String name;
  final Timestamp value;
  final bool showTime;
  final CollectionReference historyRef;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Row(
        children: <Widget>[
          Expanded(
            child: Text(toDurationString(value)),
          ),
          Text(
              value != null
                  ? DateFormat(
                          showTime ? 'd/M/yyyy   h:m a' : 'd/M/yyyy', 'ar-EG')
                      .format(
                      value.toDate(),
                    )
                  : '',
              style: Theme.of(context).textTheme.overline),
        ],
      ),
      trailing: IconButton(
        tooltip: 'السجل',
        icon: Icon(Icons.history),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: FutureBuilder<List<History>>(
                future: History.getAllFromRef(historyRef),
                builder: (context, history) {
                  if (!history.hasData)
                    return const Center(child: CircularProgressIndicator());
                  if (history.hasError) return ErrorWidget(history.error);
                  if (history.data.isEmpty)
                    return const Center(child: Text('لا يوجد سجل'));
                  return ListView.builder(
                    itemCount: history.data.length,
                    itemBuilder: (context, i) => ListTile(
                      title: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .doc('Users/' + history.data[i].byUser)
                            .get(dataSource),
                        builder: (context, user) {
                          return user.hasData
                              ? Text(user.data.data()['Name'])
                              : LinearProgressIndicator();
                        },
                      ),
                      subtitle: Text(DateFormat(
                              showTime ? 'd/M/yyyy h:m a' : 'd/M/yyyy', 'ar-EG')
                          .format(history.data[i].time.toDate())),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class EditHistoryProperty extends StatelessWidget {
  const EditHistoryProperty(this.name, this.user, this.historyRef,
      {Key key, this.showTime = true})
      : assert(name != null),
        super(key: key);

  final String name;
  final String user;
  final bool showTime;
  final CollectionReference historyRef;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: user != null
          ? FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .doc('Users/' + user)
                  .get(dataSource),
              builder: (context, user) {
                return user.hasData
                    ? Text(user.data.data()['Name'])
                    : LinearProgressIndicator();
              },
            )
          : Text(''),
      trailing: IconButton(
        tooltip: 'السجل',
        icon: Icon(Icons.history),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: FutureBuilder<List<History>>(
                future: History.getAllFromRef(historyRef),
                builder: (context, history) {
                  if (!history.hasData)
                    return const Center(child: CircularProgressIndicator());
                  if (history.hasError) return ErrorWidget(history.error);
                  if (history.data.isEmpty)
                    return const Center(child: Text('لا يوجد سجل'));
                  return ListView.builder(
                    itemCount: history.data.length,
                    itemBuilder: (context, i) => ListTile(
                      title: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .doc('Users/' + history.data[i].byUser)
                            .get(dataSource),
                        builder: (context, user) {
                          return user.hasData
                              ? Text(user.data.data()['Name'])
                              : LinearProgressIndicator();
                        },
                      ),
                      subtitle: Text(DateFormat(
                              showTime ? 'd/M/yyyy h:m a' : 'd/M/yyyy', 'ar-EG')
                          .format(history.data[i].time.toDate())),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimeHistoryProperty extends StatelessWidget {
  const TimeHistoryProperty(this.name, this.value, this.historyRef,
      {Key key, this.showTime = true})
      : assert(name != null),
        super(key: key);

  final String name;
  final Timestamp value;
  final bool showTime;
  final CollectionReference historyRef;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Row(
        children: <Widget>[
          Expanded(
            child: Text(toDurationString(value)),
          ),
          Text(
              value != null
                  ? DateFormat(
                          showTime ? 'd/M/yyyy   h:m a' : 'd/M/yyyy', 'ar-EG')
                      .format(
                      value.toDate(),
                    )
                  : '',
              style: Theme.of(context).textTheme.overline),
        ],
      ),
      trailing: IconButton(
        tooltip: 'السجل',
        icon: Icon(Icons.history),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: FutureBuilder<List<History>>(
                future: History.getAllFromRef(historyRef),
                builder: (context, history) {
                  if (!history.hasData)
                    return const Center(child: CircularProgressIndicator());
                  if (history.hasError) return ErrorWidget(history.error);
                  if (history.data.isEmpty)
                    return const Center(child: Text('لا يوجد سجل'));
                  return ListView.builder(
                    itemCount: history.data.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(DateFormat(
                              showTime ? 'd/M/yyyy h:m a' : 'd/M/yyyy', 'ar-EG')
                          .format(history.data[i].time.toDate())),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
