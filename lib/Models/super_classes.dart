import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'person.dart';
import 'user.dart';

abstract class DataObject {
  DocumentReference ref;
  String name;
  Color color;

  DataObject(this.ref, this.name, this.color);

  DataObject.createFromData(Map<dynamic, dynamic> data, this.ref)
      : name = data['Name'],
        color = Color(data['Color'] ?? Colors.transparent.value);

  @override
  int get hashCode => hashList([id, _fullyHash(getMap().values.toList())]);

  String get id => ref.id;

  @override
  bool operator ==(dynamic other) {
    return other is DataObject && other.id == id && other.hashCode == hashCode;
  }

  Map<String, dynamic> getMap();

  Map<String, dynamic> getHumanReadableMap();

  Future<String> getSecondLine();

  int _fullyHash(dynamic e) {
    if (e is Map)
      return hashValues(
          _fullyHash(e.keys.toList()), _fullyHash(e.values.toList()));
    else if (e is DocumentReference)
      return e?.path?.hashCode;
    else if (e is List &&
        e.whereType<List>().isEmpty &&
        e.whereType<Map>().isEmpty &&
        e.whereType<DocumentReference>().isEmpty)
      return hashList(e);
    else if (e is List) return hashList(e.map((it) => _fullyHash(it)));

    return e.hashCode;
  }

  Future<void> set() async {
    await ref.set(getMap());
  }

  Future<void> update({Map<String, dynamic> old}) async {
    if (old != null)
      await ref
          .update(getMap()..removeWhere((key, value) => old[key] == value));
    else
      await ref.update(getMap());
  }
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

  final AsyncCache<String> _photoUrlCache =
      AsyncCache<String>(Duration(days: 1));

  Reference get photoRef;

  Widget get photo {
    return DataObjectPhoto(this,
        key: hasPhoto ? ValueKey(photoRef?.fullPath) : null);
  }

  Widget photoWithHero(Object heroTag) {
    return DataObjectPhoto(this,
        key: hasPhoto ? ValueKey(photoRef?.fullPath) : null, heroTag: heroTag);
  }
}

class DataObjectPhoto extends StatefulWidget {
  final PhotoObject object;
  final Object heroTag;
  const DataObjectPhoto(this.object, {Key key, this.heroTag}) : super(key: key);

  @override
  _DataObjectPhotoState createState() => _DataObjectPhotoState();
}

class _DataObjectPhotoState extends State<DataObjectPhoto> {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  void _updateCache(String cache) async {
    String url = await widget.object.photoRef
        .getDownloadURL()
        .catchError((onError) => '');
    if (cache != url) {
      await Hive.box<String>('PhotosURLsCache')
          .put(widget.object.photoRef.fullPath, url);
      widget.object._photoUrlCache.invalidate();
      if (mounted && !disposed) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        if (!widget.object.hasPhoto)
          return Icon(widget.object.defaultIcon, size: constrains.maxHeight);
        return Hero(
          tag: widget.heroTag ?? widget.object.photoRef.fullPath,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(
                height: constrains.maxHeight, width: constrains.maxHeight),
            child: FutureBuilder<String>(
              future: widget.object._photoUrlCache.fetch(
                () async {
                  String cache = Hive.box<String>('PhotosURLsCache')
                      .get(widget.object.photoRef.fullPath);

                  if (cache == null) {
                    String url = await widget.object.photoRef
                        .getDownloadURL()
                        .catchError((onError) => '');
                    await Hive.box<String>('PhotosURLsCache')
                        .put(widget.object.photoRef.fullPath, url);

                    return url;
                  }
                  _updateCache(cache);
                  return cache;
                },
              ),
              builder: (context, data) {
                if (data.hasError)
                  return Center(child: ErrorWidget(data.error));
                if (!data.hasData)
                  return const AspectRatio(
                      aspectRatio: 1, child: CircularProgressIndicator());
                if (data.data == '')
                  return Icon(widget.object.defaultIcon,
                      size: constrains.maxHeight);
                else {
                  final photo = Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Hero(
                            tag: widget.heroTag ??
                                widget.object.photoRef.fullPath,
                            child: InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: data.data,
                                progressIndicatorBuilder:
                                    (context, url, progress) => AspectRatio(
                                  aspectRatio: 1,
                                  child: CircularProgressIndicator(
                                      value: progress.progress),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      child: !(widget.object is User)
                          ? CachedNetworkImage(
                              memCacheHeight:
                                  (constrains.maxHeight * 4).toInt(),
                              imageRenderMethodForWeb:
                                  ImageRenderMethodForWeb.HtmlImage,
                              imageUrl: data.data,
                              progressIndicatorBuilder:
                                  (context, url, progress) => AspectRatio(
                                aspectRatio: 1,
                                child: CircularProgressIndicator(
                                    value: progress.progress),
                              ),
                            )
                          : StreamBuilder(
                              stream: FirebaseDatabase.instance
                                  .reference()
                                  .child(
                                      'Users/${(widget.object as User).uid}/lastSeen')
                                  .onValue,
                              builder: (context, activity) {
                                if (activity.data?.snapshot?.value == 'Active')
                                  return Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CircleAvatar(
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  data.data),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Container(
                                          height: 15,
                                          width: 15,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            border:
                                                Border.all(color: Colors.white),
                                            color: Colors.greenAccent,
                                          ),
                                        ),
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
                    ),
                  );
                  return widget.object is Person || widget.object is User
                      ? ClipOval(
                          child: photo,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: photo,
                        );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
