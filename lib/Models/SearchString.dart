import 'package:flutter/foundation.dart';

class SearchString extends ValueNotifier<String> {
  SearchString([String query = '']) : super(query);
}
