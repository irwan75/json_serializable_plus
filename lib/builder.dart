import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'json_serializable_plus.dart';

Builder jsonAnnotationPlus(BuilderOptions options) =>
    SharedPartBuilder([SerializeGenerator()], 'jsonAnnotationPlus');
