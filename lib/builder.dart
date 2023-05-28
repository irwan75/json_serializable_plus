import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/source_generator.dart';

Builder generateJsonClass(BuilderOptions options) =>
    SharedPartBuilder([SerializeGenerator()], 'jsonAnnotationPlus');
