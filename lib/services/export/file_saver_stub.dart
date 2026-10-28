import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'file_saver_interface.dart';

/// Mobile implementation: system "Save as" dialog for export, document picker for import.
class StubFileSaver implements FileSaver {
  @override
  Future<void> saveFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: mimeType.split(';').first,
    );
    if (uri == null) {
      throw Exception('Saqlash bekor qilindi');
    }
  }

  @override
  Future<String?> pickJsonFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes());
  }
}

FileSaver getFileSaver() => StubFileSaver();
