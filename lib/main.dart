import 'dart:io';
import 'package:flutter/material.dart';
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
  final imageStream = ImagePreprocessorIsolate();
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Downloader'),
      ),
      body: StreamBuilder<List<String>>(
        stream: imageStream.imageStream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2)),
                      child: Image.file(
                        File(snapshot.data![index]),
                      ),
                    ),
                  );
                },
              );
            case ConnectionState.done:
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2)),
                      child: Image.file(
                        File(snapshot.data![index]),
                      ),
                    ),
                  );
                },
              );
            case ConnectionState.waiting:
              return isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : const Center(
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
          setState(() {
            isLoading = true;
          });

          final imageLinks =
              List.generate(5, (index) => loremPicsumImageLink('$index'));

          imageStream.sendAndReceive(imageLinks, editOptions);
          setState(() {
            isLoading = false;
          });
        },
        tooltip: 'Download Image',
        child: const Icon(Icons.file_download),
      ),
    );
  }
}
