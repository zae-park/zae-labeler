import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../../models/data_model.dart'; // ✅ UnifiedData 모델 불러오기

class ImageViewer extends StatelessWidget {
  final File? imageFile; // ✅ Native 파일 지원
  final Uint8List? imageData; // ✅ Web 또는 메모리 기반 이미지
  final String? base64Content; // ✅ Base64 지원 추가

  const ImageViewer._internal({Key? key, this.imageFile, this.imageData, this.base64Content}) : super(key: key);

  /// ✅ Factory constructor to create ImageViewer from a file
  factory ImageViewer.fromFile(File file) {
    return ImageViewer._internal(imageFile: file);
  }

  /// ✅ Factory constructor to create ImageViewer from a base64 encoded string
  factory ImageViewer.fromBase64(String base64String) {
    try {
      final decodedData = base64Decode(base64String);
      return ImageViewer._internal(imageData: decodedData, base64Content: base64String);
    } catch (e) {
      throw Exception('Invalid base64 image data: $e');
    }
  }

  /// ✅ Factory constructor to create ImageViewer from raw Uint8List data
  factory ImageViewer.fromBytes(Uint8List imageBytes) {
    return ImageViewer._internal(imageData: imageBytes);
  }

  /// ✅ Factory constructor to create ImageViewer from UnifiedData
  factory ImageViewer.fromUnifiedData(UnifiedData unifiedData) {
    if (unifiedData.file != null && unifiedData.file!.existsSync()) {
      return ImageViewer.fromFile(unifiedData.file!);
    } else if (unifiedData.content != null && unifiedData.content!.isNotEmpty) {
      return ImageViewer.fromBase64(unifiedData.content!);
    } else {
      return const ImageViewer._internal();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageFile != null) {
      // ✅ Handle file input (Native 환경)
      if (!imageFile!.existsSync()) {
        return const Center(child: Text('Image file does not exist.'));
      }
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.file(imageFile!, fit: BoxFit.contain),
      );
    } else if (imageData != null) {
      // ✅ Handle Uint8List input (Web 환경)
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.memory(imageData!, fit: BoxFit.contain),
      );
    } else if (base64Content != null && base64Content!.isNotEmpty) {
      // ✅ Handle Base64 input
      try {
        final decodedData = base64Decode(base64Content!);
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.memory(decodedData, fit: BoxFit.contain),
        );
      } catch (e) {
        return Center(child: Text('Invalid base64 image data: $e'));
      }
    } else {
      return const Center(child: Text('No image data available.'));
    }
  }
}
