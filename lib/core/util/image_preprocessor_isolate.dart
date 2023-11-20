import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task/core/http_core.dart';

class ImagePreprocessorIsolate {
  final StreamController<List<String>> _imagestreamController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get imageStream => _imagestreamController.stream;
// Spawns an isolate and asynchronously sends a list of imagelinks for it to
// read and decode. Waits for the response containing the decoded JSON
// before sending the next.
//
// Returns a stream that emits the JSON-decoded contents of each file.
  void sendAndReceive(List<String> imageLinks, List<Option> editOptions) async {
    List<String> processedImages = [];
    List<String> editOptions = [
      'billboard',
      'edgeGlow',
      'bump',
      'dotscreen',
      ''
    ];

    // Create a file diretory
    String dir = (await getTemporaryDirectory()).path;

    for (int index = 0; index < imageLinks.length; index++) {
      final p = ReceivePort();
      Isolate.spawn(downloadImageIsolate, [
        dir,
        imageLinks[index],
        p.sendPort,
      ]).then((value) async {
        final imagePath = await p.first as String;
        processedImages.add(imagePath);
        _imagestreamController.sink.add(processedImages);
        final processorPort = ReceivePort();
        Isolate.spawn(imageProcessor, [
          dir,
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

// The entrypoint that runs on the spawned isolate. Receives messages from
// the main isolate, takes the list of image links, downloades the image and returns a Uint8List,
// back to the main isolate.
  static void downloadImageIsolate(List<dynamic> args) async {
    final contents = await ImageClient().downloadImage(args[1]);
    // Create a file path to store the downloaded image
    String imageProcessorFilePath =
        '${args[0]}/image_${DateTime.now().millisecondsSinceEpoch}.png';
    // Add the downloaded image to File
    await File(imageProcessorFilePath).writeAsBytes(contents);
    Isolate.exit(args[2], imageProcessorFilePath);
  }

  static void imageProcessor(List<dynamic> args) async {
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
  }
}
