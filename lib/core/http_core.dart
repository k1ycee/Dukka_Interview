import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task/core/exception.dart';

class ImageClient {
  final dio = Dio();

//Download file from url

  Future<String> downloadImage(String imageUrl, SendPort p) async {
    try {
      Response response = await dio.get(imageUrl,
          options: Options(responseType: ResponseType.bytes));
      // Directory where the image will be saved
      String dir = (await getTemporaryDirectory()).path;
      // File name for the downloaded image
      String filePath =
          '$dir/image_${DateTime.now().millisecondsSinceEpoch}.png';
      File file = File(filePath);
      await file.writeAsBytes(response.data);
      // Send a SendPort to the main isolate so that it can send JSON strings to
      // this isolate.
      final commandPort = ReceivePort();
      p.send(commandPort.sendPort);

      // Wait for messages from the main isolate.
      await for (final message in commandPort) {
        if (message is String) {
          // Read and decode the file.
          final contents = await ImageClient().downloadImage(message);
          final image = File(contents);
          print(image);
          // Send the result to the main isolate.
          p.send(image);
        } else if (message == null) {
          // Exit if the main isolate sends a null message, indicating there are no
          // more files to read and parse.
          break;
        }
      }

      return file.path;

      // Isolate.exit();
      
    } on DioException catch (e) {
      throw DownloaderException(message: e.message!, trace: e.stackTrace);
    }
  }
}
