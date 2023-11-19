import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task/core/exception.dart';

class ImageClient {
  final dio = Dio();
  static String? dir;

  static Future<void> initializeDirectory() async {
    dir = (await getTemporaryDirectory()).path;

    print("Initialized: $dir");
  }

//Download file from url

  Future<Uint8List> downloadImage(String imageUrl) async {
    try {
      Response response = await dio.get(imageUrl,
          options: Options(responseType: ResponseType.bytes));
      // Directory where the image will be saved
      // String

      // print(dir);
      // // File name for the downloaded image
      // String filePath =
      //     '$dir/image_${DateTime.now().millisecondsSinceEpoch}.png';

      // File file = File(filePath);
      // await file.writeAsBytes(response.data);

      // return file.path;

      return response.data;
    } on DioException catch (e) {
      throw DownloaderException(message: e.message!, trace: e.stackTrace);
    }
  }
}
