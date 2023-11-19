import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';
import 'package:task/core/constants/strings.dart';
import 'package:task/core/util/image_preprocessor_isolate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const ImageDownloadScreen(),
    );
  }
}

class ImageDownloadScreen extends StatefulWidget {
  const ImageDownloadScreen({super.key});

  @override
  State<ImageDownloadScreen> createState() => _ImageDownloadScreenState();
}

class _ImageDownloadScreenState extends State<ImageDownloadScreen> {
  bool _downloading = false;
  String _savedImagePath = '';
  List<String> imagePaths = [];

  // Future<void> _downloadImage() async {
  //   setState(() {
  //     _downloading = true;
  //   });

  //   _savedImagePath = await ImageClient().downloadImage();
  //   imagePaths.add(_savedImagePath);
  //   setState(() {
  //     _downloading = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Downloader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_downloading)
              const CircularProgressIndicator()
            else if (_savedImagePath.isNotEmpty)
              Column(
                children: [
                  Image.file(File(_savedImagePath)) ,
                  const SizedBox(height: 20),
                ],
              )
            else
              const Text(
                'Press the button to download an image!',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          List<Option> editOptions = [
            ColorOption(matrix: [
              2,
              0,
              0,
              0,
              0,
              0,
              0.5,
              0,
              0,
              0,
              0,
              0,
              0.5,
              0,
              0,
              0,
              0,
              0,
              1,
              0
            ]),
            ColorOption(matrix: [
              1,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
              0,
              0,
              0,
              0,
              2,
              0,
              0,
              0,
              0,
              0,
              1,
              0
            ]),
            const RotateOption(180),
            const ScaleOption(
              100,
              100,
            ),
            ColorOption(matrix: [
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0
            ])
          ];
          final imageLinks =
              List.generate(5, (index) => loremPicsumImageLink('$index'));
          await for (final jsonData in ImagePreprocessorIsolate()
              .sendAndReceive(imageLinks, editOptions)) { 
            setState(() {
              _savedImagePath = jsonData;
              // imagePaths.add(jsonData);
            });
          }
        },
        tooltip: 'Download Image',
        child: const Icon(Icons.file_download),
      ),
    );
  }
}
