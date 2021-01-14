import 'package:churchdata/Models.dart';
import 'package:churchdata/utils/Helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.io) 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpdateUserDataErrorPage extends StatefulWidget {
  final Person person;

  const UpdateUserDataErrorPage({Key key, this.person}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UpdateUserDataErrorState();
}

class _UpdateUserDataErrorState extends State<UpdateUserDataErrorPage> {
  Person person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تحديث بيانات المستخدم'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Focus(
                    child: InkWell(
                      onTap: () async => person.lastTanawol = await _selectDate(
                        'تاريخ أخر تناول',
                        person.lastTanawol?.toDate() ?? DateTime.now(),
                        setState,
                      ),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تاريخ أخر تناول',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        child: person.lastTanawol != null
                            ? Text(DateFormat('yyyy/M/d').format(
                                person.lastTanawol.toDate(),
                              ))
                            : Text('(فارغ)'),
                      ),
                    ),
                  ),
                ),
                flex: 3,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Focus(
                    child: InkWell(
                      onTap: () async =>
                          person.lastConfession = await _selectDate(
                        'تاريخ أخر اعتراف',
                        person.lastConfession?.toDate() ?? DateTime.now(),
                        setState,
                      ),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تاريخ أخر اعتراف',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        child: person.lastConfession != null
                            ? Text(DateFormat('yyyy/M/d').format(
                                person.lastConfession.toDate(),
                              ))
                            : Text('(فارغ)'),
                      ),
                    ),
                  ),
                ),
                flex: 3,
              ),
            ],
          ),
          Container(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: save,
        child: Icon(Icons.save),
        tooltip: 'حفظ',
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    person = widget.person;
  }

  Future save() async {
    try {
      await person.ref.update({
        'LastConfession': person.lastConfession,
        'LastTanawol': person.lastTanawol,
        'LastEdit': FirebaseAuth.instance.currentUser.uid
      });
      Navigator.pop(context);
    } catch (err, stkTrace) {
      await showErrorDialog(
        context,
        err.toString(),
      );
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'UpdateUserDataError.save');
      await FirebaseCrashlytics.instance.setCustomKey('Person', person.id);
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
    }
  }

  Future<Timestamp> _selectDate(
      String helpText,
      DateTime initialDate,
      void Function(
    void Function(),
  )
          setState) async {
    DateTime picked = await showDatePicker(
      helpText: helpText,
      locale: Locale('ar', 'EG'),
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1500),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != initialDate) {
      setState(() {});
      return Timestamp.fromDate(picked);
    }
    return Timestamp.fromDate(initialDate);
  }
}
