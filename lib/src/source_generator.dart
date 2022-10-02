import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:json_annotation_plus/json_annotation_plus.dart';
import 'package:source_gen/source_gen.dart';

import 'model/handling_object.dart';

class SerializeGenerator extends GeneratorForAnnotation<JsonAnnotationPlus> {
  bool _isCreateToJson(ConstantReader annotation) =>
      annotation.read('createToJson').boolValue;

  bool _isListNotObject(String value) =>
      value.contains('String') ||
      value.contains('int') ||
      value.contains('bool') ||
      value.contains('double');

  String _getTopLevelTypeData(String value) {
    if (value.contains('int')) {
      return 'int';
    } else if (value.contains('bool')) {
      return 'bool';
    } else if (value.contains('double')) {
      return 'double';
    } else {
      return 'String';
    }
  }

  String _getObjectTypeDataWithoutNull(String objectName) {
    return objectName.replaceAll('?', '').replaceAll(RegExp('(List<|>)'), '');
  }

  String _buildFromJson(ModelVisitor visitor) {
    var buffer = StringBuffer();

    if (visitor.className != null) {
      final String className = visitor.className!.toString();

      buffer.writeln(
          '$className _\$${className}FromJson(Map<String, dynamic> json) => $className(');

      for (var field in visitor.fields) {
        if (field.annotationisIgnore ?? false) {
        } else if (field.typeData.isDartCoreList) {
          if (_isListNotObject(field.typeData.toString())) {
            final topLevelTypeData =
                _getTopLevelTypeData(field.typeData.toString());

            if (field.isNullable) {
              buffer.writeln(
                  "${field.key}: (json['${field.annotationKeyName ?? field.key}'] as List<dynamic>?)?.map((e) => e as $topLevelTypeData).toList(),");
            } else {
              buffer.writeln(
                  "${field.key}: (json['${field.annotationKeyName ?? field.key}'] as List<dynamic>).map((e) => e as $topLevelTypeData).toList(),");
            }
          } else {
            if (field.isNullable) {
              buffer.writeln(
                  "${field.key}: (json['${field.annotationKeyName ?? field.key}'] as List<dynamic>?)?.map((e)=> ${_getObjectTypeDataWithoutNull(field.typeData.toString())}.fromJson(e as Map<String, dynamic>)).toList(),");
            } else {
              buffer.writeln(
                  "${field.key}: (json['${field.annotationKeyName ?? field.key}'] as List<dynamic>).map((e)=> ${_getObjectTypeDataWithoutNull(field.typeData.toString())}.fromJson(e as Map<String, dynamic>)).toList(),");
            }
          }
        } else if (field.typeData.isDartCoreInt) {
          if (field.defaultValue != null) {
            buffer.writeln(
                "${field.key}: pick(json, '${field.annotationKeyName ?? field.key}', initialValue: ${field.defaultValue}).asIntorInitialValue,");
          } else {
            buffer.writeln(
                "${field.key}: pick(json, '${field.annotationKeyName ?? field.key}').${(field.isNullable) ? 'asIntorNull' : 'asIntorThrow'} ,");
          }
        } else if (field.typeData.isDartCoreBool) {
          if (field.defaultValue != null) {
            buffer.writeln(
                "${field.key}: pick(json, '${field.annotationKeyName ?? field.key}', initialValue: ${field.defaultValue}).asBoolorInitialValue,");
          } else {
            buffer.writeln(
                "${field.key}: pick(json, '${field.annotationKeyName ?? field.key}').${(field.isNullable) ? 'asBoolorNull' : 'asBoolorThrow'} ,");
          }
        } else if (field.typeData.isDartCoreString) {
          if (field.defaultValue != null) {
            buffer.writeln(
                "${field.key}: pick(json, '${field.annotationKeyName ?? field.key}', initialValue: ${field.defaultValue}).asStringorInitialValue,");
          } else {
            buffer.writeln(
                "${field.key}: pick(json, '${field.annotationKeyName ?? field.key}').${(field.isNullable) ? 'asStringorNull' : 'asStringorThrow'} ,");
          }
        } else if (field.typeData.isDartCoreDouble) {
          if (field.defaultValue != null) {
            buffer.writeln(
                "${field.key}: pick(json, '${field.annotationKeyName ?? field.key}', initialValue: ${field.defaultValue}).asDoubleorInitialValue,");
          } else {
            buffer.writeln(
                "${field.key}: pick(json, '${field.annotationKeyName ?? field.key}').${(field.isNullable) ? 'asDoubleorNull' : 'asDoubleorThrow'} ,");
          }
        } else {
          if (field.isNullable) {
            buffer.writeln(
                "${field.key}: json['${field.annotationKeyName ?? field.key}'] == null ? null : ${field.typeData}.fromJson(json['${field.annotationKeyName ?? field.key}'] as Map<String, dynamic>),");
          } else {
            buffer.writeln(
                "${field.key}: ${field.typeData}.fromJson(json['${field.annotationKeyName ?? field.key}'] as Map<String, dynamic>),");
          }
        }
      }

      buffer.writeln(');');
    }

    return buffer.toString();
  }

