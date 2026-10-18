// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'file_saver_interface.dart';

class WebFileSaver implements FileSaver {
  @override
  Future<void> saveFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  @override
  Future<String?> pickJsonFile() async {
    final completer = Completer<String?>();
    final uploadInput = html.FileUploadInputElement()..accept = '.json,application/json';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        if (!completer.isCompleted) {
          completer.complete(reader.result as String?);
        }
      });
      reader.onError.listen((e) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      reader.readAsText(file);
    });

    return completer.future;
  }
}

FileSaver getFileSaver() => WebFileSaver();
