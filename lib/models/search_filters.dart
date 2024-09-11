import 'package:churchdata/utils/globals.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/helpers.dart';
import 'list_controllers.dart';
import 'order_options.dart';

class FilterButton extends StatelessWidget {
  final int? index;
  final BaseListController? options;
  final BehaviorSubject<OrderOptions>? orderOptions;
  final bool disableOrdering;
  const FilterButton(this.index, this.options, this.orderOptions,
      {Key? key, this.disableOrdering = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.select_all),
                label: const Text('تحديد الكل'),
                onPressed: () {
                  options!.selectAll();
                  navigator.currentState!.pop();
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.select_all),
                label: const Text('تحديد لا شئ'),
                onPressed: () {
                  options!.selectNone();
                  navigator.currentState!.pop();
                },
              ),
              if (!disableOrdering)
                const Text('ترتيب حسب:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              if (!disableOrdering) ...getOrderingOptions(orderOptions!, index)
            ],
          ),
        );
      },
    );
  }
}

class SearchField extends StatelessWidget {
  SearchField(
      {Key? key,
      required this.textStyle,
      required this.searchStream,
      this.showSuffix = true})
      : super(key: key);
  final TextStyle? textStyle;
  final TextEditingController _textController = TextEditingController();
  final BehaviorSubject<String> searchStream;
  final bool showSuffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: textStyle,
      controller: _textController,
      decoration: InputDecoration(
        suffixIcon: showSuffix
            ? IconButton(
                icon: Icon(Icons.close, color: textStyle!.color),
                onPressed: () {
                  _textController.text = '';
                  searchStream.add('');
                },
              )
            : null,
        hintStyle: textStyle,
        icon: Icon(Icons.search, color: textStyle!.color),
        hintText: 'بحث ...',
        border: InputBorder.none,
      ),
      onChanged: searchStream.add,
    );
  }
}

class SearchFilters extends StatelessWidget {
  final int? index;
  final TextStyle? textStyle;
  final BaseListController options;
  final BehaviorSubject<OrderOptions>? orderOptions;
  final bool disableOrdering;
  const SearchFilters(this.index,
      {Key? key,
      required this.textStyle,
      required this.options,
      this.disableOrdering = false,
      this.orderOptions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchField(
            searchStream: options.searchQuery,
            textStyle: textStyle ??
                Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).primaryTextTheme.titleLarge!.color),
          ),
        ),
        FilterButton(
          index,
          options,
          orderOptions,
          disableOrdering: disableOrdering,
        ),
      ],
    );
  }
}
