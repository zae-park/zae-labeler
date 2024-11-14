// lib/charts/object_viewer.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class ObjectViewer extends StatelessWidget {
  final File jsonFile;

  const ObjectViewer({Key? key, required this.jsonFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? jsonData;

    try {
      final fileContent = jsonFile.readAsStringSync();
      jsonData = jsonDecode(fileContent);
    } catch (e) {
      return Center(child: Text('Invalid JSON file: $e'));
    }

    if (jsonData == null) {
      return const Center(child: Text('No data available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: jsonData.length,
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
