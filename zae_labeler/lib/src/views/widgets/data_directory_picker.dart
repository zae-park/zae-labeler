// lib/src/views/widgets/data_directory_picker.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DataDirectoryPicker extends StatelessWidget {
  final String? dataDirectory;
  final Function(String) onDataDirectoryChanged;

  const DataDirectoryPicker({
    Key? key,
    required this.dataDirectory,
    required this.onDataDirectoryChanged,
  }) : super(key: key);

  Future<void> _pickDataDirectory(BuildContext context) async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null) {
        final selectedFiles = result.files.map((f) => f.name).join('; ');
        onDataDirectoryChanged(selectedFiles);
      }
    } else {
      final directory = await FilePicker.platform.getDirectoryPath();
      directory != null && onDataDirectoryChanged(directory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            readOnly: true,
            decoration: const InputDecoration(
              labelText: kIsWeb ? '업로드된 파일 경로' : '데이터 디렉토리 경로',
              hintText: kIsWeb ? '파일을 업로드하세요' : '디렉토리를 선택하세요',
            ),
            controller: TextEditingController(text: dataDirectory),
            validator: (value) => (value == null || value.isEmpty) ? (kIsWeb ? '파일을 업로드하세요' : '데이터 디렉토리 경로를 선택하세요') : null,
          ),
        ),
        IconButton(icon: const Icon(kIsWeb ? Icons.upload_file : Icons.folder_open), onPressed: () => _pickDataDirectory(context)),
      ],
    );
  }
}
