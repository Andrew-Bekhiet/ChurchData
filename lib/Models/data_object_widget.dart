import 'package:async/async.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tinycolor/tinycolor.dart';

import 'person.dart';

class AsyncDataObjectWidget<T extends DataObject> extends StatelessWidget {
  final DocumentReference doc;
  final T Function(DocumentSnapshot) transform;

  final void Function() onLongPress;
  final void Function() onTap;
  final Widget trailing;
  final Widget photo;
  final Widget subtitle;
  final Widget title;
  final bool wrapInCard;
  final bool isDense;
  final bool showSubtitle;
  const AsyncDataObjectWidget(this.doc, this.transform,
      {this.isDense,
      this.onLongPress,
      this.onTap,
      this.trailing,
      this.subtitle,
      this.title,
      this.wrapInCard = true,
      this.photo,
      this.showSubtitle = true,
      Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: doc.get(dataSource).then(transform),
      builder: (context, snapshot) {
        if (snapshot.hasError &&
            !snapshot.error.toString().toLowerCase().contains('denied'))
          return ErrorWidget.builder(snapshot.error);
        if (snapshot.hasError) return Text('لا يمكن اظهار العنصر المطلوب');

        if (snapshot.connectionState != ConnectionState.done)
          return const LinearProgressIndicator();

        if (!snapshot.hasData) {
          return Text('لا يوجد بيانات');
        }
        return DataObjectWidget<T>(
          snapshot.data,
          isDense: isDense,
          onLongPress: onLongPress,
          onTap: onTap,
          photo: photo,
          showSubtitle: showSubtitle,
          subtitle: subtitle,
          title: title,
          trailing: trailing,
          wrapInCard: wrapInCard,
        );
      },
    );
  }
}

class DataObjectWidget<T extends DataObject> extends StatelessWidget {
  final T current;

  final void Function() onLongPress;
  final void Function() onTap;
  final Widget trailing;
  final Widget photo;
  final Widget subtitle;
  final Widget title;
  final bool wrapInCard;
  final bool isDense;
  final bool showSubtitle;

  final _memoizer = AsyncMemoizer<String>();

  DataObjectWidget(this.current,
      {this.isDense = false,
      this.onLongPress,
      this.onTap,
      this.trailing,
      this.subtitle,
      this.title,
      this.wrapInCard = true,
      this.photo,
      this.showSubtitle = true});

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      dense: isDense,
      onLongPress: onLongPress,
      onTap: onTap ?? () => dataObjectTap(current, context),
      trailing: trailing ??
          (current is Person ? (current as Person).getLeftWidget() : null),
      title: title ?? Text(current.name),
      subtitle: showSubtitle
          ? subtitle ??
              FutureBuilder(
                future: _memoizer
                    .runOnce(() async => await current.getSecondLine()),
                builder: (cont, subT) {
                  if (subT.hasData) {
                    return Text(subT.data ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis);
                  } else {
                    return LinearProgressIndicator(
                        backgroundColor: current.color != Colors.transparent
                            ? current.color
                            : null,
                        valueColor: AlwaysStoppedAnimation(
                            current.color != Colors.transparent
                                ? current.color
                                : Theme.of(context).primaryColor));
                  }
                },
              )
          : null,
      leading: photo ??
          (current is PhotoObject
              ? (current as PhotoObject).photo(current is Person)
              : null),
    );
    return wrapInCard
        ? Card(
            color: _getColor(context),
            child: tile,
          )
        : tile;
  }

  Color _getColor(BuildContext context) {
    if (current.color == Colors.transparent) return null;
    if (current.color.brightness > 170 &&
        Theme.of(context).brightness == Brightness.dark) {
      //refers to the contrasted text theme color
      return current.color
          .darken(((265 - current.color.brightness) / 255 * 100).toInt());
    } else if (current.color.brightness < 85 &&
        Theme.of(context).brightness == Brightness.light) {
      return current.color
          .lighten(((265 - current.color.brightness) / 255 * 100).toInt());
    }
    return current.color;
  }
}
