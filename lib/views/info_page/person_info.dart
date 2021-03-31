import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/models/copiable_property.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/history_property.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonInfo extends StatelessWidget {
  final Person person;

  PersonInfo({Key key, this.person}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FeatureDiscovery.discoverFeatures(context, [
        'Person.MoreOptions',
      ]),
    );
    return Scaffold(
      body: Selector<User, bool>(
        selector: (_, user) => user.write,
        builder: (context, permission, _) => StreamBuilder<Person>(
          initialData: person,
          stream: person.ref.snapshots().map(Person.fromDoc),
          builder: (context, snapshot) {
            final Person person = snapshot.data;
            if (person == null)
              return Scaffold(
                body: Center(
                  child: Text('تم حذف الشخص'),
                ),
              );
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
                                icon: Icon(Icons.restore),
                                tooltip: 'استعادة',
                                onPressed: () {
                                  recoverDoc(context, person.ref.path);
                                },
                              )
                          ]
                        : <Widget>[
                            if (permission)
                              IconButton(
                                icon: Builder(
                                  builder: (context) {
                                    return Stack(
                                      children: <Widget>[
                                        Positioned(
                                          left: 1.0,
                                          top: 2.0,
                                          child: Icon(Icons.edit,
                                              color: Colors.black54),
                                        ),
                                        Icon(Icons.edit,
                                            color: IconTheme.of(context).color),
                                      ],
                                    );
                                  },
                                ),
                                onPressed: () async {
                                  dynamic result = await Navigator.of(context)
                                      .pushNamed('Data/EditPerson',
                                          arguments: person);
                                  if (result == null) return;

                                  ScaffoldMessenger.of(mainScfld.currentContext)
                                      .hideCurrentSnackBar();
                                  if (result is DocumentReference) {
                                    ScaffoldMessenger.of(
                                            mainScfld.currentContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text('تم الحفظ بنجاح'),
                                      ),
                                    );
                                  } else if (result == 'deleted') {
                                    Navigator.of(mainScfld.currentContext)
                                        .pop();
                                    ScaffoldMessenger.of(
                                            mainScfld.currentContext)
                                        .showSnackBar(
                                      SnackBar(
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
                                      Positioned(
                                        left: 1.0,
                                        top: 2.0,
                                        child: Icon(Icons.share,
                                            color: Colors.black54),
                                      ),
                                      Icon(Icons.share,
                                          color: IconTheme.of(context).color),
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
                            DescribedFeatureOverlay(
                              onBackgroundTap: () async {
                                await FeatureDiscovery.completeCurrentStep(
                                    context);
                                return true;
                              },
                              onDismiss: () async {
                                await FeatureDiscovery.completeCurrentStep(
                                    context);
                                return true;
                              },
                              backgroundDismissible: true,
                              contentLocation: ContentLocation.below,
                              featureId: 'Person.MoreOptions',
                              tapTarget: Icon(
                                Icons.more_vert,
                              ),
                              title: Text('المزيد من الخيارات'),
                              description: Column(
                                children: <Widget>[
                                  Text(
                                      'يمكنك ايجاد المزيد من الخيارات من هنا مثل: اشعار المستخدمين عن الشخص\ىنسخ في لوحة الاتصال\ىاضافة لجهات الاتصال\ىارسال رسالة\ىارسال رسالة من خلال الواتساب'),
                                  OutlinedButton(
                                    onPressed: () =>
                                        FeatureDiscovery.completeCurrentStep(
                                            context),
                                    child: Text(
                                      'تخطي',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Theme.of(context).accentColor,
                              targetColor: Colors.transparent,
                              textColor: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyText1
                                  .color,
                              child: PopupMenuButton(
                                onSelected: (p) {
                                  sendNotification(context, person);
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    PopupMenuItem(
                                      value: '',
                                      child: Text(
                                          'ارسال اشعار للمستخدمين عن الشخص'),
                                    )
                                  ];
                                },
                              ),
                            ),
                          ],
                    expandedHeight: 250.0,
                    floating: false,
                    pinned: true,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) => FlexibleSpaceBar(
                          title: AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            opacity: constraints.biggest.height >
                                    kToolbarHeight * 1.7
                                ? 0
                                : 1,
                            child: Text(person.name),
                          ),
                          background: person.photo(false)),
                    ),
                  ),
                ];
              },
              body: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ListTile(
                        title: Hero(
                          tag: person.id + '-name',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              person.name,
                              style: Theme.of(context).textTheme.headline6,
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
                      if (person.phones != null)
                        ...person.phones.entries
                            .map((e) => PhoneNumberProperty(
                                  e.key,
                                  e.value,
                                  (n) => _phoneCall(context, n),
                                  (n) => _contactAdd(context, n, person),
                                ))
                            .toList(),
                      ListTile(
                        title: Text('السن:'),
                        subtitle: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(toDurationString(person.birthDate,
                                  appendSince: false)),
                            ),
                            Text(
                                person.birthDate != null
                                    ? DateFormat('yyyy/M/d').format(
                                        person.birthDate.toDate(),
                                      )
                                    : '',
                                style: Theme.of(context).textTheme.overline),
                          ],
                        ),
                      ),
                      if (!person.isStudent)
                        ListTile(
                          title: Text('الوظيفة:'),
                          subtitle: FutureBuilder(
                              future: person.getJobName(),
                              builder: (context, data) {
                                if (data.hasData) return Text(data.data);
                                return LinearProgressIndicator();
                              }),
                        ),
                      if (!person.isStudent)
                        ListTile(
                          title: Text('تفاصيل الوظيفة:'),
                          subtitle: Text(person.jobDescription ?? ''),
                        ),
                      if (!person.isStudent)
                        ListTile(
                          title: Text('المؤهل:'),
                          subtitle: Text(person.qualification ?? ''),
                        ),
                      if (person.isStudent)
                        ListTile(
                          title: Text('السنة الدراسية:'),
                          subtitle: FutureBuilder(
                            future: person.getStudyYearName(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            },
                          ),
                        ),
                      if (person.isStudent)
                        FutureBuilder(
                          future: Future.wait(
                            [
                              (person.studyYear?.get(dataSource) ??
                                  Future(() => null)),
                              person.getCollegeName()
                            ],
                          ),
                          builder: (context, data) {
                            if (data.hasData &&
                                data.data[0]?.data != null &&
                                (data.data[0]?.data()['IsCollegeYear'] ??
                                    false))
                              return ListTile(
                                  title: Text('الكلية'),
                                  subtitle: Text(data.data[1]));
                            else if (data.hasData) return Container();
                            return LinearProgressIndicator();
                          },
                        ),
                      ListTile(
                        title: Text('نوع الفرد:'),
                        subtitle: FutureBuilder(
                            future: person.getStringType(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            }),
                      ),
                      ListTile(
                        title: Text('الكنيسة:'),
                        subtitle: FutureBuilder(
                            future: person.getChurchName(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            }),
                      ),
                      ListTile(
                        title: Text('الاجتماع المشارك به:'),
                        subtitle: Text(person.meeting ?? ''),
                      ),
                      ListTile(
                        title: Text('اب الاعتراف:'),
                        subtitle: FutureBuilder(
                            future: person.getCFatherName(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            }),
                      ),
                      TimeHistoryProperty(
                          'تاريخ أخر اعتراف:',
                          person.lastConfession,
                          person.ref.collection('ConfessionHistory')),
                      TimeHistoryProperty(
                          'تاريخ أخر تناول:',
                          person.lastTanawol,
                          person.ref.collection('TanawolHistory')),
                      ListTile(
                        title: Text('الحالة:'),
                        subtitle: FutureBuilder<DocumentSnapshot>(
                          future: (person.state?.get(dataSource) ??
                              Future(() => null)),
                          builder: (context, data) {
                            if (data.hasData)
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(data.data.data()['Name']),
                                  Container(
                                    height: 50,
                                    width: 50,
                                    color: Color(
                                      int.parse(
                                          "0xff${data.data.data()['Color']}"),
                                    ),
                                  )
                                ],
                              );
                            return Container();
                          },
                        ),
                      ),
                      HistoryProperty('تاريخ أخر مكالمة:', person.lastCall,
                          person.ref.collection('CallHistory')),
                      if ((person.notes ?? '') != '')
                        CopiableProperty('ملاحظات:', person.notes),
                      ListTile(
                          title: Text('خادم؟:'),
                          subtitle: Text(person.isServant ? 'نعم' : 'لا')),
                      if (person.isServant)
                        Selector<User, bool>(
                          selector: (_, user) => user.superAccess,
                          builder: (context, permission, _) =>
                              FutureBuilder<String>(
                                  future: person.getServingAreaName(),
                                  builder: (context, data) {
                                    if (data.hasData && permission)
                                      return ListTile(
                                        title: Text('منطقة الخدمة'),
                                        subtitle: Text(data.data),
                                      );
                                    return Container();
                                  }),
                        ),
                      if (person.isServant)
                        ListTile(
                          title: Text('نوع الخدمة:'),
                          subtitle: FutureBuilder(
                            future: person.getServingTypeName(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            },
                          ),
                        ),
                      Divider(
                        thickness: 1,
                      ),
                      ListTile(
                        title: Text('داخل منطقة:'),
                        subtitle: person.areaId != null &&
                                person.areaId.parent.id != 'null'
                            ? AsyncDataObjectWidget<Area>(
                                person.areaId, Area.fromDoc)
                            : Text('غير موجودة'),
                      ),
                      ListTile(
                        title: Text('داخل شارع:'),
                        subtitle: person.streetId != null &&
                                person.streetId.parent.id != 'null'
                            ? AsyncDataObjectWidget<Street>(
                                person.streetId, Street.fromDoc)
                            : Text('غير موجود'),
                      ),
                      if (person.familyId != null &&
                          person.familyId.parent.id != 'null')
                        ListTile(
                          title: Text('داخل عائلة:'),
                          subtitle: AsyncDataObjectWidget<Family>(
                              person.familyId, Family.fromDoc),
                        ),
                      EditHistoryProperty(
                          'أخر تحديث للبيانات:',
                          person.lastEdit,
                          person.ref.collection('EditHistory')),
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

  void _phoneCall(BuildContext context, String number) async {
    var result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('هل تريد اجراء مكالمة الأن'),
        actions: [
          OutlinedButton.icon(
            icon: Icon(Icons.call),
            label: Text('اجراء مكالمة الأن'),
            onPressed: () => Navigator.pop(context, true),
          ),
          TextButton.icon(
            icon: Icon(Icons.dialpad),
            label: Text('نسخ في لوحة الاتصال فقط'),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result) {
      await launch('tel:' + getPhone(number, false));
      var recordLastCall = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text('هل تريد تسجيل تاريخ هذه المكالمة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('نعم'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('لا'),
            ),
          ],
        ),
      );
      if (recordLastCall == true) {
        await person.ref.update(
            {'LastEdit': User.instance.uid, 'LastCall': Timestamp.now()});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم بنجاح'),
          ),
        );
      }
    } else
      await launch('tel://' + getPhone(number, false));
  }

  Future<void> _contactAdd(
      BuildContext context, String phone, Person person) async {
    if ((await Permission.contacts.request()).isGranted) {
      TextEditingController _name = TextEditingController(text: person.name);
      if (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('ادخل اسم جهة الاتصال:'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(controller: _name),
                  Container(height: 10),
                  Text(phone ?? ''),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('حفظ جهة الاتصال'))
              ],
            ),
          ) ==
          true) {
        final c = Contact(
            photo: person.hasPhoto
                ? await person.photoRef.getData(100 * 1024 * 1024)
                : null,
            phones: [Phone(phone)])
          ..name.first = _name.text;
        await c.insert();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تمت اضافة ' + _name.text + ' بنجاح')));
      }
    }
  }
}
