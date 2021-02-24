import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
  int get hashCode => hashList([id, _fullyHash(getMap().values.toList())]);

  DocumentReference get ref;

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
        e.whereType<Map>().isEmpty &&
        e.whereType<DocumentReference>().isEmpty)
      return hashList(e);
    else if (e is List) return hashList(e.map((it) => _fullyHash(it)));

    return e.hashCode;
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
  void _updateCache(String cache) async {
    String url = await widget.object.photoRef
        .getDownloadURL()
        .catchError((onError) => '');
    if (cache != url) {
      await Hive.box<String>('PhotosURLsCache')
          .put(widget.object.photoRef.fullPath, url);
      widget.object._photoUrlCache.invalidate();
      setState(() {});
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
                else
                  return GestureDetector(
                    child: !(widget.object is User)
                        ? CachedNetworkImage(
                            memCacheHeight: (constrains.maxHeight * 4).toInt(),
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
                          tag:
                              widget.heroTag ?? widget.object.photoRef.fullPath,
                          child: CachedNetworkImage(
                            imageUrl: data.data,
                            imageBuilder: (context, imageProvider) => PhotoView(
                              imageProvider: imageProvider,
                              tightMode: true,
                              enableRotation: true,
                            ),
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
                  );
              },
            ),
          ),
        );
      },
    );
  }
}
