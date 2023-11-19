import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> getFile(String fileName) async {
  // if (_path != null) return File(_path!);

  final dir = await getTemporaryDirectory();

  String fileDirectory = "${dir.path}/cacheDirectory";

  // await Directory(fileDirectory).create(recursive: true);

  return File("$fileDirectory/$fileName");
}
