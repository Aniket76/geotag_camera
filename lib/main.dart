import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geotag_camera/image_screen.dart';
import 'package:geotag_camera/take_picture_screen.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoTag Photos',
      theme: ThemeData.dark(),
      home: HomeScreen(camera: camera),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;

  const HomeScreen({required this.camera});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> imagePaths = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = appDir.listSync();
    final List<String> images = files
        .where((file) => file.path.endsWith('.png'))
        .map((file) => file.path)
        .toList();

    setState(() {
      imagePaths = images;
    });
  }

  void _navigateToCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TakePictureScreen(camera: widget.camera)),
    );

    if (result != null) {
      setState(() {
        imagePaths.add(result);
      });
    }
  }

  void _openImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImageScreen(imagePath: imagePath)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(title: const Text('GeoTag Photos')),
          body: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openImage(imagePaths[index]),
                child: Image.file(
                  File(imagePaths[index]),
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _navigateToCamera,
            child: const Icon(Icons.camera),
          ),
        );
      }
    );
  }
}
