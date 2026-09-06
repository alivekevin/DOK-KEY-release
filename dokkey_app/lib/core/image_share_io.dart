import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

/// Native implementation: opens the platform share sheet (save to gallery / SNS)
Future<bool> savePngImpl(Uint8List bytes, String filename) async {
  try {
    final xfile = XFile.fromData(
      bytes,
      mimeType: 'image/png',
      name: filename,
    );
    final result = await Share.shareXFiles(
      [xfile],
      subject: 'DOK-KEY Daily Fortune Card',
      text: 'DOK-KEY — Unlock your day with a single draw. #DOK_KEY',
    );
    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.unavailable;
  } catch (_) {
    return false;
  }
}
