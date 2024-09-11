import 'package:flutter/material.dart';

class DataDialog extends StatelessWidget {
  const DataDialog({
    required this.content,
    super.key,
    this.actions,
    this.title,
    this.contentPadding,
  });

  final List<Widget>? actions;
  final Widget? title;
  final Widget content;
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
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              child: DefaultTextStyle(
                style: Theme.of(context).dialogTheme.titleTextStyle ??
                    Theme.of(context).textTheme.titleLarge!,
                child: title!,
              ),
            ),
          Flexible(
            child: Padding(
              padding:
                  contentPadding ?? const EdgeInsets.symmetric(horizontal: 7),
              child: content,
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            OverflowBar(
              children: actions!,
            ),
        ],
      ),
    );
  }
}