  String _buildToJson(ModelVisitor visitor) {
    var buffer = StringBuffer();

    if (visitor.className != null) {
      final String className = visitor.className!.toString();

      buffer.writeln(
          'Map<String, dynamic> _\$${className}ToJson($className instance) => <String, dynamic>{');

      for (var field in visitor.fields) {
        buffer.writeln("'${field.key}': instance.${field.key},");
      }

      buffer.writeln('};');
    }

    return buffer.toString();
  }

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    var visitor = ModelVisitor();
    var buffer = StringBuffer();

    element.visitChildren(visitor);

    buffer.writeln(_buildFromJson(visitor));

    if (_isCreateToJson(annotation)) {
      buffer.writeln(_buildToJson(visitor));
    }

    return buffer.toString();
  }
}

class ModelVisitor extends SimpleElementVisitor {
  DartType? className;
  List<HandlingObject> fields = [];

  @override
  visitConstructorElement(ConstructorElement element) {
    assert(className == null);
    className = element.type.returnType;
  }

  final _coreChecker = const TypeChecker.fromRuntime(JsonKey);

  String? _getFieldNameAnnotation(FieldElement element) {
    final isHasAnnotation = _methodHasAnnotation(JsonKey, element);
    if (isHasAnnotation) {
      return _coreChecker
          .firstAnnotationOf(element)
          ?.getField('name')
          ?.toStringValue();
    }
    return null;
  }

  bool? _getFieldIgnoreAnnotation(FieldElement element) {
    final isHasAnnotation = _methodHasAnnotation(JsonKey, element);
    if (isHasAnnotation) {
      return _coreChecker
          .firstAnnotationOf(element)
          ?.getField('ignore')
          ?.toBoolValue();
    }
    return null;
  }

  Object? _getFieldDefaultValueAnnotation(FieldElement element) {
    final isHasAnnotation = _methodHasAnnotation(JsonKey, element);
    if (isHasAnnotation) {
      return _coreChecker.firstAnnotationOf(element)?.getField('defaultValue');
    }
    return null;
  }

  bool _methodHasAnnotation(Type annotationType, FieldElement element) {
    final annotations =
        TypeChecker.fromRuntime(annotationType).annotationsOf(element);
    return annotations.isNotEmpty;
  }

  @override
  visitFieldElement(FieldElement element) {
    if (!element.isStatic) {
      final String? fieldName = _getFieldNameAnnotation(element);
      final bool? isIgnore = _getFieldIgnoreAnnotation(element);
      final Object? defaultValue = _getFieldDefaultValueAnnotation(element);

      fields.add(
        HandlingObject(
          key: element.name,
          annotationKeyName: fieldName,
          annotationisIgnore: isIgnore,
          typeData: element.type,
          defaultValue: defaultValue,
          isNullable: element.type.toString().contains('?'),
        ),
      );
    }
  }
}

// function toJson not consider to make a toJsonMap
// Default Value 
// Make safe if inside list there is another type data
// Make it consider with params ignore (done)
// consider with JsonKey Params (done)
// List<Object> (done)
// List<Not Object> (done)
// Nullable (done)
// Convert to Safe Call Converter Json (done)