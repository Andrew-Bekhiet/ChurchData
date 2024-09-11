import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/copiable_property.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/history_property.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonInfo extends StatelessWidget {
  final Person person;

  const PersonInfo({required this.person, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Selector<User, bool>(
        selector: (_, user) => user.write,
        builder: (context, permission, _) => StreamBuilder<Person?>(
          initialData: person,
          stream: person.ref.snapshots().map(Person.fromDoc),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Scaffold(
                body: Center(
                  child: Text('تم حذف الشخص'),
                ),
              );

            final Person person = snapshot.data!;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    backgroundColor: person.color != Colors.transparent
                        ? person.color
                        : null,
                    actions: person.ref.path.startsWith('Deleted')
                        ? <Widget>[
                            if (permission)
                              IconButton(
                                icon: const Icon(Icons.restore),
                                tooltip: 'استعادة',
                                onPressed: () {
                                  recoverDoc(context, person.ref.path);
                                },
                              ),
                          ]
                        : <Widget>[
                            if (permission)
                              IconButton(
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
                                    'Data/EditPerson',
                                    arguments: person,
                                  );
                                  if (result == null) return;

                                  scaffoldMessenger.currentState!
                                      .hideCurrentSnackBar();
                                  if (result is JsonRef) {
                                    scaffoldMessenger.currentState!
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text('تم الحفظ بنجاح'),
                                      ),
                                    );
                                  } else if (result == 'deleted') {
                                    navigator.currentState!.pop();
                                    scaffoldMessenger.currentState!
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text('تم الحذف بنجاح'),
                                      ),
                                    );
                                  }
                                },
                                tooltip: 'تعديل',
                              ),
                            IconButton(
                              icon: Builder(
                                builder: (context) {
                                  return Stack(
                                    children: <Widget>[
                                      const Positioned(
                                        left: 1.0,
                                        top: 2.0,
                                        child: Icon(
                                          Icons.share,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Icon(
                                        Icons.share,
                                        color: IconTheme.of(context).color,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              onPressed: () async {
                                await Share.share(
                                  await sharePerson(person),
                                );
                              },
                              tooltip: 'مشاركة برابط',
                            ),
                            PopupMenuButton(
                              onSelected: (p) {
                                sendNotification(context, person);
                              },
                              itemBuilder: (context) {
                                return [
                                  const PopupMenuItem(
                                    value: '',
                                    child:
                                        Text('ارسال اشعار للمستخدمين عن الشخص'),
                                  ),
                                ];
                              },
                            ),
                          ],
                    expandedHeight: 250.0,
                    pinned: true,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) => FlexibleSpaceBar(
                        title: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity:
                              constraints.biggest.height > kToolbarHeight * 1.7
                                  ? 0
                                  : 1,
                          child: Text(person.name),
                        ),
                        background: person.photo(cropToCircle: false),
                      ),
                    ),
                  ),
                ];
              },
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ListTile(
                        title: Hero(
                          tag: person.id + '-name',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              person.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                      ),
                      PhoneNumberProperty(
                        'رقم الهاتف:',
                        person.phone,
                        (n) => _phoneCall(context, n),
                        (n) => _contactAdd(context, n, person),
                      ),
                      ...person.phones.entries.map(
                        (e) => PhoneNumberProperty(
                          e.key,
                          e.value,
                          (n) => _phoneCall(context, n),
                          (n) => _contactAdd(context, n, person),
                        ),
                      ),
                      ListTile(
                        title: const Text('السن:'),
                        subtitle: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                toDurationString(
                                  person.birthDate,
                                  appendSince: false,
                                ),
                              ),
                            ),
                            Text(
                              person.birthDate != null
                                  ? DateFormat('yyyy/M/d').format(
                                      person.birthDate!.toDate(),
                                    )
                                  : '',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      if (!person.isStudent)
                        ListTile(
                          title: const Text('الوظيفة:'),
                          subtitle: FutureBuilder<String?>(
                            future: person.getJobName(),
                            builder: (context, data) {
                              if (data.hasData)
                                return Text(data.data!);
                              else if (data.connectionState ==
                                  ConnectionState.waiting)
                                return const LinearProgressIndicator();
                              return const Text('');
                            },
                          ),
                        ),
                      if (!person.isStudent)
                        ListTile(
                          title: const Text('تفاصيل الوظيفة:'),
                          subtitle: Text(person.jobDescription ?? ''),
                        ),
                      if (!person.isStudent)
                        ListTile(
                          title: const Text('المؤهل:'),
                          subtitle: Text(person.qualification ?? ''),
                        ),
                      if (person.isStudent)
                        ListTile(
                          title: const Text('السنة الدراسية:'),
                          subtitle: FutureBuilder<String?>(
                            future: person.getStudyYearName(),
                            builder: (context, data) {
                              if (data.hasData)
                                return Text(data.data!);
                              else if (data.connectionState ==
                                  ConnectionState.waiting)
                                return const LinearProgressIndicator();
                              return const Text('');
                            },
                          ),
                        ),
                      if (person.isStudent)
                        FutureBuilder<List>(
                          future: Future.wait(
                            [
                              (person.studyYear?.get() ?? Future(() => null)),
                              person.getCollegeName(),
                            ],
                          ),
                          builder: (context, data) {
                            if (data.hasData &&
                                data.data?[0]?.data != null &&
                                (data.data?[0]?.data()?['IsCollegeYear'] ??
                                    false))
                              return ListTile(
                                title: const Text('الكلية'),
                                subtitle: Text(data.data?[1] ?? ''),
                              );
                            else if (data.hasData) return Container();
                            return const LinearProgressIndicator();
                          },
                        ),
                      ListTile(
                        title: const Text('نوع الفرد:'),
                        subtitle: FutureBuilder<String?>(
                          future: person.getStringType(),
                          builder: (context, data) {
                            if (data.hasData)
                              return Text(data.data!);
                            else if (data.connectionState ==
                                ConnectionState.waiting)
                              return const LinearProgressIndicator();
                            return const Text('');
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('الكنيسة:'),
                        subtitle: FutureBuilder<String?>(
                          future: person.getChurchName(),
                          builder: (context, data) {
                            if (data.hasData)
                              return Text(data.data!);
                            else if (data.connectionState ==
                                ConnectionState.waiting)
                              return const LinearProgressIndicator();
                            return const Text('');
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('الاجتماع المشارك به:'),
                        subtitle: Text(person.meeting ?? ''),
                      ),
                      ListTile(
                        title: const Text('اب الاعتراف:'),
                        subtitle: FutureBuilder<String?>(
                          future: person.getCFatherName(),
                          builder: (context, data) {
                            if (data.hasData)
                              return Text(data.data!);
                            else if (data.connectionState ==
                                ConnectionState.waiting)
                              return const LinearProgressIndicator();
                            return const Text('');
                          },
                        ),
                      ),
                      TimeHistoryProperty(
                        'تاريخ أخر اعتراف:',
                        person.lastConfession,
                        person.ref.collection('ConfessionHistory'),
                      ),
                      TimeHistoryProperty(
                        'تاريخ أخر تناول:',
                        person.lastTanawol,
                        person.ref.collection('TanawolHistory'),
                      ),
                      ListTile(
                        title: const Text('الحالة:'),
                        subtitle: FutureBuilder<JsonDoc?>(
                          future: person.state?.get() ?? Future(() => null),
                          builder: (context, data) {
                            if (data.hasData)
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(data.data!.data()!['Name']),
                                  Container(
                                    height: 50,
                                    width: 50,
                                    color: Color(
                                      int.parse(
                                        "0xff${data.data!.data()!['Color']}",
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            return Container();
                          },
                        ),
                      ),
                      HistoryProperty(
                        'تاريخ أخر مكالمة:',
                        person.lastCall,
                        person.ref.collection('CallHistory'),
                      ),
                      if ((person.notes ?? '') != '')
                        CopiableProperty('ملاحظات:', person.notes),
                      ListTile(
                        title: const Text('خادم؟:'),
                        subtitle: Text(person.isServant ? 'نعم' : 'لا'),
                      ),
                      if (person.isServant)
                        Selector<User, bool>(
                          selector: (_, user) => user.superAccess,
                          builder: (context, permission, _) =>
                              FutureBuilder<String?>(
                            future: person.getServingAreaName(),
                            builder: (context, data) {
                              if (data.hasData && permission)
                                return ListTile(
                                  title: const Text('منطقة الخدمة'),
                                  subtitle: Text(data.data!),
                                );
                              else if (data.connectionState ==
                                  ConnectionState.waiting)
                                return const LinearProgressIndicator();
                              return const Text('');
                            },
                          ),
                        ),
                      if (person.isServant)
                        ListTile(
                          title: const Text('نوع الخدمة:'),
                          subtitle: FutureBuilder<String?>(
                            future: person.getServingTypeName(),
                            builder: (context, data) {
                              if (data.hasData)
                                return Text(data.data!);
                              else if (data.connectionState ==
                                  ConnectionState.waiting)
                                return const LinearProgressIndicator();
                              return const Text('');
                            },
                          ),
                        ),
                      const Divider(
                        thickness: 1,
                      ),
                      ListTile(
                        title: const Text('داخل منطقة:'),
                        subtitle: person.areaId != null &&
                                person.areaId!.parent.id != 'null'
                            ? AsyncDataObjectWidget<Area>(
                                person.areaId!,
                                Area.fromDoc,
                              )
                            : const Text('غير موجودة'),
                      ),
                      ListTile(
                        title: const Text('داخل شارع:'),
                        subtitle: person.streetId != null &&
                                person.streetId!.parent.id != 'null'
                            ? AsyncDataObjectWidget<Street>(
                                person.streetId!,
                                Street.fromDoc,
                              )
                            : const Text('غير موجود'),
                      ),
                      if (person.familyId != null &&
                          person.familyId!.parent.id != 'null')
                        ListTile(
                          title: const Text('داخل عائلة:'),
                          subtitle: AsyncDataObjectWidget<Family>(
                            person.familyId!,
                            Family.fromDoc,
                          ),
                        ),
                      EditHistoryProperty(
                        'أخر تحديث للبيانات:',
                        person.lastEdit,
                        person.ref.collection('EditHistory'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _phoneCall(BuildContext context, String number) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('هل تريد اجراء مكالمة الأن'),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.call),
            label: const Text('اجراء مكالمة الأن'),
            onPressed: () => navigator.currentState!.pop(true),
          ),
          TextButton.icon(
            icon: const Icon(Icons.dialpad),
            label: const Text('نسخ في لوحة الاتصال فقط'),
            onPressed: () => navigator.currentState!.pop(false),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result) {
      await launch('tel:' + getPhone(number, false));
      final recordLastCall = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('هل تريد تسجيل تاريخ هذه المكالمة؟'),
          actions: [
            TextButton(
              onPressed: () => navigator.currentState!.pop(true),
              child: const Text('نعم'),
            ),
            TextButton(
              onPressed: () => navigator.currentState!.pop(false),
              child: const Text('لا'),
            ),
          ],
        ),
      );
      if (recordLastCall == true) {
        await person.ref.update(
          {'LastEdit': User.instance.uid, 'LastCall': Timestamp.now()},
        );
        scaffoldMessenger.currentState!.showSnackBar(
          const SnackBar(
            content: Text('تم بنجاح'),
          ),
        );
      }
    } else
      await launch('tel://' + getPhone(number, false));
  }

  Future<void> _contactAdd(
    BuildContext context,
    String phone,
    Person person,
  ) async {
    if ((await Permission.contacts.request()).isGranted) {
      final TextEditingController _name =
          TextEditingController(text: person.name);
      if (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('ادخل اسم جهة الاتصال:'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(controller: _name),
                  Container(height: 10),
                  Text(phone),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => navigator.currentState!.pop(true),
                  child: const Text('حفظ جهة الاتصال'),
                ),
              ],
            ),
          ) ==
          true) {
        final c = Contact(
          photo: person.hasPhoto
              ? await person.photoRef.getData(100 * 1024 * 1024)
              : null,
          phones: [Phone(phone)],
        )..name.first = _name.text;
        await c.insert();
        scaffoldMessenger.currentState!.showSnackBar(
          SnackBar(content: Text('تمت اضافة ' + _name.text + ' بنجاح')),
        );
      }
    }
  }
}
