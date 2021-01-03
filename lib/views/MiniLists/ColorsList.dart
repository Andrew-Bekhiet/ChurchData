import 'package:churchdata/utils/globals.dart' as g;
import 'package:flutter/material.dart';

class ColorsList extends StatefulWidget {
  final List<Color> colors;

  final Color selectedColor;
  final void Function(Color, BuildContext) onSelect;
  final bool onlyPrimaries;
  ColorsList(
      {Key key,
      this.colors = g.colors,
      this.selectedColor,
      this.onSelect,
      this.onlyPrimaries = false})
      : super(key: key);

  @override
  _ColorsListState createState() => _ColorsListState();
}

class _ColorsListState extends State<ColorsList> {
  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];
    List<Color> colors = widget.colors;
    if (widget.onlyPrimaries) {
      colors = Colors.primaries.sublist(0, Colors.primaries.length - 3);
    }
    for (var item in colors) {
      list.add(
        InkWell(
          onTap: () => widget.onSelect(item, context),
          child: Material(
            shape: const CircleBorder(),
            child: CircleAvatar(
              radius: 45 / 2,
              backgroundColor: item,
              child: widget.selectedColor.value == item.value
                  ? Icon(Icons.done)
                  : null,
            ),
          ),
        ),
      );
    }
    return Container(
      width: double.maxFinite,
      child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: list),
    );
  }
}
