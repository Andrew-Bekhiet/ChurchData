import 'package:flutter/material.dart';

class DataDialog extends StatelessWidget {
  const DataDialog(
      {Key? key,
      this.actions,
      this.title,
      required this.content,
      this.contentPadding})
      : assert(content != null),
        super(key: key);

  final List<Widget>? actions;
  final Widget? title;
  final Widget? content;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              child: DefaultTextStyle(
                style: Theme.of(context).dialogTheme.titleTextStyle ??
                    Theme.of(context).textTheme.headline6!,
                child: title!,
              ),
            ),
          Flexible(
            child: Padding(
                padding: contentPadding ?? EdgeInsets.symmetric(horizontal: 7),
                child: content),
          ),
          if (actions != null && actions!.isNotEmpty)
            ButtonBar(
              children: actions!,
            )
        ],
      ),
    );
  }
}
