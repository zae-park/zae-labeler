// lib/src/views/widgets/class_list.dart
import 'package:flutter/material.dart';
import './core/layouts.dart';

class ClassListWidget extends StatelessWidget {
  final List<String> classes;
  final Function(String) onAddClass;
  final Function(int) onRemoveClass;

  const ClassListWidget({
    Key? key,
    required this.classes,
    required this.onAddClass,
    required this.onRemoveClass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RRow.spaceBetween(
          children: [
            const Text('클래스 목록', style: TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('클래스 추가'),
                    content: TextField(controller: controller, decoration: const InputDecoration(labelText: '클래스 이름')),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (controller.text.isNotEmpty) {
                            onAddClass(controller.text);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('추가'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        ...classes.asMap().entries.map((entry) {
          final index = entry.key;
          final className = entry.value;
          return ListTile(
            title: Text(className),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => onRemoveClass(index)),
          );
        }).toList(),
      ],
    );
  }
}
