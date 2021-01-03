import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopiableProperty extends StatelessWidget {
  const CopiableProperty(this.name, this.value, {Key key})
      : assert(name != null),
        assert(value != null),
        super(key: key);

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text(value),
      trailing: IconButton(
        icon: Icon(Icons.copy),
        tooltip: 'نسخ',
        onPressed: () => Clipboard.setData(ClipboardData(text: value)),
      ),
    );
  }
}
