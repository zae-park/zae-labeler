import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

class ImageViewer extends StatelessWidget {
  final File? imageFile; // For native File input
  final Uint8List? imageData; // For web or memory-based image input

  const ImageViewer._internal({Key? key, this.imageFile, this.imageData}) : super(key: key);

  /// Factory constructor to create ImageViewer from a file
  factory ImageViewer.fromFile(File file) {
    return ImageViewer._internal(imageFile: file);
  }

  /// Factory constructor to create ImageViewer from a base64 encoded string
  factory ImageViewer.fromBase64(String base64String) {
    try {
      final decodedData = base64Decode(base64String);
      return ImageViewer._internal(imageData: decodedData);
    } catch (e) {
      throw Exception('Invalid base64 image data: $e');
    }
  }

  /// Factory constructor to create ImageViewer from raw Uint8List data
  factory ImageViewer.fromBytes(Uint8List imageBytes) {
    return ImageViewer._internal(imageData: imageBytes);
  }

  @override
  Widget build(BuildContext context) {
    if (imageFile != null) {
      // Handle file input
      if (!imageFile!.existsSync()) {
        return const Center(child: Text('Image file does not exist.'));
      }
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.file(imageFile!, fit: BoxFit.contain),
      );
    } else if (imageData != null) {
      // Handle Uint8List input
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.memory(imageData!, fit: BoxFit.contain),
      );
    } else {
      return const Center(child: Text('No image data available.'));
    }
  }
}
