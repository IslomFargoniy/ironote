import 'file_saver_interface.dart';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart';

class FileExportHelper {
  static final FileSaver _saver = getFileSaver();

  /// Save bytes as a downloadable file (Excel, CSV, JSON)
  static Future<void> saveFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    await _saver.saveFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  /// Pick and read text of a JSON file from device storage / browser
  static Future<String?> pickJsonFile() async {
    return await _saver.pickJsonFile();
  }
}
