import 'dart:typed_data';

Future<void> downloadPng(Uint8List bytes, String filename) async {
  throw UnsupportedError('Direct browser download is only available on web.');
}
