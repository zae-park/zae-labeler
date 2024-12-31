// lib/charts/object_viewer.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class ObjectViewer extends StatelessWidget {
  final Map<String, dynamic> jsonData;

  const ObjectViewer._internal({Key? key, required this.jsonData}) : super(key: key);

  /// Factory constructor to create ObjectViewer from a JSON string
  factory ObjectViewer.fromString(String jsonString) {
    try {
      final jsonData = jsonDecode(jsonString);
      if (jsonData is Map<String, dynamic>) {
        return ObjectViewer._internal(jsonData: jsonData);
      } else {
        throw Exception('Decoded data is not a valid JSON object.');
      }
    } catch (e) {
      throw Exception('Invalid JSON data: $e');
    }
  }

  /// Factory constructor to create ObjectViewer from a file
  factory ObjectViewer.fromFile(File file) {
    try {
      final jsonString = file.readAsStringSync();
      final jsonData = jsonDecode(jsonString);
      if (jsonData is Map<String, dynamic>) {
        return ObjectViewer._internal(jsonData: jsonData);
      } else {
        throw Exception('Decoded file content is not a valid JSON object.');
      }
    } catch (e) {
      throw Exception('Invalid JSON file: $e');
    }
  }

  /// Factory constructor to create ObjectViewer directly from a Map<String, dynamic>
  factory ObjectViewer.fromMap(Map<String, dynamic> jsonData) {
    if (jsonData.isNotEmpty) {
      return ObjectViewer._internal(jsonData: jsonData);
    } else {
      throw Exception('Provided map is empty.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (jsonData.isEmpty) {
      return const Center(child: Text('No data available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: jsonData.keys.length,
      itemBuilder: (context, index) {
        final key = jsonData.keys.elementAt(index);
        final value = jsonData[key];

        return ListTile(
          title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value.toString()),
        );
      },
    );
  }
}
