import 'package:churchdata/models/person.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata/views/form_widgets/tapable_form_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpdateUserDataErrorPage extends StatefulWidget {
  final Person person;

  const UpdateUserDataErrorPage({Key? key, required this.person})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _UpdateUserDataErrorState();
}

class _UpdateUserDataErrorState extends State<UpdateUserDataErrorPage> {
  late Person person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تحديث بيانات المستخدم'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TapableFormField<Timestamp?>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: (context, state) => InputDecoration(
              errorText: state.errorText,
              labelText: 'تاريخ أخر تناول',
              suffixIcon: state.isValid
                  ? const Icon(Icons.done, color: Colors.green)
                  : const Icon(Icons.close, color: Colors.red),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            initialValue: person.lastTanawol,
            onTap: (state) async {
              state.didChange(await _selectDate(
                      'تاريخ أخر تناول', state.value ?? Timestamp.now()) ??
                  person.lastTanawol);
            },
            builder: (context, state) {
              return state.value != null
                  ? Text(DateFormat('yyyy/M/d').format(state.value!.toDate()))
                  : null;
            },
            onSaved: (v) => person.lastTanawol = v!,
            validator: (value) => value == null
                ? 'برجاء اختيار تاريخ أخر تناول'
                : value.toDate().isBefore(
                        DateTime.now().subtract(const Duration(days: 60)))
                    ? 'يجب أن يكون التاريخ منذ شهرين على الأكثر'
                    : null,
          ),
          TapableFormField<Timestamp?>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: (context, state) => InputDecoration(
              errorText: state.errorText,
              labelText: 'تاريخ أخر اعتراف',
              suffixIcon: state.isValid
                  ? const Icon(Icons.done, color: Colors.green)
                  : const Icon(Icons.close, color: Colors.red),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            initialValue: person.lastConfession,
            onTap: (state) async {
              state.didChange(await _selectDate(
                      'تاريخ أخر اعتراف', state.value ?? Timestamp.now()) ??
                  person.lastConfession);
            },
            builder: (context, state) {
              return state.value != null
                  ? Text(DateFormat('yyyy/M/d').format(state.value!.toDate()))
                  : null;
            },
            onSaved: (v) => person.lastConfession = v!,
            validator: (value) => value == null
                ? 'برجاء اختيار تاريخ أخر اعتراف'
                : value.toDate().isBefore(
                        DateTime.now().subtract(const Duration(days: 60)))
                    ? 'يجب أن يكون التاريخ منذ شهرين على الأكثر'
                    : null,
          ),
          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: save,
        tooltip: 'حفظ',
        child: Icon(Icons.save),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    person = widget.person.copyWith();
  }

  Future save() async {
    try {
      await person.ref.update({
        'LastConfession': person.lastConfession,
        'LastTanawol': person.lastTanawol,
        'LastEdit': FirebaseAuth.instance.currentUser!.uid
      });
      navigator.currentState!.pop();
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

  Future<Timestamp?> _selectDate(String helpText, Timestamp initialDate) async {
    var picked = await showDatePicker(
        helpText: helpText,
        locale: const Locale('ar', 'EG'),
        context: context,
        initialDate: initialDate.toDate(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now());
    if (picked != null && picked != initialDate.toDate()) {
      return Timestamp.fromDate(picked);
    }
    return null;
  }
}
