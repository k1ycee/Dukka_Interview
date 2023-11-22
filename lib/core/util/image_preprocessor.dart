import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:task/core/http_core.dart';
import 'package:task/core/util/model/download_model.dart';

class ImagePreprocessor {
  final StreamController<List<DownloadInformation>> _imagestreamController =
      StreamController<List<DownloadInformation>>.broadcast();

  Stream<List<DownloadInformation>> get imageStream =>
      _imagestreamController.stream;

  /// Spawns an [isolate] and sends a list of [imagelinks] to be
  /// downloaded in different spawned [isolates]. It waits for the response containing the downloaded Image
  /// before spawning a new Image manipulation [Isolate].
  /// This function is void because it adds results of [processedImages] to a [Stream].
  void initiateDownload(List<String> imageLinks) async {
    List<String> editOptions = [
      'billboard',
      'bleachBypass',
      'bump',
      'dotscreen',
      ''
    ];

    List<DownloadInformation> downloadInfo = imageLinks
        .map((imageLink) => DownloadInformation(imageUrl: imageLink))
        .toList();

    List<DownloadInformation> processedImages = downloadInfo;

    _imagestreamController.sink.add(processedImages);

    // Create a file diretory
    String downloadDirectory = (await getTemporaryDirectory()).path;

    for (int index = 0; index < downloadInfo.length; index++) {
      final downloadReceivePort = ReceivePort();
      Isolate.spawn(downloadImageIsolate, [
        downloadDirectory,
        downloadInfo[index].imageUrl,
        downloadReceivePort.sendPort,
      ]).then((_) async {
        await for (final imageInformation in downloadReceivePort) {
          if (imageInformation is double) {
            processedImages[index] = processedImages[index]
                .copyWith(downloadProgress: imageInformation);
            _imagestreamController.sink.add(processedImages);
          } else if (imageInformation is String) {
            processedImages[index] = processedImages[index]
                .copyWith(imagePath: imageInformation, isFiltering: true);
            _imagestreamController.sink.add(processedImages);
            final processorPort = ReceivePort();
            Isolate.spawn(imageProcessor, [
              downloadDirectory,
              imageInformation,
              processorPort.sendPort,
              editOptions[index]
            ]).then((_) async {
              final imagePath = await processorPort.first as String;
              processedImages[index] = processedImages[index]
                  .copyWith(imagePath: imagePath, isFiltering: false);
              _imagestreamController.sink.add(processedImages);
            });
          }
        }
      });
    }
  }

  /// Receives messages from the main isolate,
  ///  takes a [dir], string [imageLink] and a [sendPort] downloades the image and returns a [File],
  /// back to the main isolate.
  static Future<void> downloadImageIsolate(List<dynamic> args) async {
    SendPort downloadSendPort = args[2];
    String imageLink = args[1];
    String downloadDirectory = args[0];
    final contents =
        await ImageClient().downloadImage(imageLink, (received, total) {
      downloadSendPort.send((received / total) * 100);
    });
    // Create a file path to store the downloaded image
    String imageProcessorFilePath =
        '$downloadDirectory/image_${DateTime.now().millisecondsSinceEpoch}.png';
    // Add the downloaded image to File
    await File(imageProcessorFilePath).writeAsBytes(contents);
    Isolate.exit(downloadSendPort, imageProcessorFilePath);
  }

  /// Receives messages from the [downloadImageIsolate] isolate,
  ///  takes a [dir], [imagePath], [sendPort], [editOption], then it returns the edited image back
  /// back to the main isolate.
  static Future<void> imageProcessor(List<dynamic> args) async {
    SendPort processorSendPort = args[2];
    String downloadedImageFilePath = args[1];
    String editOption = args[3];
    String directory = args[0];
    try {
      Uint8List bytes = File(downloadedImageFilePath).readAsBytesSync();
      // Take the downloaded Image and add an edit to it

      final decodedImage = img.decodeImage(bytes)!;
      final newMessage = switch (editOption) {
        'billboard' => img.billboard(decodedImage),
        'bleachBypass' => img.bleachBypass(decodedImage, amount: 5),
        'bump' => img.bumpToNormal(decodedImage),
        'dotscreen' => img.dotScreen(decodedImage),
        _ => img.colorHalftone(decodedImage)
      };

      String imageProcessorFilePath =
          '$directory/processed_${DateTime.now().millisecondsSinceEpoch}.png';

      // Add the processed image to File
      await File(imageProcessorFilePath)
          .writeAsBytes(img.encodePng(newMessage));

      Isolate.exit(processorSendPort, imageProcessorFilePath);
    } catch (e) {
      Isolate.exit(processorSendPort, e.toString());
    }
  }

  void dispose() {
    _imagestreamController.close();
  }
}
