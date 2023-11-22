import 'dart:io';
import 'package:flutter/material.dart';
import 'package:task/core/constants/strings.dart';
import 'package:task/core/util/image_preprocessor.dart';
import 'package:task/core/util/model/download_model.dart';

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
  final imagePreprocessor = ImagePreprocessor();
  bool isLoading = false;

  @override
  void dispose() {
    imagePreprocessor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Downloader'),
      ),
      body: StreamBuilder<List<DownloadInformation>>(
        stream: imagePreprocessor.imageStream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final imageInformation = snapshot.data![index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2)),
                      child: imageInformation.imagePath == null
                          ? Center(
                              child: LinearProgressIndicator(
                                value: imageInformation.downloadProgress,
                                color: Colors.white,
                                valueColor: const AlwaysStoppedAnimation(
                                    Colors.amberAccent),
                                // semanticsLabel: 'Linear progress indicator',
                              ),
                            )
                          : Stack(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Image.file(
                                    File(imageInformation.imagePath!),
                                    colorBlendMode: imageInformation.isFiltering
                                        ? BlendMode.darken
                                        : null,
                                    color: imageInformation.isFiltering
                                        ? Colors.black26
                                        : null,
                                  ),
                                ),
                                if (imageInformation.isFiltering)
                                  const Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Adding filter...',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1,
                                            valueColor: AlwaysStoppedAnimation(
                                                Colors.white),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  );
                },
              );
            case ConnectionState.waiting:
              return const Center(
                child: Text('Please click the download button below.'),
              );
            default:
              return const Center(
                child: Text('Please click the download button below.'),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          //   setState(() {
          //     isLoading = true;
          //   });

          final imageLinks =
              List.generate(5, (index) => loremPicsumImageLink('$index'));

          imagePreprocessor.sendAndReceive(imageLinks);
          // setState(() {
          //   isLoading = false;
          // });

          // await for (final jsonData in sendAndReceive2(imageLinks)) {
          //   print('Download progress $jsonData ');
          // }
        },
        tooltip: 'Download Image',
        child: const Icon(Icons.file_download),
      ),
    );
  }
}
