import 'package:async/async.dart';
import 'package:churchdata/Models.dart';
import 'package:churchdata/Models/super_classes.dart';
import 'package:churchdata/utils/Helpers.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tinycolor/tinycolor.dart';

class DataObjectWidget<T extends DataObject> extends StatelessWidget {
  final T current;

  final void Function() onLongPress;
  final void Function() onTap;
  final Widget trailing;
  final Widget subtitle;
  final Widget title;
  final Widget photo;
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

  String _getTName() {
    if (T == Area) return 'Area';
    if (T == Street) return 'Street';
    if (T == Family) return 'Family';
    if (T == Person) return 'Person';
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      dense: isDense,
      onLongPress: onLongPress,
      onTap: onTap ?? () => dataObjectTap(current, context),
      trailing: trailing,
      title: title ?? Text(current.name),
      subtitle: showSubtitle
          ? (subtitle ??
              (Hive.box('Settings').get(_getTName() + 'SecondLine') != null
                  ? FutureBuilder(
                      future: _memoizer
                          .runOnce(() async => await current.getSecondLine()),
                      builder: (cont, subT) {
                        if (subT.hasData) {
                          return Text(subT.data ?? '',
                              maxLines: 1, overflow: TextOverflow.ellipsis);
                        } else {
                          return LinearProgressIndicator(
                              backgroundColor:
                                  current.color != Colors.transparent
                                      ? current.color
                                      : null,
                              valueColor: AlwaysStoppedAnimation(
                                  current.color != Colors.transparent
                                      ? current.color
                                      : Theme.of(context).primaryColor));
                        }
                      },
                    )
                  : null))
          : null,
      leading: photo ??
          (current is PhotoObject ? (current as PhotoObject).photo : null),
    );
    return wrapInCard ? Card(color: _getColor(context), child: tile) : tile;
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
