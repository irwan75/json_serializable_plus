import 'package:analyzer/dart/element/type.dart';

class HandlingObject {
  final String key;
  final DartType value;
  final bool isNullable;
  HandlingObject({
    required this.key,
    required this.value,
    this.isNullable = false,
  });
}
