import 'package:analyzer/dart/element/type.dart';

class HandlingObject {
  final String key;
  final String? annotationKeyName;
  final bool? annotationisIgnore;
  final DartType value;
  final bool isNullable;
  HandlingObject({
    required this.key,
    this.annotationKeyName,
    this.annotationisIgnore,
    required this.value,
    this.isNullable = false,
  });
}
