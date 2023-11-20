import 'dart:io';
import 'dart:isolate';
import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task/core/http_core.dart';

class ImagePreprocessorIsolate {
  // void startImageProcessing() async {

  // }

  // List<Option> editOptions = [
  //   const FlipOption(horizontal: true, vertical: false),
  //   const ClipOption(x: 0, y: 0, width: 1920, height: 1920),
  //   const RotateOption(180),
  //   const ScaleOption(
  //     100,
  //     100,
  //   ),
  //   ColorOption()
  // ];

// Spawns an isolate and asynchronously sends a list of imagelinks for it to
// read and decode. Waits for the response containing the decoded JSON
// before sending the next.
//
// Returns a stream that emits the JSON-decoded contents of each file.
  Stream<List<String>> sendAndReceive(
      List<String> imageLinks, List<Option> editOptions) async* {
    final editorOption = ImageEditorOption();

    List<String> processedImages = [];

    final p = ReceivePort();
    await Isolate.spawn(_readAndParseJsonService, p.sendPort);

    // Convert the ReceivePort into a StreamQueue to receive messages from the
    // spawned isolate using a pull-based interface. Events are stored in this
    // queue until they are accessed by `events.next`.
    final events = StreamQueue<dynamic>(p);

    // The first message from the spawned isolate is a SendPort. This port is
    // used to communicate with the spawned isolate.
    SendPort sendPort = await events.next;

    for (var imageLink in imageLinks) {
      // Send the next imagelink to be read and parsed
      sendPort.send(imageLink);

      // Receive the downloaded image
      Uint8List message = await events.next;
      // Create a file diretory
      String dir = (await getTemporaryDirectory()).path;

      // Create a file path to store the downloaded image
      String imageProcessorFilePath =
          '$dir/image_${DateTime.now().millisecondsSinceEpoch}.png';
      // Add the downloaded image to File
      await File(imageProcessorFilePath).writeAsBytes(message);
      // Add an Image editting option to the image   
      editorOption.addOption(editOptions[imageLinks.indexOf(imageLink)]);

      // Take the downloaded Image and add an edit to it
      final newMessage = await ImageEditor.editFileImage(
          file: File(imageProcessorFilePath), imageEditorOption: editorOption);


      // Create a new file path to store the processed image
      String processedFilePath =
          '$dir/processed_image_${DateTime.now().millisecondsSinceEpoch}.png';

      // Add the processed image to File
      final processedImage =
          await File(processedFilePath).writeAsBytes(newMessage!);

      processedImages.add(processedImage.path);
      // Add the processedImag to the stream returned by this async* function.
      yield processedImages;
    }
    // Send a signal to the spawned isolate indicating that it should exit.
    sendPort.send(null);

    // Dispose the StreamQueue.
    await events.cancel();
  }

// The entrypoint that runs on the spawned isolate. Receives messages from
// the main isolate, takes the list of image links, downloades the image and returns a Uint8List,
// back to the main isolate.
  Future<void> _readAndParseJsonService(SendPort p) async {
    print('Spawned isolate started.');

    // Send a SendPort to the main isolate so that it can send List of image links to
    // this isolate.
    final commandPort = ReceivePort();
    p.send(commandPort.sendPort);

    // Wait for messages from the main isolate.
    await for (final message in commandPort) {
      if (message is String) {
        // Read and decode the string.
        final contents = await ImageClient().downloadImage(message);
        // Send the result to the main isolate.
        p.send(contents);
      } else if (message == null) {
        // Exit if the main isolate sends a null message, indicating there are no
        // more images to download.
        break;
      }
    }

    Isolate.exit();
  }
}
