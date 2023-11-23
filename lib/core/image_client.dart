import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:task/core/exception.dart';

class ImageClient {
  final dio = Dio();
  static String? dir;




  

//Download file from url
  Future<Uint8List> downloadImage(String imageUrl, [Function(int, int)? onReceiveProgress]) async {
    try {
      Response response = await dio.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } on DioException catch (e) {
      throw DownloaderException(message: e.message!, trace: e.stackTrace);
    }
  }
}
