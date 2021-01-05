import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import 'User.dart';

abstract class DataObject {
  String id;
  String name;
  Color color;

  DataObject(this.id, this.name, this.color);

  DataObject.createFromData(Map<dynamic, dynamic> data, this.id)
      : name = data['Name'],
        color = Color(data['Color'] ?? Colors.transparent.value);

  @override
  int get hashCode => hashList([
        id,
        ...getMap()
            .values
            .map((e) => e is List
                ? hashList(e)
                : (e is DocumentReference ? e?.path : e))
            .toList()
      ]);

  DocumentReference get ref;

  @override
  bool operator ==(dynamic other) {
    return other is DataObject && other.id == id && other.hashCode == hashCode;
  }

  Map<String, dynamic> getMap();

  Map<String, dynamic> getHumanReadableMap();

  Map<String, dynamic> getExportMap();

  Future<String> getSecondLine();
}

abstract class ParentObject<T extends DataObject> {
  Future<List<T>> getChildren(
      [String orderBy = 'Name', bool tranucate = false]);

  Future<String> getMembersString() async {
    return (await getChildren('Name', true)).map((f) => f.name).join(',');
  }
}

abstract class ChildObject<T extends DataObject> {
  DocumentReference get parentId;
  Future<String> getParentName();
}

abstract class PhotoObject {
  IconData defaultIcon = Icons.help;
  bool hasPhoto;

  final AsyncMemoizer<String> _photoUrlCache = AsyncMemoizer<String>();

  Reference get photoRef;

  Widget get photo {
    return DataObjectPhoto(this);
  }
}

class DataObjectPhoto extends StatelessWidget {
  final PhotoObject object;
  const DataObjectPhoto(this.object, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.height / 16.56;
    if (!object.hasPhoto) return Icon(object.defaultIcon, size: size);
    return Hero(
      tag: object.photoRef.fullPath,
      child: ConstrainedBox(
        constraints: BoxConstraints.expand(width: size, height: size),
        child: FutureBuilder<String>(
          future: object._photoUrlCache.runOnce(() async =>
              await object.photoRef
                  .getDownloadURL()
                  .catchError((onError) => '') ??
              ''),
          builder: (context, data) {
            if (data.hasError) return Center(child: ErrorWidget(data.error));
            if (!data.hasData) return const CircularProgressIndicator();
            if (data.data == '')
              return Icon(object.defaultIcon, size: size);
            else
              return Material(
                type: MaterialType.transparency,
                child: InkWell(
                  child: !(object is User)
                      ? CachedNetworkImage(
                          memCacheHeight: (size * 4).toInt(),
                          imageRenderMethodForWeb:
                              ImageRenderMethodForWeb.HtmlImage,
                          imageUrl: data.data,
                          progressIndicatorBuilder: (context, url, progress) =>
                              CircularProgressIndicator(
                                  value: progress.progress),
                        )
                      : StreamBuilder(
                          stream: FirebaseDatabase.instance
                              .reference()
                              .child('Users/${(object as User).uid}/lastSeen')
                              .onValue,
                          builder: (context, activity) {
                            if (activity.data?.snapshot?.value == 'Active')
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: CircleAvatar(
                                      backgroundImage:
                                          CachedNetworkImageProvider(data.data),
                                    ),
                                  ),
                                  Align(
                                    child: Container(
                                      height: 15,
                                      width: 15,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: Colors.white),
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                    alignment: Alignment.bottomLeft,
                                  ),
                                ],
                              );
                            else
                              return CircleAvatar(
                                backgroundImage:
                                    CachedNetworkImageProvider(data.data),
                              );
                          },
                        ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Hero(
                        tag: object.photoRef.fullPath,
                        child: CachedNetworkImage(
                          imageUrl: data.data,
                          imageBuilder: (context, imageProvider) => PhotoView(
                            imageProvider: imageProvider,
                            tightMode: true,
                            enableRotation: true,
                          ),
                          progressIndicatorBuilder: (context, url, progress) =>
                              CircularProgressIndicator(
                                  value: progress.progress),
                        ),
                      ),
                    ),
                  ),
                ),
              );
          },
        ),
      ),
    );
  }
}
