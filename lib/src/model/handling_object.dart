import 'package:analyzer/dart/element/type.dart';

class HandlingObject {
  final String key;
  final String? annotationKeyName;
  final bool? annotationisIgnore;
  final dynamic defaultValue;
  final DartType typeData;
  final bool isNullable;
  HandlingObject({
    required this.key,
    this.annotationKeyName,
    this.annotationisIgnore,
    this.defaultValue,
    required this.typeData,
    this.isNullable = false,
  });
}
