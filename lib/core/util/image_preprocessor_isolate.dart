import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task/core/http_core.dart';

class ImagePreprocessorIsolate {
  final dio = Dio();
  StreamController<List<String>> _imagestreamController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get imageStream => _imagestreamController.stream;

  /// Spawns an [isolate] and asynchronously sends a list of [imagelinks] to be
  /// downloaded in different spawned [isolates]. It waits for the response containing the downloaded Image
  /// before spawning a new Image manipulation [Isolate].
  /// This function is [Future] but it adds results of [processedImages] to a [Stream].
  Future<void> sendAndReceive(
      List<String> imageLinks, List<Option> editOptions) async {
    _imagestreamController = StreamController<List<String>>.broadcast();
    List<String> processedImages = [];
    List<String> editOptions = [
      'billboard',
      'edgeGlow',
      'bump',
      'dotscreen',
      ''
    ];

    // Create a file diretory
    String downloadDirectory = (await getTemporaryDirectory()).path;

    for (int index = 0; index < imageLinks.length; index++) {
      final downloadReceivePort = ReceivePort();
    await Isolate.spawn(downloadImageIsolate, [
        downloadDirectory,
        imageLinks[index],
        downloadReceivePort.sendPort,
      ]).then((value) async {
        final imagePath = await downloadReceivePort.first as dynamic;
        processedImages.add(imagePath);
        _imagestreamController.sink.add(processedImages);
        final processorPort = ReceivePort();
        Isolate.spawn(imageProcessor, [
          downloadDirectory,
          imagePath,
          processorPort.sendPort,
          editOptions[index]
        ]).then((value) async {
          final imagePath = await processorPort.first as String;
          processedImages[index] = imagePath;
          _imagestreamController.sink.add(processedImages);
        });
      });
    }
  }

  /// Receives messages from the main isolate,
  ///  takes a [dir],list of [imageLinks] and a [sendPort] downloades the image and returns a [File],
  /// back to the main isolate.
  static Future<void> downloadImageIsolate(List<dynamic> args) async {
    SendPort downloadSendPort = args[2];
    final contents =
        await ImageClient().downloadImage(args[1]);
    // Create a file path to store the downloaded image
    String imageProcessorFilePath =
        '${args[0]}/image_${DateTime.now().millisecondsSinceEpoch}.png';
    // Add the downloaded image to File
    await File(imageProcessorFilePath).writeAsBytes(contents);
    Isolate.exit(downloadSendPort, imageProcessorFilePath);
  }

  /// Receives messages from the [downloadImageIsolate] isolate,
  ///  takes a [dir], [imagePath], [sendPort], [editOption], then it returns the edited image back
  /// back to the main isolate.
  static Future<void> imageProcessor(List<dynamic> args) async {
    try {
      Uint8List bytes = File(args[1]).readAsBytesSync();
      // Take the downloaded Image and add an edit to it
      final newMessage = switch (args[3]) {
        'billboard' => img.billboard(
            img.decodeImage(bytes)!,
          ),
        'edgeGlow' => img.edgeGlow(
            img.decodeImage(bytes)!,
          ),
        'bump' => img.bumpToNormal(
            img.decodeImage(bytes)!,
          ),
        'dotscreen' => img.dotScreen(
            img.decodeImage(bytes)!,
          ),
        _ => img.colorHalftone(
            img.decodeImage(bytes)!,
          )
      };

      String imageProcessorFilePath =
          '${args[0]}/processed_${DateTime.now().millisecondsSinceEpoch}.png';

      // Add the processed image to File
      final processedImage = await File(imageProcessorFilePath)
          .writeAsBytes(img.encodePng(newMessage));

      Isolate.exit(args[2], processedImage.path);
    } catch (e) {
      Isolate.exit(args[2], '');
    }
  }
}
