import 'file_saver_interface.dart';

class StubFileSaver implements FileSaver {
  @override
  Future<void> saveFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    // Non-web fallback
  }

  @override
  Future<String?> pickJsonFile() async {
    return null;
  }
}

FileSaver getFileSaver() => StubFileSaver();
