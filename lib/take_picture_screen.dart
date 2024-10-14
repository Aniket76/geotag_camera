import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;


class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({required this.camera});

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String _location = 'Fetching location...';
  String _timestamp = '';

  GlobalKey _globalKey = GlobalKey();
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
    _getLocation();
    _getTimestamp();
  }

  Future<void> _getLocation() async {
    if (await Permission.location.request().isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _location = '${placemarks.first.name} ${placemarks.first.locality} ${placemarks.first.subLocality} ${placemarks.first.street}';
      });
    } else {
      setState(() {
        _location = 'Location permission denied';
      });
    }
  }

  void _getTimestamp() {
    setState(() {
      _timestamp = DateTime.now().toString();
    });
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = path.join(appDir.path, '${DateTime.now()}.png');

      File imageFile = File(image.path);
      Uint8List imageData = await imageFile.readAsBytes();
      img.Image? capturedImage = img.decodeImage(imageData);

      if (capturedImage != null) {
        await _drawAdditionalImage(capturedImage);

        final File resultImageFile = File(imagePath)
          ..writeAsBytesSync(img.encodePng(capturedImage));

        Navigator.pop(context, imagePath);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              color: Colors.black87.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Location: $_location\nTimestamp: $_timestamp',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.camera),
              label: Text('Take Picture'),
              onPressed: _takePicture,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _drawAdditionalImage(img.Image capturedImage) async {
    final watermarkBytes = await _capturePng();
    final watermarkImage = img.decodeImage(watermarkBytes);

    if (watermarkImage != null) {
      final x = capturedImage.width - watermarkImage.width - 10; // Position the watermark
      final y = capturedImage.height - watermarkImage.height - 10;

      img.drawImage(capturedImage, watermarkImage, dstX: x, dstY: y);
    }
  }

  Future<List<int>> _capturePng() async {
    try {
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      setState(() {
        _imageBytes = pngBytes;
      });

      return pngBytes;
    } catch (e) {
      print(e);
      return [];
    }
  }

}