import 'dart:io';
import 'package:flutter/material.dart';
import 'package:task/core/util/image_preprocessor_isolate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ImagePreprocessorIsolate().initiate();
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
                  Image.file(File(_savedImagePath)),
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
        onPressed: () {
          ImagePreprocessorIsolate().startImageProcessing();
        },
        tooltip: 'Download Image',
        child: const Icon(Icons.file_download),
      ),
    );
  }
}
