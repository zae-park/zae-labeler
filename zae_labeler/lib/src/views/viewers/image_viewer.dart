// lib/charts/image_viewer.dart
import 'package:flutter/material.dart';
import 'dart:io';

class ImageViewer extends StatelessWidget {
  final File imageFile;

  const ImageViewer({Key? key, required this.imageFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!imageFile.existsSync()) {
      return const Center(child: Text('Image file does not exist.'));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.file(imageFile, fit: BoxFit.contain),
    );
  }
}
