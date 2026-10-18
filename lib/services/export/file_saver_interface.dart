abstract class FileSaver {
  Future<void> saveFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  });

  Future<String?> pickJsonFile();
}
