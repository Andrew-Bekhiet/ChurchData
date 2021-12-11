import 'logic/initialization.dart' as initialization;
import 'logic/root_widget.dart' as root_widget;
import 'widgets/helping_widgets.dart' as helping_widgets;
import 'widgets/widget_structures.dart' as widget_structures;

void main() async {
  await helping_widgets.main();

  await widget_structures.main();

  await initialization.main();

  await root_widget.main();
}
